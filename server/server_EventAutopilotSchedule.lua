local _, Addon = ...

Addon.Server = Addon.Server or {}
Addon.Internal = Addon.Internal or {}

local Server = Addon.Server
local Event = Addon.Internal
    and Addon.Internal.Database
    and Addon.Internal.Database.Classes
    and Addon.Internal.Database.Classes.Event
    or nil
local Autopilot = Addon.Internal.Autopilot or {}
local Ruleset = Addon.Internal.Ruleset or {}

if type(Event) ~= "table" or type(Event.CountActiveUnits) ~= "function" then
    return
end

local DEFAULT_MAX_EVENT_UNITS = 5
local baseCountActiveUnits = Event.CountActiveUnits
local countPatchDepth = 0

local function pack(...)
    return { n = select("#", ...), ... }
end

local function normalizeTurnMode(value)
    if type(Event.NormalizeTurnMode) == "function" then
        return Event.NormalizeTurnMode(value)
    end
    if type(Autopilot.NormalizeTurnMode) == "function" then
        return Autopilot.NormalizeTurnMode(value)
    end
    return tostring(value or "") == "autopilot" and "autopilot" or "manual"
end

local function isNpcEventMode(eventState)
    return type(eventState) == "table"
        and type(Event.NormalizeEventMode) == "function"
        and Event.NormalizeEventMode(eventState.eventMode) == "npc"
end

local function getMaxEventUnits()
    local activeRuleset = Ruleset.GetActiveRuleset and Ruleset.GetActiveRuleset() or nil
    local definition = Ruleset.GetRulesetRuleDefinition
        and Ruleset.GetRulesetRuleDefinition("event", "max_event_units")
        or nil
    local value = Ruleset.GetRulesetRuleValue
        and Ruleset.GetRulesetRuleValue(activeRuleset, "event", definition)
        or nil
    local resolved = math.floor(tonumber(value) or DEFAULT_MAX_EVENT_UNITS)
    if resolved <= 0 then
        return DEFAULT_MAX_EVENT_UNITS
    end
    return resolved
end

local function resolveTurnModeForUnits(units)
    local contextMode = type(Autopilot.GetEventStartTurnModeContext) == "function"
        and Autopilot.GetEventStartTurnModeContext()
        or nil
    if contextMode ~= nil then
        return normalizeTurnMode(contextMode)
    end

    local eventState = Server.EventState
    if type(eventState) == "table" and eventState.units == units then
        return normalizeTurnMode(eventState.turnMode)
    end

    local draftState = Server.EventDraftState
    if type(draftState) == "table" and draftState.units == units then
        return normalizeTurnMode(draftState.turnMode)
    end

    return "manual"
end

local function scheduleAwareActiveCount(units)
    if resolveTurnModeForUnits(units) ~= "autopilot"
        or type(Event.BuildTurnActors) ~= "function"
        or type(Event.GetTurnStepCount) ~= "function"
    then
        return baseCountActiveUnits(units)
    end

    local actors = Event.BuildTurnActors({ units = units })
    if #actors == 0 then
        return 0
    end

    local pageSize = getMaxEventUnits()
    local stepCount = Event.GetTurnStepCount({
        turnMode = "autopilot",
        units = units,
    }, pageSize)

    -- server_Event.lua computes ceil(activeCount / pageSize).  While one of
    -- its existing event methods is running, expose a synthetic count whose
    -- ceiling is the number of atomic Autopilot TurnSteps.  The public
    -- Event.CountActiveUnits contract is restored immediately afterwards.
    return ((math.max(1, stepCount) - 1) * pageSize) + 1
end

local function pushScheduleCountPatch()
    countPatchDepth = countPatchDepth + 1
    if countPatchDepth == 1 then
        Event.CountActiveUnits = scheduleAwareActiveCount
    end
end

local function popScheduleCountPatch()
    countPatchDepth = math.max(0, countPatchDepth - 1)
    if countPatchDepth == 0 then
        Event.CountActiveUnits = baseCountActiveUnits
    end
