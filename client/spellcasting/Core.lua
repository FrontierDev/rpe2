local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Client.Spellcasting = Addon.Client.Spellcasting or {}

local Client = Addon.Client
local Spellcasting = Client.Spellcasting
local Lookup = Addon.Utils and Addon.Utils.Lookup or {}

Client.ActiveSpellcastsByEventId = Client.ActiveSpellcastsByEventId or {}
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

    local currentTurnNumber = math.max(1, math.floor(tonumber(eventState.turnNumber) or 1))
    local currentTickNumber = math.max(1, math.floor(tonumber(eventState.tickNumber) or 1))
    local previousTurn = math.max(0, math.floor(tonumber(previousTurnNumber) or 0))
    local previousTick = math.max(0, math.floor(tonumber(previousTickNumber) or 0))
    if previousTurn == currentTurnNumber and previousTick == currentTickNumber then
        return false
    end

    local bucket = Spellcasting.GetEventCastBucket and Spellcasting.GetEventCastBucket(self, eventId, false) or nil
    if not bucket then
        return false
    end

    local changed = false
    local toComplete = {}
    for casterEventId, entry in pairs(bucket) do
        local turnsTotal = type(entry) == "table" and Spellcasting.NormalizeTurnCount and Spellcasting.NormalizeTurnCount(entry.turnsTotal) or nil
        if turnsTotal ~= nil and Spellcasting.IsCasterTurnOnTick and Spellcasting.IsCasterTurnOnTick(eventState, casterEventId) then
            local lastAdvancedTurnNumber = math.max(1, math.floor(tonumber(entry.lastAdvancedTurnNumber) or tonumber(entry.startedOnTurnNumber) or currentTurnNumber))
            if currentTurnNumber > lastAdvancedTurnNumber then
                local advancedTurns = currentTurnNumber - lastAdvancedTurnNumber
                local elapsedTurns = math.max(0, math.floor(tonumber(entry.turnsElapsed) or 0)) + advancedTurns
                if elapsedTurns > turnsTotal then
                    elapsedTurns = turnsTotal
                end
                entry.turnsElapsed = elapsedTurns
                entry.lastAdvancedTurnNumber = currentTurnNumber
                changed = true

                if elapsedTurns >= turnsTotal then
                    toComplete[#toComplete + 1] = tonumber(casterEventId) or 0
                end
            end
        end
    end

    for index = 1, #toComplete do
        local casterEventId = toComplete[index]
        local existing = Spellcasting.GetCastEntry and Spellcasting.GetCastEntry(self, eventId, casterEventId) or nil
        local isLocalCaster = self:IsLocalSpellcaster(eventId, casterEventId)
        if existing then
            changed = true
            if isLocalCaster then
                if existing.spellRef and type(self.OnSpellcastComplete) == "function" then
                    self:OnSpellcastComplete(existing.spellRef, existing)
                end
            else
                local previous = Spellcasting.RemoveCastEntry and Spellcasting.RemoveCastEntry(self, eventId, casterEventId) or nil
                local casterUnit = Lookup.FindEventUnitById and Lookup.FindEventUnitById(eventState.units, casterEventId) or nil
                Spellcasting.LogLifecycle(
                    "complete",
                    (previous and previous.authorityType) or "player",
                    casterUnit and casterUnit.name or "unknown",
                    (previous and previous.spellName) or (Spellcasting.ResolveSpellName and Spellcasting.ResolveSpellName(existing.spellRef) or existing.spellRef)
                )
            end
        end
    end

    if changed then
        Spellcasting.RefreshVisiblePlayerTooltip("event-state")
    end

    return changed
end

function Client:AdvanceAuraState(previousTurnNumber, previousTickNumber)
    if type(Spellcasting.AdvanceAuraState) ~= "function" then
        return false
    end

    return Spellcasting.AdvanceAuraState(self, previousTurnNumber, previousTickNumber)
end
