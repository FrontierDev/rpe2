local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Server = Addon.Server or {}
Addon.Internal = Addon.Internal or {}

local Client = Addon.Client
local Server = Addon.Server
local Tasks = Addon.Internal.Tasks or {}
local Debug = Addon.Debug or {}

Client.AutopilotAuthorization = Client.AutopilotAuthorization or {}
local Authorization = Client.AutopilotAuthorization

local authorizePendingAction = Client.AuthorizeAutopilotPendingAction
local baseAuthorizeAllPendingActions = Client.AuthorizeAllAutopilotPendingActions

if type(authorizePendingAction) ~= "function" or type(baseAuthorizeAllPendingActions) ~= "function" then
    return Authorization
end

Authorization.ActiveAuthorizeAllBatches = Authorization.ActiveAuthorizeAllBatches or {}

local function nowMilliseconds()
    if type(debugprofilestop) == "function" then
        return tonumber(debugprofilestop()) or 0
    end
    if type(GetTimePreciseSec) == "function" then
        return (tonumber(GetTimePreciseSec()) or 0) * 1000
    end
    if type(GetTime) == "function" then
        return (tonumber(GetTime()) or 0) * 1000
    end
    return 0
end

local function getAction(plan, actionId)
    if type(plan) ~= "table" then
        return nil
    end
    local key = tostring(actionId or "")
    return key ~= "" and type(plan.actionsById) == "table" and plan.actionsById[key] or nil
end

local function getCurrentEventState()
    if type(Server.EventState) == "table" then
        return Server.EventState
    end
    if type(Client.GetEventState) == "function" then
        return Client:GetEventState()
    end
    return Client.EventState
end

local function getRuntime(plan)
    local eventId = tostring(type(plan) == "table" and plan.eventId or "")
    return eventId ~= ""
        and type(Client.AutopilotRuntimeByEventId) == "table"
        and Client.AutopilotRuntimeByEventId[eventId]
        or nil
end

