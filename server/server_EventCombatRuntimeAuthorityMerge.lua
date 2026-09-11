local _, Addon = ...

local Server = Addon.Server or {}
local Client = Addon.Client or {}
local Comms = Addon.Internal and Addon.Internal.Comms or {}
local EventSync = Comms.EventSync or {}
local CombatState = Comms.EventCombatState or {}
local Serialization = Comms.Serialization or {}
local Operations = Comms.Operations or {}
local Common = Addon.Utils and Addon.Utils.Common or {}
local Spellcasting = Client.Spellcasting or {}
local AuraManager = Spellcasting.AuraManager or (Addon.Internal and Addon.Internal.AuraManager) or nil

local AURA_APPLY_OPCODE = Operations.GetOpcode and Operations:GetOpcode("AURA_APPLY") or nil
local AURA_DISPEL_OPCODE = Operations.GetOpcode and Operations:GetOpcode("AURA_DISPEL") or nil
local AURA_APPLY_BATCH_OPCODE = Operations.GetOpcode and Operations:GetOpcode("AURA_APPLY_BATCH") or nil
local AURA_DISPEL_BATCH_OPCODE = Operations.GetOpcode and Operations:GetOpcode("AURA_DISPEL_BATCH") or nil
local SPELLCAST_START_OPCODE = Operations.GetOpcode and Operations:GetOpcode("SPELLCAST_START") or nil
local SPELLCAST_COMPLETE_OPCODE = Operations.GetOpcode and Operations:GetOpcode("SPELLCAST_COMPLETE") or nil
local SPELLCAST_INTERRUPT_OPCODE = Operations.GetOpcode and Operations:GetOpcode("SPELLCAST_INTERRUPT") or nil
local EVENT_DEFENSIVE_USE_OPCODE = Operations.GetOpcode and Operations:GetOpcode("EVENT_DEFENSIVE_USE") or nil

local AURA_RECORD_SEPARATOR = string.char(27)
local AURA_FIELD_SEPARATOR = string.char(26)

local function normalizeName(value)
    if type(Common.NormalizeName) == "function" then
        return Common.NormalizeName(value)
    end
    return tostring(value or "")
end

local function localPlayerName()
    return normalizeName(type(Common.GetPlayerName) == "function" and Common.GetPlayerName() or nil)
end

local function cloneRuntimeSections(runtime)
    runtime = type(runtime) == "table" and runtime or {}
    return {
        auras = type(CombatState.CloneAuraRecords) == "function" and CombatState.CloneAuraRecords(runtime.auras or {}) or {},
        spellcasts = type(CombatState.CloneCastBucket) == "function" and CombatState.CloneCastBucket(runtime.spellcasts or {}) or {},
        cooldowns = type(CombatState.CloneCooldownBucket) == "function" and CombatState.CloneCooldownBucket(runtime.cooldowns or {}) or {},
        defensiveReactions = type(CombatState.CloneDefensiveState) == "function" and CombatState.CloneDefensiveState(
            runtime.turnState and runtime.turnState.defensiveReactions or {}
        ) or {},
    }
end

