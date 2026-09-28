local _, Addon = ...

Addon.Internal = Addon.Internal or {}
Addon.Internal.Comms = Addon.Internal.Comms or {}

local Operations = Addon.Internal.Comms.Operations or {}
local hitCheckAcknowledgementOpcode = type(Operations.Allocate) == "function" and Operations:Allocate(
    "COMBAT_HIT_CHECK_ACK",
    function(arguments, sender, distribution, target, message)
        local client = Addon.Client
        if not client or type(client.HandleCombatHitCheckAck) ~= "function" then
            return false
        end
        return client:HandleCombatHitCheckAck(arguments, sender, distribution, target, message)
    end,
    "combat-hit-check-ack"
) or nil

local hitCheckRejectionOpcode = type(Operations.Allocate) == "function" and Operations:Allocate(
    "COMBAT_HIT_CHECK_REJECT",
    function(arguments, sender, distribution, target, message)
        local client = Addon.Client
        if not client or type(client.HandleCombatHitCheckReject) ~= "function" then
            return false
        end
        return client:HandleCombatHitCheckReject(arguments, sender, distribution, target, message)
    end,
    "combat-hit-check-reject"
) or nil

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

return (hitCheckAcknowledgementOpcode and Operations:Get(hitCheckAcknowledgementOpcode))
    or (hitCheckRejectionOpcode and Operations:Get(hitCheckRejectionOpcode))
    or (operationOpcode and Operations:Get(operationOpcode))
    or (acknowledgementOpcode and Operations:Get(acknowledgementOpcode))
    or nil