local function appendUnique(values, seen, value)
    local key = tostring(value or "")
    if key ~= "" and seen[key] ~= true then
        seen[key] = true
        values[#values + 1] = key
    end
end

local function notifyHelperRefresh()
    if type(Client.QueueAutopilotDMHelperRefresh) == "function" then
        Client:QueueAutopilotDMHelperRefresh()
    end
end

local function resolveBatchStaleReason(state)
    local eventState = getCurrentEventState()
    if type(eventState) ~= "table" or eventState.active ~= true then
        return "event-inactive"
    end
    if tostring(eventState.id or "") ~= tostring(state.eventId or "") then
        return "event-changed"
    end
    if tonumber(eventState.turnNumber) ~= tonumber(state.turnNumber) then
        return "turn-changed"
    end
    if tonumber(eventState.tickNumber) ~= tonumber(state.tickNumber) then
        return "tick-changed"
    end

    local runtime = getRuntime(state.plan)
    if type(runtime) ~= "table" then
        return "runtime-unavailable"
    end
    if runtime.status ~= "ready" then
        return tostring(runtime.unavailableReason or "runtime-unavailable")
    end
    if type(runtime.authorizationByPlanId) ~= "table"
        or runtime.authorizationByPlanId[state.planId] ~= state.plan
        or tostring(runtime.activeAuthorizationPlanId or "") ~= tostring(state.planId or "")
    then
        return "replaced-plan"
    end
    if tostring(runtime.currentPlannerActorKey or "") ~= ""
        and tostring(runtime.currentPlannerActorKey or "") ~= tostring(state.actorKey or "")
    then
        return "actor-changed"
    end
    if tostring(runtime.currentPlannerScheduleRevision or "") ~= ""
        and tostring(runtime.currentPlannerScheduleRevision or "") ~= tostring(state.scheduleRevision or "")
    then
        return "schedule-changed"
    end
    return nil
end

local function logBatch(state)
    if type(Debug.Internal) ~= "function" then
        return false
    end
    local wallMs = math.max(0, nowMilliseconds() - (tonumber(state.startedAtMs) or 0))
    local maxSliceMs = math.max(0, tonumber(state.maxSliceMs) or 0)
    return Debug.Internal(
        "%sAutopilot authorize all complete event=%s turn=%d tick=%d actions=%d authorized=%d slices=%d yields=%d maxSlice=%.2fms wall=%.2fms outcome=%s reason=%s",
        maxSliceMs >= 8 and "SLOW " or "",
        tostring(state.eventId or ""),
        tonumber(state.turnNumber) or 0,
        tonumber(state.tickNumber) or 0,
        tonumber(state.attemptCount) or 0,
        #(state.authorized or {}),
        tonumber(state.sliceCount) or 0,
        tonumber(state.yieldCount) or 0,
        maxSliceMs,
        wallMs,
        tostring(state.outcome or "completed"),
        tostring(state.reason or "")
    ) == true
end

local function finishBatch(state, outcome, reason)
    if type(state) ~= "table" or state.finished == true then
        return false
    end
    state.finished = true
    state.outcome = tostring(outcome or state.outcome or "completed")
    state.reason = reason or state.reason

    local plan = state.plan
    if type(plan) == "table" then
        plan.authorizeAllInProgress = false
        if type(Authorization.RefreshPlanDependencies) == "function" then
            Authorization.RefreshPlanDependencies(plan)
        end
    end
    if Authorization.ActiveAuthorizeAllBatches[state.planId] == state then
        Authorization.ActiveAuthorizeAllBatches[state.planId] = nil
    end

    notifyHelperRefresh()
    logBatch(state)
    return true
end

local function probeBlockedBatchContext(state)
    if state.attemptCount ~= 0 or state.contextProbed == true then
        return true
    end
    state.contextProbed = true
    local eventState = getCurrentEventState()
    local ok, _, reason = baseAuthorizeAllPendingActions(state.client, eventState)
    if ok ~= true then
        state.outcome = "failed"
        state.reason = reason
        return false
    end
    return true
end

local function runBatchSlice(state, deadlineMs)
    local staleReason = resolveBatchStaleReason(state)
    if staleReason then
        state.outcome = "cancelled"
        state.reason = staleReason
        return true
    end

    local plan = state.plan
    if type(Authorization.RefreshPlanDependencies) == "function" then
        Authorization.RefreshPlanDependencies(plan)
    end
    if plan.sequenceInvariantValid == false then
        state.outcome = "failed"
        state.reason = "sequence-invariant-invalid"
        return true
    end

    while true do
        if state.transitionCount >= state.transitionLimit or state.attemptCount >= state.transitionLimit then
            return true
        end

        if state.cursor > #(plan.orderedActionIds or {}) then
            if state.passMadeProgress == true then
                state.cursor = 1
                state.passMadeProgress = false
                if type(Tasks.ShouldYield) == "function" and Tasks:ShouldYield(deadlineMs) == true then
                    return false
                end
            else
                probeBlockedBatchContext(state)
                return true
            end
        else
            local actionId = tostring(plan.orderedActionIds[state.cursor] or "")
            state.cursor = state.cursor + 1
            local action = getAction(plan, actionId)

            if type(action) == "table"
                and action.actionType == "spell"
                and action.canAuthorize == true
                and action.status == "pending"
                and actionId ~= ""
                and state.attempted[actionId] ~= true
            then
                state.attempted[actionId] = true
                state.attemptCount = state.attemptCount + 1
                local beforeStatus = tostring(action.status or "")
                local eventState = getCurrentEventState()
                local ok, attemptedAction, reason = authorizePendingAction(state.client, actionId, eventState)
                if type(attemptedAction) ~= "table" then
                    state.outcome = "failed"
                    state.reason = reason
                    return true
                end

                local afterStatus = tostring(attemptedAction.status or "")
                if afterStatus ~= beforeStatus then
                    state.transitionCount = state.transitionCount + 1
                    state.passMadeProgress = true
                end
                if ok == true then
                    appendUnique(state.authorized, state.authorizedSet, attemptedAction.actionId)
                end

                -- One canonical spell execution per slice keeps bulk authorization
                -- bounded even when the normal spell-start path is relatively heavy.
                notifyHelperRefresh()
                return false
            end

            if type(Tasks.ShouldYield) == "function" and Tasks:ShouldYield(deadlineMs) == true then
                return false
            end
        end
    end
end

function Authorization.IsAuthorizeAllBatchActive(plan)
    if type(plan) ~= "table" then
        return false
    end
    local state = Authorization.ActiveAuthorizeAllBatches[tostring(plan.planId or "")]
    return type(state) == "table" and state.finished ~= true
end

function Client:AuthorizeAllAutopilotPendingActions(eventStateOverride)
    local plan = type(self.GetAutopilotPendingPlan) == "function"
        and select(1, self:GetAutopilotPendingPlan(eventStateOverride))
        or nil
    if type(plan) ~= "table" then
        return baseAuthorizeAllPendingActions(self, eventStateOverride)
    end

    if type(Authorization.RefreshPlanDependencies) == "function" then
        Authorization.RefreshPlanDependencies(plan)
    end
    if plan.sequenceInvariantValid == false then
        return false, {}, "sequence-invariant-invalid"
    end
    if type(Tasks.EnqueueSliceable) ~= "function" then
        return false, {}, "task-queue-unavailable"
    end

    local planId = tostring(plan.planId or "")
    local existing = Authorization.ActiveAuthorizeAllBatches[planId]
    if type(existing) == "table" and existing.finished ~= true then
        return true, existing.authorized, "already-running", existing.job
    end

    local state = {
        client = self,
        plan = plan,
        planId = planId,
        eventId = tostring(plan.eventId or ""),
        turnNumber = math.max(0, math.floor(tonumber(plan.turnNumber) or 0)),
        tickNumber = math.max(0, math.floor(tonumber(plan.tickNumber) or 0)),
        actorKey = tostring(plan.actorKey or ""),
        scheduleRevision = tostring(plan.scheduleRevision or ""),
        cursor = 1,
        passMadeProgress = false,
        attempted = {},
        authorized = {},
        authorizedSet = {},
        attemptCount = 0,
        transitionCount = 0,
        transitionLimit = #(plan.orderedActionIds or {}),
        contextProbed = false,
        sliceCount = 0,
        yieldCount = 0,
        maxSliceMs = 0,
        startedAtMs = nowMilliseconds(),
        outcome = "completed",
        reason = nil,
        finished = false,
        staleReason = nil,
        job = nil,
    }

    plan.authorizeAllInProgress = true
    Authorization.ActiveAuthorizeAllBatches[planId] = state

    local job = Tasks:EnqueueSliceable({
        label = ("Autopilot.AuthorizeAll event=%s turn=%s tick=%s actor=%s"):format(
            state.eventId,
            tostring(state.turnNumber),
            tostring(state.tickNumber),
            state.actorKey
        ),
        scope = "autopilot-authorize:" .. state.eventId,
        state = state,
        isStale = function(batchState)
            local reason = resolveBatchStaleReason(batchState)
            batchState.staleReason = reason
            return reason ~= nil
        end,
        step = function(batchState, deadlineMs)
            local startedAt = nowMilliseconds()
            batchState.sliceCount = batchState.sliceCount + 1
            local complete = runBatchSlice(batchState, deadlineMs) == true
            local elapsed = math.max(0, nowMilliseconds() - startedAt)
            batchState.maxSliceMs = math.max(batchState.maxSliceMs, elapsed)
            if not complete then
                batchState.yieldCount = batchState.yieldCount + 1
            end
            return complete
        end,
        onCancel = function(batchState, reason)
            finishBatch(batchState, "cancelled", batchState.staleReason or reason)
        end,
        onComplete = function(batchState)
            finishBatch(batchState, batchState.outcome, batchState.reason)
        end,
    })

    state.job = job
    notifyHelperRefresh()
    return true, state.authorized, "queued", job
end

-- The generic runtime timing wrapper measures only the enqueue call now that
-- Authorise All is asynchronous. The batch owns the meaningful end-to-end
-- diagnostic above, so prevent installation of the obsolete synchronous hook.
local Timings = Debug.Timings
if type(Timings) == "table" and type(Timings.RuntimeHooks) == "table" then
    Timings.RuntimeHooks["Client.AuthorizeAllAutopilotPendingActionsProcess"] = true
end

return Authorization
