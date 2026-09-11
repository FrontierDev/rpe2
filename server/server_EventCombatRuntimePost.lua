local _, Addon = ...

local Server = Addon.Server or {}
local Client = Addon.Client or {}
local Comms = Addon.Internal and Addon.Internal.Comms or {}
local CombatState = Comms.EventCombatState or {}
local Operations = Comms.Operations or {}
local Registry = Addon.Internal and Addon.Internal.Registry or {}
local Spellcasting = Client.Spellcasting or {}
local Combat = Client.Combat or {}

local SPELLCAST_START_OPCODE = Operations.GetOpcode and Operations:GetOpcode("SPELLCAST_START") or nil
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

-- The #235 integration consumes the changed flag from the shared helper. Make
-- completion removal an intrinsic part of the pure transition as well, so a
-- caller cannot accidentally leave a fully elapsed cast active by ignoring the
-- helper's second return value.
do
    local baseAdvanceCastBucket = CombatState.AdvanceCastBucket
    if type(baseAdvanceCastBucket) == "function" then
        function CombatState.AdvanceCastBucket(bucket, currentTurnNumber, isCasterTurnOnTick)
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
