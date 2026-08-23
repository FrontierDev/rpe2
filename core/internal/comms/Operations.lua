local _, Addon = ...

Addon.Internal = Addon.Internal or {}
Addon.Internal.Comms = Addon.Internal.Comms or {}
Addon.Internal.Comms.Operations = Addon.Internal.Comms.Operations or {}
Addon.Utils = Addon.Utils or {}

local Common = Addon.Utils.Common or {}
local Operations = Addon.Internal.Comms.Operations

Operations.Registry = Operations.Registry or {}
Operations.KeyIndex = Operations.KeyIndex or {}

local invokeCallback = Common.InvokeCallback

local function ensureOperation(self, opcode)
    local numericOpcode = tonumber(opcode)
    if not numericOpcode then
        return nil
    end

    local operation = self.Registry[numericOpcode]
    if operation then
        return operation
    end

    operation = {
        opcode = numericOpcode,
        key = self.KeyIndex and self.KeyIndex[numericOpcode] or nil,
        name = "",
        ["function"] = nil,
    }

    self.Registry[numericOpcode] = operation
    return operation
end

function Operations:Register(opcode, handler, name)
    local numericOpcode = tonumber(opcode)
    if not numericOpcode then
        error("Addon.Internal.Comms.Operations:Register(opcode, handler, name) requires a numeric opcode.", 2)
    end

    if type(handler) ~= "function" then
        error("Addon.Internal.Comms.Operations:Register(opcode, handler, name) requires a function handler.", 2)
    end

    local operation = ensureOperation(self, numericOpcode)
    if not operation then
        error("Addon.Internal.Comms.Operations:Register(opcode, handler, name) could not allocate an operation entry.", 2)
    end

    operation.name = tostring(name or operation.name or "")
    operation["function"] = handler
    if not operation.key and self.KeyIndex then
        operation.key = self.KeyIndex[numericOpcode]
    end

    return operation
end

function Operations:Unregister(opcode)
    local numericOpcode = tonumber(opcode)
    if not numericOpcode then
        return false
    end

    self.Registry[numericOpcode] = nil
    return true
end

function Operations:Get(opcode)
    local numericOpcode = tonumber(opcode)
    if not numericOpcode then
        return nil
    end

    return self.Registry[numericOpcode]
end

function Operations:GetOpcode(key)
    if type(key) ~= "string" or key == "" then
        return nil
    end

    return self.KeyIndex[string.upper(key)]
end

function Operations:GetByKey(key)
    local opcode = self:GetOpcode(key)
    if not opcode then
        return nil
    end

    return self:Get(opcode)
end

function Operations:Dispatch(opcode, arguments, sender, distribution, target, message)
    local operation = self:Get(opcode)
    if not operation then
        return false
    end

    invokeCallback(operation["function"], arguments or {}, sender, distribution, target, message)
    return true
end

function Operations:ResetRegistry()
    self.Registry = {}
    self.KeyIndex = {}

    for opcode, definition in pairs(self.Opcodes or {}) do
        local numericOpcode = tonumber(opcode)
        if numericOpcode then
            definition.opcode = numericOpcode
            self.Registry[numericOpcode] = definition
            self.KeyIndex[string.upper(tostring(definition.key or ""))] = numericOpcode
        end
    end

    return self.Registry
end

