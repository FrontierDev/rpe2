local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Server = Addon.Server or {}
Addon.Internal = Addon.Internal or {}

local Client = Addon.Client
local Server = Addon.Server
local Event = Addon.Internal
    and Addon.Internal.Database
    and Addon.Internal.Database.Classes
    and Addon.Internal.Database.Classes.Event
    or nil
local Autopilot = Addon.Internal.Autopilot or {}
local Ruleset = Addon.Internal.Ruleset or {}
local Tasks = Addon.Internal.Tasks or {}
local Planner = Client.AutopilotPlanner or {}

if type(Event) ~= "table" or type(Planner) ~= "table" then
    return
end

local DEFAULT_MAX_EVENT_UNITS = 5
local advanceEventStepDepth = 0

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

local function getEventId(eventState)
    return tostring(type(eventState) == "table" and eventState.id or "")
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

local function isHostAutopilotEvent(eventState)
    return type(eventState) == "table"
        and eventState.active == true
        and normalizeTurnMode(eventState.turnMode) == "autopilot"
        and type(Client.IsLocalEventHost) == "function"
        and Client:IsLocalEventHost(eventState) == true
end

local function sameEventStep(left, right)
    return type(left) == "table"
        and type(right) == "table"
        and getEventId(left) ~= ""
        and getEventId(left) == getEventId(right)
        and tonumber(left.turnNumber) == tonumber(right.turnNumber)
        and tonumber(left.tickNumber) == tonumber(right.tickNumber)
end

local function ensurePlannerRuntimeFields(runtime)
    if type(runtime) ~= "table" then
        return nil
    end

    runtime.planByStepKey = type(runtime.planByStepKey) == "table" and runtime.planByStepKey or {}
    runtime.activePlanId = runtime.activePlanId
    runtime.lastCompletedPlanId = runtime.lastCompletedPlanId
    runtime.currentPlannerActorKey = runtime.currentPlannerActorKey
    runtime.currentPlannerScheduleRevision = runtime.currentPlannerScheduleRevision
    runtime.plannerStatus = tostring(runtime.plannerStatus or "ready")
    return runtime
end

local function getPlannerRuntime(eventState)
    if not isHostAutopilotEvent(eventState) then
        return nil, "not-host-autopilot"
    end

    local eventId = getEventId(eventState)
    local runtime = eventId ~= ""
        and type(Client.AutopilotRuntimeByEventId) == "table"
        and Client.AutopilotRuntimeByEventId[eventId]
        or nil
    if type(runtime) ~= "table" then
        return nil, "runtime-unavailable"
    end

    ensurePlannerRuntimeFields(runtime)
    if runtime.status ~= "ready" then
        local reason = tostring(runtime.unavailableReason or "position-unavailable")
        if reason == "instance" or reason == "instance-mismatch" then
            runtime.plannerStatus = "suspended-instance"
        else
            runtime.plannerStatus = "suspended-position"
        end
        return nil, reason
    end

    return runtime
end

local function markPlanCancelled(plan, reason)
    if type(plan) ~= "table" then
        return false
    end

    local normalizedReason = tostring(reason or "cancelled")
    plan.job = nil
    plan.result = nil
    plan.cancelReason = normalizedReason
    if normalizedReason == "stale" or string.find(normalizedReason, "stale", 1, true) then
        plan.status = "cancelled-stale"
    elseif normalizedReason == "error" or string.find(normalizedReason, "error", 1, true) then
        plan.status = "failed"
    else
        plan.status = "cancelled"
    end
    return true
end

local function updateRuntimeAfterCancellation(runtime, plan, reason)
    if type(runtime) ~= "table" or type(plan) ~= "table" then
        return
    end

    local planId = tostring(plan.id or "")
    if planId == "" or tostring(runtime.activePlanId or "") ~= planId then
        return
    end

    runtime.activePlanId = nil

    local normalizedReason = tostring(reason or "cancelled")
    if normalizedReason == "stale" or string.find(normalizedReason, "stale", 1, true) then
        runtime.plannerStatus = "cancelled-stale"
    elseif normalizedReason == "error" or string.find(normalizedReason, "error", 1, true) then
        runtime.plannerStatus = "failed"
    elseif runtime.status == "ready" then
        runtime.plannerStatus = "ready"
    end
