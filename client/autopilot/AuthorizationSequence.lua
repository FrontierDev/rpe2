local _, Addon = ...

Addon.Client = Addon.Client or {}
local Client = Addon.Client

Client.AutopilotAuthorization = Client.AutopilotAuthorization or {}
local Authorization = Client.AutopilotAuthorization

local basePublishPendingPlan = Client.PublishAutopilotPendingPlan
local baseAuthorizePendingAction = Client.AuthorizeAutopilotPendingAction
local baseAuthorizeAllPendingActions = Client.AuthorizeAllAutopilotPendingActions
local baseRejectPendingAction = Client.RejectAutopilotPendingAction
local baseConfirmPendingMovement = Client.ConfirmAutopilotPendingMovement
local baseSkipPendingMovement = Client.SkipAutopilotPendingMovement

local RESOLVED_PREDECESSOR = {
    completed = true,
    rejected = true,
}

local FAILED_PREDECESSOR_REASON = {
    stale = "previous-caster-action-stale",
    failed = "previous-caster-action-failed",
}

local UNRESOLVED_PREDECESSOR = {
    pending = true,
    blocked = true,
    authorized = true,
    executing = true,
}

local NON_REOPENABLE_SPELL_STATUS = {
    authorized = true,
    executing = true,
    completed = true,
    rejected = true,
    stale = true,
    failed = true,
}

local function normalizeEventId(value)
    local eventId = math.floor(tonumber(value) or 0)
    return eventId > 0 and eventId or 0
end

local function normalizeSequenceInteger(value)
    local numeric = tonumber(value)
    if numeric == nil or numeric < 1 or numeric ~= math.floor(numeric) then
        return nil
    end
    return numeric
end

local function getAction(plan, actionId)
    if type(plan) ~= "table" then
        return nil
    end
    local key = tostring(actionId or "")
    return key ~= "" and type(plan.actionsById) == "table" and plan.actionsById[key] or nil
end

local function notifyHelperRefresh()
    if type(Client.QueueAutopilotDMHelperRefresh) == "function" then
        Client:QueueAutopilotDMHelperRefresh()
    end
end

local function getRuntimeForPlan(plan, runtimeOverride)
    if type(runtimeOverride) == "table" then
        return runtimeOverride
    end
    local eventId = tostring(type(plan) == "table" and plan.eventId or "")
    return eventId ~= ""
        and type(Client.AutopilotRuntimeByEventId) == "table"
        and Client.AutopilotRuntimeByEventId[eventId]
        or nil
end

local function validateUniqueActionIds(completedPlan)
    local seen = {}
    local collections = {
        completedPlan and completedPlan.movements or {},
        completedPlan and completedPlan.actions or {},
    }
    for collectionIndex = 1, #collections do
        local collection = collections[collectionIndex]
        for index = 1, #collection do
            local actionId = tostring(collection[index] and collection[index].actionId or "")
            if actionId == "" or seen[actionId] == true then
                return false
            end
            seen[actionId] = true
        end
    end
    return true
end

