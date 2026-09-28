local _, Addon = ...

Addon.Internal = Addon.Internal or {}
Addon.Internal.Comms = Addon.Internal.Comms or {}

local Operations = Addon.Internal.Comms.Operations or {}

local opcode = type(Operations.Allocate) == "function" and Operations:Allocate(
    "EVENT_SNAPSHOT_REQUEST",
    function(arguments, sender, distribution, target, message)
        local server = Addon.Server
        if type(server) ~= "table" or type(server.HandleEventSnapshotRequest) ~= "function" then
            return false
        end
        return server:HandleEventSnapshotRequest(arguments, sender, distribution, target, message)
    end,
    "event-snapshot-request"
) or nil

return opcode and Operations:Get(opcode) or nil