end

function Client:GetAutopilotPlannerRuntime(eventState)
    return getPlannerRuntime(eventState)
end

function Client:GetAutopilotCurrentPlan(eventState)
    local runtime, reason = getPlannerRuntime(eventState)
    if type(runtime) ~= "table" then
        return nil, reason
    end

    local planId = tostring(runtime.activePlanId or "")
    if planId == "" then
        return nil, "plan-unavailable"
    end
    return runtime.planByStepKey[planId]
end

function Client:IsAutopilotPlanStateStale(state)
    if type(state) ~= "table" then
        return true
    end

    local eventState = Server.EventState
    if not isHostAutopilotEvent(eventState) then
        return true
    end
    if getEventId(eventState) ~= tostring(state.eventId or "") then
        return true
    end
    if tonumber(eventState.turnNumber) ~= tonumber(state.turnNumber)
        or tonumber(eventState.tickNumber) ~= tonumber(state.tickNumber)
    then
        return true
    end

    local runtime = type(Client.AutopilotRuntimeByEventId) == "table"
        and Client.AutopilotRuntimeByEventId[tostring(state.eventId or "")]
        or nil
    if type(runtime) ~= "table" or runtime ~= state.runtimeRef or runtime.status ~= "ready" then
        return true
    end
    if tostring(runtime.currentPlannerActorKey or "") ~= tostring(state.actorKey or "") then
        return true
    end
    if tostring(runtime.currentPlannerScheduleRevision or "") ~= tostring(state.scheduleRevision or "") then
        return true
    end

    return false
end

function Client:CancelAutopilotPlannerScope(eventId, reason)
    local normalizedEventId = tostring(eventId or "")
    if normalizedEventId == "" or type(Tasks.CancelScope) ~= "function" then
        return 0
    end
    return Tasks:CancelScope("autopilot:" .. normalizedEventId, reason or "event-cancelled")
end

function Client:ResetAutopilotBatchState(eventId, reason)
    local normalizedEventId = tostring(eventId or "")
    if normalizedEventId == "" then
        return false
    end

    local runtime = type(self.AutopilotRuntimeByEventId) == "table"
        and self.AutopilotRuntimeByEventId[normalizedEventId]
        or nil
    if type(runtime) ~= "table" then
        return false
    end

    ensurePlannerRuntimeFields(runtime)

    -- Detach the active pointer before cancellation callbacks run so obsolete
    -- planner callbacks cannot republish status into the reset batch. Keep the
    -- records alive until the scope has been cancelled, then dispose them.
    runtime.activePlanId = nil
    runtime.lastCompletedPlanId = nil
    runtime.currentPlannerActorKey = nil
    runtime.currentPlannerScheduleRevision = nil

    self:CancelAutopilotPlannerScope(normalizedEventId, reason or "batch-reset")
    runtime.planByStepKey = {}

    if runtime.status == "ready" then
        runtime.plannerStatus = "ready"
    end

    -- Clear legacy #127/#133/#135 transient fields if this session was already
    -- running when the addon code changed. They are not part of the new model.
    runtime.pendingPlannerClientSync = nil
    runtime.pendingCombatSettlementsByCastId = nil
    runtime.postSettlementPlanId = nil
    runtime.postSettlementReplanUsed = nil
    runtime.plannerFailureReason = nil

    if type(self.ResetAutopilotAuthorizationBatch) == "function" then
        self:ResetAutopilotAuthorizationBatch(normalizedEventId, reason or "batch-reset")
    end
    return true
end

