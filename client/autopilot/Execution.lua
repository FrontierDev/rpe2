local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Internal = Addon.Internal or {}

local Client = Addon.Client
local Spellcasting = Client.Spellcasting or {}
local Event = Addon.Internal
    and Addon.Internal.Database
    and Addon.Internal.Database.Classes
    and Addon.Internal.Database.Classes.Event
    or nil
local Profile = Addon.Internal and Addon.Internal.Profile or {}
local Common = Addon.Utils and Addon.Utils.Common or {}

Client.AutopilotExecution = Client.AutopilotExecution or {}
local Execution = Client.AutopilotExecution

if type(Client.OnSpellcastStart) ~= "function"
    or type(Client.OnSpellcastComplete) ~= "function"
    or type(Spellcasting.QueueLocalSpellTargetSelection) ~= "function"
then
    return Execution
end

local baseAuthorizePendingAction = Client.AuthorizeAutopilotPendingAction
local baseAuthorizeAllPendingActions = Client.AuthorizeAllAutopilotPendingActions

local function pack(...)
    return { n = select("#", ...), ... }
end

local function normalizeEventId(value)
    local eventId = math.floor(tonumber(value) or 0)
    return eventId > 0 and eventId or 0
end

local function normalizeTurnMode(value)
    if type(Event) == "table" and type(Event.NormalizeTurnMode) == "function" then
        return Event.NormalizeTurnMode(value)
    end
    return tostring(value or "") == "autopilot" and "autopilot" or "manual"
end

local function isUnitActive(unit)
    if type(unit) ~= "table" then
        return false
    end
    if type(Event) == "table" and type(Event.IsUnitActive) == "function" then
        return Event.IsUnitActive(unit) == true
    end
    return unit.active ~= false
end

local function findUnit(eventState, eventId)
    local wanted = normalizeEventId(eventId)
    if wanted <= 0 then
        return nil
    end
    for index = 1, #((eventState and eventState.units) or {}) do
        local unit = eventState.units[index]
        if normalizeEventId(unit and unit.eventID) == wanted then
            return unit
        end
    end
    return nil
end

local function getHealthResourceRef()
    if type(Profile.GetHealthResourceRef) == "function" then
        return Profile.GetHealthResourceRef()
    end
    return nil
end

local function isUnitAlive(unit)
    if type(unit) ~= "table" or unit.dead == true then
        return false
    end
    local healthRef = getHealthResourceRef()
    if type(healthRef) ~= "string" or healthRef == "" then
        return true
    end
    for index = 1, #(unit.resources or {}) do
        local resource = unit.resources[index]
        if type(resource) == "table" and tostring(resource.resourceRef or "") == healthRef then
            local current = tonumber(resource.currentValue)
            if current == nil then
                current = tonumber(resource.maxValue)
            end
            return current == nil or current > 0
        end
    end
    return true
end

local function normalizeName(value)
    if type(Common.NormalizeName) == "function" then
        return Common.NormalizeName(value)
    end
    return tostring(value or "")
end

local function validateController(client, eventState, casterUnit)
    if type(client.CanControlEventUnit) == "function"
        and client:CanControlEventUnit(casterUnit, eventState) ~= true
    then
        return false
    end

    if type(Spellcasting.ResolveControllerPlayerUnit) == "function"
        and type(Spellcasting.GetLocalPlayerName) == "function"
    then
        local controllerUnit = Spellcasting.ResolveControllerPlayerUnit(eventState, casterUnit)
        if type(controllerUnit) ~= "table" then
            return false
        end
        local expected = normalizeName(controllerUnit.ownerID or controllerUnit.controllerID or controllerUnit.name)
        local localName = normalizeName(Spellcasting.GetLocalPlayerName())
        if expected == "" or localName == "" or expected ~= localName then
            return false
        end
    end
    return true
end

local function findCurrentActorForUnit(eventState, casterEventId)
    if type(Event) ~= "table" or type(Event.BuildTurnActors) ~= "function" then
        return nil
    end
    local wanted = normalizeEventId(casterEventId)
    local actors = Event.BuildTurnActors(eventState) or {}
    for index = 1, #actors do
        local actor = actors[index]
        for memberIndex = 1, #(actor and actor.unitEventIds or {}) do
            if normalizeEventId(actor.unitEventIds[memberIndex]) == wanted then
                return actor
            end
        end
    end
    return nil
