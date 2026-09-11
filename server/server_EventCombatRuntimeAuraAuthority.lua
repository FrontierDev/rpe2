local _, Addon = ...

local Server = Addon.Server or {}
local Client = Addon.Client or {}
local Comms = Addon.Internal and Addon.Internal.Comms or {}
local CombatState = Comms.EventCombatState or {}
local Common = Addon.Utils and Addon.Utils.Common or {}
local Tasks = Addon.Internal and Addon.Internal.Tasks or {}
local Spellcasting = Client.Spellcasting or {}
local AuraManager = Spellcasting.AuraManager or (Addon.Internal and Addon.Internal.AuraManager) or nil

local function normalizeName(value)
    if type(Common.NormalizeName) == "function" then
        return Common.NormalizeName(value)
    end
    return tostring(value or "")
end

local function localPlayerName()
    if type(Spellcasting.GetLocalPlayerName) == "function" then
        return normalizeName(Spellcasting.GetLocalPlayerName())
    end
    return normalizeName(type(Common.GetPlayerName) == "function" and Common.GetPlayerName() or nil)
end

local function findEventUnit(eventState, eventId)
    local numericEventId = tonumber(eventId) or 0
    if numericEventId <= 0 then
        return nil
    end
    for index = 1, #(type(eventState) == "table" and eventState.units or {}) do
        local unit = eventState.units[index]
        if tonumber(unit and unit.eventID) == numericEventId then
            return unit
        end
    end
    return nil
end

local function expectedRuntimeOwner(eventState, casterUnit)
    if type(casterUnit) ~= "table" then
        return ""
    end
    if casterUnit.isPlayer == true then
        return normalizeName(casterUnit.ownerID or casterUnit.controllerID or casterUnit.name)
    end
    local controller = type(Spellcasting.ResolveControllerPlayerUnit) == "function"
        and Spellcasting.ResolveControllerPlayerUnit(eventState, casterUnit)
        or nil
    return normalizeName(controller and (controller.ownerID or controller.controllerID or controller.name) or nil)
end

local function isLocalRuntimeOwner(eventState, casterUnit)
    local expectedOwner = expectedRuntimeOwner(eventState, casterUnit)
    if expectedOwner ~= "" then
        return expectedOwner == localPlayerName()
    end
    return type(Client.IsLocalEventHost) == "function" and Client:IsLocalEventHost(eventState) == true
end

local function findMatchingAuraEntry(bucket, previous)
    if type(bucket) ~= "table" or type(previous) ~= "table" then
        return nil
    end
    for _, entry in pairs(bucket.byKey or {}) do
        if type(entry) == "table"
            and tostring(entry.auraRef or "") == tostring(previous.auraRef or "")
            and tonumber(entry.casterEventId) == tonumber(previous.casterEventId)
            and tonumber(entry.targetEventId) == tonumber(previous.targetEventId)
        then
            return entry
        end
    end
    return nil
end

local function cloneAuraTickDispatches(values)
    local cloned = {}
    for index = 1, #(values or {}) do
        local value = values[index]
        local aura = type(CombatState.CloneAuraRecord) == "function"
            and CombatState.CloneAuraRecord(type(value) == "table" and value.aura or nil)
            or nil
        if aura then
            cloned[#cloned + 1] = {
                eventId = tostring(type(value) == "table" and value.eventId or ""),
                turnNumber = math.max(1, math.floor(tonumber(type(value) == "table" and value.turnNumber or nil) or 1)),
                tickNumber = math.max(1, math.floor(tonumber(type(value) == "table" and value.tickNumber or nil) or 1)),
                aura = aura,
            }
        end
    end
    return cloned
end

local function clonePendingSpellCompletions(values)
    local cloned = {}
    for index = 1, #(values or {}) do
        local value = values[index]
        local castEntry = type(CombatState.CloneCastEntry) == "function"
            and CombatState.CloneCastEntry(type(value) == "table" and value.castEntry or nil)
            or nil
        if castEntry then
            cloned[#cloned + 1] = {
                eventId = tostring(type(value) == "table" and value.eventId or ""),
                turnNumber = math.max(1, math.floor(tonumber(type(value) == "table" and value.turnNumber or nil) or 1)),
                tickNumber = math.max(1, math.floor(tonumber(type(value) == "table" and value.tickNumber or nil) or 1)),
                castEntry = castEntry,
            }
        end
    end
    return cloned