function Authorization.ValidateCompletedPlanSequences(completedPlan)
    if type(completedPlan) ~= "table" then
        return false, "sequence-invariant-invalid"
    end
    if not validateUniqueActionIds(completedPlan) then
        return false, "sequence-invariant-invalid"
    end

    local groups = {}
    for index = 1, #(completedPlan.actions or {}) do
        local action = completedPlan.actions[index]
        local casterEventId = normalizeEventId(action and action.casterEventId)
        local sequenceIndex = normalizeSequenceInteger(action and action.casterSequenceIndex)
        local sequenceCount = normalizeSequenceInteger(action and action.casterSequenceCount)
        if casterEventId <= 0 or sequenceIndex == nil or sequenceCount == nil or sequenceIndex > sequenceCount then
            return false, "sequence-invariant-invalid"
        end

        local group = groups[casterEventId]
        if type(group) ~= "table" then
            group = {
                count = sequenceCount,
                byIndex = {},
                size = 0,
            }
            groups[casterEventId] = group
        elseif group.count ~= sequenceCount then
            return false, "sequence-invariant-invalid"
        end

        if group.byIndex[sequenceIndex] ~= nil then
            return false, "sequence-invariant-invalid"
        end
        group.byIndex[sequenceIndex] = action
        group.size = group.size + 1
    end

    for _, group in pairs(groups) do
        if group.size ~= group.count then
            return false, "sequence-invariant-invalid"
        end
        local terminalSeen = false
        for sequenceIndex = 1, group.count do
            local action = group.byIndex[sequenceIndex]
            if type(action) ~= "table" then
                return false, "sequence-invariant-invalid"
            end
            if terminalSeen then
                return false, "sequence-invariant-invalid"
            end

            local previousActionId = tostring(action.previousCasterActionId or "")
            if sequenceIndex == 1 then
                if previousActionId ~= "" then
                    return false, "sequence-invariant-invalid"
                end
            else
                local expectedPrevious = group.byIndex[sequenceIndex - 1]
                if type(expectedPrevious) ~= "table"
                    or previousActionId ~= tostring(expectedPrevious.actionId or "")
                then
                    return false, "sequence-invariant-invalid"
                end
            end

            if tostring(action.actionEconomyClass or "") == "terminal" then
                terminalSeen = true
                if sequenceIndex ~= group.count then
                    return false, "sequence-invariant-invalid"
                end
            end
        end
    end

    return true
end

local function buildRuntimeSequenceGroups(plan)
    local groups = {}
    local seenActionIds = {}
    for index = 1, #(type(plan) == "table" and plan.spellActionIds or {}) do
        local actionId = tostring(plan.spellActionIds[index] or "")
        if actionId == "" or seenActionIds[actionId] == true then
            return nil
        end
        seenActionIds[actionId] = true

        local action = getAction(plan, actionId)
        if type(action) ~= "table" or action.actionType ~= "spell" or tostring(action.actionId or "") ~= actionId then
            return nil
        end
        local casterEventId = normalizeEventId(action.casterEventId)
        local sequenceIndex = normalizeSequenceInteger(action.casterSequenceIndex)
        local sequenceCount = normalizeSequenceInteger(action.casterSequenceCount)
        if casterEventId <= 0 or sequenceIndex == nil or sequenceCount == nil or sequenceIndex > sequenceCount then
            return nil
        end
        local group = groups[casterEventId]
        if type(group) ~= "table" then
            group = { count = sequenceCount, byIndex = {}, size = 0 }
            groups[casterEventId] = group
        elseif group.count ~= sequenceCount then
            return nil
        end
        if group.byIndex[sequenceIndex] ~= nil then
            return nil
        end
        group.byIndex[sequenceIndex] = action
        group.size = group.size + 1
    end

    for _, group in pairs(groups) do
        if group.size ~= group.count then
            return nil
        end
        local terminalSeen = false
        for sequenceIndex = 1, group.count do
            local action = group.byIndex[sequenceIndex]
            if type(action) ~= "table" or terminalSeen then
                return nil
            end
            local previousActionId = tostring(action.previousCasterActionId or "")
            if sequenceIndex == 1 then
                if previousActionId ~= "" then
                    return nil
                end
            else
                local expectedPrevious = group.byIndex[sequenceIndex - 1]
                if type(expectedPrevious) ~= "table" or previousActionId ~= tostring(expectedPrevious.actionId or "") then
                    return nil
                end
            end
            if tostring(action.actionEconomyClass or "") == "terminal" then
                terminalSeen = true
                if sequenceIndex ~= group.count then
                    return nil
                end
            end
        end
    end
    return groups
end