end

local function getRuntime(eventState)
    local eventId = tostring(type(eventState) == "table" and eventState.id or "")
    return eventId ~= ""
        and type(Client.AutopilotRuntimeByEventId) == "table"
        and Client.AutopilotRuntimeByEventId[eventId]
        or nil
end

local function validatePlanIdentity(action, plan, eventState)
    if type(action) ~= "table" or type(plan) ~= "table" or type(eventState) ~= "table" then
        return false, "pending-action-unavailable"
    end
    if eventState.active ~= true or normalizeTurnMode(eventState.turnMode) ~= "autopilot" then
        return false, "event-inactive"
    end
    if type(Client.IsLocalEventHost) ~= "function" or Client:IsLocalEventHost(eventState) ~= true then
        return false, "not-event-host"
    end
    if tostring(action.eventId or "") ~= tostring(eventState.id or "")
        or tostring(plan.eventId or "") ~= tostring(eventState.id or "")
    then
        return false, "event-changed"
    end
    if tonumber(action.turnNumber) ~= tonumber(eventState.turnNumber)
        or tonumber(plan.turnNumber) ~= tonumber(eventState.turnNumber)
    then
        return false, "turn-changed"
    end
    if tonumber(action.tickNumber) ~= tonumber(eventState.tickNumber)
        or tonumber(plan.tickNumber) ~= tonumber(eventState.tickNumber)
    then
        return false, "tick-changed"
    end

    local runtime = getRuntime(eventState)
    if type(runtime) ~= "table" or runtime.status ~= "ready" then
        return false, tostring(type(runtime) == "table" and runtime.unavailableReason or "runtime-unavailable")
    end
    if tostring(runtime.currentPlannerActorKey or "") ~= ""
        and tostring(runtime.currentPlannerActorKey or "") ~= tostring(plan.actorKey or "")
    then
        return false, "actor-changed"
    end
    if tostring(runtime.currentPlannerScheduleRevision or "") ~= ""
        and tostring(runtime.currentPlannerScheduleRevision or "") ~= tostring(plan.scheduleRevision or "")
    then
        return false, "schedule-changed"
    end

    local currentActor = findCurrentActorForUnit(eventState, action.casterEventId)
    if type(currentActor) ~= "table" or tostring(currentActor.key or "") ~= tostring(action.actorKey or "") then
        return false, "actor-changed"
    end
    return true
end

local function normalizePolicyCount(value)
    return math.max(0, math.floor(tonumber(value) or 0))
end

local function cloneArray(values)
    local copied = {}
    for index = 1, #(values or {}) do
        copied[index] = values[index]
    end
    return copied
end

