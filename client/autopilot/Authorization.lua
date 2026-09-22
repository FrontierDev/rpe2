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
local Spatial = Client.AutopilotSpatial or {}
local Planner = Client.AutopilotPlanner or {}

Client.AutopilotAuthorization = Client.AutopilotAuthorization or {}
local Authorization = Client.AutopilotAuthorization

if type(Event) ~= "table" or type(Spatial) ~= "table" or type(Planner) ~= "table" then
    return
end

Authorization.SpellStatuses = Authorization.SpellStatuses or {
    pending = true,
    authorized = true,
    executing = true,
    completed = true,
    rejected = true,
    blocked = true,
    stale = true,
    failed = true,
}
Authorization.MovementStatuses = Authorization.MovementStatuses or {
    pending = true,
    confirmed = true,
    skipped = true,
    blocked = true,
    stale = true,
}

local EPSILON = 0.0001

local function pack(...)
    return { n = select("#", ...), ... }
end

local function normalizeEventId(value)
    local eventId = math.floor(tonumber(value) or 0)
    return eventId > 0 and eventId or 0
end

local function normalizeRaidMarker(value)
    return math.max(0, math.floor(tonumber(value) or 0))
end

local function copyArray(values)
    local copied = {}
    for index = 1, #(values or {}) do
        copied[index] = values[index]
    end
    return copied
end

local function copyMap(values)
    local copied = {}
    for key, value in pairs(type(values) == "table" and values or {}) do
        copied[key] = value
    end
    return copied
end

local function copyPosition(position)
    if type(Spatial.CopyPosition) == "function" then
        return Spatial.CopyPosition(position)
    end
    return type(position) == "table" and copyMap(position) or nil
end

local function copyTargetSelections(values)
    local copied = {}
    for key, targets in pairs(type(values) == "table" and values or {}) do
        copied[key] = copyArray(targets)
    end
    return copied
end

local function copyMovementDetails(details, fallbackAllowance)
    local source = type(details) == "table" and details or {}
    local reason = tostring(source.reason or "")
    local statRef = tostring(source.statRef or "")
    local baseStatFound = source.baseStatFound
    if baseStatFound == nil then
        baseStatFound = statRef ~= "" and reason ~= "movement-range-stat-missing"
    end
    local usedMissingStatFallback = source.usedMissingStatFallback == true
        or (baseStatFound ~= true and source.movementRangeOverride == nil)
    return {
        available = source.available ~= false,
        reason = source.reason,
        statRef = source.statRef,
        baseStatFound = baseStatFound == true,
        baseValue = source.baseValue,
        movementRangeOverride = source.movementRangeOverride,
        usedMissingStatFallback = usedMissingStatFallback,
        missingStatFallbackValue = source.missingStatFallbackValue or (usedMissingStatFallback and 30 or nil),
        effectiveValue = tonumber(source.effectiveValue) or tonumber(fallbackAllowance),
    }
end

local function copyMovementDetailsByMember(source)
    local copied = {}
    for eventId, details in pairs(type(source) == "table" and source or {}) do
        local normalizedId = normalizeEventId(eventId)
        if normalizedId > 0 and type(details) == "table" then
            copied[normalizedId] = copyMovementDetails(details, details.effectiveValue)
        end
    end
    return copied
end

