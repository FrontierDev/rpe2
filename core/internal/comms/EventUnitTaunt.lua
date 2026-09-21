local _, Addon = ...

Addon.Internal = Addon.Internal or {}
Addon.Internal.Comms = Addon.Internal.Comms or {}

local Operations = Addon.Internal.Comms.Operations or {}
local operationOpcode = type(Operations.Allocate) == "function" and Operations:Allocate(
    "EVENT_UNIT_TAUNT",
    function(arguments, sender, distribution, target, message)
        local server = Addon.Server
        if not server or type(server.HandleEventUnitTaunt) ~= "function" then
            return false
        end

        return server:HandleEventUnitTaunt(arguments, sender, distribution, target, message)
    end,
    "event-unit-taunt"
) or nil

return operationOpcode and Operations:Get(operationOpcode) or nil
