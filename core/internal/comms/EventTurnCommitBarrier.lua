local _, Addon = ...

Addon.Internal = Addon.Internal or {}
Addon.Internal.Comms = Addon.Internal.Comms or {}

local Operations = Addon.Internal.Comms.Operations or {}
local OPCODE = 41
local OPERATION_KEY = "EVENT_TURN_COMMIT_BARRIER"

local existing = type(Operations.Get) == "function" and Operations:Get(OPCODE) or nil
if existing and tostring(existing.key or "") ~= OPERATION_KEY then
    error(("RPE EVENT_TURN_COMMIT_BARRIER opcode %d conflicts with %s."):format(OPCODE, tostring(existing.key or existing.name or "unknown")), 2)
end

local operation = type(Operations.Register) == "function" and Operations:Register(OPCODE, function(arguments, sender, distribution, target, message)
    if type(arguments) == "table" and arguments[6] == "request" then
        local client = Addon.Client
        return client and type(client.HandleEventTurnCommitBarrierRequest) == "function"
            and client:HandleEventTurnCommitBarrierRequest(arguments, sender, distribution, target, message)
            or false
    end
    local server = Addon.Server
    return server and type(server.HandleEventTurnCommitBarrierAcknowledgement) == "function"
        and server:HandleEventTurnCommitBarrierAcknowledgement(arguments, sender, distribution, target, message)
        or false
end, "event-turn-commit-barrier") or nil

if operation then
    operation.key = OPERATION_KEY
    Operations.KeyIndex = Operations.KeyIndex or {}
    Operations.KeyIndex[OPERATION_KEY] = OPCODE
    Operations.Opcodes = Operations.Opcodes or {}
    Operations.Opcodes[OPCODE] = operation
end

return operation