end

local function invokeWithScheduleCount(fn, self, ...)
    local args = pack(...)
    pushScheduleCountPatch()
    local results = pack(pcall(fn, self, unpack(args, 1, args.n)))
    popScheduleCountPatch()

    if results[1] ~= true then
        error(results[2], 0)
    end

    return unpack(results, 2, results.n)
end

local function normalizeState(state)
    if type(Event.NormalizeTurnScheduleState) == "function" then
        Event.NormalizeTurnScheduleState(state, getMaxEventUnits())
    end
    return state
end

local function normalizeKnownServerStates(server)
    normalizeState(server and server.EventState or nil)
    normalizeState(server and server.EventDraftState or nil)
end

local function wrapScheduleSensitiveMethod(methodName)
    local baseMethod = Server[methodName]
    if type(baseMethod) ~= "function" then
        return false
    end

    Server[methodName] = function(self, ...)
        if methodName == "AdvanceEventStep" and isNpcEventMode(self and self.EventState) then
            return false
        end
        local results = pack(invokeWithScheduleCount(baseMethod, self, ...))
        if not (methodName == "_AdvanceEventStepAfterCommit" and isNpcEventMode(self and self.EventState)) then
            normalizeKnownServerStates(self)
        end
        return unpack(results, 1, results.n)
    end
    return true
end

-- These are the current server_Event.lua entry points which can invoke the
-- private normalizeEventStepState()/computeTotalTicks() path.  Wrapping the
-- final public methods preserves the existing turn-commit and delta logic
-- rather than duplicating it for Autopilot.
local scheduleSensitiveMethods = {
    "GetEventDraftState",
    "ReconcileClientEventSession",
    "AddEventNpcUnit",
    "SummonEventPetUnit",
    "SetEventUnitActive",
    "ClearEventNpcUnits",
    "StartEvent",
    "AdvanceEventStep",
    "_AdvanceEventStepAfterCommit",
}

for index = 1, #scheduleSensitiveMethods do
    wrapScheduleSensitiveMethod(scheduleSensitiveMethods[index])
end

-- Raid-marker changes do not affect manual pagination, so the existing setter
-- intentionally does not recompute totalTicks.  They do affect Autopilot
-- TurnActors, so normalize the derived state afterwards and send EVENT_STATE
-- only when the scalar tick state actually changed.
do
    local baseSetEventUnitRaidMarker = Server.SetEventUnitRaidMarker
    if type(baseSetEventUnitRaidMarker) == "function" then
        function Server:SetEventUnitRaidMarker(eventId, raidMarker)
            local eventState = self.EventState
            local previousTick = tonumber(eventState and eventState.tickNumber) or 0
            local previousTotalTicks = tonumber(eventState and eventState.totalTicks) or 0

            local results = pack(invokeWithScheduleCount(baseSetEventUnitRaidMarker, self, eventId, raidMarker))
            normalizeKnownServerStates(self)

            eventState = self.EventState
            local changedStepState = type(eventState) == "table"
                and normalizeTurnMode(eventState.turnMode) == "autopilot"
                and (
                    previousTick ~= (tonumber(eventState.tickNumber) or 0)
                    or previousTotalTicks ~= (tonumber(eventState.totalTicks) or 0)
                )

            if results[1] == true
                and changedStepState
                and eventState.active == true
                and type(self.BroadcastEventDeltaBatch) == "function"
            then
                local numericEventId = tonumber(eventId) or 0
                local unit = nil
                for index = 1, #(eventState.units or {}) do
                    local candidate = eventState.units[index]
                    if tonumber(candidate and candidate.eventID) == numericEventId then
                        unit = candidate
                        break
                    end
                end

                if unit then
                    self:BroadcastEventDeltaBatch({
                        {
                            operation = "upsert",
                            eventID = numericEventId,
                            unit = unit,
                        },
                    }, true)
                end
            end

            return unpack(results, 1, results.n)
        end
    end
end