Operations.Opcodes = Operations.Opcodes or {
    [1] = {
        key = "SERVER_START",
        name = "server-start",
        ["function"] = function(arguments, sender, distribution, target, message)
            local client = Addon.Client
            if not client or type(client.HandleServerStart) ~= "function" then
                return false
            end

            return client:HandleServerStart(arguments, sender, distribution, target, message)
        end,
    },
    [2] = {
        key = "SERVER_STOP",
        name = "server-stop",
        ["function"] = function(arguments, sender, distribution, target, message)
            local client = Addon.Client
            if not client or type(client.HandleServerStop) ~= "function" then
                return false
            end

            return client:HandleServerStop(arguments, sender, distribution, target, message)
        end,
    },
    [3] = {
        key = "CLIENT_CONNECT",
        name = "client-connect",
        ["function"] = function(arguments, sender, distribution, target, message)
            local server = Addon.Server
            local client = Addon.Client
            local handled = false

            if server and type(server.HandleClientConnect) == "function" then
                handled = server:HandleClientConnect(arguments, sender, distribution, target, message) or handled
            end

            if client and type(client.HandleClientConnect) == "function" then
                handled = client:HandleClientConnect(arguments, sender, distribution, target, message) or handled
            end

            return handled
        end,
    },
    [4] = {
        key = "CLIENT_DISCONNECT",
        name = "client-disconnect",
        ["function"] = function(arguments, sender, distribution, target, message)
            local server = Addon.Server
            local client = Addon.Client
            local handled = false

            if server and type(server.HandleClientDisconnect) == "function" then
                handled = server:HandleClientDisconnect(arguments, sender, distribution, target, message) or handled
            end

            if client and type(client.HandleClientDisconnect) == "function" then
                handled = client:HandleClientDisconnect(arguments, sender, distribution, target, message) or handled
            end

            return handled
        end,
    },
    [5] = {
        key = "EVENT_START",
        name = "event-start",
        ["function"] = function(arguments, sender, distribution, target, message)
            local client = Addon.Client
            if not client or type(client.HandleEventStart) ~= "function" then
                return false
            end

            return client:HandleEventStart(arguments, sender, distribution, target, message)
        end,
    },
    [6] = {
        key = "EVENT_END",
        name = "event-end",
        ["function"] = function(arguments, sender, distribution, target, message)
            local client = Addon.Client
            if not client or type(client.HandleEventEnd) ~= "function" then
                return false
            end

            return client:HandleEventEnd(arguments, sender, distribution, target, message)
        end,
    },
    [7] = {
        key = "EVENT_UNITS",
        name = "event-units",
        ["function"] = function(arguments, sender, distribution, target, message)
            local client = Addon.Client
            if not client or type(client.HandleEventUnits) ~= "function" then
                return false
            end

            return client:HandleEventUnits(arguments, sender, distribution, target, message)
        end,
    },
    [8] = {
        key = "EVENT_STATE",
        name = "event-state",
        ["function"] = function(arguments, sender, distribution, target, message)
            local client = Addon.Client
            if not client or type(client.HandleEventState) ~= "function" then
                return false
            end

            return client:HandleEventState(arguments, sender, distribution, target, message)
        end,
    },
    [9] = {
        key = "RESOURCE",
        name = "resource",
        ["function"] = function(arguments, sender, distribution, target, message)
            local server = Addon.Server
            local client = Addon.Client
            local handled = false

            if server and type(server.HandleResource) == "function" then
                handled = server:HandleResource(arguments, sender, distribution, target, message) or handled
            end

            if client and type(client.HandleResource) == "function" then
                handled = client:HandleResource(arguments, sender, distribution, target, message) or handled
            end

            return handled
        end,
    },
    [10] = {
        key = "SERVER_QUERY",
        name = "server-query",
        ["function"] = function(arguments, sender, distribution, target, message)
            local server = Addon.Server
            if not server or type(server.HandleServerQuery) ~= "function" then
                return false
            end

            return server:HandleServerQuery(arguments, sender, distribution, target, message)
        end,
    },
    [11] = {
        key = "SPELLCAST_START",
        name = "spellcast-start",
        ["function"] = function(arguments, sender, distribution, target, message)
            local server = Addon.Server
            local client = Addon.Client
            local handled = false

            if server and type(server.HandleSpellcastStart) == "function" then
                handled = server:HandleSpellcastStart(arguments, sender, distribution, target, message) or handled
            end

            if client and type(client.HandleSpellcastStart) == "function" then
                handled = client:HandleSpellcastStart(arguments, sender, distribution, target, message) or handled
            end

            return handled
        end,
    },
    [12] = {
        key = "SPELLCAST_COMPLETE",
        name = "spellcast-complete",
        ["function"] = function(arguments, sender, distribution, target, message)
            local server = Addon.Server
            local client = Addon.Client
            local handled = false

            if server and type(server.HandleSpellcastComplete) == "function" then
                handled = server:HandleSpellcastComplete(arguments, sender, distribution, target, message) or handled
            end

            if client and type(client.HandleSpellcastComplete) == "function" then
                handled = client:HandleSpellcastComplete(arguments, sender, distribution, target, message) or handled
            end

            return handled
        end,
    },
    [13] = {
        key = "SPELLCAST_INTERRUPT",
        name = "spellcast-interrupt",
        ["function"] = function(arguments, sender, distribution, target, message)
            local server = Addon.Server
            local client = Addon.Client
            local handled = false

            if server and type(server.HandleSpellcastInterrupt) == "function" then
                handled = server:HandleSpellcastInterrupt(arguments, sender, distribution, target, message) or handled
            end

            if client and type(client.HandleSpellcastInterrupt) == "function" then
                handled = client:HandleSpellcastInterrupt(arguments, sender, distribution, target, message) or handled
            end

            return handled
        end,
    },
    [14] = {
        key = "COMBAT_HIT_CHECK_REQUEST",
        name = "combat-hit-check-request",
        ["function"] = function(arguments, sender, distribution, target, message)
            local client = Addon.Client
            if not client or type(client.HandleCombatHitCheckRequest) ~= "function" then
                return false
            end

            return client:HandleCombatHitCheckRequest(arguments, sender, distribution, target, message)
        end,
    },
    [15] = {
        key = "COMBAT_HIT_CHECK_RESPONSE",
        name = "combat-hit-check-response",
        ["function"] = function(arguments, sender, distribution, target, message)
            local client = Addon.Client
            if not client or type(client.HandleCombatHitCheckResponse) ~= "function" then
                return false
            end

            return client:HandleCombatHitCheckResponse(arguments, sender, distribution, target, message)
        end,
    },
    [16] = {
        key = "RESOURCE_DELTA",
        name = "resource-delta",
        ["function"] = function(arguments, sender, distribution, target, message)
            local server = Addon.Server
            local client = Addon.Client
            local handled = false

            if server and type(server.HandleResourceDelta) == "function" then
                handled = server:HandleResourceDelta(arguments, sender, distribution, target, message) or handled
            end

            if client and type(client.HandleResourceDelta) == "function" then
                handled = client:HandleResourceDelta(arguments, sender, distribution, target, message) or handled
            end

            return handled
        end,
    },
    [17] = {
        key = "AURA_APPLY",
        name = "aura-apply",
        ["function"] = function(arguments, sender, distribution, target, message)
            local client = Addon.Client
            if not client or type(client.HandleAuraApply) ~= "function" then
                return false
            end

            return client:HandleAuraApply(arguments, sender, distribution, target, message)
        end,
    },
    [18] = {
        key = "AURA_DISPEL",
        name = "aura-dispel",
        ["function"] = function(arguments, sender, distribution, target, message)
            local client = Addon.Client
            if not client or type(client.HandleAuraDispel) ~= "function" then
                return false
            end

            return client:HandleAuraDispel(arguments, sender, distribution, target, message)
        end,
    },
    [19] = {
        key = "RESOURCE_DELTA_BATCH",
        name = "resource-delta-batch",
        ["function"] = function(arguments, sender, distribution, target, message)
            local server = Addon.Server
            local client = Addon.Client
            local handled = false

            if server and type(server.HandleResourceDeltaBatch) == "function" then
                handled = server:HandleResourceDeltaBatch(arguments, sender, distribution, target, message) or handled
            end

            if client and type(client.HandleResourceDeltaBatch) == "function" then
                handled = client:HandleResourceDeltaBatch(arguments, sender, distribution, target, message) or handled
            end

            return handled
        end,
    },
    [20] = {
        key = "AURA_APPLY_BATCH",
        name = "aura-apply-batch",
        ["function"] = function(arguments, sender, distribution, target, message)
            local client = Addon.Client
            local handled = false

            if client and type(client.HandleAuraApplyBatch) == "function" then
                handled = client:HandleAuraApplyBatch(arguments, sender, distribution, target, message) or handled
            end

            return handled
        end,
    },
    [21] = {
        key = "AURA_DISPEL_BATCH",
        name = "aura-dispel-batch",
        ["function"] = function(arguments, sender, distribution, target, message)
            local client = Addon.Client
            local handled = false

            if client and type(client.HandleAuraDispelBatch) == "function" then
                handled = client:HandleAuraDispelBatch(arguments, sender, distribution, target, message) or handled
            end

            return handled
        end,
    },
    [22] = {
        key = "EVENT_UNIT_DELTA_BATCH",
        name = "event-unit-delta-batch",
        ["function"] = function(arguments, sender, distribution, target, message)
            local client = Addon.Client
            if not client or type(client.HandleEventUnitDeltaBatch) ~= "function" then
                return false
            end

            return client:HandleEventUnitDeltaBatch(arguments, sender, distribution, target, message)
        end,
    },
    [23] = {
        key = "COMBAT_LOG",
        name = "combat-log",
        ["function"] = function(arguments, sender, distribution, target, message)
            local client = Addon.Client
            if not client or type(client.HandleCombatLog) ~= "function" then
                return false
            end

            return client:HandleCombatLog(arguments, sender, distribution, target, message)
        end,
    },
    [24] = {
        key = "GUILD_ADMIN_QUERY",
        name = "guild-admin-query",
        ["function"] = function(arguments, sender, distribution, target, message)
            local guild = Addon.Client and Addon.Client.Guild
            if not guild or type(guild.HandleGuildAdminQuery) ~= "function" then
                return false
            end

            return guild:HandleGuildAdminQuery(arguments, sender, distribution, target, message)
        end,
    },
    [25] = {
        key = "GUILD_ADMIN_QUERY_RESPONSE",
        name = "guild-admin-query-response",
        ["function"] = function(arguments, sender, distribution, target, message)
            local guild = Addon.Client and Addon.Client.Guild
            if not guild or type(guild.HandleGuildAdminQueryResponse) ~= "function" then
                return false
            end

            return guild:HandleGuildAdminQueryResponse(arguments, sender, distribution, target, message)
        end,
    },
    [26] = {
        key = "GUILD_ADMIN_MUTATION",
        name = "guild-admin-mutation",
        ["function"] = function(arguments, sender, distribution, target, message)
            local guild = Addon.Client and Addon.Client.Guild
            if not guild or type(guild.HandleGuildAdminMutation) ~= "function" then
                return false
            end

            return guild:HandleGuildAdminMutation(arguments, sender, distribution, target, message)
        end,
    },
    [27] = {
        key = "GUILD_ADMIN_MUTATION_RESPONSE",
        name = "guild-admin-mutation-response",
        ["function"] = function(arguments, sender, distribution, target, message)
            local guild = Addon.Client and Addon.Client.Guild
            if not guild or type(guild.HandleGuildAdminMutationResponse) ~= "function" then
                return false
            end

            return guild:HandleGuildAdminMutationResponse(arguments, sender, distribution, target, message)
        end,
    },
}

Operations:ResetRegistry()
