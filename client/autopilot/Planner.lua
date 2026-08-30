local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Internal = Addon.Internal or {}

local Client = Addon.Client
local Event = Addon.Internal
    and Addon.Internal.Database
    and Addon.Internal.Database.Classes
    and Addon.Internal.Database.Classes.Event
    or nil
local Tasks = Addon.Internal.Tasks or {}

Client.AutopilotPlanner = Client.AutopilotPlanner or {}
local Planner = Client.AutopilotPlanner

Planner.Status = Planner.Status or {
    Ready = "ready",
    Planning = "planning",
    AwaitingAuthorization = "awaiting-authorization",
    SuspendedInstance = "suspended-instance",
    SuspendedPosition = "suspended-position",
    CancelledStale = "cancelled-stale",
    Failed = "failed",
}

local function normalizePositiveInteger(value, fallback)
    local numericValue = math.floor(tonumber(value) or tonumber(fallback) or 1)
    if numericValue <= 0 then
        return math.max(1, math.floor(tonumber(fallback) or 1))
    end
    return numericValue
end

local function copyArray(values)
    local copied = {}
    for index = 1, #(values or {}) do
        copied[index] = values[index]
    end
    return copied
end

local function isNpcActor(actor)
    local kind = tostring(type(actor) == "table" and actor.kind or "")
    return kind == "npc" or kind == "npc_marker"
end

local function buildCompositeActorKey(actorKeys)
    if #(actorKeys or {}) == 0 then
        return nil
    end
    if #actorKeys == 1 then
        return tostring(actorKeys[1])
    end
    return "step:" .. table.concat(actorKeys, "+")
end