local function findLimitingMemberEventIds(movementByMemberEventId, movementAllowance)
    local minimum = math.max(0, tonumber(movementAllowance) or 0)
    local ids = {}
    for eventId, details in pairs(type(movementByMemberEventId) == "table" and movementByMemberEventId or {}) do
        local normalizedId = normalizeEventId(eventId)
        local effectiveValue = type(details) == "table" and tonumber(details.effectiveValue) or nil
        if normalizedId > 0 and effectiveValue ~= nil and math.abs(math.max(0, effectiveValue) - minimum) <= EPSILON then
            ids[#ids + 1] = normalizedId
        end
    end
    table.sort(ids)
    return ids
end

local function normalizeTurnMode(value)
    if type(Event.NormalizeTurnMode) == "function" then
        return Event.NormalizeTurnMode(value)
    end
    return tostring(value or "") == "autopilot" and "autopilot" or "manual"
end

local function isHostAutopilotEvent(eventState)
    return type(eventState) == "table"
        and eventState.active == true
        and normalizeTurnMode(eventState.turnMode) == "autopilot"
        and type(Client.IsLocalEventHost) == "function"
        and Client:IsLocalEventHost(eventState) == true
end

local function resolveEventState(override)
    if type(override) == "table" then
        return override
    end
    if type(Server.EventState) == "table" then
        return Server.EventState
    end
    if type(Client.GetEventState) == "function" then
        return Client:GetEventState()
    end
    return Client.EventState
end

local function ensureRuntimeFields(runtime)
    if type(runtime) ~= "table" then
        return nil
    end
    runtime.authorizationByPlanId = type(runtime.authorizationByPlanId) == "table"
        and runtime.authorizationByPlanId
        or {}
    runtime.activeAuthorizationPlanId = runtime.activeAuthorizationPlanId
    runtime.authorizationStatus = tostring(runtime.authorizationStatus or "ready")
    return runtime
end

local function getRuntimeForEvent(eventState)
    if not isHostAutopilotEvent(eventState) then
        return nil, "not-host-autopilot"
    end
    local eventId = tostring(eventState.id or "")
    local runtime = eventId ~= ""
        and type(Client.AutopilotRuntimeByEventId) == "table"
        and Client.AutopilotRuntimeByEventId[eventId]
        or nil
    if type(runtime) ~= "table" then
        return nil, "runtime-unavailable"
    end
    return ensureRuntimeFields(runtime)
end

local function getAction(plan, actionId)
    if type(plan) ~= "table" then
        return nil
    end
    local key = tostring(actionId or "")
    return key ~= "" and type(plan.actionsById) == "table" and plan.actionsById[key] or nil
end

local function hasUnresolvedActions(plan)
    for index = 1, #(plan and plan.orderedActionIds or {}) do
        local action = getAction(plan, plan.orderedActionIds[index])
        local status = tostring(action and action.status or "")
        if action and action.actionType == "spell"
            and (status == "pending" or status == "blocked" or status == "authorized")
        then
            return true
        end
        if action and action.actionType == "movement"
            and (status == "pending" or status == "blocked")
        then
            return true
        end
    end
    return false
end

local function refreshAuthorizationStatus(runtime, plan)
    if type(runtime) ~= "table" then
        return
    end
    if type(plan) ~= "table" then
        runtime.authorizationStatus = "ready"
        return
    end
    if tostring(plan.status or "") == "stale" then
        runtime.authorizationStatus = "stale"
    elseif hasUnresolvedActions(plan) then
        runtime.authorizationStatus = "pending"
        runtime.plannerStatus = "awaiting-authorization"
    else
        runtime.authorizationStatus = "ready"
        if runtime.plannerStatus == "awaiting-authorization" then
            runtime.plannerStatus = "ready"
        end
    end
end

local function notifyHelperRefresh()
    if type(Client.QueueAutopilotDMHelperRefresh) == "function" then
        Client:QueueAutopilotDMHelperRefresh()
    end
end

local function expectedMarkerMembers(completedPlan, raidMarker)
    local expected = {}
    local marker = normalizeRaidMarker(raidMarker)
    for index = 1, #((completedPlan and completedPlan.snapshot and completedPlan.snapshot.members) or {}) do
        local member = completedPlan.snapshot.members[index]
        local eventId = normalizeEventId(member and member.eventID)
        if eventId > 0
            and member.active ~= false
            and normalizeRaidMarker(member.raidMarker) == marker
        then
            expected[#expected + 1] = eventId
        end
    end
    table.sort(expected)
    return expected
end

local function copyPendingMovement(source, completedPlan)
    local action = copyMap(source)
    action.actionType = "movement"
    action.actionId = tostring(source and source.actionId or "")
    action.planId = tostring(completedPlan and completedPlan.planId or "")
    action.eventId = tostring(completedPlan and completedPlan.eventId or "")
    action.turnNumber = math.max(0, math.floor(tonumber(completedPlan and completedPlan.turnNumber) or 0))
    action.tickNumber = math.max(0, math.floor(tonumber(completedPlan and completedPlan.tickNumber) or 0))
    action.actorKey = tostring(source and source.actorKey or "")
    action.raidMarker = normalizeRaidMarker(source and source.raidMarker)
    action.proposedPosition = copyPosition(source and source.proposedPosition)
    action.objectiveTargetEventIds = copyArray(source and source.objectiveTargetEventIds)
    action.expectedMemberEventIds = expectedMarkerMembers(completedPlan, action.raidMarker)
    action.movementAllowance = math.max(0, tonumber(source and source.movementAllowance) or 0)
    action.movementDistance = math.max(0, tonumber(source and source.movementDistance) or 0)
    action.plannedMovementAllowance = math.max(
        0,
        tonumber(source and source.plannedMovementAllowance) or action.movementAllowance
    )
    action.plannedMovementDistance = math.max(
        0,
        tonumber(source and source.plannedMovementDistance) or action.movementDistance
    )
    action.movementByMemberEventId = copyMovementDetailsByMember(source and source.movementByMemberEventId)
    action.limitingMemberEventIds = copyArray(source and source.limitingMemberEventIds)
    if #action.limitingMemberEventIds == 0 then
        action.limitingMemberEventIds = findLimitingMemberEventIds(
            action.movementByMemberEventId,
            action.plannedMovementAllowance
        )
    end
    action.plannedLimitingMemberEventIds = copyArray(
        source and source.plannedLimitingMemberEventIds or action.limitingMemberEventIds
    )
    action.status = "pending"
    action.reason = nil
    return action
end

local function copyPendingSpell(source, completedPlan, movementById)
    local action = copyMap(source)
    action.actionType = "spell"
    action.actionId = tostring(source and source.actionId or "")
    action.planId = tostring(completedPlan and completedPlan.planId or "")
    action.eventId = tostring(completedPlan and completedPlan.eventId or "")
    action.turnNumber = math.max(0, math.floor(tonumber(completedPlan and completedPlan.turnNumber) or 0))
    action.tickNumber = math.max(0, math.floor(tonumber(completedPlan and completedPlan.tickNumber) or 0))
    action.actorKey = tostring(source and source.actorKey or "")
    action.casterEventId = normalizeEventId(source and source.casterEventId)
    action.spellRef = tostring(source and source.spellRef or "")
    action.targetSelections = copyTargetSelections(source and source.targetSelections)
    action.targetSelectionOrder = copyArray(source and source.targetSelectionOrder)
    action.targetEventIds = copyArray(source and source.targetEventIds)
    action.requiresMovementActionId = source and source.requiresMovementActionId
        and tostring(source.requiresMovementActionId)
        or nil
    action.status = "pending"
    action.reason = nil
    if action.requiresMovementActionId then
        local movement = movementById[action.requiresMovementActionId]
        if type(movement) ~= "table" then
            action.status = "blocked"
            action.reason = "movement-missing"
        elseif movement.status ~= "confirmed" then
            action.status = "blocked"
            action.reason = "movement-pending"
        end
    end
    return action
end

local function markActionStale(action, reason)
    if type(action) ~= "table" then
        return false
    end
    local status = tostring(action.status or "")
    if action.actionType == "spell" then
        if status == "pending" or status == "blocked" or status == "authorized" then
            action.status = "stale"
            action.reason = tostring(reason or "stale")
            return true
        end
    elseif action.actionType == "movement" then
        if status == "pending" or status == "blocked" then
            action.status = "stale"
            action.reason = tostring(reason or "stale")
            return true
        end
    end
    return false
end

function Authorization.MarkPlanStale(plan, reason)
    if type(plan) ~= "table" then
        return false
    end
    local changed = false
    for index = 1, #(plan.orderedActionIds or {}) do
        changed = markActionStale(getAction(plan, plan.orderedActionIds[index]), reason) or changed
    end
    plan.status = "stale"
    plan.reason = tostring(reason or "stale")
    if type(Client.ClearAutopilotSpeechCuesForPlan) == "function" then
        Client:ClearAutopilotSpeechCuesForPlan(plan)
    end
    return changed
end

function Client:PublishAutopilotPendingPlan(completedPlan, runtimeOverride)
    if type(completedPlan) ~= "table" or tostring(completedPlan.status or "ready") ~= "ready" then
        return nil, false, "plan-not-ready"
    end
    local eventState = resolveEventState(nil)
    if not isHostAutopilotEvent(eventState)
        or tostring(eventState.id or "") ~= tostring(completedPlan.eventId or "")
    then
        return nil, false, "not-host-autopilot"
    end
    local runtime = type(runtimeOverride) == "table" and runtimeOverride or select(1, getRuntimeForEvent(eventState))
    if type(runtime) ~= "table" then
        return nil, false, "runtime-unavailable"
    end
    ensureRuntimeFields(runtime)

    local planId = tostring(completedPlan.planId or "")
    if planId == "" then
        return nil, false, "plan-id-unavailable"
    end
    local existing = runtime.authorizationByPlanId[planId]
    if type(existing) == "table" then
        runtime.activeAuthorizationPlanId = planId
        refreshAuthorizationStatus(runtime, existing)
        return existing, false
    end

    local previousId = tostring(runtime.activeAuthorizationPlanId or "")
    if previousId ~= "" and previousId ~= planId then
        local previous = runtime.authorizationByPlanId[previousId]
        if type(previous) == "table" then
            Authorization.MarkPlanStale(previous, "replaced-plan")
        end
    end

    local pending = {
        planId = planId,
        eventId = tostring(completedPlan.eventId or ""),
        turnNumber = math.max(0, math.floor(tonumber(completedPlan.turnNumber) or 0)),
        tickNumber = math.max(0, math.floor(tonumber(completedPlan.tickNumber) or 0)),
        actorKey = tostring(completedPlan.actorKey or ""),
        actorKeys = copyArray(completedPlan.actorKeys),
        scheduleRevision = tostring(completedPlan.scheduleRevision or ""),
        status = "pending",
        actionsById = {},
        orderedActionIds = {},
        movementActionIds = {},
        spellActionIds = {},
        noActions = {},
        warnings = {},
    }

    local movementById = {}
    for index = 1, #(completedPlan.movements or {}) do
        local movement = copyPendingMovement(completedPlan.movements[index], completedPlan)
        if movement.actionId ~= "" then
            movementById[movement.actionId] = movement
            pending.actionsById[movement.actionId] = movement
            pending.orderedActionIds[#pending.orderedActionIds + 1] = movement.actionId
            pending.movementActionIds[#pending.movementActionIds + 1] = movement.actionId
        end
    end
    for index = 1, #(completedPlan.actions or {}) do
        local spell = copyPendingSpell(completedPlan.actions[index], completedPlan, movementById)
        if spell.actionId ~= "" then
            pending.actionsById[spell.actionId] = spell
            pending.orderedActionIds[#pending.orderedActionIds + 1] = spell.actionId
            pending.spellActionIds[#pending.spellActionIds + 1] = spell.actionId
        end
    end
    for index = 1, #(completedPlan.noActions or {}) do
        pending.noActions[index] = copyMap(completedPlan.noActions[index])
    end
    for index = 1, #(completedPlan.warnings or {}) do
        pending.warnings[index] = copyMap(completedPlan.warnings[index])
    end

    runtime.authorizationByPlanId[planId] = pending
    runtime.activeAuthorizationPlanId = planId
    refreshAuthorizationStatus(runtime, pending)
    notifyHelperRefresh()
    return pending, true
end

function Client:GetAutopilotPendingPlan(eventStateOverride)
    local eventState = resolveEventState(eventStateOverride)
    local runtime, reason = getRuntimeForEvent(eventState)
    if type(runtime) ~= "table" then
        return nil, reason
    end
    local planId = tostring(runtime.activeAuthorizationPlanId or "")
    if planId == "" then
        return nil, "pending-plan-unavailable"
    end
    return runtime.authorizationByPlanId[planId]
end

function Client:GetAutopilotPendingAction(actionId, eventStateOverride)
    local plan, reason = self:GetAutopilotPendingPlan(eventStateOverride)
    if type(plan) ~= "table" then
        return nil, reason
    end
    local action = getAction(plan, actionId)
    return action, action and nil or "pending-action-unavailable"
end

local function isPlanCurrent(plan, eventState, runtime)
    if type(plan) ~= "table" or type(eventState) ~= "table" or type(runtime) ~= "table" then
        return false, "pending-plan-unavailable"
    end
    if tostring(plan.eventId or "") ~= tostring(eventState.id or "") then
        return false, "event-changed"
    end
    if tonumber(plan.turnNumber) ~= tonumber(eventState.turnNumber) then
        return false, "turn-changed"
    end
    if tonumber(plan.tickNumber) ~= tonumber(eventState.tickNumber) then
        return false, "tick-changed"
    end
    local currentActorKey = tostring(runtime.currentPlannerActorKey or "")
    if currentActorKey ~= "" and currentActorKey ~= tostring(plan.actorKey or "") then
        return false, "actor-changed"
    end
    local revision = tostring(runtime.currentPlannerScheduleRevision or "")
    if revision ~= "" and revision ~= tostring(plan.scheduleRevision or "") then
        return false, "schedule-changed"
    end
    return true
end

local function resolveCurrentContext(eventStateOverride)
    local eventState = resolveEventState(eventStateOverride)
    local runtime, reason = getRuntimeForEvent(eventState)
    if type(runtime) ~= "table" then
        return nil, nil, nil, reason
    end
    local planId = tostring(runtime.activeAuthorizationPlanId or "")
    local plan = planId ~= "" and runtime.authorizationByPlanId[planId] or nil
    if runtime.status ~= "ready" then
        return eventState, runtime, plan, tostring(runtime.unavailableReason or "runtime-unavailable")
    end
    if type(plan) ~= "table" then
        return eventState, runtime, nil, "pending-plan-unavailable"
    end
    local current, currentReason = isPlanCurrent(plan, eventState, runtime)
    if not current then
        Authorization.MarkPlanStale(plan, currentReason)
        refreshAuthorizationStatus(runtime, plan)
        notifyHelperRefresh()
        return eventState, runtime, plan, currentReason
    end
    return eventState, runtime, plan
end

local function callAuthorizedHook(action, plan, eventState)
    if type(Client.OnAutopilotPendingActionAuthorized) ~= "function" then
        return true, "execution-pending-implementation"
    end
    local results = pack(pcall(Client.OnAutopilotPendingActionAuthorized, Client, action, plan, eventState))
    if results[1] ~= true then
        action.status = "failed"
        action.reason = tostring(results[2] or "authorization-hook-error")
        return false, action.reason
    end
    if results[2] == false then
        action.status = "failed"
        action.reason = tostring(results[3] or "authorization-hook-rejected")
        return false, action.reason
    end
    return true, results[2]
end

function Client:AuthorizeAutopilotPendingAction(actionId, eventStateOverride)
    local eventState, runtime, plan, reason = resolveCurrentContext(eventStateOverride)
    if type(plan) ~= "table" or reason then
        return false, nil, reason
    end
    local action = getAction(plan, actionId)
    if type(action) ~= "table" or action.actionType ~= "spell" then
        return false, nil, "spell-action-unavailable"
    end
    if action.status ~= "pending" then
        return false, action, "action-not-pending"
    end
    if action.requiresMovementActionId then
        local movement = getAction(plan, action.requiresMovementActionId)
        if type(movement) ~= "table" or movement.status ~= "confirmed" then
            return false, action, "movement-not-confirmed"
        end
    end

    action.status = "authorized"
    action.reason = nil
    local hookOk, hookReason = callAuthorizedHook(action, plan, eventState)
    refreshAuthorizationStatus(runtime, plan)
    notifyHelperRefresh()
    return hookOk, action, hookReason
end

function Client:RejectAutopilotPendingAction(actionId, eventStateOverride)
    local _, runtime, plan, reason = resolveCurrentContext(eventStateOverride)
    if type(plan) ~= "table" or reason then
        return false, nil, reason
    end
    local action = getAction(plan, actionId)
    if type(action) ~= "table" or action.actionType ~= "spell" then
        return false, nil, "spell-action-unavailable"
    end
    if action.status ~= "pending" and action.status ~= "blocked" then
        return false, action, "action-not-rejectable"
    end
    action.status = "rejected"
    action.reason = "dm-rejected"
    refreshAuthorizationStatus(runtime, plan)
    notifyHelperRefresh()
    return true, action
end

local function markMovementDependents(plan, movementActionId, status, reason, onlyMovementPending)
    local changed = 0
    for index = 1, #(plan and plan.spellActionIds or {}) do
        local action = getAction(plan, plan.spellActionIds[index])
        if type(action) == "table" and tostring(action.requiresMovementActionId or "") == tostring(movementActionId or "") then
            local canChange = action.status == "pending" or action.status == "blocked" or action.status == "authorized"
            if onlyMovementPending == true then
                canChange = action.status == "blocked" and action.reason == "movement-pending"
            end
            if canChange then
                action.status = status
                action.reason = reason
                changed = changed + 1
            end
        end
    end
    return changed
end

local function findCurrentMarkerActor(eventState, actorKey)
    if type(Event.BuildTurnActors) ~= "function" then
        return nil
    end
    local actors = Event.BuildTurnActors(eventState) or {}
    for index = 1, #actors do
        local actor = actors[index]
        if tostring(actor and actor.key or "") == tostring(actorKey or "") then
            return actor
        end
    end
    return nil
end

local function sameEventIdSet(left, right)
    if #(left or {}) ~= #(right or {}) then
        return false
    end
    local leftSet = {}
    for index = 1, #(left or {}) do
        leftSet[normalizeEventId(left[index])] = true
    end
    for index = 1, #(right or {}) do
        if leftSet[normalizeEventId(right[index])] ~= true then
            return false
        end
    end
    return true
end

local function blockMovement(plan, action, runtime, reason)
    action.status = "blocked"
    action.reason = tostring(reason or "movement-invalid")
    markMovementDependents(plan, action.actionId, "stale", action.reason, false)
    refreshAuthorizationStatus(runtime, plan)
    notifyHelperRefresh()
    return false, action, action.reason
end

function Client:ConfirmAutopilotPendingMovement(actionId, eventStateOverride)
    local eventState, runtime, plan, reason = resolveCurrentContext(eventStateOverride)
    if type(plan) ~= "table" or reason then
        return false, nil, reason
    end
    local action = getAction(plan, actionId)
    if type(action) ~= "table" or action.actionType ~= "movement" then
        return false, nil, "movement-action-unavailable"
    end
    if action.status ~= "pending" then
        return false, action, "movement-not-pending"
    end
    local marker = normalizeRaidMarker(action.raidMarker)
    if marker <= 0 or tostring(action.actorKey or "") ~= ("marker:" .. tostring(marker)) then
        return blockMovement(plan, action, runtime, "marked-cohort-required")
    end

    local actor = findCurrentMarkerActor(eventState, action.actorKey)
    if type(actor) ~= "table" or tostring(actor.kind or "") ~= "npc_marker" or normalizeRaidMarker(actor.raidMarker) ~= marker then
        return blockMovement(plan, action, runtime, "cohort-changed")
    end
    local currentMemberIds = copyArray(actor.unitEventIds)
    table.sort(currentMemberIds)
    local expectedMemberIds = copyArray(action.expectedMemberEventIds)
    table.sort(expectedMemberIds)
    if not sameEventIdSet(currentMemberIds, expectedMemberIds) then
        return blockMovement(plan, action, runtime, "cohort-changed")
    end

    local movement = RPE and RPE.Core and RPE.Core.Movement or nil
    if type(movement) ~= "table" or type(movement.ResolveEventUnitMovementAllowance) ~= "function" then
        return blockMovement(plan, action, runtime, "movement-allowance-api-unavailable")
    end
    local cohortAllowance = nil
    local currentMovementByMemberEventId = {}
    for index = 1, #(actor.units or {}) do
        local unit = actor.units[index]
        if type(unit) == "table" and (type(Event.IsUnitActive) ~= "function" or Event.IsUnitActive(unit) == true) then
            local resolvedAllowance, details = movement:ResolveEventUnitMovementAllowance(eventState, unit)
            local allowance = tonumber(resolvedAllowance)
            local eventId = normalizeEventId(unit.eventID)
            if eventId > 0 then
                currentMovementByMemberEventId[eventId] = copyMovementDetails(details, allowance)
            end
            if allowance == nil then
                action.currentMovementByMemberEventId = currentMovementByMemberEventId
                action.currentMovementAllowance = cohortAllowance
                action.limitingMemberEventIds = findLimitingMemberEventIds(
                    currentMovementByMemberEventId,
                    cohortAllowance
                )
                return blockMovement(plan, action, runtime, "movement-allowance-unavailable")
            end
            allowance = math.max(0, allowance)
            if eventId > 0 then
                currentMovementByMemberEventId[eventId].effectiveValue = allowance
            end
            if cohortAllowance == nil or allowance < cohortAllowance then
                cohortAllowance = allowance
            end
        end
    end
    cohortAllowance = math.max(0, tonumber(cohortAllowance) or 0)
    action.currentMovementAllowance = cohortAllowance
    action.currentMovementByMemberEventId = currentMovementByMemberEventId
    action.limitingMemberEventIds = findLimitingMemberEventIds(
        currentMovementByMemberEventId,
        cohortAllowance
    )

    local committedPosition, positionReason = nil, "position-unavailable"
    if type(Spatial.GetActorPosition) == "function" then
        committedPosition, positionReason = Spatial.GetActorPosition(runtime, eventState, action.actorKey)
    end
    if type(committedPosition) ~= "table" then
        return blockMovement(plan, action, runtime, positionReason or "position-unavailable")
    end
    local proposedPosition = action.proposedPosition
    if type(proposedPosition) ~= "table" then
        return blockMovement(plan, action, runtime, "proposed-position-unavailable")
    end
    local distance, distanceReason = nil, "distance-api-unavailable"
    if type(Spatial.DistanceBetweenPositions) == "function" then
        distance, distanceReason = Spatial.DistanceBetweenPositions(committedPosition, proposedPosition)
    end
    if tonumber(distance) == nil then
        return blockMovement(plan, action, runtime, distanceReason or "distance-unavailable")
    end
    action.currentMovementDistance = math.max(0, tonumber(distance) or 0)
    if tonumber(distance) > cohortAllowance + EPSILON then
        return blockMovement(plan, action, runtime, cohortAllowance <= 0 and "cohort-immobilized" or "movement-allowance-reduced")
    end

    local committed, nextPosition = false, "movement-commit-api-unavailable"
    if type(Spatial.SetActorPosition) == "function" then
        committed, nextPosition = Spatial.SetActorPosition(runtime, eventState, action.actorKey, proposedPosition)
    end
    if committed ~= true then
        return blockMovement(plan, action, runtime, tostring(nextPosition or "movement-commit-failed"))
    end

    action.status = "confirmed"
    action.reason = nil
    action.confirmedMovementAllowance = cohortAllowance
    action.confirmedPosition = copyPosition(nextPosition)
    markMovementDependents(plan, action.actionId, "pending", nil, true)
    refreshAuthorizationStatus(runtime, plan)
    notifyHelperRefresh()
    return true, action
end

function Client:SkipAutopilotPendingMovement(actionId, eventStateOverride)
    local _, runtime, plan, reason = resolveCurrentContext(eventStateOverride)
    if type(plan) ~= "table" or reason then
        return false, nil, reason
    end
    local action = getAction(plan, actionId)
    if type(action) ~= "table" or action.actionType ~= "movement" then
        return false, nil, "movement-action-unavailable"
    end
    if action.status ~= "pending" then
        return false, action, "movement-not-pending"
    end
    action.status = "skipped"
    action.reason = "dm-skipped"
    markMovementDependents(plan, action.actionId, "stale", "movement-skipped", false)
    refreshAuthorizationStatus(runtime, plan)
    notifyHelperRefresh()
    return true, action
end

function Client:AuthorizeAllAutopilotPendingActions(eventStateOverride)
    local eventState, runtime, plan, reason = resolveCurrentContext(eventStateOverride)
    if type(plan) ~= "table" or reason then
        return false, {}, reason
    end
    local authorized = {}
    for index = 1, #(plan.spellActionIds or {}) do
        local action = getAction(plan, plan.spellActionIds[index])
        if type(action) == "table" and action.status == "pending" then
            local dependencyReady = true
            if action.requiresMovementActionId then
                local movement = getAction(plan, action.requiresMovementActionId)
                dependencyReady = type(movement) == "table" and movement.status == "confirmed"
            end
            if dependencyReady then
                action.status = "authorized"
                action.reason = nil
                local hookOk = callAuthorizedHook(action, plan, eventState)
                if hookOk then
                    authorized[#authorized + 1] = action.actionId
                end
            end
        end
    end
    refreshAuthorizationStatus(runtime, plan)
    notifyHelperRefresh()
    return true, authorized
end

function Client:ReplanPendingAutopilotPlan(eventStateOverride)
    local eventState, runtime, plan, reason = resolveCurrentContext(eventStateOverride)
    if type(plan) ~= "table" or reason then
        return nil, false, reason
    end
    Authorization.MarkPlanStale(plan, "dm-replan")
    local planId = tostring(plan.planId or "")
    runtime.authorizationByPlanId[planId] = nil
    if runtime.activeAuthorizationPlanId == planId then
        runtime.activeAuthorizationPlanId = nil
    end
    runtime.authorizationStatus = "planning"
    notifyHelperRefresh()
    if type(self.ReplanAutopilotCurrentStep) ~= "function" then
        return nil, false, "replan-api-unavailable"
    end
    return self:ReplanAutopilotCurrentStep(eventState)
end

function Client:ResetAutopilotAuthorizationBatch(eventId, reason)
    local normalizedEventId = tostring(eventId or "")
    local runtime = normalizedEventId ~= ""
        and type(self.AutopilotRuntimeByEventId) == "table"
        and self.AutopilotRuntimeByEventId[normalizedEventId]
        or nil
    if type(runtime) ~= "table" then
        return false
    end

    ensureRuntimeFields(runtime)
    local hadState = next(runtime.authorizationByPlanId) ~= nil
        or tostring(runtime.activeAuthorizationPlanId or "") ~= ""
        or runtime.authorizationStatus ~= "ready"

    runtime.authorizationByPlanId = {}
    runtime.activeAuthorizationPlanId = nil
    runtime.authorizationStatus = "ready"
    if runtime.plannerStatus == "awaiting-authorization" then
        runtime.plannerStatus = "ready"
    end

    if hadState then
        notifyHelperRefresh()
    end
    return true
end

-- Publish only completed coordinator-owned plans. On cancel the plan record is not ready,
-- so ReleaseScratch remains a pure delegate and publishes nothing.
local baseReleaseScratch = Planner.ReleaseScratch
if type(baseReleaseScratch) == "function" then
    function Planner.ReleaseScratch(state)
        if type(state) == "table"
            and type(state.planRecord) == "table"
            and state.planRecord.status == "ready"
            and type(state.planRecord.result) == "table"
            and type(state.runtimeRef) == "table"
        then
            local ok, pending = pcall(Client.PublishAutopilotPendingPlan, Client, state.planRecord.result, state.runtimeRef)
            if ok ~= true then
                state.runtimeRef.authorizationStatus = "failed"
            elseif type(pending) == "table" then
                refreshAuthorizationStatus(state.runtimeRef, pending)
            end
        end
        return baseReleaseScratch(state)
    end
end

return Authorization
