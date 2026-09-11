local _, Addon = ...

local Server = Addon.Server or {}
local Client = Addon.Client or {}
local Comms = Addon.Internal and Addon.Internal.Comms or {}
local EventSync = Comms.EventSync or {}
local Serialization = Comms.Serialization or {}
local CombatState = Comms.EventCombatState or {}
local Operations = Comms.Operations or {}
local Registry = Addon.Internal and Addon.Internal.Registry or {}
local Spellcasting = Client.Spellcasting or {}
local Combat = Client.Combat or {}

local SPELLCAST_START_OPCODE = Operations.GetOpcode and Operations:GetOpcode("SPELLCAST_START") or nil
local SPELLCAST_COMPLETE_OPCODE = Operations.GetOpcode and Operations:GetOpcode("SPELLCAST_COMPLETE") or nil
local SPELLCAST_INTERRUPT_OPCODE = Operations.GetOpcode and Operations:GetOpcode("SPELLCAST_INTERRUPT") or nil
local EVENT_DEFENSIVE_USE_OPCODE = Operations.GetOpcode and Operations:GetOpcode("EVENT_DEFENSIVE_USE") or nil

local function findEventUnit(eventState, eventId)
    local numericEventId = tonumber(eventId) or 0
    for index = 1, #(type(eventState) == "table" and eventState.units or {}) do
        local unit = eventState.units[index]
        if tonumber(unit and unit.eventID) == numericEventId then
            return unit
        end
    end
    return nil
end

local function getCooldownSpellState(unitState, spellRef)
    return type(unitState) == "table"
        and type(unitState.spells) == "table"
        and unitState.spells[spellRef]
        or nil
end

local function spellUsesGlobalCooldown(spell)
    return type(Spellcasting.SpellUsesGlobalCooldown) == "function"
        and Spellcasting.SpellUsesGlobalCooldown(spell) == true
end

local function canStartFromCanonicalCooldown(eventState, casterEventId, spellRef, spell)
    local runtime = Server.EventRuntime
    local unitState = type(runtime) == "table" and type(runtime.cooldowns) == "table"
        and runtime.cooldowns[tonumber(casterEventId) or 0] or nil
    local spellState = getCooldownSpellState(unitState, spellRef)
    if spellUsesGlobalCooldown(spell)
        and math.max(0, math.floor(tonumber(unitState and unitState.globalCooldownRemaining) or 0)) > 0
    then
        return false
    end
    if math.max(0, math.floor(tonumber(spellState and spellState.lockoutRemainingTurns) or 0)) > 0 then
        return false
    end
    if type(spell) == "table" and spell.useCooldownCharges == true then
        local maxCharges = math.max(1, math.floor(tonumber(spell.charges) or 1))
        local currentCharges = spellState and math.max(0, math.floor(tonumber(spellState.currentCharges) or maxCharges)) or maxCharges
        return currentCharges > 0
    end
    return math.max(0, math.floor(tonumber(spellState and spellState.remainingTurns) or 0)) <= 0
end

local function deriveInstantCooldownCandidate(eventState, casterUnit, spellRef, spell, runtimeState)
    if type(eventState) ~= "table" or type(casterUnit) ~= "table" or type(runtimeState) ~= "table" then
        return false
    end
    local eventId = tostring(eventState.id or "")
    local casterEventId = tonumber(casterUnit.eventID) or 0
    if eventId == "" or casterEventId <= 0 or type(Client.ApplyLocalSpellCooldown) ~= "function" then
        return false
    end

    local savedBucket = Client.CooldownsByEventId and Client.CooldownsByEventId[eventId] or nil
    local savedQueued = Client.ActionBarRefreshQueued
    local savedReason = Client.PendingActionBarRefreshReason
    Client.CooldownsByEventId = Client.CooldownsByEventId or {}
    Client.CooldownsByEventId[eventId] = type(CombatState.CloneCooldownBucket) == "function"
        and CombatState.CloneCooldownBucket(Server.EventRuntime and Server.EventRuntime.cooldowns or {})
        or {}

    Client:ApplyLocalSpellCooldown(eventState, casterUnit, spellRef, spell)
    local derived = type(CombatState.CloneCooldownBucket) == "function"
        and CombatState.CloneCooldownBucket(Client.CooldownsByEventId[eventId] or {})
        or (Client.CooldownsByEventId[eventId] or {})

    Client.CooldownsByEventId[eventId] = savedBucket
    Client.ActionBarRefreshQueued = savedQueued
    Client.PendingActionBarRefreshReason = savedReason
    runtimeState.cooldowns = derived
    return true
