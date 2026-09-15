local _, Addon = ...

Addon.Internal = Addon.Internal or {}
Addon.Internal.Comms = Addon.Internal.Comms or {}

local Operations = Addon.Internal.Comms.Operations or {}
local OPCODE = 35
local OPERATION_KEY = "EVENT_TURN_COMPLETE"

local existing = type(Operations.Get) == "function" and Operations:Get(OPCODE) or nil
if existing and tostring(existing.key or "") ~= OPERATION_KEY then
    error(("RPE EVENT_TURN_COMPLETE opcode %d conflicts with %s."):format(OPCODE, tostring(existing.key or existing.name or "unknown")), 2)
end

local operation = type(Operations.Register) == "function" and Operations:Register(OPCODE, function(arguments, sender, distribution, target, message)
    if type(arguments) == "table" and arguments[6] == "confirmed" then
        local client = Addon.Client
        if not client or type(client.HandleEventTurnComplete) ~= "function" then
            return false
        end

        return client:HandleEventTurnComplete(arguments, sender, distribution, target, message)
    end

    local server = Addon.Server
    if not server or type(server.HandleEventTurnComplete) ~= "function" then
        return false
    end

    return server:HandleEventTurnComplete(arguments, sender, distribution, target, message)
end, "event-turn-complete") or nil

if operation then
    operation.key = OPERATION_KEY
    Operations.KeyIndex = Operations.KeyIndex or {}
    Operations.KeyIndex[OPERATION_KEY] = OPCODE
    Operations.Opcodes = Operations.Opcodes or {}
    Operations.Opcodes[OPCODE] = operation
end

return operation