local function cancelObsoleteActivePlan(runtime, nextPlanId, reason)
    if type(runtime) ~= "table" then
        return false
    end

    local activePlanId = tostring(runtime.activePlanId or "")
    if activePlanId == "" or activePlanId == tostring(nextPlanId or "") then
        return false
    end

    local activePlan = runtime.planByStepKey and runtime.planByStepKey[activePlanId] or nil
    if type(activePlan) == "table"
        and (activePlan.status == "queued" or activePlan.status == "planning")
        and activePlan.job
        and type(Tasks.Cancel) == "function"
    then
        Tasks:Cancel(activePlan.job, reason or "replaced")
    end

    if tostring(runtime.activePlanId or "") == activePlanId then
        runtime.activePlanId = nil
    end
    return true
end

function Client:EnsureAutopilotPlanForCurrentStep(eventStateOverride)
    local eventState = eventStateOverride or Server.EventState
    local runtime, runtimeReason = getPlannerRuntime(eventState)
    if type(runtime) ~= "table" then
        return nil, false, runtimeReason
    end
    if type(Tasks.EnqueueSliceable) ~= "function"
        or type(Planner.ResolveActiveNpcStep) ~= "function"
        or type(Planner.BuildPlanIdentity) ~= "function"
        or type(Planner.CreateState) ~= "function"
        or type(Planner.Step) ~= "function"
    then
        runtime.plannerStatus = "failed"
        return nil, false, "planner-api-unavailable"
    end

    local stepCapacity = getMaxEventUnits()
    local descriptor, descriptorReason = Planner.ResolveActiveNpcStep(eventState, stepCapacity)
    if type(descriptor) ~= "table" then
        runtime.currentPlannerActorKey = nil
        runtime.currentPlannerScheduleRevision = nil
        if descriptorReason == "no-npc-actor" then
            cancelObsoleteActivePlan(runtime, nil, "actor-changed")
            runtime.plannerStatus = "ready"
        end
        return nil, false, descriptorReason
    end

    runtime.currentPlannerActorKey = tostring(descriptor.actorKey or "")
    runtime.currentPlannerScheduleRevision = tostring(descriptor.scheduleRevision or "")

    local planId = Planner.BuildPlanIdentity(eventState, descriptor, descriptor.scheduleRevision)
    if type(planId) ~= "string" or planId == "" then
        runtime.plannerStatus = "failed"
        return nil, false, "plan-identity-unavailable"
    end

    local existing = runtime.planByStepKey[planId]
    if type(existing) == "table"
        and (existing.status == "queued" or existing.status == "planning" or existing.status == "ready")
    then
        runtime.activePlanId = planId
        return existing, false
    end

    cancelObsoleteActivePlan(runtime, planId, "replaced")

    local state = Planner.CreateState(eventState, descriptor, descriptor.scheduleRevision, planId)
    if type(state) ~= "table" then
        runtime.plannerStatus = "failed"
        return nil, false, "planner-state-unavailable"
    end

    local plan = {
        id = planId,
        eventId = tostring(eventState.id or ""),
        turnNumber = math.max(0, math.floor(tonumber(eventState.turnNumber) or 0)),
        tickNumber = math.max(0, math.floor(tonumber(eventState.tickNumber) or 0)),
        actorKey = tostring(descriptor.actorKey or ""),
        actorKeys = descriptor.actorKeys,
        scheduleRevision = tostring(descriptor.scheduleRevision or ""),
        status = "queued",
        result = nil,
        job = nil,
    }

    state.runtimeRef = runtime
    state.planRecord = plan
    state.stepCapacity = stepCapacity
    runtime.planByStepKey[planId] = plan
    runtime.activePlanId = planId
    runtime.plannerStatus = "planning"

    local job = Tasks:EnqueueSliceable({
        label = ("Autopilot.Plan event=%s turn=%s tick=%s actor=%s"):format(
            tostring(state.eventId or ""),
            tostring(state.turnNumber or ""),
            tostring(state.tickNumber or ""),
            tostring(state.actorKey or "")
        ),
        scope = "autopilot:" .. tostring(state.eventId or ""),
        state = state,
        isStale = function(jobState)
            return Client:IsAutopilotPlanStateStale(jobState)
        end,
        step = function(jobState, deadlineMs)
            local jobPlan = jobState and jobState.planRecord or nil
            local jobRuntime = jobState and jobState.runtimeRef or nil
            if type(jobPlan) == "table" and jobPlan.status == "queued" then
                jobPlan.status = "planning"
            end
            if type(jobRuntime) == "table" and tostring(jobRuntime.activePlanId or "") == tostring(jobPlan and jobPlan.id or "") then
                jobRuntime.plannerStatus = "planning"
            end
            return Planner.Step(jobState, deadlineMs)
        end,
        onCancel = function(jobState, cancelReason)
            local jobPlan = jobState and jobState.planRecord or nil
            local jobRuntime = jobState and jobState.runtimeRef or nil
            markPlanCancelled(jobPlan, cancelReason)
            updateRuntimeAfterCancellation(jobRuntime, jobPlan, cancelReason)
            if type(Planner.ReleaseScratch) == "function" then
                Planner.ReleaseScratch(jobState)
            end
        end,
        onComplete = function(jobState)
            local jobPlan = jobState and jobState.planRecord or nil
            local jobRuntime = jobState and jobState.runtimeRef or nil
            local completedPlan = type(Planner.CopyCompletedPlan) == "function"
                and Planner.CopyCompletedPlan(jobState)
                or nil

            if type(jobPlan) == "table" and type(completedPlan) == "table" then
                jobPlan.result = completedPlan
                jobPlan.status = "ready"
                jobPlan.job = nil
            elseif type(jobPlan) == "table" then
                jobPlan.status = "failed"
                jobPlan.job = nil
            end

            if type(jobRuntime) == "table"
                and tostring(jobRuntime.activePlanId or "") == tostring(jobPlan and jobPlan.id or "")
            then
                if type(completedPlan) == "table" then
                    jobRuntime.plannerStatus = "ready"
                    jobRuntime.lastCompletedPlanId = tostring(jobState and jobState.planId or "")
                    jobRuntime.activePlanId = tostring(jobState and jobState.planId or "")
                else
                    jobRuntime.plannerStatus = "failed"
                end
            end

            if type(Planner.ReleaseScratch) == "function" then
                Planner.ReleaseScratch(jobState)
            end
        end,
    })

    plan.job = job
    return plan, true
