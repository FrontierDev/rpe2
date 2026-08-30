local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Server = Addon.Server or {}
Addon.Internal = Addon.Internal or {}
Addon.Internal.Comms = Addon.Internal.Comms or {}

local Client = Addon.Client
local Server = Addon.Server
local Comms = Addon.Internal.Comms
local Operations = Comms.Operations or {}
local ResourceSync = Comms.ResourceSync or {}
local Spellcasting = Client.Spellcasting or {}
local Combat = Client.Combat or {}
local Planner = Client.AutopilotPlanner or {}
local Helper = Client.AutopilotHelper or {}

if type(Comms.SendToChannel) ~= "function"
    or type(Spellcasting.GetCastEntry) ~= "function"
    or type(Client.EnsureAutopilotPlanAfterClientSync) ~= "function"
    or type(Client.EnsureAutopilotPlanForCurrentStep) ~= "function"
then
    return
end

local SPELLCAST_START_OPCODE = Operations.GetOpcode and Operations:GetOpcode("SPELLCAST_START") or nil
local SPELLCAST_COMPLETE_OPCODE = Operations.GetOpcode and Operations:GetOpcode("SPELLCAST_COMPLETE") or nil
local SPELLCAST_INTERRUPT_OPCODE = Operations.GetOpcode and Operations:GetOpcode("SPELLCAST_INTERRUPT") or nil

if not SPELLCAST_START_OPCODE or not SPELLCAST_COMPLETE_OPCODE or not SPELLCAST_INTERRUPT_OPCODE then
    return
end

Client.AutopilotTimedCastLifecycle = Client.AutopilotTimedCastLifecycle or {}
local Lifecycle = Client.AutopilotTimedCastLifecycle

local function pack(...)
    return { n = select("#", ...), ... }
end

local function copyArray(values)
    local copied = {}
    for index = 1, #(values or {}) do
        copied[index] = values[index]
    end
    return copied
end

local function normalizeEventId(value)
    local numeric = math.floor(tonumber(value) or 0)
    return numeric > 0 and numeric or 0
end

local function normalizeName(value)
    if type(Spellcasting.NormalizeName) == "function" then
        return Spellcasting.NormalizeName(value)
    end
    return tostring(value or "")
end

local function getEventKey(eventId)
    return tostring(eventId or "")
end

local function getCasterKey(scope, eventId, casterEventId)
    return table.concat({
        tostring(scope or "client"),
        getEventKey(eventId),
        tostring(normalizeEventId(casterEventId)),
    }, "\31")
end

local outboundGenerationByCasterKey = {}
local terminalCastIdsByScope = {
    client = {},
    server = {},
}
local pendingTerminalSendByScope = {
    client = nil,
    server = nil,
}

local function getTerminalBucket(scope, eventId, create)
    local root = terminalCastIdsByScope[scope]
    if type(root) ~= "table" then
        return nil
    end
    local eventKey = getEventKey(eventId)
    local bucket = root[eventKey]
    if type(bucket) ~= "table" and create == true then
        bucket = {}
        root[eventKey] = bucket
    end
    return bucket
end

local function recordTerminal(scope, entry, eventId)
    if type(entry) ~= "table" then
        return false
    end
    local castId = tostring(entry.castId or "")
    if castId == "" then
        return false
    end
    local bucket = getTerminalBucket(scope, eventId or entry.autopilotEventId or entry.eventId, true)
    if type(bucket) ~= "table" then
        return false
    end
    bucket[castId] = true
    return true
end

local function wasTerminal(scope, eventId, castId)
    local normalizedCastId = tostring(castId or "")
    if normalizedCastId == "" then
        return false
    end
    local bucket = getTerminalBucket(scope, eventId, false)
    return type(bucket) == "table" and bucket[normalizedCastId] == true
end

