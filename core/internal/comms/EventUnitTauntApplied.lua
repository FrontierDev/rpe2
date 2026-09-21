local _, Addon = ...

Addon.Internal = Addon.Internal or {}
Addon.Internal.Comms = Addon.Internal.Comms or {}

local Operations = Addon.Internal.Comms.Operations or {}
local operationOpcode = type(Operations.Allocate) == "function" and Operations:Allocate(
    "EVENT_UNIT_TAUNT_APPLIED",
    function(arguments, sender, distribution, target, message)
        local client = Addon.Client
        if not client or type(client.HandleEventUnitTauntApplied) ~= "function" then
            return false
        end

        return client:HandleEventUnitTauntApplied(arguments, sender, distribution, target, message)
    end,
    "event-unit-taunt-applied"
) or nil

return operationOpcode and Operations:Get(operationOpcode) or nil