function Planner.ResolveActiveNpcStep(eventState, stepCapacity)
    if type(Event) ~= "table" or type(Event.BuildTurnSchedule) ~= "function" then
        return nil, "schedule-api-unavailable"
    end
    if type(eventState) ~= "table" or eventState.active ~= true then
        return nil, "event-inactive"
    end

    local tickNumber = normalizePositiveInteger(eventState.tickNumber, 1)
    local schedule = Event.BuildTurnSchedule(eventState, stepCapacity)
    local step = type(schedule) == "table" and schedule[tickNumber] or nil
    if type(step) ~= "table" then
        return nil, "step-unavailable"
    end

    local actorKeys = {}
    local npcEventIds = {}
    local actorCount = 0

    for actorIndex = 1, #(step.actors or {}) do
        local actor = step.actors[actorIndex]
        if isNpcActor(actor) then
            actorCount = actorCount + 1
            actorKeys[#actorKeys + 1] = tostring(actor.key or "")
            for memberIndex = 1, #(actor.unitEventIds or {}) do
                local eventId = tonumber(actor.unitEventIds[memberIndex]) or 0
                if eventId > 0 then
                    npcEventIds[#npcEventIds + 1] = eventId
                end
            end
        end
    end

    if #actorKeys == 0 or #npcEventIds == 0 then
        return nil, "no-npc-actor"
    end

    return {
        tickNumber = tickNumber,
        stepIndex = tickNumber,
        actorKey = buildCompositeActorKey(actorKeys),
        actorKeys = actorKeys,
        actorCount = actorCount,
        npcEventIds = npcEventIds,
        npcCount = #npcEventIds,
        oversized = step.oversized == true,
    }
end

function Planner.BuildPlanIdentity(eventState, descriptor, scheduleRevision)
    if type(eventState) ~= "table" or type(descriptor) ~= "table" then
        return nil
    end

    local eventId = tostring(eventState.id or "")
    local turnNumber = math.max(0, math.floor(tonumber(eventState.turnNumber) or 0))
    local tickNumber = math.max(0, math.floor(tonumber(eventState.tickNumber) or 0))
    local actorKey = tostring(descriptor.actorKey or "")
    local revision = math.max(0, math.floor(tonumber(scheduleRevision) or 0))
    if eventId == "" or turnNumber <= 0 or tickNumber <= 0 or actorKey == "" then
        return nil
    end

    return table.concat({
        eventId,
        tostring(turnNumber),
        tostring(tickNumber),
        actorKey,
        tostring(revision),
    }, ":")
end

function Planner.CreateState(eventState, descriptor, scheduleRevision, planId)
    if type(eventState) ~= "table" or type(descriptor) ~= "table" then
        return nil
    end

    return {
        planId = tostring(planId or ""),
        eventId = tostring(eventState.id or ""),
        turnNumber = math.max(0, math.floor(tonumber(eventState.turnNumber) or 0)),
        tickNumber = math.max(0, math.floor(tonumber(eventState.tickNumber) or 0)),
        actorKey = tostring(descriptor.actorKey or ""),
        actorKeys = copyArray(descriptor.actorKeys),
        npcEventIds = copyArray(descriptor.npcEventIds),
        scheduleRevision = math.max(0, math.floor(tonumber(scheduleRevision) or 0)),
        phase = "validate",
        actorIndex = 1,
        npcIndex = 1,
        spellIndex = 1,
        targetIndex = 1,
        anchorIndex = 1,
        snapshot = {
            npcEventIds = {},
        },
        scratch = {
            visitedNpcCount = 0,
        },
        provisionalActions = {},
        actionCandidates = {},
        anchorCandidates = {},
        result = nil,
    }
end

function Planner.ReleaseScratch(state)
    if type(state) ~= "table" then
        return false
    end

    state.snapshot = nil
    state.scratch = nil
    state.provisionalActions = nil
    state.actionCandidates = nil
    state.anchorCandidates = nil
    state.result = nil
    return true
end

function Planner.Step(state, deadlineMs)
    if type(state) ~= "table" then
        return true
    end

    if state.phase == "validate" then
        state.phase = "snapshot"
        if type(Tasks.ShouldYield) == "function" and Tasks:ShouldYield(deadlineMs) then
            return false
        end
    end

    if state.phase == "snapshot" then
        state.snapshot = type(state.snapshot) == "table" and state.snapshot or { npcEventIds = {} }
        state.snapshot.npcEventIds = type(state.snapshot.npcEventIds) == "table" and state.snapshot.npcEventIds or {}
        state.scratch = type(state.scratch) == "table" and state.scratch or { visitedNpcCount = 0 }

        while state.npcIndex <= #(state.npcEventIds or {}) do
            local eventId = tonumber(state.npcEventIds[state.npcIndex]) or 0
            if eventId > 0 then
                state.snapshot.npcEventIds[#state.snapshot.npcEventIds + 1] = eventId
                state.scratch.visitedNpcCount = (tonumber(state.scratch.visitedNpcCount) or 0) + 1
            end
            state.npcIndex = state.npcIndex + 1

            if type(Tasks.ShouldYield) == "function" and Tasks:ShouldYield(deadlineMs) then
                return false
            end
        end

        state.phase = "finalize"
        if type(Tasks.ShouldYield) == "function" and Tasks:ShouldYield(deadlineMs) then
            return false
        end
    end

    if state.phase == "finalize" then
        state.result = {
            planId = tostring(state.planId or ""),
            eventId = tostring(state.eventId or ""),
            turnNumber = math.max(0, math.floor(tonumber(state.turnNumber) or 0)),
            tickNumber = math.max(0, math.floor(tonumber(state.tickNumber) or 0)),
            actorKey = tostring(state.actorKey or ""),
            actorKeys = copyArray(state.actorKeys),
            npcEventIds = copyArray(state.snapshot and state.snapshot.npcEventIds or {}),
            scheduleRevision = math.max(0, math.floor(tonumber(state.scheduleRevision) or 0)),
            actions = {},
            movement = nil,
            status = "ready",
        }
        state.phase = "complete"
        return true
    end

    return state.phase == "complete"
end

function Planner.CopyCompletedPlan(state)
    if type(state) ~= "table" or state.phase ~= "complete" or type(state.result) ~= "table" then
        return nil
    end

    local source = state.result
    return {
        planId = tostring(source.planId or ""),
        eventId = tostring(source.eventId or ""),
        turnNumber = math.max(0, math.floor(tonumber(source.turnNumber) or 0)),
        tickNumber = math.max(0, math.floor(tonumber(source.tickNumber) or 0)),
        actorKey = tostring(source.actorKey or ""),
        actorKeys = copyArray(source.actorKeys),
        npcEventIds = copyArray(source.npcEventIds),
        scheduleRevision = math.max(0, math.floor(tonumber(source.scheduleRevision) or 0)),
        actions = {},
        movement = nil,
        status = tostring(source.status or "ready"),
    }
end

return Planner