local function resolveSequenceDependency(group, sequenceIndex)
    if type(group) ~= "table" or sequenceIndex <= 1 then
        return nil
    end

    -- Terminal predecessor failures stop the caster even if an earlier action is
    -- still unresolved. This prevents a nearer blocked/pending action from
    -- masking the failure that actually makes continuation impossible.
    for previousIndex = 1, sequenceIndex - 1 do
        local previous = group.byIndex[previousIndex]
        if type(previous) ~= "table" then
            return "sequence-invariant-invalid"
        end
        local failureReason = FAILED_PREDECESSOR_REASON[tostring(previous.status or "")]
        if failureReason then
            return failureReason
        end
    end

    for previousIndex = 1, sequenceIndex - 1 do
        local previous = group.byIndex[previousIndex]
        local status = tostring(previous.status or "")
        if RESOLVED_PREDECESSOR[status] ~= true then
            if UNRESOLVED_PREDECESSOR[status] == true then
                return "previous-caster-action-pending"
            end
            return "previous-caster-action-pending"
        end
    end
    return nil
end

local function resolveMovementDependency(plan, action)
    local movementActionId = tostring(type(action) == "table" and action.requiresMovementActionId or "")
    if movementActionId == "" then
        return nil
    end
    local movement = getAction(plan, movementActionId)
    if type(movement) ~= "table" or movement.actionType ~= "movement" then
        return "movement-stale"
    end
    local status = tostring(movement.status or "")
    if status == "confirmed" then
        return nil
    end
    if status == "pending" then
        return "movement-pending"
    end
    return "movement-stale"
end

local function compatibilityReason(sequenceReason, movementReason)
    if sequenceReason then
        return sequenceReason
    end
    if movementReason == "movement-pending" then
        return "movement-pending"
    end
    if movementReason == "movement-stale" then
        return "movement-stale"
    end
    return nil
end

function Authorization.RefreshPlanDependencies(plan)
    if type(plan) ~= "table" then
        return false
    end

    local groups = buildRuntimeSequenceGroups(plan)
    if plan.sequenceInvariantValid == false or type(groups) ~= "table" then
        plan.sequenceInvariantValid = false
        plan.sequenceInvariantReason = "sequence-invariant-invalid"
        plan.status = "blocked"
        plan.reason = "sequence-invariant-invalid"
        for index = 1, #(plan.spellActionIds or {}) do
            local action = getAction(plan, plan.spellActionIds[index])
            if type(action) == "table" then
                action.dependencyReasons = {
                    sequence = "sequence-invariant-invalid",
                    movement = resolveMovementDependency(plan, action),
                }
                action.canAuthorize = false
                local status = tostring(action.status or "")
                if status == "pending" or status == "blocked" then
                    action.status = "blocked"
                    action.reason = "sequence-invariant-invalid"
                elseif status == "authorized" or status == "executing" then
                    action.status = "stale"
                    action.reason = "sequence-invariant-invalid"
                end
            end
        end
        return false
    end

    local changed = false
    for _, group in pairs(groups) do
        for sequenceIndex = 1, group.count do
            local action = group.byIndex[sequenceIndex]
            if type(action) == "table" then
                local sequenceReason = resolveSequenceDependency(group, sequenceIndex)
                local movementReason = resolveMovementDependency(plan, action)
                local previousCanAuthorize = action.canAuthorize == true
                local previousStatus = tostring(action.status or "")
                local previousReason = action.reason

                action.dependencyReasons = {
                    sequence = sequenceReason,
                    movement = movementReason,
                }

                if NON_REOPENABLE_SPELL_STATUS[previousStatus] == true then
                    action.canAuthorize = false
                else
                    local ready = sequenceReason == nil and movementReason == nil
                    action.canAuthorize = ready
                    if ready then
                        action.status = "pending"
                        action.reason = nil
                    else
                        action.status = "blocked"
                        action.reason = compatibilityReason(sequenceReason, movementReason)
                    end
                end

                if previousCanAuthorize ~= (action.canAuthorize == true)
                    or previousStatus ~= tostring(action.status or "")
                    or previousReason ~= action.reason
                then
                    changed = true
                end
            end
        end
    end

    return changed
