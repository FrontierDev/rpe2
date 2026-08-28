local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Client.Spellcasting = Addon.Client.Spellcasting or {}

local Client = Addon.Client
local Spellcasting = Client.Spellcasting
local Lookup = Addon.Utils and Addon.Utils.Lookup or {}

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
Client.ActiveAurasByEventId = Client.ActiveAurasByEventId or {}

function Client:GetSpellcastEntry(eventId, casterEventId)
    return Spellcasting.GetCastEntry and Spellcasting.GetCastEntry(self, eventId, casterEventId) or nil
end

function Client:IsLocalSpellcaster(eventId, casterEventId, localEventUnitOverride, unitsByEventId, playerUnitsByName)
    return Spellcasting.IsLocalCasterEntry
        and Spellcasting.IsLocalCasterEntry(
            self,
            eventId,
            casterEventId,
            localEventUnitOverride,
            unitsByEventId,
            playerUnitsByName
        )
        or false
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

local function shouldYield(deadlineMs)
    local tasks = Addon.Internal and Addon.Internal.Tasks or nil
    return type(tasks) == "table"
        and type(tasks.ShouldYield) == "function"
        and tasks:ShouldYield(deadlineMs) == true
end

local function isSpellcastContinuationCurrent(continuation)
    local client = continuation and continuation.client or nil
    local eventState = continuation and continuation.eventState or nil
    if type(client) ~= "table"
        or type(eventState) ~= "table"
        or eventState.active ~= true
        or eventState.ending == true
    then
        return false
    end
    local currentEventState = client.GetEventState and client:GetEventState() or client.EventState
    return currentEventState == eventState
        and tostring(currentEventState.id or "") == tostring(continuation.eventId or "")
end

local function isSpellcastCasterTurnOnTick(continuation, eventState, casterEventId)
    local turnPageIndex = continuation
        and continuation.options
        and continuation.options.turnPageIndex
        or nil
    if type(turnPageIndex) == "table" then
        local currentTick = math.max(1, math.floor(tonumber(eventState and eventState.tickNumber) or 0))
        local numericCasterEventId = tonumber(casterEventId) or 0
        return numericCasterEventId > 0
            and tonumber(turnPageIndex[numericCasterEventId]) == currentTick
    end

    return Spellcasting.IsCasterTurnOnTick
        and Spellcasting.IsCasterTurnOnTick(eventState, casterEventId)
        or false
end

-- This continuation deliberately keeps the broad cast bucket scan intact.  The
-- following sparse due-index task owns replacing that scan.  The scan and the
-- completion list are nevertheless resumable here so event packets no longer
-- own the whole cast consequence graph on their call stack.
function Spellcasting.CreateSpellcastAdvanceContinuation(self, previousTurnNumber, previousTickNumber, options)
    local eventState = self.GetEventState and self:GetEventState() or nil
    local eventId = tostring(eventState and eventState.id or "")
    if type(eventState) ~= "table" or eventState.active ~= true or eventId == "" then
        return nil
    end

    local currentTurnNumber = math.max(1, math.floor(tonumber(eventState.turnNumber) or 1))
    local currentTickNumber = math.max(1, math.floor(tonumber(eventState.tickNumber) or 1))
    local previousTurn = math.max(0, math.floor(tonumber(previousTurnNumber) or 0))
    local previousTick = math.max(0, math.floor(tonumber(previousTickNumber) or 0))
    local bucket = Spellcasting.GetEventCastBucket and Spellcasting.GetEventCastBucket(self, eventId, false) or nil
    return {
        client = self,
        eventState = eventState,
        eventId = eventId,
        previousTurn = previousTurn,
        previousTick = previousTick,
        currentTurn = currentTurnNumber,
        currentTick = currentTickNumber,
        bucket = bucket,
        options = type(options) == "table" and options or {},
        phase = previousTurn == currentTurnNumber and previousTick == currentTickNumber and "done" or "scan",
        scanKey = nil,
        completionIndex = 0,
        toComplete = {},
        changed = false,
        inspected = 0,
        processed = 0,
        completed = 0,
    }
