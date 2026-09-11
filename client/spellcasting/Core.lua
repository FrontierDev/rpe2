local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Client.Spellcasting = Addon.Client.Spellcasting or {}

local Client = Addon.Client
local Spellcasting = Client.Spellcasting
local Lookup = Addon.Utils and Addon.Utils.Lookup or {}
local CombatState = Addon.Internal
    and Addon.Internal.Comms
    and Addon.Internal.Comms.EventCombatState
    or {}

local function startTiming(label, thresholdMs, context)
    local timings = Addon.Debug and Addon.Debug.Timings or nil
    if timings and type(timings.Start) == "function" then
        if type(timings.IsEnabled) == "function" and not timings:IsEnabled() then
            return nil
        end
        return timings:Start(label, {
            thresholdMs = thresholdMs,
            context = context,
        })
    end
    return nil
end

local function stopTiming(timer, cardinality)
    if not timer then
        return
    end

    local timings = Addon.Debug and Addon.Debug.Timings or nil
    if timings and type(timings.Stop) == "function" then
        timings:Stop(timer, { cardinality = cardinality })
    end
end

local function countEntries(value)
    local count = 0
    if type(value) == "table" then
        for _ in pairs(value) do
            count = count + 1
        end
    end
    return count
end

Client.ActiveSpellcastsByEventId = Client.ActiveSpellcastsByEventId or {}
Client.ActiveSpellcastRevisionByEventId = Client.ActiveSpellcastRevisionByEventId or {}
Client.ActiveAurasByEventId = Client.ActiveAurasByEventId or {}

function Client:GetSpellcastEntry(eventId, casterEventId)
    return Spellcasting.GetCastEntry and Spellcasting.GetCastEntry(self, eventId, casterEventId) or nil
end

function Client:IsLocalSpellcaster(eventId, casterEventId)
    return Spellcasting.IsLocalCasterEntry and Spellcasting.IsLocalCasterEntry(self, eventId, casterEventId) or false
end

function Client:ResetSpellcastingState(eventId)
    if type(eventId) == "string" and eventId ~= "" then
        if Spellcasting.ClearEventCastBucket then
            Spellcasting.ClearEventCastBucket(self, eventId)
        end
        if Spellcasting.ResetCooldownState then
            Spellcasting.ResetCooldownState(self, eventId)
        end
        if Spellcasting.ResetAuraState then
            Spellcasting.ResetAuraState(self, eventId)
        end
        return true
    end

    local existingCastBuckets = self.ActiveSpellcastsByEventId
    if type(existingCastBuckets) == "table" and Spellcasting.BumpEventCastRevision then
        for existingEventId in pairs(existingCastBuckets) do
            Spellcasting.BumpEventCastRevision(self, tostring(existingEventId or ""))
        end
    end
    self.ActiveSpellcastsByEventId = {}
    if Spellcasting.ResetCooldownState then
        Spellcasting.ResetCooldownState(self)
    end
    if Spellcasting.ResetAuraState then
        Spellcasting.ResetAuraState(self)
    end
    return true
end

function Client:AdvanceSpellcastState(previousTurnNumber, previousTickNumber)
    local eventState = self.GetEventState and self:GetEventState() or nil
    if not eventState or eventState.active ~= true then
        return false
    end

    local eventId = tostring(eventState.id or "")
    if eventId == "" then
        return false
    end

    local timer = startTiming("Spellcast advancement", 8, eventId)

    local currentTurnNumber = math.max(1, math.floor(tonumber(eventState.turnNumber) or 1))
    local currentTickNumber = math.max(1, math.floor(tonumber(eventState.tickNumber) or 1))
    local previousTurn = math.max(0, math.floor(tonumber(previousTurnNumber) or 0))
    local previousTick = math.max(0, math.floor(tonumber(previousTickNumber) or 0))
    if previousTurn == currentTurnNumber and previousTick == currentTickNumber then
        if timer then
            stopTiming(timer, { activeCasts = 0, completedCasts = 0, eventUnits = type(eventState.units) == "table" and #eventState.units or 0 })
        end
        return false
    end

    local bucket = Spellcasting.GetEventCastBucket and Spellcasting.GetEventCastBucket(self, eventId, false) or nil
    if not bucket then
        if timer then
            stopTiming(timer, { activeCasts = 0, completedCasts = 0, eventUnits = type(eventState.units) == "table" and #eventState.units or 0 })
        end
        return false
    end
    if type(CombatState.AdvanceCastBucket) ~= "function" then
        return false
    end

    local before = type(CombatState.CloneCastBucket) == "function"
        and CombatState.CloneCastBucket(bucket)
        or {}
    local changed, completed = CombatState.AdvanceCastBucket(
        bucket,
        currentTurnNumber,
        function(casterEventId)
            return type(Spellcasting.IsCasterTurnOnTick) == "function"
                and Spellcasting.IsCasterTurnOnTick(eventState, casterEventId) == true
        end
    )
    completed = type(completed) == "table" and completed or {}

    if changed == true and Spellcasting.BumpEventCastRevision then
        Spellcasting.BumpEventCastRevision(self, eventId)
    end

    for index = 1, #completed do
        local casterEventId = tonumber(completed[index]) or 0
        local previous = before[casterEventId]
        if type(previous) == "table" then
            if self:IsLocalSpellcaster(eventId, casterEventId) then
                if previous.spellRef and type(self.OnSpellcastComplete) == "function" then
                    self:OnSpellcastComplete(previous.spellRef, previous)
                end
            else
                local casterUnit = Lookup.FindEventUnitById and Lookup.FindEventUnitById(eventState.units, casterEventId) or nil
                Spellcasting.LogLifecycle(
                    "complete",
                    previous.authorityType or "player",
                    casterUnit and casterUnit.name or "unknown",
                    previous.spellName or (Spellcasting.ResolveSpellName and Spellcasting.ResolveSpellName(previous.spellRef) or previous.spellRef)
                )
            end
        end
    end

    if changed == true then
        Spellcasting.RefreshVisiblePlayerTooltip("event-state")
    end

    if timer then
        stopTiming(timer, {
            activeCasts = countEntries(bucket),
            completedCasts = #completed,
            eventUnits = type(eventState.units) == "table" and #eventState.units or 0,
        })
    end
    return changed == true
end

function Client:AdvanceAuraState(previousTurnNumber, previousTickNumber)
    if type(Spellcasting.AdvanceAuraState) ~= "function" then
        return false
    end

    return Spellcasting.AdvanceAuraState(self, previousTurnNumber, previousTickNumber)
end