end

local function markInvalidPendingPlan(pending, runtime)
    if type(pending) ~= "table" then
        return
    end
    pending.sequenceInvariantValid = false
    pending.sequenceInvariantReason = "sequence-invariant-invalid"
    pending.status = "blocked"
    pending.reason = "sequence-invariant-invalid"
    Authorization.RefreshPlanDependencies(pending)
    if type(runtime) == "table" then
        runtime.authorizationStatus = "stale"
    end
end

if type(basePublishPendingPlan) == "function" then
    function Client:PublishAutopilotPendingPlan(completedPlan, runtimeOverride)
        local sequenceValid, sequenceReason = Authorization.ValidateCompletedPlanSequences(completedPlan)
        local pending, created, reason = basePublishPendingPlan(self, completedPlan, runtimeOverride)
        if type(pending) ~= "table" then
            return pending, created, reason
        end

        local runtime = getRuntimeForPlan(pending, runtimeOverride)
        if sequenceValid ~= true then
            markInvalidPendingPlan(pending, runtime)
            notifyHelperRefresh()
            return pending, created, sequenceReason or "sequence-invariant-invalid"
        end

        pending.sequenceInvariantValid = true
        pending.sequenceInvariantReason = nil
        Authorization.RefreshPlanDependencies(pending)
        notifyHelperRefresh()
        return pending, created, reason
    end
end

local function actionDependencyReason(action)
    if type(action) ~= "table" then
        return "pending-action-unavailable"
    end
    local reasons = type(action.dependencyReasons) == "table" and action.dependencyReasons or {}
    return reasons.sequence or reasons.movement or "action-not-pending"
end

if type(baseAuthorizePendingAction) == "function" then
    function Client:AuthorizeAutopilotPendingAction(actionId, eventStateOverride)
        local plan = type(self.GetAutopilotPendingPlan) == "function"
            and select(1, self:GetAutopilotPendingPlan(eventStateOverride))
            or nil
        if type(plan) == "table" then
            Authorization.RefreshPlanDependencies(plan)
            local action = getAction(plan, actionId)
            if type(action) == "table" and action.actionType == "spell" then
                if plan.sequenceInvariantValid == false or action.canAuthorize ~= true then
                    -- Probe the existing API while the action is non-pending so
                    -- its current event/turn/actor/schedule checks still run,
                    -- without creating any possibility of execution.
                    local probeOk, _, probeReason = baseAuthorizePendingAction(self, actionId, eventStateOverride)
                    if probeOk ~= true and probeReason ~= "action-not-pending" then
                        Authorization.RefreshPlanDependencies(plan)
                        notifyHelperRefresh()
                        return false, action, probeReason
                    end
                    if plan.sequenceInvariantValid == false then
                        return false, action, "sequence-invariant-invalid"
                    end
                    return false, action, actionDependencyReason(action)
                end
            end
        end

        local ok, action, reason = baseAuthorizePendingAction(self, actionId, eventStateOverride)
        if type(plan) ~= "table" and type(self.GetAutopilotPendingPlan) == "function" then
            plan = select(1, self:GetAutopilotPendingPlan(eventStateOverride))
        end
        if type(plan) == "table" then
            Authorization.RefreshPlanDependencies(plan)
        end
        notifyHelperRefresh()
        return ok, action, reason
    end
end

if type(baseRejectPendingAction) == "function" then
    function Client:RejectAutopilotPendingAction(actionId, eventStateOverride)
        local ok, action, reason = baseRejectPendingAction(self, actionId, eventStateOverride)
        local plan = type(self.GetAutopilotPendingPlan) == "function"
            and select(1, self:GetAutopilotPendingPlan(eventStateOverride))
            or nil
        if type(plan) == "table" then
            Authorization.RefreshPlanDependencies(plan)
        end
        notifyHelperRefresh()
        return ok, action, reason
    end
end

