local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Client.Spellcasting = Addon.Client.Spellcasting or {}

local Client = Addon.Client
local AuraManager = Addon.Client.Spellcasting and Addon.Client.Spellcasting.AuraManager or nil

local function flushLiveAuraApply(client, context)
    if type(AuraManager) ~= "table"
        or type(AuraManager.FlushOutboundAuraOperations) ~= "function"
        or type(client) ~= "table"
        or type(context) ~= "table"
        or context.immediate == true
    then
        return false
    end

    local eventState = context.eventState
    if type(eventState) ~= "table"
        or eventState.active ~= true
        or eventState.ending == true
        or eventState.startupReady ~= true
    then
        return false
    end

    local scope = tostring(context.pendingScope or context.scope or "turn") == "reaction"
        and "reaction"
        or "turn"

    return AuraManager:FlushOutboundAuraOperations(
        client,
        scope,
        eventState,
        math.floor(tonumber(eventState.turnNumber) or 0),
        math.floor(tonumber(eventState.tickNumber) or 0)
    ) == true
end

-- Live aura state must reach the other event clients when the local aura is
-- applied, rather than waiting for the next turn-commit barrier. Keep the
-- existing pending/flush implementation so a send which is still in flight is
-- still visible to the turn commit and must complete before the step advances.
if AuraManager and AuraManager._liveAuraApplyFlushInstalled ~= true then
    AuraManager._liveAuraApplyFlushInstalled = true

    if type(AuraManager.ApplyAuraFromContext) == "function" then
        local nativeApplyAuraFromContext = AuraManager.ApplyAuraFromContext
        function AuraManager:ApplyAuraFromContext(client, context, ...)
            local applied, entry = nativeApplyAuraFromContext(self, client, context, ...)
            if applied == true then
                flushLiveAuraApply(client, context)
            end
            return applied, entry
        end
    end

    if type(AuraManager.RemoveAuraStacksFromContext) == "function" then
        local nativeRemoveAuraStacksFromContext = AuraManager.RemoveAuraStacksFromContext
        function AuraManager:RemoveAuraStacksFromContext(client, context, ...)
            local changed, entry = nativeRemoveAuraStacksFromContext(self, client, context, ...)
            if changed == true then
                flushLiveAuraApply(client, context)
            end
            return changed, entry
        end
    end
end

-- The aura owner already emits the status entry through COMBAT_LOG when the
-- local aura changes. The inbound AURA_APPLY handler also queues an equivalent
-- local status entry after installing the remote state. Suppress only that
-- second presentation entry; the authoritative aura mutation and all display /
-- derived-state refreshes still run normally.
local function handleInboundAuraApplyWithoutDuplicateTicker(handler, arguments, sender)
    if not AuraManager or type(handler) ~= "function" then
        return false
    end

    local nativeQueueCombatLogEntry = Client.QueueCombatLogEntry
    if type(nativeQueueCombatLogEntry) ~= "function" then
        return handler(AuraManager, Client, arguments, sender)
    end

    Client.QueueCombatLogEntry = function()
        return true
    end
    local ok, result = pcall(handler, AuraManager, Client, arguments, sender)
    Client.QueueCombatLogEntry = nativeQueueCombatLogEntry

    if not ok then
        error(result, 0)
    end
    return result
end

function Client:HandleAuraApply(arguments, sender)
    if not AuraManager or type(AuraManager.HandleAuraApply) ~= "function" then
        return false
    end

    return handleInboundAuraApplyWithoutDuplicateTicker(AuraManager.HandleAuraApply, arguments, sender)
end

function Client:HandleAuraDispel(arguments, sender)
    if not AuraManager or type(AuraManager.HandleAuraDispel) ~= "function" then
        return false
    end

    return AuraManager:HandleAuraDispel(self, arguments, sender)
end

function Client:HandleAuraApplyBatch(arguments, sender)
    if not AuraManager or type(AuraManager.HandleAuraApplyBatch) ~= "function" then
        return false
    end

    return handleInboundAuraApplyWithoutDuplicateTicker(AuraManager.HandleAuraApplyBatch, arguments, sender)
end

function Client:HandleAuraDispelBatch(arguments, sender)
    if not AuraManager or type(AuraManager.HandleAuraDispelBatch) ~= "function" then
        return false
    end

    return AuraManager:HandleAuraDispelBatch(self, arguments, sender)
end

return Client
