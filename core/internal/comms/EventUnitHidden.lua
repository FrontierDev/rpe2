local _, Addon = ...

Addon.Internal = Addon.Internal or {}
Addon.Internal.Comms = Addon.Internal.Comms or {}

local Operations = Addon.Internal.Comms.Operations or {}
local OPCODE = 34
local OPERATION_KEY = "EVENT_UNIT_HIDDEN"

local existing = type(Operations.Get) == "function" and Operations:Get(OPCODE) or nil
if existing and tostring(existing.key or "") ~= OPERATION_KEY then
    error(("RPE EVENT_UNIT_HIDDEN opcode %d conflicts with %s."):format(OPCODE, tostring(existing.key or existing.name or "unknown")), 2)
end

local operation = type(Operations.Register) == "function" and Operations:Register(OPCODE, function(arguments, sender, distribution, target, message)
    local server = Addon.Server
    if not server or type(server.HandleEventUnitHidden) ~= "function" then
        return false
    end

    return server:HandleEventUnitHidden(arguments, sender, distribution, target, message)
end, "event-unit-hidden") or nil

if operation then
    operation.key = OPERATION_KEY
    Operations.KeyIndex = Operations.KeyIndex or {}
    Operations.KeyIndex[OPERATION_KEY] = OPCODE
    Operations.Opcodes = Operations.Opcodes or {}
    Operations.Opcodes[OPCODE] = operation
end

return operation