end

-- Keep derived cast fields complete even when the source entry predates the
-- richer recovery representation.
do
    local baseCloneCastEntry = CombatState.CloneCastEntry
    if type(baseCloneCastEntry) == "function" then
        function CombatState.CloneCastEntry(entry)
            local cloned = baseCloneCastEntry(entry)
            if type(cloned) ~= "table" then
                return cloned
            end
            if type(entry) == "table" and entry.turnsRemaining == nil then
                cloned.turnsRemaining = math.max(0, (tonumber(cloned.turnsTotal) or 1) - (tonumber(cloned.turnsElapsed) or 0))
            end
            if tonumber(cloned.completeOnTurnNumber) == nil or tonumber(cloned.completeOnTurnNumber) <= 0 then
                cloned.completeOnTurnNumber = math.max(1, tonumber(cloned.startedOnTurnNumber) or 1)
                    + math.max(1, tonumber(cloned.turnsTotal) or 1)
            end
            return cloned
        end
    end
end

-- Completion is a two-stage authoritative transition: the turn commit advances
-- and removes a fully elapsed persistent cast, then the owner executes effects
-- and sends SPELLCAST_COMPLETE. Keep a one-shot server expectation so that
-- completion can be validated even though the cast is no longer active and is
-- therefore never retained in a recovery snapshot.
do
    local baseAdvanceCastBucket = CombatState.AdvanceCastBucket
    if type(baseAdvanceCastBucket) == "function" then
        function CombatState.AdvanceCastBucket(bucket, currentTurnNumber, isCasterTurnOnTick)
            local before = {}
            for casterEventId, entry in pairs(type(bucket) == "table" and bucket or {}) do
                before[tonumber(casterEventId) or casterEventId] = {
                    spellRef = tostring(entry and entry.spellRef or ""),
                    authorityType = tostring(entry and entry.authorityType or ""),
                }
            end

            local changed, completed = baseAdvanceCastBucket(bucket, currentTurnNumber, isCasterTurnOnTick)
            for index = 1, #(completed or {}) do
                bucket[completed[index]] = nil
            end

            local runtime = Server.EventRuntime
            local eventState = Server.EventState
            if type(runtime) == "table"
                and runtime.spellcasts == bucket
                and type(eventState) == "table"
                and eventState.active == true
            then
                runtime.completedSpellcasts = runtime.completedSpellcasts or {}
                for index = 1, #(completed or {}) do
                    local casterEventId = completed[index]
                    local previous = before[casterEventId]
                    if type(previous) == "table" and previous.spellRef ~= "" then
                        runtime.completedSpellcasts[casterEventId] = {
                            spellRef = previous.spellRef,
                            authorityType = previous.authorityType,
                            completedOnTurnNumber = math.max(1, math.floor(tonumber(eventState.turnNumber) or 1)),
                        }
                    end
                end
                Server.ActiveSpellcastsByEventId = Server.ActiveSpellcastsByEventId or {}
                Server.ActiveSpellcastsByEventId[eventState.id] = CombatState.CloneCastBucket(bucket)
                runtime._deterministicRuntimeTurnNumber = math.max(0, math.floor(tonumber(eventState.turnNumber) or 0))
                runtime._deterministicRuntimeTickNumber = math.max(0, math.floor(tonumber(eventState.tickNumber) or 0))
            end
            return changed, completed
        end
    end
end