end

function Client:ReplaceAutopilotPlanForCurrentStep(eventStateOverride)
    local eventState = eventStateOverride or Server.EventState
    local runtime, reason = getPlannerRuntime(eventState)
    if type(runtime) ~= "table" then
        return nil, false, reason
    end

    if type(Planner.ResolveActiveNpcStep) ~= "function"
        or type(Planner.BuildPlanIdentity) ~= "function"
    then
        return nil, false, "planner-api-unavailable"
    end

    local descriptor, descriptorReason = Planner.ResolveActiveNpcStep(eventState, getMaxEventUnits())
    if type(descriptor) ~= "table" then
        return nil, false, descriptorReason
    end

    local planId = Planner.BuildPlanIdentity(eventState, descriptor, descriptor.scheduleRevision)
    local existing = planId and runtime.planByStepKey[planId] or nil
    if type(existing) == "table" then
        if existing.job and type(Tasks.Cancel) == "function" then
            Tasks:Cancel(existing.job, "replan")
        else
            markPlanCancelled(existing, "replan")
        end
        runtime.planByStepKey[planId] = nil
        if runtime.activePlanId == planId then
            runtime.activePlanId = nil
        end
    end

    return self:EnsureAutopilotPlanForCurrentStep(eventState)
end

local function ensureAfterScheduleMutation(server)
    if advanceEventStepDepth > 0 then
        return
    end

    local eventState = server and server.EventState or nil
    if not isHostAutopilotEvent(eventState) then
        return
    end
    if not sameEventStep(Client.EventState, eventState) then
        return
    end

    Client:EnsureAutopilotPlanForCurrentStep(eventState)