local function extractSelectionIds(action, key)
    local source = type(action.targetSelections) == "table" and action.targetSelections[key] or nil
    if type(source) == "table" and type(source.targetEventIds) == "table" then
        source = source.targetEventIds
    end
    if type(source) ~= "table" then
        return {}
    end
    local ids = {}
    local seen = {}
    for index = 1, #source do
        local eventId = normalizeEventId(source[index])
        if eventId > 0 and seen[eventId] ~= true then
            seen[eventId] = true
            ids[#ids + 1] = eventId
        end
    end
    return ids
end

local function buildCandidateSet(candidates)
    local set = {}
    for index = 1, #(candidates or {}) do
        local eventId = normalizeEventId(candidates[index] and candidates[index].eventID)
        if eventId > 0 then
            set[eventId] = true
        end
    end
    return set
end

local function buildCandidateByEventId(candidates)
    local byEventId = {}
    for index = 1, #(candidates or {}) do
        local candidate = candidates[index]
        local eventId = normalizeEventId(candidate and candidate.eventID)
        if eventId > 0 then
            byEventId[eventId] = candidate
        end
    end
    return byEventId
end

local function normalizeRaidMarker(value)
    local marker = math.floor(tonumber(value) or 0)
    return marker >= 1 and marker <= 8 and marker or 0
end

local function validateSelectionForPolicy(ids, candidates, policy)
    policy = type(policy) == "table" and policy or {}
    local minTargets = normalizePolicyCount(policy.minTargets)
    local maxTargets = normalizePolicyCount(policy.maxTargets)
    local targetType = tostring(policy.type or "single")
    if targetType ~= "all_allies" and maxTargets < minTargets then
        maxTargets = minTargets
    end
    if #ids < minTargets
        or (targetType ~= "all_allies" and maxTargets > 0 and #ids > maxTargets)
    then
        return false, "target-count-invalid"
    end
    if targetType ~= "all_allies" and maxTargets == 0 and #ids > 0 then
        return false, "target-count-invalid"
    end

    local candidateSet = buildCandidateSet(candidates)
    local candidatesByEventId = buildCandidateByEventId(candidates)
    for index = 1, #ids do
        if candidateSet[ids[index]] ~= true then
            return false, "target-invalid"
        end
    end

    if targetType == "all_allies" then
        local expectedCount = #candidates
        if #ids ~= expectedCount then
            return false, "target-set-invalid"
        end
    elseif targetType == "raid_marker" then
        local anchor = candidatesByEventId[ids[1]]
        local anchorMarker = normalizeRaidMarker(anchor and anchor.raidMarker)
        if anchorMarker <= 0 then
            return false, "target-marker-invalid"
        end
        for index = 2, #ids do
            if normalizeRaidMarker(candidatesByEventId[ids[index]] and candidatesByEventId[ids[index]].raidMarker) ~= anchorMarker then
                return false, "target-marker-mismatch"
            end
        end
    end
    return true
end

local function buildValidatedTargetSelection(action, snapshot)
    local groups = type(snapshot.targetGroups) == "table" and snapshot.targetGroups or {}
    local selections = {}
    local order = {}
    local knownGroups = {}

    if #groups > 0 then
        for index = 1, #groups do
            local group = groups[index]
            local key = tostring(group and group.key or "")
            if key == "" then
                return nil, nil, "target-group-unavailable"
            end
            knownGroups[key] = true
            local ids = extractSelectionIds(action, key)
            local candidates = type(snapshot.targetCandidatesByGroup) == "table"
                and snapshot.targetCandidatesByGroup[key]
                or {}
            local valid, reason = validateSelectionForPolicy(ids, candidates, group.policy)
            if not valid then
                return nil, nil, reason
            end
            selections[key] = {
                groupKey = key,
                targetEventIds = cloneArray(ids),
                focusedTargetEventId = ids[1] or 0,
                policy = group.policy,
            }
            order[#order + 1] = key
        end
        for key in pairs(type(action.targetSelections) == "table" and action.targetSelections or {}) do
            if knownGroups[tostring(key)] ~= true then
                return nil, nil, "target-group-unavailable"
            end
        end
        for index = 1, #(action.targetSelectionOrder or {}) do
            if knownGroups[tostring(action.targetSelectionOrder[index] or "")] ~= true then
                return nil, nil, "target-group-unavailable"
            end
        end
        return selections, order
    end

    local key = "default"
    local ids = extractSelectionIds(action, key)
    if #ids == 0 and type(action.targetEventIds) == "table" then
        local fallback = { targetSelections = { default = action.targetEventIds } }
        ids = extractSelectionIds(fallback, key)
    end
    local valid, reason = validateSelectionForPolicy(ids, snapshot.targetCandidates or {}, snapshot.policy)
    if not valid then
        return nil, nil, reason
    end
    selections[key] = {
        groupKey = key,
        targetEventIds = cloneArray(ids),
        focusedTargetEventId = ids[1] or 0,
        policy = snapshot.policy,
    }
    order[1] = key
    return selections, order
end

local function refreshHelper()
    if type(Client.QueueAutopilotDMHelperRefresh) == "function" then
        Client:QueueAutopilotDMHelperRefresh()
    end
end

local function createExecutionProxy(casterUnit, eventState)
    local proxy = {
        QueuedSpellTargetSelection = false,
        ResolveActiveSpellcasterUnit = function(_, requestedEventState)
            if requestedEventState ~= eventState then
                return nil
            end
            return casterUnit, eventState
        end,
    }

    return setmetatable(proxy, {
        __index = Client,
        __newindex = function(tableValue, key, value)
            if key == "QueuedSpellTargetSelection" then
                rawset(tableValue, key, value)
                return
            end
            Client[key] = value
        end,
    })
end

local function classifyStaleReason(reason)
    local staleReasons = {
        ["event-changed"] = true,
        ["turn-changed"] = true,
        ["tick-changed"] = true,
        ["actor-changed"] = true,
        ["schedule-changed"] = true,
        ["caster-unavailable"] = true,
        ["caster-inactive"] = true,
        ["caster-dead"] = true,
        ["not-controller"] = true,
        ["caster-not-on-step"] = true,
        ["movement-not-confirmed"] = true,
        ["target-group-unavailable"] = true,
        ["target-count-invalid"] = true,
        ["target-invalid"] = true,
    }
    if staleReasons[tostring(reason or "")] == true then
        return true
    end
    return string.sub(tostring(reason or ""), 1, 11) == "activation-"
end

function Client:ExecuteEventUnitSpell(request)
    request = type(request) == "table" and request or {}
    local eventState = type(request.eventState) == "table"
        and request.eventState
        or (type(self.GetEventState) == "function" and self:GetEventState() or nil)
    local action = request.action
    local plan = request.plan
    if tostring(request.source or "") ~= "autopilot-authorized"
        or type(action) ~= "table"
        or type(plan) ~= "table"
        or action.status ~= "executing"
    then
        return false, "authorization-context-unavailable", "failed"
    end
    local casterEventId = normalizeEventId(request.casterEventId or (action and action.casterEventId))
    local spellRef = tostring(request.spellRef or (action and action.spellRef) or "")
    if type(eventState) ~= "table" or casterEventId <= 0 or spellRef == "" then
        return false, "execution-request-invalid", "failed"
    end

    local current, reason = validatePlanIdentity(action, plan, eventState)
    if not current then
        return false, reason, "stale"
    end

    local casterUnit = findUnit(eventState, casterEventId)
    if type(casterUnit) ~= "table" or casterUnit.isPlayer == true then
        return false, "caster-unavailable", "stale"
    end
    if not isUnitActive(casterUnit) then
        return false, "caster-inactive", "stale"
    end
    if not isUnitAlive(casterUnit) then
        return false, "caster-dead", "stale"
    end
    if not validateController(self, eventState, casterUnit) then
        return false, "not-controller", "stale"
    end
    if type(Spellcasting.IsCasterTurnOnTick) == "function"
        and Spellcasting.IsCasterTurnOnTick(eventState, casterEventId) ~= true
    then
        return false, "caster-not-on-step", "stale"
    end

    if type(action) == "table" and action.requiresMovementActionId then
        local movement = type(plan) == "table" and type(plan.actionsById) == "table"
            and plan.actionsById[tostring(action.requiresMovementActionId)]
            or nil
        if type(movement) ~= "table" or movement.status ~= "confirmed" then
            return false, "movement-not-confirmed", "stale"
        end
    end

    if type(self.ResolveSpellActivationSnapshot) ~= "function" then
        return false, "activation-api-unavailable", "failed"
    end
    local snapshot = self:ResolveSpellActivationSnapshot(spellRef, {
        casterEventId = casterEventId,
        includeTargetCandidates = true,
    })
    if type(snapshot) ~= "table" or snapshot.canCast ~= true then
        return false, "activation-" .. tostring(type(snapshot) == "table" and snapshot.reason or "unavailable"), "stale"
    end

    local selectionSource = type(action) == "table" and action or request
    local targetSelections, targetSelectionOrder, targetReason = buildValidatedTargetSelection(selectionSource, snapshot)
    if not targetSelections then
        return false, targetReason, "stale"
    end

    local proxy = createExecutionProxy(casterUnit, eventState)
    Spellcasting.QueueLocalSpellTargetSelection(proxy, spellRef, targetSelections, targetSelectionOrder)

    local castTime = tonumber(snapshot.spell and snapshot.spell.totalTicks) or (snapshot.spell and snapshot.spell.castTime)
    local results = pack(pcall(Client.OnSpellcastStart, proxy, spellRef, castTime, snapshot))
    if results[1] ~= true or results[2] ~= true then
        local existing = type(Spellcasting.GetCastEntry) == "function"
            and Spellcasting.GetCastEntry(Client, tostring(eventState.id or ""), casterEventId)
            or nil
        if type(existing) == "table"
            and normalizeEventId(existing.casterEventId) == casterEventId
            and tostring(existing.spellRef or "") == spellRef
            and type(Spellcasting.RemoveCastEntry) == "function"
        then
            Spellcasting.RemoveCastEntry(Client, tostring(eventState.id or ""), casterEventId)
        end
        return false, results[1] == true and "spell-start-failed" or "spell-start-error", "failed"
    end

    local castEntry = type(Spellcasting.GetCastEntry) == "function"
        and Spellcasting.GetCastEntry(Client, tostring(eventState.id or ""), casterEventId)
        or nil
    return true, {
        casterEventId = casterEventId,
        spellRef = spellRef,
        castEntry = castEntry,
        instant = castEntry == nil,
        source = tostring(request.source or "autopilot-authorized"),
    }
end

function Client:OnAutopilotPendingActionAuthorized(action, plan, eventState)
    if type(action) ~= "table" or tostring(action.actionType or "") ~= "spell" then
        return false, "spell-action-unavailable"
    end
    if action.status ~= "authorized" then
        return false, "action-not-authorized"
    end

    action.status = "executing"
    action.reason = nil
    refreshHelper()
    local ok, resultOrReason, failureKind = self:ExecuteEventUnitSpell({
        casterEventId = action.casterEventId,
        spellRef = action.spellRef,
        targetSelections = action.targetSelections,
        targetSelectionOrder = action.targetSelectionOrder,
        targetEventIds = action.targetEventIds,
        action = action,
        plan = plan,
        eventState = eventState,
        source = "autopilot-authorized",
    })
    if ok ~= true then
        action.status = (failureKind == "stale" or classifyStaleReason(resultOrReason)) and "stale" or "failed"
        action.reason = tostring(resultOrReason or "execution-failed")
        refreshHelper()
        return false, action.reason
    end

    action.status = "completed"
    action.reason = nil
    refreshHelper()
    return true, resultOrReason
end

local function reclassifyStaleAuthorizationFailure(action)
    if type(action) ~= "table" or action.status ~= "failed" then
        return false
    end
    if classifyStaleReason(action.reason) ~= true then
        return false
    end
    action.status = "stale"
    refreshHelper()
    return true
end

if type(baseAuthorizePendingAction) == "function" then
    function Client:AuthorizeAutopilotPendingAction(...)
        local results = pack(pcall(baseAuthorizePendingAction, self, ...))
        if results[1] ~= true then
            error(results[2], 0)
        end
        reclassifyStaleAuthorizationFailure(results[3])
        return unpack(results, 2, results.n)
    end
end

if type(baseAuthorizeAllPendingActions) == "function" then
    function Client:AuthorizeAllAutopilotPendingActions(eventStateOverride, ...)
        local results = pack(pcall(baseAuthorizeAllPendingActions, self, eventStateOverride, ...))
        if results[1] ~= true then
            error(results[2], 0)
        end
        local pending = type(self.GetAutopilotPendingPlan) == "function"
            and select(1, self:GetAutopilotPendingPlan(eventStateOverride))
            or nil
        if type(pending) == "table" then
            for index = 1, #(pending.spellActionIds or {}) do
                local action = type(pending.actionsById) == "table"
                    and pending.actionsById[pending.spellActionIds[index]]
                    or nil
                reclassifyStaleAuthorizationFailure(action)
            end
        end
        return unpack(results, 2, results.n)
    end
end

Execution.ValidatePlanIdentity = validatePlanIdentity
Execution.BuildValidatedTargetSelection = buildValidatedTargetSelection
return Execution
