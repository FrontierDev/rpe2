local _, Addon = ...

local Server = Addon.Server or {}
local Client = Addon.Client or {}
local Comms = Addon.Internal and Addon.Internal.Comms or {}
local CombatState = Comms.EventCombatState or {}
local Common = Addon.Utils and Addon.Utils.Common or {}
local Tasks = Addon.Internal and Addon.Internal.Tasks or {}
local Spellcasting = Client.Spellcasting or {}

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

local function expectedCasterOwner(eventState, casterUnit)
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

local function isLocalCasterOwner(eventState, casterUnit)
    local expectedOwner = expectedCasterOwner(eventState, casterUnit)
    if expectedOwner ~= "" then
        return expectedOwner == localPlayerName()
    end
    return type(Client.IsLocalEventHost) == "function" and Client:IsLocalEventHost(eventState) == true
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
                eventId = tostring(value.eventId or ""),
                turnNumber = math.max(1, math.floor(tonumber(value.turnNumber) or 1)),
                tickNumber = math.max(1, math.floor(tonumber(value.tickNumber) or 1)),
                castEntry = castEntry,
            }
        end
    end
    return cloned
end

-- Preserve the full pre-removal cast entry when the host's pure progression
-- marks a persistent cast complete. server_EventCombatRuntimePost.lua already
-- creates the one-shot completion expectation; this layer adds only transient
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

-- Extend the commit-local runtime envelope without changing the canonical
-- Server.EventRuntime snapshot shape. AuraAuthority may already have extended
-- CloneRuntimeState; wrapping the current function preserves those fields.
do
    local baseCloneRuntimeState = CombatState.CloneRuntimeState
    if type(baseCloneRuntimeState) == "function" then
        function CombatState.CloneRuntimeState(value)
            local cloned = baseCloneRuntimeState(value)
            if type(cloned) == "table" then
                cloned.pendingSpellCompletions = clonePendingSpellCompletions(
                    type(value) == "table" and value.pendingSpellCompletions or nil
                )
            end
            return cloned
        end
    end
end

-- Include completion dispatches in exactly the runtime operation produced by
-- the completing turn, then remove the transient copy from Server.EventRuntime.
do
    local baseExportEventCombatRuntime = Server.ExportEventCombatRuntime
    if type(baseExportEventCombatRuntime) == "function" then
        function Server:ExportEventCombatRuntime(...)
            local exported = baseExportEventCombatRuntime(self, ...)
            if type(exported) == "table" and type(self.EventRuntime) == "table" then
                exported.pendingSpellCompletions = clonePendingSpellCompletions(self.EventRuntime._pendingSpellCompletions)
                self.EventRuntime._pendingSpellCompletions = nil
            end
            return exported
        end
    end
end

-- EVENT_RUNTIME_STATE is the canonical progression result. Do not independently
-- advance local cast/cooldown caches from EVENT_STATE while applying the same
-- revision; doing so can execute completion effects re-entrantly and attempt
-- resource mutations while nested event-sync sends are suppressed.
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
end

local function executeAuthoritativeSpellCompletion(client, dispatch)
    local eventState = type(client) == "table" and type(client.GetEventState) == "function" and client:GetEventState() or nil
    local castEntry = type(dispatch) == "table" and dispatch.castEntry or nil
    if type(eventState) ~= "table" or eventState.active ~= true
        or tostring(eventState.id or "") ~= tostring(dispatch and dispatch.eventId or "")
        or type(castEntry) ~= "table"
    then
        return false
    end

    local casterUnit = findEventUnit(eventState, castEntry.casterEventId)
    if not casterUnit or not isLocalCasterOwner(eventState, casterUnit) then
        return false
    end
    if type(client.OnSpellcastComplete) ~= "function" then
        return false
    end
    return client:OnSpellcastComplete(castEntry.spellRef, castEntry) == true
end

local function queueAuthoritativeSpellCompletions(client, dispatches)
    for index = 1, #(dispatches or {}) do
        local dispatch = dispatches[index]
        local eventState = type(client.GetEventState) == "function" and client:GetEventState() or nil
        local casterUnit = findEventUnit(eventState, dispatch and dispatch.castEntry and dispatch.castEntry.casterEventId)
        if casterUnit and isLocalCasterOwner(eventState, casterUnit) then
            if type(Tasks.Enqueue) ~= "function" then
                return false
            end
            Tasks:Enqueue(function(targetClient, pendingDispatch)
                executeAuthoritativeSpellCompletion(targetClient, pendingDispatch)
            end, client, dispatch)
        end
    end
    return true
end

-- Runtime replacement removes the completed cast and installs the authoritative
-- cooldown state first. Only then is the owner's completion queued. The task
-- runs after EventSyncApplyingCommittedMutation is released, so completion
-- effects and their resource/aura mutations use the normal host proposal path.
do
    local baseHandleEventRuntimeState = Client.HandleEventRuntimeState
    if type(baseHandleEventRuntimeState) == "function" then
        function Client:HandleEventRuntimeState(arguments, sender, ...)
            local decoded = type(CombatState.DeserializeRuntimeState) == "function"
                and CombatState.DeserializeRuntimeState(arguments and arguments[3] or "")
                or nil
            local result = baseHandleEventRuntimeState(self, arguments, sender, ...)
            if result == true
                and type(decoded) == "table"
                and #((decoded.pendingSpellCompletions) or {}) > 0
            then
                if queueAuthoritativeSpellCompletions(self, decoded.pendingSpellCompletions) ~= true then
                    return false
                end
            end
            return result
        end
    end
end

return Server
