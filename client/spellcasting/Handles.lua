local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Client.Spellcasting = Addon.Client.Spellcasting or {}

local Client = Addon.Client
local AuraManager = Addon.Client.Spellcasting and Addon.Client.Spellcasting.AuraManager or nil

local function isLiveAuraContext(context)
    local eventState = type(context) == "table" and context.eventState or nil
    return type(eventState) == "table"
        and eventState.active == true
        and eventState.ending ~= true
        and eventState.startupReady == true
end

local function callLiveAuraMutation(nativeHandler, manager, client, context, ...)
    if type(nativeHandler) ~= "function" or not isLiveAuraContext(context) then
        return nativeHandler(manager, client, context, ...)
    end

    -- A live aura mutation should use its own aura packet as the remote
    -- presentation boundary. Make the existing outbound aura queue flush now
    -- instead of waiting for End Turn / Advance.
    local previousImmediate = context.immediate
    context.immediate = true

    -- The aura manager also emits a COMBAT_LOG status entry locally. Keep that
    -- local ticker entry, but do not broadcast a second independent message:
    -- remote clients will create the same ticker entry when they install the
    -- inbound AURA_APPLY/AURA_DISPEL packet. This keeps state and presentation
    -- ordered together and prevents duplicate ticker entries.
    local nativeQueueCombatLogEntryEmission = client.QueueCombatLogEntryEmission
    local nativeQueueCombatLogEntry = client.QueueCombatLogEntry
    if type(nativeQueueCombatLogEntryEmission) == "function"
        and type(nativeQueueCombatLogEntry) == "function"
    then
        client.QueueCombatLogEntryEmission = function(targetClient, entry)
            return nativeQueueCombatLogEntry(targetClient, entry)
        end
    end

    local ok, firstResult, secondResult = pcall(nativeHandler, manager, client, context, ...)

    context.immediate = previousImmediate
    client.QueueCombatLogEntryEmission = nativeQueueCombatLogEntryEmission

    if not ok then
        error(firstResult, 0)
    end
    return firstResult, secondResult
end

-- Keep live aura changes synchronized immediately. Startup reconciliation keeps
-- its original deferred behavior because eventState.startupReady is still false.
if AuraManager and AuraManager._liveAuraMutationSyncInstalled ~= true then
    AuraManager._liveAuraMutationSyncInstalled = true

    if type(AuraManager.ApplyAuraFromContext) == "function" then
        local nativeApplyAuraFromContext = AuraManager.ApplyAuraFromContext
        function AuraManager:ApplyAuraFromContext(client, context, ...)
            return callLiveAuraMutation(nativeApplyAuraFromContext, self, client, context, ...)
        end
    end

    if type(AuraManager.RemoveAuraStacksFromContext) == "function" then
        local nativeRemoveAuraStacksFromContext = AuraManager.RemoveAuraStacksFromContext
        function AuraManager:RemoveAuraStacksFromContext(client, context, ...)
            return callLiveAuraMutation(nativeRemoveAuraStacksFromContext, self, client, context, ...)
        end
    end

    if type(AuraManager.DispelAuraFromContext) == "function" then
        local nativeDispelAuraFromContext = AuraManager.DispelAuraFromContext
        function AuraManager:DispelAuraFromContext(client, context, ...)
            local changed = callLiveAuraMutation(nativeDispelAuraFromContext, self, client, context, ...)
            return changed
        end
    end

    -- A live aura flush may already have removed its operation from the pending
    -- table while its sliceable flush job is still completing. The turn commit
    -- must regard that matching in-flight job as pending rather than advance the
    -- event step early.
    if type(AuraManager.HasPendingOutboundAuraOperations) == "function" then
        local nativeHasPendingOutboundAuraOperations = AuraManager.HasPendingOutboundAuraOperations
        function AuraManager:HasPendingOutboundAuraOperations(client, scopeOverride, eventStateOverride, sourceTurnNumber, sourceTickNumber)
            if nativeHasPendingOutboundAuraOperations(
                self,
                client,
                scopeOverride,
                eventStateOverride,
                sourceTurnNumber,
                sourceTickNumber
            ) == true then
                return true
            end

            local scope = tostring(scopeOverride or "turn") == "reaction" and "reaction" or "turn"
            local job = type(client) == "table"
                and type(client.PendingOutboundAuraFlushJobsByScope) == "table"
                and client.PendingOutboundAuraFlushJobsByScope[scope]
                or nil
            local state = type(job) == "table" and job.state or nil
            if type(job) ~= "table"
                or job.finalized == true
                or job.cancelled == true
                or type(state) ~= "table"
            then
                return false
            end

            if eventStateOverride ~= nil and state.expectedEventState ~= eventStateOverride then
                return false
            end
            if sourceTurnNumber ~= nil and tonumber(state.sourceTurnNumber) ~= tonumber(sourceTurnNumber) then
                return false
            end
            if sourceTickNumber ~= nil and tonumber(state.sourceTickNumber) ~= tonumber(sourceTickNumber) then
                return false
            end
            return true
        end
    end
end

function Client:HandleAuraApply(arguments, sender)
    if not AuraManager or type(AuraManager.HandleAuraApply) ~= "function" then
        return false
    end

    return AuraManager:HandleAuraApply(self, arguments, sender)
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

    return AuraManager:HandleAuraApplyBatch(self, arguments, sender)
end

function Client:HandleAuraDispelBatch(arguments, sender)
    if not AuraManager or type(AuraManager.HandleAuraDispelBatch) ~= "function" then
        return false
    end

    return AuraManager:HandleAuraDispelBatch(self, arguments, sender)
end

return Client
