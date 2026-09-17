local _, Addon = ...

Addon.Client = Addon.Client or {}

local Client = Addon.Client
local Common = Addon.Utils and Addon.Utils.Common or {}
local EventRejoinState = Addon.Internal
    and Addon.Internal.Comms
    and Addon.Internal.Comms.EventRejoinState
    or {}
local Spellcasting = Client.Spellcasting or {}
local AuraManager = Spellcasting.AuraManager
local Debug = Addon.Debug or {}

Client.PendingEventRejoinStateByEventId = Client.PendingEventRejoinStateByEventId or {}

local function normalizeName(value)
    if type(Common.NormalizeName) == "function" then
        return Common.NormalizeName(value)
    end
    return tostring(value or "")
end

local function findUnit(eventState, eventId)
    local numericEventId = tonumber(eventId) or 0
    for index = 1, #((eventState and eventState.units) or {}) do
        local unit = eventState.units[index]
        if tonumber(unit and unit.eventID) == numericEventId then
            return unit
        end
    end
    return nil
end

local function installAuraSnapshot(client, eventState, records, replaceExisting)
    if replaceExisting == true and type(Spellcasting.ResetAuraState) == "function" then
        Spellcasting.ResetAuraState(client, eventState.id)
    end
    if type(AuraManager) ~= "table" or type(AuraManager.UpsertAura) ~= "function" then
        return 0, #(records or {})
    end

    local installed = 0
    local failed = 0
    for index = 1, #(records or {}) do
        local record = records[index]
        local applied = AuraManager:UpsertAura(client, {
            eventState = eventState,
            auraRef = record.auraRef,
            casterEventId = record.casterEventId,
            targetEventId = record.targetEventId,
            stacks = record.stacks,
            turns = record.turnsRemaining,
            powerLevel = record.powerLevel,
            fullState = true,
        })
        if applied == true then
            installed = installed + 1
            if type(AuraManager.ApplyAuraRuntimeSnapshot) == "function"
                and type(record.effectState) == "table"
            then
                AuraManager:ApplyAuraRuntimeSnapshot(
                    client,
                    eventState,
                    record.casterEventId,
                    record.targetEventId,
                    record.auraRef,
                    record.effectState
                )
            end
        else
            failed = failed + 1
        end
    end
    return installed, failed
end

local function installCastSnapshot(client, eventState, records, replaceExisting)
    if replaceExisting == true and type(Spellcasting.ClearEventCastBucket) == "function" then
        Spellcasting.ClearEventCastBucket(client, eventState.id)
    end
    if type(Spellcasting.BuildCastEntry) ~= "function" or type(Spellcasting.SetCastEntry) ~= "function" then
        return 0, #(records or {})
    end

    local installed = 0
    local failed = 0
    for index = 1, #(records or {}) do
        local record = records[index]
        local casterUnit = findUnit(eventState, record.casterEventId)
        local authorityType = tostring(record.authorityType or "")
        if authorityType == "" then
            authorityType = type(casterUnit) == "table" and casterUnit.isPlayer == true and "player" or "npc"
        end
        local entry = Spellcasting.BuildCastEntry(
            record.spellRef,
            type(Spellcasting.ResolveSpellName) == "function" and Spellcasting.ResolveSpellName(record.spellRef) or record.spellRef,
            authorityType,
            record.casterEventId,
            record.turnsTotal,
            record.startedOnTurnNumber
        )
        if type(entry) == "table" then
            entry.startedOnTurnNumber = math.max(1, math.floor(tonumber(record.startedOnTurnNumber) or entry.startedOnTurnNumber or 1))
            entry.completeOnTurnNumber = math.max(entry.startedOnTurnNumber, math.floor(tonumber(record.completeOnTurnNumber) or entry.completeOnTurnNumber or entry.startedOnTurnNumber))
            entry.turnsElapsed = math.min(
                math.max(0, math.floor(tonumber(record.turnsElapsed) or 0)),
                math.max(0, math.floor(tonumber(entry.turnsTotal) or 0))
            )
            entry.lastAdvancedTurnNumber = math.max(1, math.floor(tonumber(record.lastAdvancedTurnNumber) or entry.startedOnTurnNumber))
            entry.targetSelections = type(record.targetSelections) == "table" and record.targetSelections or nil
            entry.targetSelectionOrder = type(record.targetSelectionOrder) == "table" and record.targetSelectionOrder or nil
            entry.targetEventIds = type(record.targetEventIds) == "table" and record.targetEventIds or nil
            entry.focusedTargetEventId = tonumber(record.focusedTargetEventId) or 0
            entry.resolvedStartCostAmounts = type(record.resolvedStartCostAmounts) == "table" and record.resolvedStartCostAmounts or nil
            Spellcasting.SetCastEntry(client, eventState.id, record.casterEventId, entry)
            installed = installed + 1
        else
            failed = failed + 1
        end
    end
    return installed, failed