end

-- Deterministic aura duration/independent-stack progression is pure data. The
-- host applies it while the authoritative EVENT_STATE transaction is still
-- open. The pre-advance aura record is returned separately so the owning client
-- can execute periodic effects after the committed state is fully installed.
function CombatState.AdvanceAuraRecords(records, eventState, resolveOwnerPage)
    if type(records) ~= "table" or type(eventState) ~= "table" then
        return false, {}
    end

    local currentTurn = math.max(1, math.floor(tonumber(eventState.turnNumber) or 1))
    local currentTick = math.max(1, math.floor(tonumber(eventState.tickNumber) or 1))
    local changed = false
    local pendingTicks = {}
    local kept = {}

    for index = 1, #records do
        local entry = records[index]
        local normalized = type(CombatState.CloneAuraRecord) == "function"
            and CombatState.CloneAuraRecord(entry)
            or entry
        if type(normalized) == "table" then
            local casterUnit = findEventUnit(eventState, normalized.casterEventId)
            local targetUnit = findEventUnit(eventState, normalized.targetEventId)
            if not casterUnit or not targetUnit then
                changed = true
            else
                local ownerPage = type(resolveOwnerPage) == "function"
                    and tonumber(resolveOwnerPage(normalized.casterEventId))
                    or nil
                local lastAdvanced = tonumber(normalized.lastAdvancedOwnerTurnNumber)
                if lastAdvanced == nil then
                    lastAdvanced = currentTurn
                end

                if ownerPage ~= nil
                    and ownerPage > 0
                    and currentTurn > lastAdvanced
                    and currentTick >= ownerPage
                then
                    pendingTicks[#pendingTicks + 1] = {
                        eventId = tostring(eventState.id or ""),
                        turnNumber = currentTurn,
                        tickNumber = currentTick,
                        aura = type(CombatState.CloneAuraRecord) == "function"
                            and CombatState.CloneAuraRecord(normalized)
                            or normalized,
                    }

                    if tostring(normalized.stackBehavior or "") == "independent_duration" then
                        local keptTurns = {}
                        local maxTurns = 0
                        for stackIndex = 1, #(normalized.stackTurns or {}) do
                            local nextTurns = (tonumber(normalized.stackTurns[stackIndex]) or 0) - 1
                            if nextTurns > 0 then
                                keptTurns[#keptTurns + 1] = nextTurns
                                maxTurns = math.max(maxTurns, nextTurns)
                            end
                        end
                        normalized.stackTurns = keptTurns
                        normalized.stacks = #keptTurns
                        normalized.turnsRemaining = maxTurns
                    else
                        normalized.turnsRemaining = math.max(0, (tonumber(normalized.turnsRemaining) or 0) - 1)
                        if normalized.turnsRemaining <= 0 then
                            normalized.stacks = 0
                        end
                    end

                    normalized.lastAdvancedOwnerTurnNumber = currentTurn
                    changed = true
                end

                if (tonumber(normalized.stacks) or 0) > 0
                    and (tonumber(normalized.turnsRemaining) or 0) > 0
                then
                    kept[#kept + 1] = normalized
                else
                    changed = true
                end
            end
        else
            changed = true
        end
    end

    if changed then
        for index = #records, 1, -1 do
            records[index] = nil
        end
        for index = 1, #kept do
            records[index] = kept[index]
        end
    end

    return changed, pendingTicks
end

-- Preserve the full pre-removal cast entry when the host's pure progression
-- marks a persistent cast complete. server_EventCombatRuntimePost.lua already
-- creates the one-shot completion expectation; this layer adds transient
-- dispatch metadata required to execute the owner's completion after the turn
-- commit has finished applying.
do
    local baseAdvanceCastBucket = CombatState.AdvanceCastBucket
    if type(baseAdvanceCastBucket) == "function" then
        function CombatState.AdvanceCastBucket(bucket, currentTurnNumber, isCasterTurnOnTick)
            local before = type(CombatState.CloneCastBucket) == "function"
                and CombatState.CloneCastBucket(bucket or {})
                or {}
            local changed, completed = baseAdvanceCastBucket(bucket, currentTurnNumber, isCasterTurnOnTick)

            local runtime = Server.EventRuntime
            local eventState = Server.EventState
            if type(runtime) == "table"
                and runtime.spellcasts == bucket
                and type(eventState) == "table"
                and eventState.active == true
                and #((completed) or {}) > 0
            then
                local pending = {}
                runtime.completedSpellcasts = runtime.completedSpellcasts or {}
                for index = 1, #completed do
                    local casterEventId = completed[index]
                    local castEntry = before[tonumber(casterEventId) or casterEventId]
                    if type(castEntry) == "table" then
                        local clonedEntry = type(CombatState.CloneCastEntry) == "function"
                            and CombatState.CloneCastEntry(castEntry)
                            or castEntry
                        pending[#pending + 1] = {
                            eventId = tostring(eventState.id or ""),
                            turnNumber = math.max(1, math.floor(tonumber(eventState.turnNumber) or 1)),
                            tickNumber = math.max(1, math.floor(tonumber(eventState.tickNumber) or 1)),
                            castEntry = clonedEntry,
                        }
                        local expectation = runtime.completedSpellcasts[tonumber(casterEventId) or casterEventId]
                        if type(expectation) == "table" then
                            expectation.castEntry = type(CombatState.CloneCastEntry) == "function"
                                and CombatState.CloneCastEntry(clonedEntry)
                                or clonedEntry
                        end
                    end
                end
                if #pending > 0 then
                    runtime._pendingSpellCompletions = clonePendingSpellCompletions(pending)
                end
            end
            return changed, completed
        end
    end
end

-- The historical client progression removes a completed cast before the owner
-- has passed completion-time conditions. Preserve the active host cast until a
-- SPELLCAST_COMPLETE proposal is actually accepted. The owner still receives a
-- post-commit completion dispatch for this turn; a failed completion therefore
-- leaves the fully progressed cast present and eligible to retry on a later
-- owner turn, matching the pre-authority behavior.
do
    local baseAdvanceCastBucket = CombatState.AdvanceCastBucket
    if type(baseAdvanceCastBucket) == "function" then
        function CombatState.AdvanceCastBucket(bucket, currentTurnNumber, isCasterTurnOnTick)
            local runtime = Server.EventRuntime
            local eventState = Server.EventState
            local isAuthoritativeBucket = type(runtime) == "table"
                and runtime.spellcasts == bucket
                and type(eventState) == "table"
                and eventState.active == true
            local before = isAuthoritativeBucket and type(CombatState.CloneCastBucket) == "function"
                and CombatState.CloneCastBucket(bucket or {})
                or nil

            local changed, completed = baseAdvanceCastBucket(bucket, currentTurnNumber, isCasterTurnOnTick)
            if not isAuthoritativeBucket or #((completed) or {}) == 0 then
                return changed, completed
            end

            for index = 1, #completed do
                local casterEventId = tonumber(completed[index]) or completed[index]
                local entry = type(before) == "table" and before[casterEventId] or nil
                if type(entry) == "table" then
                    local turnsTotal = math.max(1, math.floor(tonumber(entry.turnsTotal) or 1))
                    entry.turnsElapsed = turnsTotal
                    entry.turnsRemaining = 0
                    entry.lastAdvancedTurnNumber = math.max(1, math.floor(tonumber(currentTurnNumber) or tonumber(eventState.turnNumber) or 1))
                    bucket[casterEventId] = entry
                end
            end

            Server.ActiveSpellcastsByEventId = Server.ActiveSpellcastsByEventId or {}
            Server.ActiveSpellcastsByEventId[eventState.id] = type(CombatState.CloneCastBucket) == "function"
                and CombatState.CloneCastBucket(bucket)
                or bucket

            -- The completion has already been captured as transient dispatch
            -- metadata by the wrapped helper above. Return no removals to the
            -- outer turn integrator so it does not delete the retained casts.
            return changed, {}
        end
    end
end

-- EventCombatState's runtime codec is also used by EVENT_RUNTIME_STATE. Extend
-- that envelope with transient, commit-local aura tick and spell completion
-- dispatch metadata. These fields are not canonical Server.EventRuntime state
-- and are therefore absent from later rejoin snapshots.
do
    local baseCloneRuntimeState = CombatState.CloneRuntimeState
    if type(baseCloneRuntimeState) == "function" then
        function CombatState.CloneRuntimeState(value)
            local cloned = baseCloneRuntimeState(value)
            if type(cloned) == "table" then
                cloned.pendingAuraTicks = cloneAuraTickDispatches(type(value) == "table" and value.pendingAuraTicks or nil)
                cloned.pendingSpellCompletions = clonePendingSpellCompletions(
                    type(value) == "table" and value.pendingSpellCompletions or nil
                )
            end
            return cloned
        end
    end
end

-- The server's deterministic runtime step already invokes AdvanceCooldownBucket
-- inside the same EventMutationContext as EVENT_STATE. Piggyback aura duration
-- progression there so the eventual EVENT_RUNTIME_STATE operation contains the
-- post-turn aura state under the same revision.
do
    local baseAdvanceCooldownBucket = CombatState.AdvanceCooldownBucket
    if type(baseAdvanceCooldownBucket) == "function" then
        function CombatState.AdvanceCooldownBucket(bucket, currentTurnNumber, isCasterTurnOnTick)
            local changed = baseAdvanceCooldownBucket(bucket, currentTurnNumber, isCasterTurnOnTick) == true
            local runtime = Server.EventRuntime
            local eventState = Server.EventState
            if type(runtime) == "table"
                and runtime.cooldowns == bucket
                and type(eventState) == "table"
                and eventState.active == true
                and tostring(runtime.eventId or "") == tostring(eventState.id or "")
            then
                local auraChanged, pendingTicks = CombatState.AdvanceAuraRecords(
                    runtime.auras or {},
                    eventState,
                    function(casterEventId)
                        return type(Spellcasting.GetUnitPageIndex) == "function"
                            and Spellcasting.GetUnitPageIndex(eventState, casterEventId)
                            or nil
                    end
                )
                if auraChanged == true then
                    changed = true
                end
                if #pendingTicks > 0 then
                    runtime._pendingAuraTicks = cloneAuraTickDispatches(pendingTicks)
                end
            end
            return changed
        end
    end
end

-- Export transient turn-effect dispatches only into the runtime operation being
-- built, then clear them from authoritative runtime. This prevents stale replay
-- in subsequent commits and keeps them out of Issue #236 snapshots.
do
    local baseExportEventCombatRuntime = Server.ExportEventCombatRuntime
    if type(baseExportEventCombatRuntime) == "function" then
        function Server:ExportEventCombatRuntime(...)
            local exported = baseExportEventCombatRuntime(self, ...)
            if type(exported) == "table" and type(self.EventRuntime) == "table" then
                exported.pendingAuraTicks = cloneAuraTickDispatches(self.EventRuntime._pendingAuraTicks)
                exported.pendingSpellCompletions = clonePendingSpellCompletions(self.EventRuntime._pendingSpellCompletions)
                self.EventRuntime._pendingAuraTicks = nil
                self.EventRuntime._pendingSpellCompletions = nil
            end
            return exported
        end
    end
end

-- EVENT_RUNTIME_STATE is the canonical turn-progression result. Do not also
-- advance client cast/cooldown/aura caches from EVENT_STATE while applying the
-- same revision: that can double-advance state and can execute completion/tick
-- effects re-entrantly while nested event-sync sends are suppressed.
do
    local baseAdvanceSpellcastState = Client.AdvanceSpellcastState
    if type(baseAdvanceSpellcastState) == "function" then
        function Client:AdvanceSpellcastState(...)
            if self.EventSyncApplyingCommittedMutation == true then
                return false
            end
            return baseAdvanceSpellcastState(self, ...)
        end
    end

    local baseAdvanceCooldownState = Client.AdvanceCooldownState
    if type(baseAdvanceCooldownState) == "function" then
        function Client:AdvanceCooldownState(...)
            if self.EventSyncApplyingCommittedMutation == true then
                return false
            end
            return baseAdvanceCooldownState(self, ...)
        end
    end

    local baseAdvanceAuraState = Client.AdvanceAuraState
    if type(baseAdvanceAuraState) == "function" then
        function Client:AdvanceAuraState(...)
            if self.EventSyncApplyingCommittedMutation == true then
                return false
            end
            return baseAdvanceAuraState(self, ...)
        end
    end
end

local function executeAuthoritativeAuraTick(client, dispatch)
    local eventState = type(client) == "table" and type(client.GetEventState) == "function" and client:GetEventState() or nil
    local record = type(dispatch) == "table" and dispatch.aura or nil
    if type(eventState) ~= "table" or eventState.active ~= true
        or tostring(eventState.id or "") ~= tostring(type(dispatch) == "table" and dispatch.eventId or "")
        or type(record) ~= "table"
    then
        return false
    end

    local casterUnit = findEventUnit(eventState, record.casterEventId)
    local targetUnit = findEventUnit(eventState, record.targetEventId)
    if not casterUnit or not targetUnit or not isLocalRuntimeOwner(eventState, casterUnit) then
        return false
    end

    if type(AuraManager) ~= "table" or type(AuraManager.ResolveAuraDefinition) ~= "function" or type(AuraManager.TickAura) ~= "function" then
        return false
    end
    local _, auraDefinition = AuraManager:ResolveAuraDefinition(record.auraRef, { datasetId = record.datasetId })
    if type(auraDefinition) ~= "table" then
        return false
    end

    local tickEntry = type(CombatState.CloneValue) == "function" and CombatState.CloneValue(record) or record
    tickEntry.definition = auraDefinition
    return AuraManager:TickAura(client, eventState, tickEntry, casterUnit, targetUnit) == true
end

local function executeAuthoritativeSpellCompletion(client, dispatch)
    local eventState = type(client) == "table" and type(client.GetEventState) == "function" and client:GetEventState() or nil
    local castEntry = type(dispatch) == "table" and dispatch.castEntry or nil
    if type(eventState) ~= "table" or eventState.active ~= true
        or tostring(eventState.id or "") ~= tostring(type(dispatch) == "table" and dispatch.eventId or "")
        or type(castEntry) ~= "table"
    then
        return false
    end

    local casterUnit = findEventUnit(eventState, castEntry.casterEventId)
    if not casterUnit or not isLocalRuntimeOwner(eventState, casterUnit) then
        return false
    end
    if type(client.OnSpellcastComplete) ~= "function" then
        return false
    end
    return client:OnSpellcastComplete(castEntry.spellRef, castEntry) == true
end

local function queueAuthoritativeTurnEffects(client, runtimeState)
    local eventState = type(client) == "table" and type(client.GetEventState) == "function" and client:GetEventState() or nil
    if type(eventState) ~= "table" or eventState.active ~= true then
        return false
    end

    local queuedAny = false
    for index = 1, #((runtimeState and runtimeState.pendingAuraTicks) or {}) do
        local dispatch = runtimeState.pendingAuraTicks[index]
        local casterUnit = findEventUnit(eventState, dispatch and dispatch.aura and dispatch.aura.casterEventId)
        if casterUnit and isLocalRuntimeOwner(eventState, casterUnit) then
            if type(Tasks.Enqueue) ~= "function" then
                return false
            end
            Tasks:Enqueue(function(targetClient, pendingDispatch)
                executeAuthoritativeAuraTick(targetClient, pendingDispatch)
            end, client, dispatch)
            queuedAny = true
        end
    end

    for index = 1, #((runtimeState and runtimeState.pendingSpellCompletions) or {}) do
        local dispatch = runtimeState.pendingSpellCompletions[index]
        local casterUnit = findEventUnit(eventState, dispatch and dispatch.castEntry and dispatch.castEntry.casterEventId)
        if casterUnit and isLocalRuntimeOwner(eventState, casterUnit) then
            if type(Tasks.Enqueue) ~= "function" then
                return false
            end
            Tasks:Enqueue(function(targetClient, pendingDispatch)
                executeAuthoritativeSpellCompletion(targetClient, pendingDispatch)
            end, client, dispatch)
            queuedAny = true
        end
    end

    return true, queuedAny
end

-- Runtime replacement installs the post-turn canonical aura/cast/cooldown state
-- first. Owner-only periodic effects/completions are then queued from pre-turn
-- records and run after EventSyncApplyingCommittedMutation is released, so any
-- resulting resource/aura mutations use the normal host proposal path.
do
    local baseHandleEventRuntimeState = Client.HandleEventRuntimeState
    if type(baseHandleEventRuntimeState) == "function" then
        function Client:HandleEventRuntimeState(arguments, sender, ...)
            local decoded = type(CombatState.DeserializeRuntimeState) == "function"
                and CombatState.DeserializeRuntimeState(arguments and arguments[3] or "")
                or nil
            local result = baseHandleEventRuntimeState(self, arguments, sender, ...)
            if result == true and type(decoded) == "table" then
                local hasAuraTicks = #((decoded.pendingAuraTicks) or {}) > 0
                local hasSpellCompletions = #((decoded.pendingSpellCompletions) or {}) > 0
                if (hasAuraTicks or hasSpellCompletions)
                    and queueAuthoritativeTurnEffects(self, decoded) ~= true
                then
                    return false
                end
            end
            return result
        end
    end
end

-- Aura advancement outside the authoritative EVENT_STATE path (for example a
-- topology owner-page recheck) still uses the existing owner-executed path.
-- Publish its post-advance full state so Server.EventRuntime remains current.
if type(AuraManager) == "table" and type(AuraManager.AdvanceAuraEntry) == "function" then
    local baseAdvanceAuraEntry = AuraManager.AdvanceAuraEntry
    function AuraManager:AdvanceAuraEntry(client, eventId, auraKey, targetTurnNumber, targetTickNumber)
        local eventState = type(client) == "table" and type(client.GetEventState) == "function" and client:GetEventState() or nil
        local bucket = type(self.GetEventAuraBucket) == "function" and self:GetEventAuraBucket(client, eventId, false) or nil
        local entry = type(bucket) == "table" and type(bucket.byKey) == "table" and bucket.byKey[auraKey] or nil
        local previous = type(entry) == "table" and {
            auraRef = entry.auraRef,
            casterEventId = tonumber(entry.casterEventId) or 0,
            targetEventId = tonumber(entry.targetEventId) or 0,
        } or nil
        local casterUnit = previous and findEventUnit(eventState, previous.casterEventId) or nil
        local isOwner = isLocalRuntimeOwner(eventState, casterUnit)

        local changed = baseAdvanceAuraEntry(self, client, eventId, auraKey, targetTurnNumber, targetTickNumber)
        if changed ~= true or type(previous) ~= "table" or not isOwner then
            return changed
        end

        local sessionState = type(client.GetState) == "function" and client:GetState() or nil
        local currentEventState = type(client.GetEventState) == "function" and client:GetEventState() or nil
        if type(sessionState) ~= "table" or sessionState.active ~= true
            or type(currentEventState) ~= "table" or currentEventState.active ~= true
            or tostring(currentEventState.id or "") ~= tostring(eventId or "")
        then
            return changed
        end

        local currentBucket = type(self.GetEventAuraBucket) == "function" and self:GetEventAuraBucket(client, eventId, false) or nil
        local currentEntry = findMatchingAuraEntry(currentBucket, previous)
        local context = {
            sessionState = sessionState,
            eventState = currentEventState,
            immediate = true,
            pendingScope = "turn",
            scope = "turn",
        }

        if type(currentEntry) == "table" and (tonumber(currentEntry.stacks) or 0) > 0 and (tonumber(currentEntry.turnsRemaining) or 0) > 0 then
            self:QueueAuraApply(client, context, currentEntry, {
                stacks = currentEntry.stacks,
                turns = currentEntry.turnsRemaining,
                powerLevel = currentEntry.powerLevel,
                fullState = true,
            })
        else
            self:QueueAuraDispel(
                client,
                context,
                previous.auraRef,
                previous.casterEventId,
                previous.targetEventId
            )
        end

        return changed
    end
end

return AuraManager