local function splitPreservingEmpty(value, separator)
    if type(Common.SplitPreservingEmpty) == "function" then
        return Common.SplitPreservingEmpty(value, separator)
    end
    local rows = {}
    local text = tostring(value or "")
    local start = 1
    while true do
        local position = string.find(text, separator, start, true)
        if not position then
            rows[#rows + 1] = string.sub(text, start)
            break
        end
        rows[#rows + 1] = string.sub(text, start, position - 1)
        start = position + #separator
    end
    return rows
end

local function parseAuraApplyBatch(payload)
    local entries = {}
    if type(payload) ~= "string" or payload == "" then
        return entries
    end
    local records = splitPreservingEmpty(payload, AURA_RECORD_SEPARATOR)
    for index = 1, #records do
        local fields = splitPreservingEmpty(records[index], AURA_FIELD_SEPARATOR)
        if #fields >= 3 then
            entries[#entries + 1] = {
                casterEventId = tonumber(fields[1]) or 0,
                targetEventId = tonumber(fields[2]) or 0,
                auraRef = tostring(fields[3] or ""),
                stacks = math.max(1, math.floor(tonumber(fields[4]) or 1)),
                turns = math.max(1, math.floor(tonumber(fields[5]) or 1)),
                powerLevel = tonumber(fields[6]) or 0,
                fullState = tostring(fields[7] or "") == "1",
            }
        end
    end
    return entries
end

local function parseAuraDispelBatch(payload)
    local entries = {}
    if type(payload) ~= "string" or payload == "" then
        return entries
    end
    local records = splitPreservingEmpty(payload, AURA_RECORD_SEPARATOR)
    for index = 1, #records do
        local fields = splitPreservingEmpty(records[index], AURA_FIELD_SEPARATOR)
        if #fields >= 3 then
            entries[#entries + 1] = {
                casterEventId = tonumber(fields[1]) or 0,
                targetEventId = tonumber(fields[2]) or 0,
                auraRef = tostring(fields[3] or ""),
            }
        end
    end
    return entries
end

local function applyHostLocalAuraScratch(opcode, arguments, sender)
    local eventState = Server.EventState
    if type(AuraManager) ~= "table" or type(eventState) ~= "table" or eventState.active ~= true then
        return false
    end

    local function applyEntry(entry, fullState)
        local payload = type(AuraManager.ValidateInboundAuraPayload) == "function" and AuraManager:ValidateInboundAuraPayload(
            Client,
            sender,
            arguments[1],
            arguments[2],
            entry.casterEventId,
            entry.targetEventId,
            entry.auraRef,
            entry.stacks,
            entry.turns,
            entry.powerLevel
        ) or nil
        if not payload then
            return false
        end
        payload.fullState = fullState == true
        return type(AuraManager.UpsertAura) == "function" and AuraManager:UpsertAura(Client, payload) == true
    end

    local function dispelEntry(entry)
        local payload = type(AuraManager.ValidateInboundAuraPayload) == "function" and AuraManager:ValidateInboundAuraPayload(
            Client,
            sender,
            arguments[1],
            arguments[2],
            entry.casterEventId,
            entry.targetEventId,
            entry.auraRef
        ) or nil
        if not payload then
            return false
        end
        return type(AuraManager.RemoveAura) == "function" and AuraManager:RemoveAura(
            Client,
            payload.eventState,
            payload.auraRef,
            payload.casterEventId,
            payload.targetEventId
        ) == true
    end

    if opcode == AURA_APPLY_OPCODE then
        return applyEntry({
            casterEventId = tonumber(arguments[3]) or 0,
            targetEventId = tonumber(arguments[4]) or 0,
            auraRef = arguments[5],
            stacks = arguments[6],
            turns = arguments[7],
            powerLevel = arguments[8],
        }, false)
    end
    if opcode == AURA_DISPEL_OPCODE then
        return dispelEntry({
            casterEventId = tonumber(arguments[3]) or 0,
            targetEventId = tonumber(arguments[4]) or 0,
            auraRef = arguments[5],
        })
    end
    if opcode == AURA_APPLY_BATCH_OPCODE then
        local entries = parseAuraApplyBatch(arguments[3])
        if #entries == 0 then
            return false
        end
        local changed = false
        for index = 1, #entries do
            changed = applyEntry(entries[index], entries[index].fullState) or changed
        end
        return changed
    end
    if opcode == AURA_DISPEL_BATCH_OPCODE then
        local entries = parseAuraDispelBatch(arguments[3])
        if #entries == 0 then
            return false
        end
        local changed = false
        for index = 1, #entries do
            changed = dispelEntry(entries[index]) or changed
        end
        return changed
    end
    return false
end

local auraOpcodes = {
    [AURA_APPLY_OPCODE or -1] = true,
    [AURA_DISPEL_OPCODE or -2] = true,
    [AURA_APPLY_BATCH_OPCODE or -3] = true,
    [AURA_DISPEL_BATCH_OPCODE or -4] = true,
}
local spellOpcodes = {
    [SPELLCAST_START_OPCODE or -1] = true,
    [SPELLCAST_COMPLETE_OPCODE or -2] = true,
    [SPELLCAST_INTERRUPT_OPCODE or -3] = true,
}

-- Sync only the domain the current proposal is allowed to mutate. The host UI
-- cache can lag an already accepted remote commit, so copying every local
-- combat table after a proposal would allow an older client view to overwrite
-- canonical server state in unrelated domains.
do
    local baseSyncRuntime = Server.SyncEventCombatRuntimeFromLocalClient
    if type(baseSyncRuntime) == "function" then
        function Server:SyncEventCombatRuntimeFromLocalClient(...)
            local domain = self.EventCombatProposalDomain
            if domain == nil or type(self.EventRuntime) ~= "table" then
                return baseSyncRuntime(self, ...)
            end

            local before = cloneRuntimeSections(self.EventRuntime)
            local result = baseSyncRuntime(self, ...)
            if result ~= true then
                return result
            end

            if domain ~= "aura" then
                self.EventRuntime.auras = before.auras
            end
            if domain ~= "spell" then
                self.EventRuntime.spellcasts = before.spellcasts
                self.EventRuntime.cooldowns = before.cooldowns
            end
            if domain ~= "defensive" then
                self.EventRuntime.turnState = self.EventRuntime.turnState or {}
                self.EventRuntime.turnState.defensiveReactions = before.defensiveReactions
            end
            return result
        end
    end
end

-- Seed host execution caches from canonical runtime state before applying a
-- proposal. Aura proposals require special handling for the host-local sender:
-- their ordinary inbound handler intentionally treats local packets as echoes,
-- so the exact validated operation is applied silently to the canonical base.
do
    local baseHandleEventMutationRequest = Server.HandleEventMutationRequest
    if type(baseHandleEventMutationRequest) == "function" then
        function Server:HandleEventMutationRequest(payload, sender)
            local request = type(EventSync.DeserializeMutationRequest) == "function"
                and EventSync.DeserializeMutationRequest(payload) or nil
            if type(request) ~= "table" then
                return baseHandleEventMutationRequest(self, payload, sender)
            end

            local domain = auraOpcodes[request.opcode] and "aura"
                or spellOpcodes[request.opcode] and "spell"
                or request.opcode == EVENT_DEFENSIVE_USE_OPCODE and "defensive"
                or nil
            if domain == nil then
                return baseHandleEventMutationRequest(self, payload, sender)
            end

            local previousDomain = self.EventCombatProposalDomain
            self.EventCombatProposalDomain = domain

            local prepared = true
            if domain == "aura" and type(AuraManager) == "table" and type(AuraManager.ReplaceEventAuraState) == "function" then
                prepared = AuraManager:ReplaceEventAuraState(
                    Client,
                    self.EventState,
                    self.EventRuntime and self.EventRuntime.auras or {},
                    { refresh = false }
                ) == true

                if prepared and normalizeName(sender) == localPlayerName() then
                    local proposal = type(CombatState.DeserializeDomainProposal) == "function"
                        and CombatState.DeserializeDomainProposal(request.payload) or nil
                    local arguments = proposal and Serialization:DeserializeArguments(proposal.domainPayload or "") or nil
                    prepared = type(arguments) == "table" and applyHostLocalAuraScratch(request.opcode, arguments, sender) == true
                end
            elseif domain == "spell" and type(self.EventRuntime) == "table" and type(self.EventState) == "table" then
                if type(Spellcasting.ReplaceEventCastState) == "function" then
                    prepared = Spellcasting.ReplaceEventCastState(
                        Client,
                        self.EventState.id,
                        self.EventRuntime.spellcasts or {},
                        { refresh = false }
                    ) == true and prepared
                end
                if type(Spellcasting.ReplaceEventCooldownState) == "function" then
                    prepared = Spellcasting.ReplaceEventCooldownState(
                        Client,
                        self.EventState.id,
                        self.EventRuntime.cooldowns or {},
                        { refresh = false }
                    ) == true and prepared
                end
            end

            local ok, result
            if prepared then
                ok, result = pcall(baseHandleEventMutationRequest, self, payload, sender)
            else
                ok, result = true, false
            end
            self.EventCombatProposalDomain = previousDomain
            if not ok then
                error(result, 0)
            end
            return result
        end
    end
end

-- Server-owned NPC spell lifecycle messages enter the existing commit wrapper
-- without EVENT_MUTATION_REQUEST. Mark that path as a spell-domain mutation so
-- its runtime sync cannot copy stale aura/defensive state from the host client.
do
    local baseSendToChannel = Comms.SendToChannel
    if type(baseSendToChannel) == "function" then
        Comms.SendToChannel = function(self, channelId, opcodeOrPayload, argumentsOrMetadata, metadata)
            local opcode = tonumber(opcodeOrPayload)
            if spellOpcodes[opcode] == true
                and type(metadata) == "table"
                and metadata.scope == "server"
                and type(Server.EventRuntime) == "table"
            then
                local previousDomain = Server.EventCombatProposalDomain
                Server.EventCombatProposalDomain = "spell"
                local ok, result = pcall(baseSendToChannel, self, channelId, opcodeOrPayload, argumentsOrMetadata, metadata)
                Server.EventCombatProposalDomain = previousDomain
                if not ok then
                    error(result, 0)
                end
                return result
            end
            return baseSendToChannel(self, channelId, opcodeOrPayload, argumentsOrMetadata, metadata)
        end
    end
end

return Server