end

function Client:ApplyEventRejoinState(eventId)
    local normalizedEventId = tostring(eventId or "")
    local pending = self.PendingEventRejoinStateByEventId and self.PendingEventRejoinStateByEventId[normalizedEventId] or nil
    local eventState = type(self.GetEventState) == "function" and self:GetEventState() or self.EventState
    if type(pending) ~= "table"
        or type(eventState) ~= "table"
        or eventState.active ~= true
        or tostring(eventState.id or "") ~= normalizedEventId
        or eventState.startupReady ~= true
    then
        return false
    end

    self.PendingEventRejoinStateByEventId[normalizedEventId] = nil
    local replaceExisting = pending.replaceExisting == true
    local auraInstalled, auraFailed = installAuraSnapshot(self, eventState, pending.auras, replaceExisting)
    local castInstalled, castFailed = installCastSnapshot(self, eventState, pending.casts, replaceExisting)

    if type(AuraManager) == "table" and type(AuraManager.RefreshLocalPlayerDerivedState) == "function" then
        AuraManager:RefreshLocalPlayerDerivedState(eventState)
    end
    if type(self.QueueEventWidgetRefresh) == "function" then
        self:QueueEventWidgetRefresh("event-rejoin-state")
    end
    if type(Spellcasting.RefreshVisiblePlayerTooltip) == "function" then
        Spellcasting.RefreshVisiblePlayerTooltip("event-rejoin-state")
    end

    if type(Debug.Internal) == "function" then
        Debug.Internal(
            "Event rejoin state applied: event=%s mode=%s auras=%d failedAuras=%d casts=%d failedCasts=%d.",
            normalizedEventId,
            replaceExisting and "replace" or "merge",
            auraInstalled,
            auraFailed,
            castInstalled,
            castFailed
        )
    end
    return auraFailed == 0 and castFailed == 0
end

function Client:HandleEventRejoinState(arguments, sender)
    local sessionState = type(self.GetState) == "function" and self:GetState() or self.State
    local eventState = type(self.GetEventState) == "function" and self:GetEventState() or self.EventState
    if type(sessionState) ~= "table"
        or sessionState.active ~= true
        or type(eventState) ~= "table"
        or eventState.active ~= true
    then
        return false
    end

    local channelName = tostring(arguments and arguments[1] or "")
    local eventId = tostring(arguments and arguments[2] or "")
    if channelName == ""
        or channelName ~= tostring(sessionState.channelName or "")
        or eventId == ""
        or eventId ~= tostring(eventState.id or "")
    then
        return false
    end

    local expectedHost = normalizeName(eventState.hostName)
    if expectedHost == "" or normalizeName(sender) ~= expectedHost then
        return false
    end

    local snapshot = nil
    local reason = "codec-unavailable"
    if type(EventRejoinState.DeserializeSnapshot) == "function" then
        snapshot, reason = EventRejoinState.DeserializeSnapshot(arguments and arguments[3] or "")
    end
    if type(snapshot) ~= "table" then
        if type(Debug.Error) == "function" then
            Debug.Error("Event rejoin state rejected: %s.", tostring(reason or "invalid-payload"))
        end
        return false
    end

    snapshot.replaceExisting = tostring(arguments and arguments[4] or "") == "replace"
    self.PendingEventRejoinStateByEventId[eventId] = snapshot
    if eventState.startupReady == true then
        return self:ApplyEventRejoinState(eventId)
    end
    return true
end

if Client.EventRejoinStateTransitionWrapped ~= true and type(Client.EndEventTransition) == "function" then
    Client.EventRejoinStateTransitionWrapped = true
    local nativeEndEventTransition = Client.EndEventTransition
    function Client:EndEventTransition(eventId, generation, eventState, reason)
        local ended = nativeEndEventTransition(self, eventId, generation, eventState, reason)
        if ended == true and type(eventState) == "table" and eventState.startupReady == true then
            self:ApplyEventRejoinState(eventId)
        end
        return ended
    end
end