-- EVENT_DEFENSIVE_USE is a request-only opcode. The authoritative result is
-- represented solely by EVENT_RUNTIME_STATE, so never leak the proposal opcode
-- into a client commit (where direct dispatch is intentionally unsupported).
do
    local baseCommitEventMutation = Server.CommitEventMutation
    if type(baseCommitEventMutation) == "function" then
        function Server:CommitEventMutation(eventId, operations, applyFn, options)
            local filtered = {}
            for index = 1, #(operations or {}) do
                local operation = operations[index]
                if tonumber(operation and operation.opcode) ~= tonumber(EVENT_DEFENSIVE_USE_OPCODE) then
                    filtered[#filtered + 1] = operation
                end
            end
            return baseCommitEventMutation(self, eventId, filtered, applyFn, options)
        end
    end
end

-- A host-local defensive proposal is tentatively marked pending before it is
-- synchronously validated by the host. The host validation must consult the
-- committed ledger, not reject its own proposal because of that tentative bit.
do
    local baseCanUseDefensiveReaction = Combat.CanUseDefensiveReaction
    if type(baseCanUseDefensiveReaction) == "function" then
        function Combat:CanUseDefensiveReaction(entry, action)
            if Client.EventCombatApplyingHostProposal == true then
                local pending = Client.PendingDefensiveReactionUses
                Client.PendingDefensiveReactionUses = {}
                local allowed, reason = baseCanUseDefensiveReaction(self, entry, action)
                Client.PendingDefensiveReactionUses = pending
                return allowed, reason
            end
            return baseCanUseDefensiveReaction(self, entry, action)
        end
    end
end

-- Server-owned NPC casts do not carry a client proposal snapshot. Apply the
-- existing cooldown transition locally before the #235 transport wrapper
-- serializes the host runtime, while avoiding a second application when the
-- state is already present.
do
    local baseSendToChannel = Comms.SendToChannel
    if type(baseSendToChannel) == "function" then
        Comms.SendToChannel = function(self, channelId, opcodeOrPayload, argumentsOrMetadata, metadata)
            local opcode = tonumber(opcodeOrPayload)
            if opcode == SPELLCAST_START_OPCODE
                and type(metadata) == "table"
                and metadata.scope == "server"
                and type(Server.EventRuntime) == "table"
            then
                local eventState = Server.EventState
                local casterEventId = tonumber(type(argumentsOrMetadata) == "table" and argumentsOrMetadata[3] or nil) or 0
                local spellRef = tostring(type(argumentsOrMetadata) == "table" and argumentsOrMetadata[4] or "")
                local casterUnit = findEventUnit(eventState, casterEventId)
                local unitState = type(Spellcasting.GetUnitCooldownState) == "function"
                    and Spellcasting.GetUnitCooldownState(Client, eventState and eventState.id or nil, casterEventId, false)
                    or nil
                local alreadyApplied = type(unitState) == "table"
                    and type(unitState.spells) == "table"
                    and type(unitState.spells[spellRef]) == "table"
                if not alreadyApplied
                    and type(casterUnit) == "table"
                    and spellRef ~= ""
                    and type(Registry.ResolveSpellReference) == "function"
                    and type(Client.ApplyLocalSpellCooldown) == "function"
                then
                    local _, spell = Registry:ResolveSpellReference(spellRef)
                    if type(spell) == "table" then
                        Client:ApplyLocalSpellCooldown(eventState, casterUnit, spellRef, spell)
                    end
                end
            end
            return baseSendToChannel(self, channelId, opcodeOrPayload, argumentsOrMetadata, metadata)
        end
    end
end

-- Validate lifecycle phase against canonical runtime state. Persistent complete
-- consumes the completion expectation produced by the authoritative turn
-- transition. Instant complete has no cast entry; it derives cooldown/GCD state
-- directly from spell metadata at completion and commits no persistent cast.
do
    local baseHandleEventMutationRequest = Server.HandleEventMutationRequest
    if type(baseHandleEventMutationRequest) == "function" then
        function Server:HandleEventMutationRequest(payload, sender)
            local request = type(EventSync.DeserializeMutationRequest) == "function"
                and EventSync.DeserializeMutationRequest(payload) or nil
            if type(request) ~= "table"
                or (request.opcode ~= SPELLCAST_START_OPCODE
                    and request.opcode ~= SPELLCAST_COMPLETE_OPCODE
                    and request.opcode ~= SPELLCAST_INTERRUPT_OPCODE)
            then
                return baseHandleEventMutationRequest(self, payload, sender)
            end

            local proposal = type(CombatState.DeserializeDomainProposal) == "function"
                and CombatState.DeserializeDomainProposal(request.payload) or nil
            local arguments = proposal and Serialization:DeserializeArguments(proposal.domainPayload or "") or nil
            local eventState = self.EventState
            local runtime = self.EventRuntime
            local casterEventId = tonumber(arguments and arguments[3]) or 0
            local spellRef = tostring(arguments and arguments[4] or "")
            local casterUnit = findEventUnit(eventState, casterEventId)
            local _, spell = type(Registry.ResolveSpellReference) == "function" and Registry:ResolveSpellReference(spellRef) or nil, nil
            if type(Registry.ResolveSpellReference) == "function" then
                local _, resolvedSpell = Registry:ResolveSpellReference(spellRef)
                spell = resolvedSpell
            end
            if type(proposal) ~= "table" or type(arguments) ~= "table"
                or type(eventState) ~= "table" or eventState.active ~= true
                or type(runtime) ~= "table" or not casterUnit or type(spell) ~= "table"
            then
                return false
            end

            local persistentTurns = type(Spellcasting.ResolvePersistentCastTurns) == "function"
                and Spellcasting.ResolvePersistentCastTurns(spell, nil) or nil
            local activeCast = type(runtime.spellcasts) == "table" and runtime.spellcasts[casterEventId] or nil
            local expectation = type(runtime.completedSpellcasts) == "table" and runtime.completedSpellcasts[casterEventId] or nil

            if request.opcode == SPELLCAST_START_OPCODE then
                if persistentTurns == nil or type(activeCast) == "table" or type(expectation) == "table"
                    or canStartFromCanonicalCooldown(eventState, casterEventId, spellRef, spell) ~= true
                then
                    return false
                end
            elseif request.opcode == SPELLCAST_INTERRUPT_OPCODE then
                if persistentTurns == nil or type(activeCast) ~= "table" or tostring(activeCast.spellRef or "") ~= spellRef then
                    return false
                end
            elseif persistentTurns ~= nil then
                if type(expectation) ~= "table" or tostring(expectation.spellRef or "") ~= spellRef then
                    return false
                end
            else
                if type(activeCast) == "table" or type(expectation) == "table"
                    or canStartFromCanonicalCooldown(eventState, casterEventId, spellRef, spell) ~= true
                then
                    return false
                end
                proposal.runtimeState = type(proposal.runtimeState) == "table"
                    and CombatState.CloneRuntimeState(proposal.runtimeState) or CombatState.CloneRuntimeState({})
                if deriveInstantCooldownCandidate(eventState, casterUnit, spellRef, spell, proposal.runtimeState) ~= true then
                    return false
                end
                local proposalPayload = CombatState.SerializeDomainProposal(proposal.domainPayload, proposal.runtimeState)
                payload = EventSync.SerializeMutationRequest({
                    protocolVersion = request.protocolVersion,
                    channelName = request.channelName,
                    eventId = request.eventId,
                    opcode = request.opcode,
                    payload = proposalPayload,
                })
                if not payload then
                    return false
                end
            end

            local result = baseHandleEventMutationRequest(self, payload, sender)
            if result == true and request.opcode == SPELLCAST_COMPLETE_OPCODE and persistentTurns ~= nil then
                runtime.completedSpellcasts[casterEventId] = nil
            end
            return result
        end
    end
end

-- Before the host's own client has consumed the newly committed EVENT_STATE,
-- do not let a synchronous unrelated proposal overwrite already-advanced
-- canonical cast/cooldown/defensive mirrors with the host client's previous
-- turn view.
do
    local baseSyncRuntime = Server.SyncEventCombatRuntimeFromLocalClient
    if type(baseSyncRuntime) == "function" then
        function Server:SyncEventCombatRuntimeFromLocalClient(...)
            local runtime = self.EventRuntime
            local eventState = self.EventState
            local clientState = type(Client.GetEventState) == "function" and Client:GetEventState() or Client.EventState
            local preserveAdvanced = type(runtime) == "table"
                and type(eventState) == "table"
                and eventState.active == true
                and type(clientState) == "table"
                and tostring(clientState.id or "") == tostring(eventState.id or "")
                and (
                    tonumber(clientState.turnNumber) ~= tonumber(eventState.turnNumber)
                    or tonumber(clientState.tickNumber) ~= tonumber(eventState.tickNumber)
                )
                and tonumber(runtime._deterministicRuntimeTurnNumber) == tonumber(eventState.turnNumber)
                and tonumber(runtime._deterministicRuntimeTickNumber) == tonumber(eventState.tickNumber)

            local savedCasts = preserveAdvanced and CombatState.CloneCastBucket(runtime.spellcasts or {}) or nil
            local savedCooldowns = preserveAdvanced and CombatState.CloneCooldownBucket(runtime.cooldowns or {}) or nil
            local savedDefensive = preserveAdvanced and CombatState.CloneDefensiveState(
                runtime.turnState and runtime.turnState.defensiveReactions or {}
            ) or nil

            local result = baseSyncRuntime(self, ...)
            if result == true and preserveAdvanced then
                runtime.spellcasts = savedCasts
                runtime.cooldowns = savedCooldowns
                runtime.turnState = runtime.turnState or {}
                runtime.turnState.defensiveReactions = savedDefensive
            end
            return result
        end
    end
end

return Server