end

function Spellcasting.StepSpellcastAdvanceContinuation(continuation, deadlineMs)
    if type(continuation) ~= "table" then
        return nil, "error"
    end
    if continuation.phase == "done" then
        return true, "complete"
    end
    if not isSpellcastContinuationCurrent(continuation) then
        return nil, "stale"
    end

    local client = continuation.client
    local eventState = continuation.eventState
    local eventId = continuation.eventId
    local bucket = continuation.bucket
    if type(bucket) ~= "table" then
        continuation.phase = "done"
        return true, "complete"
    end

    if continuation.phase == "scan" then
        local casterEventId, entry = next(bucket, continuation.scanKey)
        if casterEventId == nil then
            continuation.phase = "complete"
            continuation.completionIndex = 0
        else
            continuation.scanKey = casterEventId
            continuation.inspected = continuation.inspected + 1
            local turnsTotal = type(entry) == "table"
                and Spellcasting.NormalizeTurnCount
                and Spellcasting.NormalizeTurnCount(entry.turnsTotal)
                or nil
            if turnsTotal ~= nil
                and isSpellcastCasterTurnOnTick(continuation, eventState, casterEventId)
            then
                local lastAdvancedTurnNumber = math.max(
                    1,
                    math.floor(tonumber(entry.lastAdvancedTurnNumber) or tonumber(entry.startedOnTurnNumber) or continuation.currentTurn)
                )
                if continuation.currentTurn > lastAdvancedTurnNumber then
                    local advancedTurns = continuation.currentTurn - lastAdvancedTurnNumber
                    local elapsedTurns = math.max(0, math.floor(tonumber(entry.turnsElapsed) or 0)) + advancedTurns
                    if elapsedTurns > turnsTotal then
                        elapsedTurns = turnsTotal
                    end
                    entry.turnsElapsed = elapsedTurns
                    entry.lastAdvancedTurnNumber = continuation.currentTurn
                    continuation.changed = true
                    if elapsedTurns >= turnsTotal then
                        continuation.toComplete[#continuation.toComplete + 1] = tonumber(casterEventId) or 0
                    end
                end
            end
        end
        if continuation.phase == "scan" and shouldYield(deadlineMs) then
            return false, "incomplete"
        end
    end

    if continuation.phase == "complete" then
        continuation.completionIndex = continuation.completionIndex + 1
        local casterEventId = continuation.toComplete[continuation.completionIndex]
        if casterEventId == nil then
            if continuation.changed
                and continuation.options.deferPresentation ~= true
                and type(Spellcasting.RefreshVisiblePlayerTooltip) == "function"
            then
                Spellcasting.RefreshVisiblePlayerTooltip("event-state")
            end
            continuation.phase = "done"
            return true, "complete"
        end

        local existing = Spellcasting.GetCastEntry and Spellcasting.GetCastEntry(client, eventId, casterEventId) or nil
        if existing then
            continuation.processed = continuation.processed + 1
            continuation.completed = continuation.completed + 1
            continuation.changed = true
            local isLocalCaster = client:IsLocalSpellcaster(
                eventId,
                casterEventId,
                continuation.options and continuation.options.localEventUnit,
                continuation.options and continuation.options.unitsByEventId,
                continuation.options and continuation.options.playerUnitsByName
            )
            if isLocalCaster then
                if existing.spellRef and type(client.OnSpellcastComplete) == "function" then
                    -- OnSpellcastComplete remains the intentionally indivisible
                    -- spell-component boundary owned by #69.  The event-step
                    -- phase still isolates it from packet receipt and other
                    -- phases, and the internal flag is scoped to this call.
                    local previousInternal = client.EventStepInternal
                    client.EventStepInternal = true
                    local ok, completionError = pcall(function()
                        client:OnSpellcastComplete(existing.spellRef, existing)
                    end)
                    client.EventStepInternal = previousInternal
                    if not ok then
                        return nil, "error"
                    end
                end
            else
                local previous = Spellcasting.RemoveCastEntry and Spellcasting.RemoveCastEntry(client, eventId, casterEventId) or nil
                local unitsByEventId = continuation.options and continuation.options.unitsByEventId or nil
                local casterUnit
                if type(unitsByEventId) == "table" then
                    casterUnit = unitsByEventId[tonumber(casterEventId) or 0]
                elseif Lookup.FindEventUnitById then
                    casterUnit = Lookup.FindEventUnitById(eventState.units, casterEventId)
                end
                if type(Spellcasting.LogLifecycle) == "function" then
                    Spellcasting.LogLifecycle(
                        "complete",
                        (previous and previous.authorityType) or "player",
                        casterUnit and casterUnit.name or "unknown",
                        (previous and previous.spellName) or (Spellcasting.ResolveSpellName and Spellcasting.ResolveSpellName(existing.spellRef) or existing.spellRef)
                    )
                end
            end
            local numericCasterEventId = tonumber(casterEventId) or 0
            if numericCasterEventId > 0 then
                continuation.affectedEventUnitIds = continuation.affectedEventUnitIds or {}
                if not continuation.affectedEventUnitIds[numericCasterEventId] then
                    continuation.affectedEventUnitIds[numericCasterEventId] = true
                    continuation.affectedEventUnitList = continuation.affectedEventUnitList or {}
                    continuation.affectedEventUnitList[#continuation.affectedEventUnitList + 1] = numericCasterEventId
                end
            end
        end
        if shouldYield(deadlineMs) then
            return false, "incomplete"
        end
    end

    if continuation.phase == "complete" and continuation.completionIndex >= #continuation.toComplete then
        if continuation.changed
            and continuation.options.deferPresentation ~= true
            and type(Spellcasting.RefreshVisiblePlayerTooltip) == "function"
        then
            Spellcasting.RefreshVisiblePlayerTooltip("event-state")
        end
        continuation.phase = "done"
        return true, "complete"
    end

    return false, "incomplete"
end

function Client:AdvanceSpellcastState(previousTurnNumber, previousTickNumber)
    local continuation = Spellcasting.CreateSpellcastAdvanceContinuation(self, previousTurnNumber, previousTickNumber)
    if not continuation then
        return false
    end
    while continuation.phase ~= "done" do
        local complete, status = Spellcasting.StepSpellcastAdvanceContinuation(continuation, nil)
        if complete == nil then
            return false
        end
        if complete == true then
            break
        end
        if status ~= "incomplete" then
            break
        end
    end
    return continuation.changed == true
end

function Client:AdvanceAuraState(previousTurnNumber, previousTickNumber)
    local continuation = self:CreateAuraAdvanceContinuation(previousTurnNumber, previousTickNumber)
    if not continuation then
        return false
    end

    while continuation.phase ~= "done" do
        local complete, status = self:StepAuraAdvanceContinuation(continuation, nil)
        if complete == nil or (complete ~= true and status ~= "incomplete") then
            return false
        end
        if complete == true then
            break
        end
    end
    return continuation.changed == true
end

function Client:CreateSpellcastAdvanceContinuation(previousTurnNumber, previousTickNumber, options)
    return Spellcasting.CreateSpellcastAdvanceContinuation(self, previousTurnNumber, previousTickNumber, options)
end

function Client:StepSpellcastAdvanceContinuation(continuation, deadlineMs)
    return Spellcasting.StepSpellcastAdvanceContinuation(continuation, deadlineMs)
end

function Client:CreateAuraAdvanceContinuation(previousTurnNumber, previousTickNumber, options)
    return Spellcasting.CreateAuraAdvanceContinuation
        and Spellcasting.CreateAuraAdvanceContinuation(self, previousTurnNumber, previousTickNumber, options)
        or nil
end

function Client:StepAuraAdvanceContinuation(continuation, deadlineMs)
    if type(Spellcasting.StepAuraAdvanceContinuation) ~= "function" then
        return nil, "error"
    end
    return Spellcasting.StepAuraAdvanceContinuation(continuation, deadlineMs)
end
