local _, Addon = ...

Addon.Server = Addon.Server or {}
Addon.Internal = Addon.Internal or {}
Addon.Internal.Comms = Addon.Internal.Comms or {}

local Server = Addon.Server
local EventTransactions = Addon.Internal.Comms.EventTransactions or {}
local ServerTransactions = Addon.Server.EventTransactions
local ResourceSync = Addon.Internal.Comms.ResourceSync or {}

local function clone(value, seen)
    if type(value) ~= "table" then
        return value
    end
    seen = seen or {}
    if seen[value] then
        return seen[value]
    end
    local result = {}
    seen[value] = result
    for key, child in pairs(value) do
        result[clone(key, seen)] = clone(child, seen)
    end
    return result
end

local function normalizeId(value)
    return math.floor(tonumber(value) or 0)
end

local function findUnit(units, eventId)
    local wanted = normalizeId(eventId)
    if wanted <= 0 then
        return nil
    end
    for index = 1, #(units or {}) do
        local unit = units[index]
        if type(unit) == "table" and normalizeId(unit.eventID) == wanted then
            return unit
        end
    end
    return nil
end

local function isDead(unit, eventState, Combat)
    if not Combat or type(Combat.IsUnitDead) ~= "function" then
        return nil
    end
    return Combat:IsUnitDead(unit, { eventState = eventState }) == true
end

local function reject(reason)
    return {
        state = "rejected",
        outcome = { reason = tostring(reason or "combat-hit-rejected") },
    }
end

local function buildRequestEntry(envelope, eventState, request, actor, defender, Combat, component)
    local context = clone(request.context or {})
    context.attackerUnit = actor
    context.casterUnit = actor
    context.defenderUnit = defender
    context.targetUnit = defender
    context.eventState = eventState
    context.healthResourceRef = request.healthResourceRef or eventState.healthResourceRef
    context.combatLookupSnapshot = clone(request.combatLookupSnapshot)

    return {
        eventId = envelope.eventId,
        spellRef = request.spellRef,
        componentKey = request.componentKey,
        attackType = request.attackType,
        defenceSystem = request.defenceSystem,
        attackerUnit = actor,
        defenderUnit = defender,
        attackerEventId = normalizeId(envelope.actorEventId),
        defenderEventId = normalizeId(envelope.targetEventIds[1]),
        turnNumber = tonumber(envelope.turnNumber),
        tickNumber = tonumber(envelope.tickNumber),
        attackerTotal = tonumber(request.attackerTotal) or 0,
        rawDamage = tonumber(request.rawDamage) or 0,
        resultType = request.resultType,
        effect = component and component.effect or nil,
        component = component,
        weaponSkillContext = clone(request.weaponSkillContext),
        attackerRollContext = clone(request.attackerRollContext),
        attackModifierContext = clone(request.attackModifierContext),
        combatLookupSnapshot = clone(request.combatLookupSnapshot),
        targetEvents = clone(request.targetEvents or {}),
        context = context,
        eventState = eventState,
        sessionState = Server.GetState and Server:GetState() or nil,
    }
end