if type(baseConfirmPendingMovement) == "function" then
    function Client:ConfirmAutopilotPendingMovement(actionId, eventStateOverride)
        local ok, action, reason = baseConfirmPendingMovement(self, actionId, eventStateOverride)
        local plan = type(self.GetAutopilotPendingPlan) == "function"
            and select(1, self:GetAutopilotPendingPlan(eventStateOverride))
            or nil
        if type(plan) == "table" then
            Authorization.RefreshPlanDependencies(plan)
        end
        notifyHelperRefresh()
        return ok, action, reason
    end
end

if type(baseSkipPendingMovement) == "function" then
    function Client:SkipAutopilotPendingMovement(actionId, eventStateOverride)
        local ok, action, reason = baseSkipPendingMovement(self, actionId, eventStateOverride)
        local plan = type(self.GetAutopilotPendingPlan) == "function"
            and select(1, self:GetAutopilotPendingPlan(eventStateOverride))
            or nil
        if type(plan) == "table" then
            Authorization.RefreshPlanDependencies(plan)
        end
        notifyHelperRefresh()
        return ok, action, reason
    end
end

local function appendUnique(values, seen, value)
    local key = tostring(value or "")
    if key ~= "" and seen[key] ~= true then
        seen[key] = true
        values[#values + 1] = key
    end
end

if type(baseAuthorizeAllPendingActions) == "function" then
    function Client:AuthorizeAllAutopilotPendingActions(eventStateOverride)
        local plan = type(self.GetAutopilotPendingPlan) == "function"
            and select(1, self:GetAutopilotPendingPlan(eventStateOverride))
            or nil
        if type(plan) ~= "table" then
            return baseAuthorizeAllPendingActions(self, eventStateOverride)
        end
        Authorization.RefreshPlanDependencies(plan)
        if plan.sequenceInvariantValid == false then
            return false, {}, "sequence-invariant-invalid"
        end

        local authorized = {}
        local authorizedSet = {}
        local attempted = {}
        local attemptCount = 0
        local transitionCount = 0
        local transitionLimit = #(plan.orderedActionIds or {})
        local madeProgress = true

        while madeProgress and transitionCount < transitionLimit and attemptCount < transitionLimit do
            madeProgress = false
            for index = 1, #(plan.orderedActionIds or {}) do
                if transitionCount >= transitionLimit or attemptCount >= transitionLimit then
                    break
                end
                local action = getAction(plan, plan.orderedActionIds[index])
                local actionId = tostring(type(action) == "table" and action.actionId or "")
                if type(action) == "table"
                    and action.actionType == "spell"
                    and action.canAuthorize == true
                    and action.status == "pending"
                    and actionId ~= ""
                    and attempted[actionId] ~= true
                then
                    attempted[actionId] = true
                    attemptCount = attemptCount + 1
                    local beforeStatus = action.status
                    local ok, attemptedAction, reason = self:AuthorizeAutopilotPendingAction(actionId, eventStateOverride)
                    if type(attemptedAction) ~= "table" then
                        return false, authorized, reason
                    end
                    Authorization.RefreshPlanDependencies(plan)
                    local afterStatus = tostring(attemptedAction.status or "")
                    if afterStatus ~= tostring(beforeStatus or "") then
                        transitionCount = transitionCount + 1
                        madeProgress = true
                    end
                    if ok == true then
                        appendUnique(authorized, authorizedSet, attemptedAction.actionId)
                    end
                end
            end
        end

        -- Preserve the old API's context-validation behavior when every spell is
        -- externally blocked (most commonly pending marker movement). The base
        -- pass cannot authorize a blocked action, and it never confirms movement.
        if attemptCount == 0 then
            local ok, _, reason = baseAuthorizeAllPendingActions(self, eventStateOverride)
            if ok ~= true then
                return false, authorized, reason
            end
        end

        Authorization.RefreshPlanDependencies(plan)
        notifyHelperRefresh()
        return true, authorized
    end
end

return Authorization