local function clearLifecycleEvent(scope, eventId)
    local root = terminalCastIdsByScope[scope]
    if type(root) == "table" then
        if eventId == nil or tostring(eventId or "") == "" then
            terminalCastIdsByScope[scope] = {}
        else
            root[getEventKey(eventId)] = nil
        end
    end

    local prefix = tostring(scope or "client") .. "\31" .. getEventKey(eventId) .. "\31"
    for key in pairs(outboundGenerationByCasterKey) do
        if eventId == nil or tostring(eventId or "") == "" or string.sub(key, 1, #prefix) == prefix then
            outboundGenerationByCasterKey[key] = nil
        end
    end
end

local function getClientCastEntry(eventId, casterEventId)
    return Spellcasting.GetCastEntry(Client, getEventKey(eventId), normalizeEventId(casterEventId))
end

local function getServerCastEntry(eventId, casterEventId)
    if type(Server.GetSpellcastEntry) ~= "function" then
        return nil
    end
    return Server:GetSpellcastEntry(getEventKey(eventId), normalizeEventId(casterEventId))
end

local function getCastEntryForScope(scope, eventId, casterEventId)
    if scope == "server" then
        return getServerCastEntry(eventId, casterEventId)
    end
    return getClientCastEntry(eventId, casterEventId)
end

local function ensureCastIdentity(scope, eventId, casterEventId, entry, startedOnTurnNumber)
    if type(entry) ~= "table" then
        return nil
    end

    local eventKey = getEventKey(eventId)
    local casterId = normalizeEventId(casterEventId or entry.casterEventId)
    if eventKey == "" or casterId <= 0 then
        return nil
    end

    local generation = math.max(0, math.floor(tonumber(entry.castGeneration) or 0))
    local generationKey = getCasterKey(scope, eventKey, casterId)
    if generation <= 0 then
        generation = math.max(0, math.floor(tonumber(outboundGenerationByCasterKey[generationKey]) or 0)) + 1
        entry.castGeneration = generation
    end
    outboundGenerationByCasterKey[generationKey] = math.max(
        generation,
        math.floor(tonumber(outboundGenerationByCasterKey[generationKey]) or 0)
    )

    if tostring(entry.castId or "") == "" then
        entry.castId = table.concat({
            tostring(scope or "client"),
            eventKey,
            tostring(casterId),
            tostring(generation),
        }, ":")
    end

    local startTurn = math.max(
        1,
        math.floor(
            tonumber(entry.startedOnTurnNumber)
                or tonumber(startedOnTurnNumber)
                or 1
        )
    )
    entry.startedOnTurnNumber = startTurn
    if tonumber(entry.turnsTotal) ~= nil then
        entry.completeOnTurnNumber = startTurn + math.max(1, math.floor(tonumber(entry.turnsTotal) or 1))
        if tonumber(entry.lastAdvancedTurnNumber) == nil then
            entry.lastAdvancedTurnNumber = startTurn
        end
    end
    return entry
end

local function attachInboundIdentity(entry, castId, generation, startedOnTurnNumber)
    if type(entry) ~= "table" or tostring(castId or "") == "" then
        return entry
    end

    entry.castId = tostring(castId)
    entry.castGeneration = math.max(1, math.floor(tonumber(generation) or 1))
    local startTurn = tonumber(startedOnTurnNumber)
    if startTurn ~= nil then
        startTurn = math.max(1, math.floor(startTurn))
        entry.startedOnTurnNumber = startTurn
        entry.lastAdvancedTurnNumber = startTurn
        if tonumber(entry.turnsTotal) ~= nil then
            entry.completeOnTurnNumber = startTurn + math.max(1, math.floor(tonumber(entry.turnsTotal) or 1))
        end
    end
    return entry
end

local function getPacketIdentity(arguments, phase)
    if type(arguments) ~= "table" then
        return nil
    end
    local castId, startTurn, generation
    if phase == "start" then
        castId = tostring(arguments[7] or "")
        startTurn = tonumber(arguments[8])
        generation = tonumber(arguments[9])
    else
        -- args[6] intentionally repeats authorityType for compatibility with older
        -- ValidateInboundSpellcast implementations that prefer [6] over [5].
        castId = tostring(arguments[7] or "")
        startTurn = tonumber(arguments[8])
        generation = tonumber(arguments[9])
    end
    if castId == "" or generation == nil then
        return nil
    end
    return {
        castId = castId,
        startedOnTurnNumber = startTurn,
        castGeneration = math.max(1, math.floor(generation)),
    }
end

local baseSendToChannel = Comms.SendToChannel
function Comms:SendToChannel(channelId, opcodeOrPayload, argumentsOrMetadata, metadata)
    local opcode = tonumber(opcodeOrPayload)
    local arguments = argumentsOrMetadata
    if type(arguments) ~= "table"
        or (opcode ~= SPELLCAST_START_OPCODE
            and opcode ~= SPELLCAST_COMPLETE_OPCODE
            and opcode ~= SPELLCAST_INTERRUPT_OPCODE)
    then
        return baseSendToChannel(self, channelId, opcodeOrPayload, argumentsOrMetadata, metadata)
    end

    local scope = type(metadata) == "table" and tostring(metadata.scope or "") or ""
    if scope ~= "server" then
        scope = "client"
    end
    local eventId = arguments[2]
    local casterEventId = arguments[3]
    local entry = nil

    if opcode == SPELLCAST_START_OPCODE then
        entry = getCastEntryForScope(scope, eventId, casterEventId)
        if type(entry) == "table" then
            local sourceEventState = scope == "server" and Server.EventState or Client.EventState
            ensureCastIdentity(
                scope,
                eventId,
                casterEventId,
                entry,
                entry.startedOnTurnNumber or (sourceEventState and sourceEventState.turnNumber)
            )
        end
    else
        entry = pendingTerminalSendByScope[scope]
        if type(entry) ~= "table" then
            entry = getCastEntryForScope(scope, eventId, casterEventId)
        end
        if type(entry) == "table" then
            ensureCastIdentity(scope, eventId, casterEventId, entry, entry.startedOnTurnNumber)
        end
    end

    if type(entry) ~= "table" or tostring(entry.castId or "") == "" then
        return baseSendToChannel(self, channelId, opcodeOrPayload, argumentsOrMetadata, metadata)
    end

    local extended = copyArray(arguments)
    if opcode ~= SPELLCAST_START_OPCODE then
        extended[6] = extended[5]
    end
    extended[7] = entry.castId
    extended[8] = entry.startedOnTurnNumber
    extended[9] = entry.castGeneration
    return baseSendToChannel(self, channelId, opcodeOrPayload, extended, metadata)
end

local function installInboundLifecycleWrappers(owner, scope, getEntry)
    if type(owner) ~= "table" then
        return
    end

    local baseStart = owner.HandleSpellcastStart
    if type(baseStart) == "function" then
        owner.HandleSpellcastStart = function(self, arguments, sender, ...)
            local identity = getPacketIdentity(arguments, "start")
            if not identity then
                return baseStart(self, arguments, sender, ...)
            end

            local eventId = arguments and arguments[2] or nil
            local casterEventId = arguments and arguments[3] or nil
            if wasTerminal(scope, eventId, identity.castId) then
                return true
            end

            local existing = getEntry(eventId, casterEventId)
            if type(existing) == "table" and tostring(existing.castId or "") == identity.castId then
                return true
            end
            if type(existing) == "table"
                and tonumber(existing.castGeneration) ~= nil
                and identity.castGeneration <= tonumber(existing.castGeneration)
            then
                return true
            end

            local results = pack(baseStart(self, arguments, sender, ...))
            if results[1] == true then
                local created = getEntry(eventId, casterEventId)
                if type(created) == "table" then
                    attachInboundIdentity(
                        created,
                        identity.castId,
                        identity.castGeneration,
                        identity.startedOnTurnNumber
                    )
                end
            end
            return unpack(results, 1, results.n)
        end
    end

    local function installTerminal(methodName, phase)
        local baseMethod = owner[methodName]
        if type(baseMethod) ~= "function" then
            return
        end

        owner[methodName] = function(self, arguments, sender, ...)
            local identity = getPacketIdentity(arguments, phase)
            if not identity then
                return baseMethod(self, arguments, sender, ...)
            end

            local eventId = arguments and arguments[2] or nil
            local casterEventId = arguments and arguments[3] or nil
            if wasTerminal(scope, eventId, identity.castId) then
                return true
            end

            local existing = getEntry(eventId, casterEventId)
            if type(existing) == "table"
                and tostring(existing.castId or "") ~= ""
                and tostring(existing.castId or "") ~= identity.castId
            then
                return true
            end

            local results = pack(baseMethod(self, arguments, sender, ...))
            if results[1] == true then
                recordTerminal(scope, {
                    castId = identity.castId,
                    castGeneration = identity.castGeneration,
                    startedOnTurnNumber = identity.startedOnTurnNumber,
                    eventId = eventId,
                }, eventId)
            end
            return unpack(results, 1, results.n)
        end
    end

    installTerminal("HandleSpellcastComplete", "complete")
    installTerminal("HandleSpellcastInterrupt", "interrupt")
end

installInboundLifecycleWrappers(Client, "client", getClientCastEntry)
installInboundLifecycleWrappers(Server, "server", getServerCastEntry)

local function getRuntimeForEventId(eventId)
    local key = getEventKey(eventId)
    return key ~= ""
        and type(Client.AutopilotRuntimeByEventId) == "table"
        and Client.AutopilotRuntimeByEventId[key]
        or nil
end

local function isAutopilotTimedCast(entry)
    return type(entry) == "table"
        and tonumber(entry.turnsTotal) ~= nil
        and tostring(entry.autopilotSource or "") == "autopilot-authorized"
        and tostring(entry.autopilotEventId or "") ~= ""
end

local function ensureSettlementMap(runtime)
    if type(runtime) ~= "table" then
        return nil
    end
    runtime.pendingCombatSettlementsByCastId = type(runtime.pendingCombatSettlementsByCastId) == "table"
        and runtime.pendingCombatSettlementsByCastId
        or {}
    return runtime.pendingCombatSettlementsByCastId
end

local function getCastSettlement(entry)
    if type(entry) ~= "table" then
        return nil, nil
    end
    local runtime = getRuntimeForEventId(entry.autopilotEventId)
    local map = type(runtime) == "table" and ensureSettlementMap(runtime) or nil
    local castId = tostring(entry.castId or "")
    return castId ~= "" and type(map) == "table" and map[castId] or nil, runtime
end

local function queueHelperRefresh()
    if type(Client.QueueAutopilotDMHelperRefresh) == "function" then
        Client:QueueAutopilotDMHelperRefresh()
    end
end

local function registerSettlement(entry)
    if not isAutopilotTimedCast(entry) then
        return nil
    end
    local eventId = tostring(entry.autopilotEventId or "")
    local casterEventId = normalizeEventId(entry.autopilotCasterEventId or entry.casterEventId)
    ensureCastIdentity("client", eventId, casterEventId, entry, entry.startedOnTurnNumber)

    local combatState = type(entry.combatEventState) == "table" and entry.combatEventState or nil
    if type(combatState) ~= "table" or math.max(0, math.floor(tonumber(combatState.pendingDamageCount) or 0)) <= 0 then
        return nil
    end

    local runtime = getRuntimeForEventId(eventId)
    local map = type(runtime) == "table" and ensureSettlementMap(runtime) or nil
    if type(map) ~= "table" then
        return nil
    end

    local castId = tostring(entry.castId or "")
    local settlement = map[castId]
    if type(settlement) ~= "table" then
        settlement = {
            castId = castId,
            eventId = eventId,
            casterEventId = casterEventId,
            castEntry = entry,
            awaitingResources = {},
        }
        map[castId] = settlement
    else
        settlement.castEntry = entry
    end
    runtime.plannerStatus = "waiting-combat-settle"
    runtime.plannerFailureReason = nil
    queueHelperRefresh()
    return settlement
end

local function getPendingDamageCount(settlement)
    local entry = type(settlement) == "table" and settlement.castEntry or nil
    local combatState = type(entry) == "table" and entry.combatEventState or nil
    return math.max(0, math.floor(tonumber(type(combatState) == "table" and combatState.pendingDamageCount or 0) or 0))
end

local function hasAwaitingResources(settlement)
    return type(settlement) == "table"
        and type(settlement.awaitingResources) == "table"
        and next(settlement.awaitingResources) ~= nil
end

local function resourceWaitKey(sender, targetEventId)
    return table.concat({
        normalizeName(sender),
        tostring(normalizeEventId(targetEventId)),
    }, "\31")
end

local function markAwaitingResource(entry, sender, targetEventId)
    local settlement = getCastSettlement(entry)
    local targetId = normalizeEventId(targetEventId)
    local normalizedSender = normalizeName(sender)
    if type(settlement) ~= "table" or targetId <= 0 or normalizedSender == "" then
        return false
    end
    settlement.awaitingResources = type(settlement.awaitingResources) == "table"
        and settlement.awaitingResources
        or {}
    settlement.awaitingResources[resourceWaitKey(normalizedSender, targetId)] = true
    return true
end

local function hasPendingSettlements(eventState)
    local eventId = type(eventState) == "table" and tostring(eventState.id or "") or ""
    local runtime = getRuntimeForEventId(eventId)
    local map = type(runtime) == "table" and runtime.pendingCombatSettlementsByCastId or nil
    return type(map) == "table" and next(map) ~= nil, runtime
end

local function samePlannerStep(left, right)
    return type(left) == "table"
        and type(right) == "table"
        and tostring(left.id or "") == tostring(right.id or "")
        and tonumber(left.turnNumber) == tonumber(right.turnNumber)
        and tonumber(left.tickNumber) == tonumber(right.tickNumber)
end

local function resumePlannerAfterSettlement(runtime)
    local clientEventState = Client.EventState
    local serverEventState = Server.EventState
    if type(runtime) ~= "table"
        or type(clientEventState) ~= "table"
        or type(serverEventState) ~= "table"
        or samePlannerStep(clientEventState, serverEventState) ~= true
    then
        return nil, false, "event-state-not-synchronized"
    end

    local plan, created, reason
    if type(runtime.pendingPlannerClientSync) == "table" then
        plan, created, reason = Client:EnsureAutopilotPlanAfterClientSync(clientEventState)
    else
        plan, created, reason = Client:EnsureAutopilotPlanForCurrentStep(serverEventState)
    end

    if type(plan) == "table" then
        runtime.postSettlementPlanId = tostring(plan.id or "")
        runtime.postSettlementReplanUsed = false
    else
        runtime.postSettlementPlanId = nil
        runtime.postSettlementReplanUsed = nil
    end
    return plan, created, reason
end

local function tryReleaseSettlements(eventId)
    local runtime = getRuntimeForEventId(eventId)
    local map = type(runtime) == "table" and runtime.pendingCombatSettlementsByCastId or nil
    if type(map) ~= "table" then
        return false
    end

    local changed = false
    for castId, settlement in pairs(map) do
        if getPendingDamageCount(settlement) <= 0 and not hasAwaitingResources(settlement) then
            map[castId] = nil
            changed = true
        end
    end

    if next(map) ~= nil then
        runtime.plannerStatus = "waiting-combat-settle"
        if changed then
            queueHelperRefresh()
        end
        return false
    end

    runtime.pendingCombatSettlementsByCastId = nil
    runtime.plannerStatus = type(runtime.pendingPlannerClientSync) == "table"
        and "waiting-client-sync"
        or "ready"
    queueHelperRefresh()
    resumePlannerAfterSettlement(runtime)
    return true
end

local baseEnsureAutopilotPlanAfterClientSync = Client.EnsureAutopilotPlanAfterClientSync
function Client:EnsureAutopilotPlanAfterClientSync(eventStateOverride)
    local eventState = eventStateOverride or self.EventState
    local pending, runtime = hasPendingSettlements(eventState)
    if pending then
        runtime.plannerStatus = "waiting-combat-settle"
        return nil, false, "combat-settlement-pending"
    end
    return baseEnsureAutopilotPlanAfterClientSync(self, eventStateOverride)
end

local baseEnsureAutopilotPlanForCurrentStep = Client.EnsureAutopilotPlanForCurrentStep
function Client:EnsureAutopilotPlanForCurrentStep(eventStateOverride)
    local eventState = eventStateOverride or Server.EventState
    local pending, runtime = hasPendingSettlements(eventState)
    if pending then
        runtime.plannerStatus = "waiting-combat-settle"
        return nil, false, "combat-settlement-pending"
    end
    return baseEnsureAutopilotPlanForCurrentStep(self, eventStateOverride)
end

local function runWithTerminalContext(scope, entry, fn, ...)
    pendingTerminalSendByScope[scope] = entry
    local results = pack(pcall(fn, ...))
    pendingTerminalSendByScope[scope] = nil
    if results[1] ~= true then
        error(results[2], 0)
    end
    return results
end

local baseClientOnSpellcastComplete = Client.OnSpellcastComplete
if type(baseClientOnSpellcastComplete) == "function" then
    function Client:OnSpellcastComplete(spellRef, castEntryOverride, ...)
        local eventState = self.GetEventState and self:GetEventState() or self.EventState
        local entry = castEntryOverride
        if type(entry) ~= "table" and type(eventState) == "table" and type(self.ResolveActiveSpellcasterUnit) == "function" then
            local caster = self:ResolveActiveSpellcasterUnit(eventState)
            if type(caster) == "table" then
                entry = getClientCastEntry(eventState.id, caster.eventID)
            end
        end
        local timedEntry = type(entry) == "table" and tonumber(entry.turnsTotal) ~= nil and entry or nil
        if timedEntry then
            ensureCastIdentity("client", eventState and eventState.id or timedEntry.autopilotEventId, timedEntry.casterEventId, timedEntry, timedEntry.startedOnTurnNumber)
        end

        local results = runWithTerminalContext(
            "client",
            timedEntry,
            baseClientOnSpellcastComplete,
            self,
            spellRef,
            castEntryOverride,
            ...
        )
        if timedEntry then
            recordTerminal("client", timedEntry, eventState and eventState.id or timedEntry.autopilotEventId)
            registerSettlement(timedEntry)
        end
        return unpack(results, 2, results.n)
    end
end

local baseClientOnSpellcastInterrupted = Client.OnSpellcastInterrupted
if type(baseClientOnSpellcastInterrupted) == "function" then
    function Client:OnSpellcastInterrupted(spellRef, castEntryOverride, ...)
        local eventState = self.GetEventState and self:GetEventState() or self.EventState
        local entry = castEntryOverride
        if type(entry) == "table" and tonumber(entry.turnsTotal) ~= nil then
            ensureCastIdentity("client", eventState and eventState.id or entry.autopilotEventId, entry.casterEventId, entry, entry.startedOnTurnNumber)
        else
            entry = nil
        end
        local results = runWithTerminalContext(
            "client",
            entry,
            baseClientOnSpellcastInterrupted,
            self,
            spellRef,
            castEntryOverride,
            ...
        )
        if entry then
            recordTerminal("client", entry, eventState and eventState.id or entry.autopilotEventId)
        end
        return unpack(results, 2, results.n)
    end
end

local baseInterruptUnitSpellcast = Spellcasting.InterruptUnitSpellcast
if type(baseInterruptUnitSpellcast) == "function" then
    function Spellcasting.InterruptUnitSpellcast(self, eventState, targetUnit, options, ...)
        local entry = type(eventState) == "table"
            and type(targetUnit) == "table"
            and getClientCastEntry(eventState.id, targetUnit.eventID)
            or nil
        if type(entry) == "table" then
            ensureCastIdentity("client", eventState.id, targetUnit.eventID, entry, entry.startedOnTurnNumber)
        end
        local results = runWithTerminalContext(
            "client",
            entry,
            baseInterruptUnitSpellcast,
            self,
            eventState,
            targetUnit,
            options,
            ...
        )
        if entry and results[2] == true then
            recordTerminal("client", entry, eventState and eventState.id)
        end
        return unpack(results, 2, results.n)
    end
end

local function wrapServerTerminalMethod(methodName)
    local baseMethod = Server[methodName]
    if type(baseMethod) ~= "function" then
        return
    end
    Server[methodName] = function(self, casterEventId, spellRef, ...)
        local eventState = self.GetEventState and self:GetEventState() or self.EventState
        local entry = type(eventState) == "table" and getServerCastEntry(eventState.id, casterEventId) or nil
        if type(entry) == "table" then
            ensureCastIdentity("server", eventState.id, casterEventId, entry, entry.startedOnTurnNumber or eventState.turnNumber)
        end
        local results = runWithTerminalContext(
            "server",
            entry,
            baseMethod,
            self,
            casterEventId,
            spellRef,
            ...
        )
        if entry then
            recordTerminal("server", entry, eventState and eventState.id)
        end
        return unpack(results, 2, results.n)
    end
end

wrapServerTerminalMethod("OnSpellcastComplete")
wrapServerTerminalMethod("OnSpellcastInterrupted")

local activeReactionCastEntry = nil
local baseQueueClientResourceDeltas = Client.QueueClientResourceDeltas
if type(baseQueueClientResourceDeltas) == "function" then
    function Client:QueueClientResourceDeltas(state, reason, resourceDeltas, targetEventId, options, ...)
        local results = pack(baseQueueClientResourceDeltas(self, state, reason, resourceDeltas, targetEventId, options, ...))
        if results[1] == true
            and tostring(reason or "") == "combat-damage"
            and type(options) == "table"
            and tostring(options.scope or "") == "reaction"
            and type(activeReactionCastEntry) == "table"
        then
            local senderName = type(Spellcasting.GetLocalPlayerName) == "function"
                and Spellcasting.GetLocalPlayerName()
                or ""
            markAwaitingResource(activeReactionCastEntry, senderName, targetEventId)
        end
        return unpack(results, 1, results.n)
    end
end

local function completeMissingLocalDefenceDamageResolution(entry, result)
    if type(entry) ~= "table"
        or entry.localOnly ~= true
        or type(result) ~= "table"
        or result.landed == true
        or type(Combat.CompleteActionDamageResolution) ~= "function"
    then
        return false
    end

    local castEntry = type(entry.context) == "table" and entry.context.castEntry or nil
    local state = type(castEntry) == "table" and castEntry.combatEventState or nil
    local componentKey = tostring(entry.componentKey or "")
    local componentCount = type(state) == "table"
        and type(state.pendingDamageCountByComponentKey) == "table"
        and tonumber(state.pendingDamageCountByComponentKey[componentKey])
        or 0
    if (tonumber(state and state.pendingDamageCount) or 0) <= 0 or componentCount <= 0 then
        return false
    end

    Combat:CompleteActionDamageResolution(Client, entry, false)
    return true
end

local baseResolveCombatReactionAction = Client.ResolveCombatReactionAction
if type(baseResolveCombatReactionAction) == "function" then
    function Client:ResolveCombatReactionAction(actionId, ...)
        local entry = self.ActiveCombatReactionEntry
        local castEntry = type(entry) == "table" and type(entry.context) == "table" and entry.context.castEntry or nil
        activeReactionCastEntry = castEntry
        local results = pack(pcall(baseResolveCombatReactionAction, self, actionId, ...))
        activeReactionCastEntry = nil
        if results[1] ~= true then
            error(results[2], 0)
        end

        if results[2] == true and type(entry) == "table" then
            completeMissingLocalDefenceDamageResolution(entry, results[3])
        end
        if type(castEntry) == "table" and isAutopilotTimedCast(castEntry) then
            tryReleaseSettlements(castEntry.autopilotEventId)
        end
        return unpack(results, 2, results.n)
    end
end

local baseHandleDamageHitCheckResponse = Combat.HandleDamageHitCheckResponse
if type(baseHandleDamageHitCheckResponse) == "function" then
    function Combat:HandleDamageHitCheckResponse(client, arguments, sender, ...)
        local checkId = tostring(arguments and arguments[1] or "")
        local entry = checkId ~= ""
            and type(client) == "table"
            and type(client.GetPendingCombatHitCheck) == "function"
            and client:GetPendingCombatHitCheck(checkId)
            or nil
        local castEntry = type(entry) == "table" and type(entry.context) == "table" and entry.context.castEntry or nil
        local resultToken = tostring(arguments and arguments[3] or "")
        if resultToken == "pass" and type(castEntry) == "table" and isAutopilotTimedCast(castEntry) then
            local expectedSender = type(self.ResolveSenderForUnit) == "function"
                and self:ResolveSenderForUnit(entry.eventState, entry.defenderUnit)
                or sender
            markAwaitingResource(castEntry, expectedSender, entry.defenderEventId)
        end

        local results = pack(baseHandleDamageHitCheckResponse(self, client, arguments, sender, ...))
        if type(castEntry) == "table" and isAutopilotTimedCast(castEntry) then
            tryReleaseSettlements(castEntry.autopilotEventId)
        end
        return unpack(results, 1, results.n)
    end
end

local function clearAwaitingResourcesForTargets(sender, targetEventIds)
    local eventState = Client.GetEventState and Client:GetEventState() or Client.EventState
    local eventId = type(eventState) == "table" and tostring(eventState.id or "") or ""
    local runtime = getRuntimeForEventId(eventId)
    local map = type(runtime) == "table" and runtime.pendingCombatSettlementsByCastId or nil
    if type(map) ~= "table" then
        return false
    end

    local normalizedSender = normalizeName(sender)
    if normalizedSender == "" then
        return false
    end

    local changed = false
    for _, settlement in pairs(map) do
        local waits = type(settlement) == "table" and settlement.awaitingResources or nil
        if type(waits) == "table" then
            for index = 1, #(targetEventIds or {}) do
                local key = resourceWaitKey(normalizedSender, targetEventIds[index])
                if waits[key] == true then
                    waits[key] = nil
                    changed = true
                end
            end
        end
    end
    if changed then
        tryReleaseSettlements(eventId)
    end
    return changed
end

local baseHandleResourceDelta = Client.HandleResourceDelta
if type(baseHandleResourceDelta) == "function" then
    function Client:HandleResourceDelta(arguments, sender, ...)
        local results = pack(baseHandleResourceDelta(self, arguments, sender, ...))
        if results[1] == true then
            local targetEventId = normalizeEventId(arguments and arguments[4])
            if targetEventId > 0 then
                clearAwaitingResourcesForTargets(sender, { targetEventId })
            end
        end
        return unpack(results, 1, results.n)
    end
end

local baseHandleResourceDeltaBatch = Client.HandleResourceDeltaBatch
if type(baseHandleResourceDeltaBatch) == "function" then
    function Client:HandleResourceDeltaBatch(arguments, sender, ...)
        local results = pack(baseHandleResourceDeltaBatch(self, arguments, sender, ...))
        if results[1] == true then
            local targetIds = {}
            local seen = {}
            local payload = arguments and arguments[3] or nil
            local deltas = type(ResourceSync.CoalesceTargetedResourceDeltas) == "function"
                and ResourceSync.CoalesceTargetedResourceDeltas(payload)
                or {}
            for index = 1, #(deltas or {}) do
                local targetEventId = normalizeEventId(deltas[index] and deltas[index].targetEventId)
                if targetEventId > 0 and seen[targetEventId] ~= true then
                    seen[targetEventId] = true
                    targetIds[#targetIds + 1] = targetEventId
                end
            end
            if #targetIds > 0 then
                clearAwaitingResourcesForTargets(sender, targetIds)
            end
        end
        return unpack(results, 1, results.n)
    end
end

local baseCopyCompletedPlan = Planner.CopyCompletedPlan
if type(baseCopyCompletedPlan) == "function" then
    function Planner.CopyCompletedPlan(state)
        local completed = baseCopyCompletedPlan(state)
        if completed ~= nil then
            return completed
        end

        local runtime = type(state) == "table" and state.runtimeRef or nil
        local reason = tostring(type(state) == "table" and type(state.result) == "table" and state.result.reason or "")
        if type(runtime) == "table" then
            runtime.plannerFailureReason = reason ~= "" and reason or nil
        end
        if reason == "snapshot-stale"
            and type(runtime) == "table"
            and tostring(runtime.postSettlementPlanId or "") == tostring(state and state.planId or "")
            and runtime.postSettlementReplanUsed ~= true
        then
            state.__issue135PostSettlementReplan = true
        end
        return nil
    end
end

local baseReleaseScratch = Planner.ReleaseScratch
if type(baseReleaseScratch) == "function" then
    function Planner.ReleaseScratch(state)
        local runtime = type(state) == "table" and state.runtimeRef or nil
        local planId = tostring(type(state) == "table" and state.planId or "")
        local shouldReplan = type(state) == "table" and state.__issue135PostSettlementReplan == true
        local results = pack(baseReleaseScratch(state))

        if shouldReplan
            and type(runtime) == "table"
            and runtime.postSettlementReplanUsed ~= true
            and tostring(runtime.postSettlementPlanId or "") == planId
        then
            runtime.postSettlementReplanUsed = true
            local eventState = Server.EventState
            local pending = hasPendingSettlements(eventState)
            if not pending and samePlannerStep(Client.EventState, eventState) == true then
                local plan = type(Client.ReplaceAutopilotPlanForCurrentStep) == "function"
                    and select(1, Client:ReplaceAutopilotPlanForCurrentStep(eventState))
                    or nil
                runtime.postSettlementPlanId = type(plan) == "table" and tostring(plan.id or "") or nil
            end
        elseif type(runtime) == "table" and tostring(runtime.postSettlementPlanId or "") == planId then
            runtime.postSettlementPlanId = nil
            runtime.postSettlementReplanUsed = nil
        end

        return unpack(results, 1, results.n)
    end
end

local function wrapResetSpellcastingState(owner, scope)
    local baseReset = type(owner) == "table" and owner.ResetSpellcastingState or nil
    if type(baseReset) ~= "function" then
        return
    end
    owner.ResetSpellcastingState = function(self, eventId, ...)
        local results = pack(baseReset(self, eventId, ...))
        clearLifecycleEvent(scope, eventId)
        if scope == "client" then
            local runtime = getRuntimeForEventId(eventId)
            if type(runtime) == "table" then
                runtime.pendingCombatSettlementsByCastId = nil
                runtime.postSettlementPlanId = nil
                runtime.postSettlementReplanUsed = nil
                runtime.plannerFailureReason = nil
            end
        end
        return unpack(results, 1, results.n)
    end
end

wrapResetSpellcastingState(Client, "client")
wrapResetSpellcastingState(Server, "server")

local baseHelperGetStatusLabel = Helper.GetStatusLabel
if type(baseHelperGetStatusLabel) == "function" then
    function Helper.GetStatusLabel(status)
        if tostring(status or "") == "waiting-combat-settle" then
            return "Waiting for combat to resolve"
        end
        return baseHelperGetStatusLabel(status)
    end
end

local baseHelperGetReasonText = Helper.GetReasonText
if type(baseHelperGetReasonText) == "function" then
    function Helper.GetReasonText(reason)
        if tostring(reason or "") == "combat-settlement-pending" then
            return "A timed NPC cast is still resolving combat or authoritative resource state."
        end
        return baseHelperGetReasonText(reason)
    end
end

local function patchStatusEntry(eventState, entries)
    local pending, runtime = hasPendingSettlements(eventState)
    if not pending or type(entries) ~= "table" then
        return entries
    end
    for index = 1, #entries do
        local entry = entries[index]
        if type(entry) == "table" and entry.kind == "status" then
            entry.status = "waiting-combat-settle"
            entry.summary = "Autopilot — Waiting for combat to resolve"
            entry.text = "Autopilot: Waiting for combat to resolve"
            entry.reasonCode = "combat-settlement-pending"
            entry.reasonText = Helper.GetReasonText("combat-settlement-pending")
            entry.details = table.concat({
                "Status: Waiting for combat to resolve",
                "Reason: " .. tostring(entry.reasonText or "combat-settlement-pending"),
                "Reason code: combat-settlement-pending",
            }, "\n")
            break
        end
    end
    if type(runtime) == "table" then
        runtime.plannerStatus = "waiting-combat-settle"
    end
    return entries
end

local baseHelperBuildEntries = Helper.BuildEntries
if type(baseHelperBuildEntries) == "function" then
    function Helper.BuildEntries(eventState)
        return patchStatusEntry(eventState, baseHelperBuildEntries(eventState))
    end
end

local baseHelperBuildOverviewDetails = Helper.BuildOverviewDetails
if type(baseHelperBuildOverviewDetails) == "function" then
    function Helper.BuildOverviewDetails(eventState)
        local details = baseHelperBuildOverviewDetails(eventState)
        local pending = hasPendingSettlements(eventState)
        if not pending then
            return details
        end
        local replacement = "Autopilot — Waiting for combat to resolve"
        local newline = string.find(details or "", "\n", 1, true)
        if newline then
            return replacement .. string.sub(details, newline)
        end
        return replacement .. "\nA timed NPC cast is still resolving combat or authoritative resource state."
    end
end

Lifecycle.EnsureCastIdentity = ensureCastIdentity
Lifecycle.GetPacketIdentity = getPacketIdentity
Lifecycle.RegisterSettlement = registerSettlement
Lifecycle.TryReleaseSettlements = tryReleaseSettlements
Lifecycle.HasPendingSettlements = hasPendingSettlements

return Lifecycle