local function handleCombatHit(envelope, transactionContext)
    local eventState = Server.GetEventState and Server:GetEventState() or Server.EventState
    if type(eventState) ~= "table" or eventState.active ~= true then
        return reject("event-inactive")
    end

    local actorEventId = normalizeId(envelope.actorEventId)
    local targetEventIds = envelope.targetEventIds or {}
    if actorEventId <= 0 or #targetEventIds ~= 1 then
        return reject("invalid-combat-targets")
    end

    local actor = findUnit(eventState.units, actorEventId)
    local defender = findUnit(eventState.units, targetEventIds[1])
    local Combat = Addon.Client and Addon.Client.Combat
    if not actor or not defender then
        return reject("event-unit-missing")
    end
    if actor.active == false or defender.active == false then
        return reject("event-unit-inactive")
    end
    local actorDead = isDead(actor, eventState, Combat)
    local defenderDead = isDead(defender, eventState, Combat)
    if actorDead == nil or defenderDead == nil then
        return reject("combat-authority-unavailable")
    end
    if actorDead or defenderDead then
        return reject("event-unit-dead")
    end
    if tonumber(envelope.turnNumber) ~= tonumber(eventState.turnNumber)
        or tonumber(envelope.tickNumber) ~= tonumber(eventState.tickNumber)
    then
        return reject("stale-step")
    end
    if not Combat or type(Combat.ApplyResolvedDamage) ~= "function"
        or type(Combat.ResolveSpellComponent) ~= "function"
    then
        return reject("combat-formula-unavailable")
    end

    local input = type(envelope.input) == "table" and envelope.input or {}
    local request = type(input.request) == "table" and input.request or nil
    local reaction = type(input.reaction) == "table" and input.reaction or nil
    local initialInput = transactionContext and transactionContext.record and transactionContext.record.initialInput or nil
    local initialRequest = type(initialInput) == "table" and initialInput.request or input.request
    if not request or not reaction or not initialRequest
        or type(EventTransactions.Encode) ~= "function"
        or EventTransactions.Encode(initialRequest) ~= EventTransactions.Encode(request)
    then
        return reject("combat-request-conflict")
    end

    local resultToken = tostring(reaction.resultToken or ""):lower()
    if resultToken ~= "pass" and resultToken ~= "fail" then
        return reject("invalid-reaction-result")
    end

    local outcome = {
        resultToken = resultToken,
        landed = resultToken == "pass",
        defended = reaction.successfullyDefended == true,
        defenceStatRef = reaction.defenceStatRef,
        attackerEventId = actorEventId,
        defenderEventId = normalizeId(targetEventIds[1]),
        spellRef = request.spellRef,
        componentKey = request.componentKey,
    }
    if resultToken ~= "pass" then
        return {
            state = "committed",
            outcome = outcome,
            newRevision = tonumber(eventState.liveUnitRevision) or 0,
            authoritativeDelta = {},
        }
    end

    local _, _, component = Combat:ResolveSpellComponent(request.spellRef, request.componentKey)
    if type(component) ~= "table" or type(component.effect) ~= "table" then
        return reject("combat-component-missing")
    end
    local entry = buildRequestEntry(envelope, eventState, request, actor, defender, Combat, component)
    local applied, damageResult = Combat:ApplyResolvedDamage(entry, true)
    if applied ~= true or type(damageResult) ~= "table" then
        return reject("damage-resolution-failed")
    end

    local changed = false
    if type(ResourceSync.ApplyResourceDeltasToEventUnitByEventID) ~= "function" then
        return reject("resource-sync-unavailable")
    end
    if type(Server.BroadcastEventDeltaBatch) ~= "function" then
        return reject("event-delta-publish-unavailable")
    end
    if type(damageResult.resourceDeltas) == "table" and #damageResult.resourceDeltas > 0 then
        changed = ResourceSync.ApplyResourceDeltasToEventUnitByEventID(
            eventState.units,
            defender.eventID,
            damageResult.resourceDeltas,
            { healthResourceRef = damageResult.healthResourceRef or eventState.healthResourceRef }
        ) == true or changed
    end

    local threatUpdate = damageResult.threatUpdate
    if type(threatUpdate) == "table" and (tonumber(threatUpdate.amount) or 0) > 0 then
        defender.threatTable = type(defender.threatTable) == "table" and defender.threatTable or {}
        local sourceEventId = normalizeId(threatUpdate.sourceEventId)
        local amount = tonumber(threatUpdate.amount) or 0
        defender.threatTable[sourceEventId] = (tonumber(defender.threatTable[sourceEventId]) or 0) + amount
        changed = true
        outcome.threatUpdate = clone(threatUpdate)
    end

    outcome.damageResult = clone(damageResult)
    outcome.appliedDelta = tonumber(damageResult.appliedDelta) or 0
    outcome.dead = isDead(defender, eventState, Combat)
    outcome.healthResourceRef = damageResult.healthResourceRef or eventState.healthResourceRef

    local authoritativeDelta = {}
    local newRevision = tonumber(eventState.liveUnitRevision) or 0
    if changed then
        authoritativeDelta[1] = {
            operation = "upsert",
            eventID = defender.eventID,
            unit = clone(defender),
        }
        Server:BroadcastEventDeltaBatch(authoritativeDelta, false)
        newRevision = tonumber(eventState.liveUnitRevision) or newRevision
    end

    outcome.newRevision = newRevision
    return {
        state = "committed",
        outcome = outcome,
        newRevision = newRevision,
        authoritativeDelta = authoritativeDelta,
    }
end

if type(ServerTransactions) ~= "table" or type(ServerTransactions.Register) ~= "function" then
    error("Authoritative EventTransactions server service is unavailable for combat-hit.")
end
ServerTransactions:Register("combat-hit", handleCombatHit)