end

local function wrapScheduleMutation(methodName)
    local baseMethod = Server[methodName]
    if type(baseMethod) ~= "function" then
        return false
    end

    Server[methodName] = function(self, ...)
        local results = pack(pcall(baseMethod, self, ...))
        if results[1] ~= true then
            error(results[2], 0)
        end
        ensureAfterScheduleMutation(self)
        return unpack(results, 2, results.n)
    end
    return true
end

local baseHandleEventState = Client.HandleEventState
if type(baseHandleEventState) == "function" then
    function Client:HandleEventState(arguments, ...)
        local results = pack(pcall(baseHandleEventState, self, arguments, ...))
        if results[1] ~= true then
            error(results[2], 0)
        end

        if results[2] == true
            and advanceEventStepDepth == 0
            and isHostAutopilotEvent(Server.EventState)
            and sameEventStep(self.EventState, Server.EventState)
        then
            self:EnsureAutopilotPlanForCurrentStep(Server.EventState)
        end
        return unpack(results, 2, results.n)
    end
end

local baseStartEvent = Server.StartEvent
if type(baseStartEvent) == "function" then
    function Server:StartEvent(...)
        local results = pack(pcall(baseStartEvent, self, ...))
        if results[1] ~= true then
            error(results[2], 0)
        end

        local eventState = results[2]
        if isHostAutopilotEvent(eventState) then
            Client:EnsureAutopilotPlanForCurrentStep(eventState)
        end
        return unpack(results, 2, results.n)
    end
end

local baseAdvanceEventStepAfterCommit = Server._AdvanceEventStepAfterCommit
if type(baseAdvanceEventStepAfterCommit) == "function" then
    function Server:_AdvanceEventStepAfterCommit(commit, completed, ...)
        local sourceState = self.EventState
        local sourceEventId = getEventId(sourceState)
        local sourceTurn = tonumber(type(sourceState) == "table" and sourceState.turnNumber or nil)
        local sourceTick = tonumber(type(sourceState) == "table" and sourceState.tickNumber or nil)

        advanceEventStepDepth = advanceEventStepDepth + 1
        local results = pack(pcall(baseAdvanceEventStepAfterCommit, self, commit, completed, ...))
        advanceEventStepDepth = math.max(0, advanceEventStepDepth - 1)

        if results[1] ~= true then
            error(results[2], 0)
        end

        local nextState = self.EventState
        local changedStep = results[2] == true and type(nextState) == "table"
            and (getEventId(nextState) ~= sourceEventId
                or tonumber(nextState.turnNumber) ~= sourceTurn
                or tonumber(nextState.tickNumber) ~= sourceTick)

        if changedStep and sourceEventId ~= "" then
            Client:ResetAutopilotBatchState(sourceEventId, "step-advanced")
        end

        if changedStep
            and isHostAutopilotEvent(nextState)
            and sameEventStep(Client.EventState, nextState)
        then
            Client:EnsureAutopilotPlanForCurrentStep(nextState)
        end
        return unpack(results, 2, results.n)
    end
end

local baseEndEvent = Server.EndEvent
if type(baseEndEvent) == "function" then
    function Server:EndEvent(...)
        local eventId = getEventId(self.EventState)
        local results = pack(pcall(baseEndEvent, self, ...))
        if results[1] ~= true then
            error(results[2], 0)
        end

        if eventId ~= "" then
            Client:CancelAutopilotPlannerScope(eventId, "event-ended")
        end
        return unpack(results, 2, results.n)
    end
end

local scheduleMutationMethods = {
    "ReconcileClientEventSession",
    "AddEventNpcUnit",
    "SummonEventPetUnit",
    "SetEventUnitActive",
    "SetEventUnitRaidMarker",
    "ClearEventNpcUnits",
}

for index = 1, #scheduleMutationMethods do
    wrapScheduleMutation(scheduleMutationMethods[index])
end

return Client
