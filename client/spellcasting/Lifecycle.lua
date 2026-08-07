local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Client.Spellcasting = Addon.Client.Spellcasting or {}
Addon.Internal = Addon.Internal or {}
Addon.Utils = Addon.Utils or {}

local Client = Addon.Client
local Comms = Addon.Internal.Comms or {}
local Operations = Comms.Operations or {}
local Registry = Addon.Internal.Registry or {}
local Spellcasting = Client.Spellcasting
local Conditions = Client.Conditions or {}

local SPELLCAST_START_OPCODE = Operations:GetOpcode("SPELLCAST_START")
local SPELLCAST_COMPLETE_OPCODE = Operations:GetOpcode("SPELLCAST_COMPLETE")
local SPELLCAST_INTERRUPT_OPCODE = Operations:GetOpcode("SPELLCAST_INTERRUPT")

local function getTasks()
    return Addon.Internal and Addon.Internal.Tasks or nil
end

local function enqueueSpellcastWork(fn, ...)
    local tasks = getTasks()
    if tasks and tasks.Enqueue then
        tasks:Enqueue(fn, ...)
        return true
    end

    if C_Timer and C_Timer.After then
        local args = { ... }
        local argCount = select("#", ...)
        C_Timer.After(0, function()
            fn(unpack(args, 1, argCount))
        end)
        return true
    end

    fn(...)
    return true
end

local function getNowMilliseconds()
    if type(debugprofilestop) == "function" then
        return debugprofilestop()
    end

    return (os.clock() or 0) * 1000
end

local function isSpellcastTimingEnabled()
    return type(Addon.Debug) == "table" and Addon.Debug.SpellcastTiming == true
end

local function logSpellcastTiming(spellRef, phases)
    if not isSpellcastTimingEnabled() or type(Debug) ~= "table" or type(Debug.Internal) ~= "function" then
        return false
    end

    local parts = {}
    for index = 1, #(phases or {}) do
        local phase = phases[index]
        if type(phase) == "table" and type(phase.label) == "string" then
            parts[#parts + 1] = ("%s=%.2fms"):format(phase.label, tonumber(phase.elapsed) or 0)
        end
    end

    Debug.Internal(
        "Spellcast timing [%s]: %s",
        tostring(spellRef or ""),
        table.concat(parts, ", ")
    )
    return true
end

local function sendSpellcastPacket(channelId, opcode, arguments)
    if type(Comms.SendToChannel) ~= "function" then
        return false
    end

    return Comms:SendToChannel(channelId, opcode, arguments, Spellcasting.BuildSendMetadata(opcode))
end

local function getActiveContext(self)
    return Spellcasting.GetActiveSpellcastContext(self)
end

local function findEventUnitById(units, targetEventId)
    local numericTargetEventId = tonumber(targetEventId) or 0
    if numericTargetEventId <= 0 then
        return nil
    end

    for index = 1, #(units or {}) do
        local unit = units[index]
        if tonumber(unit and unit.eventID) == numericTargetEventId then
            return unit
        end
    end

    return nil
end

local function resolveLifecycleCasterUnit(client, eventState, castEntry, fallbackUnit)
    local numericCasterEventId = tonumber(type(castEntry) == "table" and castEntry.casterEventId or nil) or 0
    if numericCasterEventId > 0 then
        local eventUnit = findEventUnitById(type(eventState) == "table" and eventState.units or nil, numericCasterEventId)
        if type(eventUnit) == "table" then
            return eventUnit
        end
    end

    if type(fallbackUnit) == "table" then
        return fallbackUnit
    end

    return nil
end

local function resolveLifecycleTargetUnit(eventState, castEntry)
    local focusedTargetEventId = tonumber(type(castEntry) == "table" and castEntry.focusedTargetEventId or nil) or 0
    if focusedTargetEventId > 0 then
        return findEventUnitById(type(eventState) == "table" and eventState.units or nil, focusedTargetEventId)
    end

    for index = 1, #(type(castEntry) == "table" and castEntry.targetEventIds or {}) do
        local targetUnit = findEventUnitById(type(eventState) == "table" and eventState.units or nil, castEntry.targetEventIds[index])
        if type(targetUnit) == "table" then
            return targetUnit
        end
    end

    return nil
end

local function evaluateLifecycleSpellConditions(spellRef, spell, sessionState, eventState, casterUnit, targetUnit)
    if type(Conditions.EvaluateList) ~= "function" or type(spell) ~= "table" then
        return {
            passed = true,
            failureText = "",
        }
    end

    local context = Conditions:BuildContext("spell", spell, {
        ownerRef = spellRef,
        spellRef = spellRef,
        sessionState = sessionState,
        eventState = eventState,
        casterUnit = casterUnit,
        targetUnit = targetUnit,
    })
    local authored = Conditions:EvaluateList(spell.conditions, context)
    if authored.passed ~= true then
        return authored
    end

    return Conditions:EvaluateList(Conditions:BuildSpellResourceConditions(spell, {
        allowHealth = false,
    }), context)
end

local function refreshSpellcastVisualState(reason, casterEventId)
    Spellcasting.RefreshVisiblePlayerTooltip(reason)

    local numericCasterEventId = tonumber(casterEventId) or 0
    if numericCasterEventId > 0 and type(Client.QueueEventWidgetTargetedRefresh) == "function" then
        Client:QueueEventWidgetTargetedRefresh(reason, { numericCasterEventId })
    elseif numericCasterEventId > 0 and type(Client.RefreshEventWidgetPortraits) == "function" then
        Client:RefreshEventWidgetPortraits({
            [numericCasterEventId] = true,
        }, reason)
    elseif type(Client.QueueEventWidgetRefresh) == "function" then
        Client:QueueEventWidgetRefresh(reason)
    end
end

local function queueSpellcastResourceVisualSync(client, eventState, eventUnit, payload, reason)
    if type(client) ~= "table" or type(payload) ~= "table" or #payload == 0 then
        return false
    end

    return enqueueSpellcastWork(function(targetClient, queuedEventState, queuedEventUnit, queuedPayload, queuedReason)
        if type(Spellcasting.RefreshLocalResourceDisplays) == "function" then
            Spellcasting.RefreshLocalResourceDisplays(queuedReason or "spellcast-resource")
        end
        if type(Spellcasting.ShowLocalResourceDeltaCombatText) == "function" then
            Spellcasting.ShowLocalResourceDeltaCombatText(
                targetClient,
                queuedEventState,
                queuedEventUnit,
                queuedEventUnit,
                queuedPayload,
                "ability",
                nil
            )
        end
    end, client, eventState, eventUnit, payload, reason)
end

local function resolveSpellcastActivationSnapshot(client, spellRef, activationSnapshot)
    if type(client) ~= "table" then
        return nil
    end

    if type(activationSnapshot) == "table"
        and tostring(activationSnapshot.spellRef or "") == tostring(spellRef or "")
        and type(Spellcasting.IsSpellActivationSnapshotValid) == "function"
        and Spellcasting.IsSpellActivationSnapshotValid(client, activationSnapshot)
    then
        return activationSnapshot
    end

    if type(client.ResolveSpellActivationSnapshot) == "function" then
        return client:ResolveSpellActivationSnapshot(spellRef)
    end

    return nil
end

local function sendSpellcasterResourceSync(self, eventUnit, reason, resourceDeltas)
    local sessionState = self.GetState and self:GetState() or nil
    local eventState = self.GetEventState and self:GetEventState() or nil
    local controlledEventId = tonumber(eventUnit and eventUnit.eventID) or 0
    if not sessionState or sessionState.active ~= true or not eventState or eventState.active ~= true or controlledEventId <= 0 then
        return false
    end

    local payload = Spellcasting.BuildResourceDeltaPayload(resourceDeltas)
    if type(payload) ~= "table" or #payload == 0 then
        return false
    end

    if type(self.QueueClientResourceDeltas) ~= "function" then
        return false
    end

    local queued = self:QueueClientResourceDeltas(sessionState, reason or "spellcast-resource", payload, controlledEventId)
    if queued then
        queueSpellcastResourceVisualSync(self, eventState, eventUnit, payload, reason)
    end
    return queued
end

local function queueLocalInstantSpellcastCompletion(targetClient, spellRef, castEntryOverride)
    local enqueued = enqueueSpellcastWork(function(client, queuedSpellRef, queuedCastEntry)
        if type(client) ~= "table" or type(client.OnSpellcastComplete) ~= "function" then
            return
        end

        client:OnSpellcastComplete(queuedSpellRef, queuedCastEntry)
    end, targetClient, spellRef, castEntryOverride)
    if enqueued then
        return true
    end

    return targetClient.OnSpellcastComplete and targetClient:OnSpellcastComplete(spellRef, castEntryOverride) or false
end

function Spellcasting.InterruptUnitSpellcast(self, eventState, targetUnit, options)
    local sessionState = self.GetState and self:GetState() or nil
    local numericTargetEventId = tonumber(targetUnit and targetUnit.eventID) or 0
    if type(eventState) ~= "table" or eventState.active ~= true or numericTargetEventId <= 0 then
        return false
    end

    local activeEntry = Spellcasting.GetCastEntry and Spellcasting.GetCastEntry(self, eventState.id, numericTargetEventId) or nil
    if type(activeEntry) ~= "table" or type(activeEntry.spellRef) ~= "string" or activeEntry.spellRef == "" then
        return false
    end

    local removedEntry = Spellcasting.RemoveCastEntry and Spellcasting.RemoveCastEntry(self, eventState.id, numericTargetEventId) or activeEntry
    refreshSpellcastVisualState("spellcast-interrupt-effect", numericTargetEventId)

    local channelId = sessionState and Spellcasting.ResolveSessionChannelId(sessionState) or nil
    if channelId then
        sendSpellcastPacket(channelId, SPELLCAST_INTERRUPT_OPCODE, {
            sessionState.channelName,
            eventState.id,
            numericTargetEventId,
            removedEntry.spellRef,
            targetUnit.isPlayer == true and "player" or "npc",
        })
    end

    return true, removedEntry
end

function Client:HandleSpellcastStart(arguments, sender)
    local payload = Spellcasting.ValidateInboundSpellcast and Spellcasting.ValidateInboundSpellcast(self, arguments, sender) or nil
    if not payload then
        return false
    end

    if payload.castTurns == nil then
        return false
    end

    local suppressLog = Spellcasting.ShouldSuppressLoopbackLog and Spellcasting.ShouldSuppressLoopbackLog(
        self,
        payload.eventId,
        payload.casterEventId,
        payload.spellRef,
        payload.authorityType,
        payload.sender,
        "start"
    )
    local entry = Spellcasting.BuildCastEntry(
        payload.spellRef,
        Spellcasting.ResolveSpellName(payload.spellRef),
        payload.authorityType,
        payload.casterEventId,
        payload.castTurns,
        payload.eventState.turnNumber
    )
    if not entry then
        return false
    end

    local existing = Spellcasting.GetCastEntry and Spellcasting.GetCastEntry(self, payload.eventId, payload.casterEventId) or nil
    if suppressLog and existing then
        entry.targetSelections = existing.targetSelections
        entry.targetSelectionOrder = existing.targetSelectionOrder
        entry.targetEventIds = existing.targetEventIds
        entry.focusedTargetEventId = existing.focusedTargetEventId
        entry.targetPolicy = existing.targetPolicy
        entry.resolvedStartCostAmounts = existing.resolvedStartCostAmounts
    end

    Spellcasting.SetCastEntry(self, payload.eventId, payload.casterEventId, entry)

    if not suppressLog then
        Spellcasting.LogLifecycle("start", payload.authorityType, payload.casterUnit.name, Spellcasting.ResolveSpellName(payload.spellRef), payload.castTurns)
        refreshSpellcastVisualState("spellcast-start", payload.casterEventId)
    end
    return true
end

function Client:HandleSpellcastComplete(arguments, sender)
    local payload = Spellcasting.ValidateInboundSpellcast and Spellcasting.ValidateInboundSpellcast(self, arguments, sender) or nil
    if not payload then
        return false
    end

    local previous = Spellcasting.RemoveCastEntry(self, payload.eventId, payload.casterEventId)
    local suppressLog = Spellcasting.ShouldSuppressLoopbackLog(self, payload.eventId, payload.casterEventId, payload.spellRef, payload.authorityType, payload.sender, "complete")
    if not suppressLog then
        Spellcasting.LogLifecycle(
            "complete",
            payload.authorityType,
            payload.casterUnit.name,
            (previous and previous.spellName) or Spellcasting.ResolveSpellName(payload.spellRef)
        )
        refreshSpellcastVisualState("spellcast-complete", payload.casterEventId)
    end
    return true
end

function Client:HandleSpellcastInterrupt(arguments, sender)
    local payload = Spellcasting.ValidateInboundSpellcast and Spellcasting.ValidateInboundSpellcast(self, arguments, sender) or nil
    if not payload then
        return false
    end

    local previous = Spellcasting.RemoveCastEntry(self, payload.eventId, payload.casterEventId)
    local suppressLog = Spellcasting.ShouldSuppressLoopbackLog(self, payload.eventId, payload.casterEventId, payload.spellRef, payload.authorityType, payload.sender, "interrupt")
    if not suppressLog then
        Spellcasting.LogLifecycle(
            "interrupt",
            payload.authorityType,
            payload.casterUnit.name,
            (previous and previous.spellName) or Spellcasting.ResolveSpellName(payload.spellRef)
        )
        refreshSpellcastVisualState("spellcast-interrupt", payload.casterEventId)
    end
    return true
end

function Client:OnSpellcastStart(spellRef, castTime, activationSnapshot)
    local timingEnabled = isSpellcastTimingEnabled()
    local timingPhases = timingEnabled and {} or nil
    local totalStartTime = timingEnabled and getNowMilliseconds() or nil

    local sessionState, eventState = getActiveContext(self)
    if not sessionState or not eventState then
        return false
    end

    local channelId = Spellcasting.ResolveSessionChannelId(sessionState)
    if not channelId then
        return false
    end

    local activationStartTime = timingEnabled and getNowMilliseconds() or nil
    local snapshot = resolveSpellcastActivationSnapshot(self, spellRef, activationSnapshot)
    if timingEnabled then
        timingPhases[#timingPhases + 1] = {
            label = "activation",
            elapsed = getNowMilliseconds() - activationStartTime,
        }
    end
    if type(snapshot) ~= "table" or snapshot.canCast ~= true then
        return false
    end

    local validationStartTime = timingEnabled and getNowMilliseconds() or nil
    local casterUnit = snapshot.casterUnit
    local activeEventState = snapshot.eventState or eventState
    local dataset = snapshot.dataset
    local spell = snapshot.spell
    if not casterUnit or not dataset or not spell then
        return false
    end

    local queuedTargetSelection = Spellcasting.PeekQueuedSpellTargetSelection and Spellcasting.PeekQueuedSpellTargetSelection(self, spellRef) or nil
    local queuedTargetUnit = resolveLifecycleTargetUnit(activeEventState or eventState, queuedTargetSelection)
    local conditionState = snapshot.conditionState
    if queuedTargetUnit ~= nil then
        conditionState = evaluateLifecycleSpellConditions(spellRef, spell, sessionState, activeEventState or eventState, casterUnit, queuedTargetUnit)
    end
    if conditionState and conditionState.passed ~= true then
        return false
    end

    local auraManager = self.Spellcasting and self.Spellcasting.AuraManager or nil
    if auraManager
        and type(auraManager.CanUnitCast) == "function"
        and auraManager:CanUnitCast(eventState, casterUnit.eventID) ~= true
    then
        return false
    end
    if timingEnabled then
        timingPhases[#timingPhases + 1] = {
            label = "validate",
            elapsed = getNowMilliseconds() - validationStartTime,
        }
    end

    local numericCastTime = Spellcasting.NormalizeTurnCount(castTime)
    if numericCastTime == nil then
        numericCastTime = Spellcasting.NormalizeTurnCount(spell.totalTicks) or Spellcasting.NormalizeTurnCount(spell.castTime)
    end

    local startCosts = snapshot.startCosts or Spellcasting.GetSpellResourceCostsForPhase(spell, "on_cast_start")
    local resolvedStartCostAmounts = nil
    if #startCosts > 0 then
        local resourceStartTime = timingEnabled and getNowMilliseconds() or nil
        local applied, updates, resolvedAmounts = Spellcasting.ApplySpellResourceCostsToUnit(casterUnit, spell, "on_cast_start", false)
        if not applied then
            return false
        end

        resolvedStartCostAmounts = resolvedAmounts
        sendSpellcasterResourceSync(self, casterUnit, "spellcast-start-resource", updates)
        if timingEnabled then
            timingPhases[#timingPhases + 1] = {
                label = "resources",
                elapsed = getNowMilliseconds() - resourceStartTime,
            }
        end
    end

    if self.ApplyLocalSpellCooldown then
        local cooldownStartTime = timingEnabled and getNowMilliseconds() or nil
        self:ApplyLocalSpellCooldown(eventState, casterUnit, spellRef, spell)
        if timingEnabled then
            timingPhases[#timingPhases + 1] = {
                label = "cooldown",
                elapsed = getNowMilliseconds() - cooldownStartTime,
            }
        end
    end

    if numericCastTime == nil then
        local instantCastEntry = Spellcasting.ConsumeQueuedSpellTargetSelection and Spellcasting.ConsumeQueuedSpellTargetSelection(self, spellRef) or nil
        if timingEnabled then
            timingPhases[#timingPhases + 1] = {
                label = "schedule",
                elapsed = math.max(0, getNowMilliseconds() - (totalStartTime or 0)),
            }
            logSpellcastTiming(spellRef, timingPhases)
        end
        return queueLocalInstantSpellcastCompletion(self, spellRef, instantCastEntry)
    end

    local entry = Spellcasting.BuildCastEntryWithSelection(
        self,
        spellRef,
        Spellcasting.ResolveSpellName(spellRef),
        casterUnit.isPlayer == true and "player" or "npc",
        casterUnit.eventID,
        numericCastTime,
        activeEventState and activeEventState.turnNumber or eventState.turnNumber
    )
    if not entry then
        return false
    end

    entry.resolvedStartCostAmounts = resolvedStartCostAmounts

    Spellcasting.SetCastEntry(self, eventState.id, casterUnit.eventID, entry)
    Spellcasting.LogLifecycle("start", casterUnit.isPlayer == true and "player" or "npc", casterUnit.name, Spellcasting.ResolveSpellName(spellRef), numericCastTime)
    refreshSpellcastVisualState("spellcast-start-local", casterUnit.eventID)
    if timingEnabled then
        timingPhases[#timingPhases + 1] = {
            label = "schedule",
            elapsed = getNowMilliseconds() - (totalStartTime or 0),
        }
        logSpellcastTiming(spellRef, timingPhases)
    end

    return sendSpellcastPacket(channelId, SPELLCAST_START_OPCODE, {
        sessionState.channelName,
        eventState.id,
        casterUnit.eventID,
        spellRef,
        numericCastTime,
        casterUnit.isPlayer == true and "player" or "npc",
    })
end

function Client:OnSpellcastComplete(spellRef, castEntryOverride)
    local sessionState, eventState = getActiveContext(self)
    if not sessionState or not eventState then
        return false
    end

    local channelId = Spellcasting.ResolveSessionChannelId(sessionState)
    if not channelId then
        return false
    end

    local activeCasterUnit = self:ResolveActiveSpellcasterUnit(eventState)
    local candidateEntry = castEntryOverride
    if type(candidateEntry) ~= "table" and type(Spellcasting.GetCastEntry) == "function" and type(activeCasterUnit) == "table" then
        candidateEntry = Spellcasting.GetCastEntry(self, eventState.id, tonumber(activeCasterUnit.eventID) or 0)
    end
    local casterUnit = resolveLifecycleCasterUnit(self, eventState, candidateEntry, activeCasterUnit)
    local dataset, spell = nil, nil
    if Registry.ResolveSpellReference then
        dataset, spell = Registry:ResolveSpellReference(spellRef)
    end
    if not casterUnit or not dataset or not spell then
        return false
    end

    local targetUnit = resolveLifecycleTargetUnit(eventState, candidateEntry)
    local conditionState = evaluateLifecycleSpellConditions(spellRef, spell, sessionState, eventState, casterUnit, targetUnit)
    if conditionState and conditionState.passed ~= true then
        return false
    end

    local endCosts = Spellcasting.GetSpellResourceCostsForPhase(spell, "on_cast_end")
    if #endCosts > 0 then
        local applied, updates = Spellcasting.ApplySpellResourceCostsToUnit(casterUnit, spell, "on_cast_end", false)
        if applied then
            sendSpellcasterResourceSync(self, casterUnit, "spellcast-complete-resource", updates)
        end
    end

    local previous = Spellcasting.RemoveCastEntry(self, eventState.id, casterUnit.eventID)
    local castEntry = previous or castEntryOverride or (Spellcasting.ConsumeQueuedSpellTargetSelection and Spellcasting.ConsumeQueuedSpellTargetSelection(self, spellRef)) or nil
    Spellcasting.ExecuteSpellComponentsForPhase(self, eventState, casterUnit, dataset, spell, spellRef, "on_cast_end", castEntry)
    Spellcasting.LogLifecycle("complete", casterUnit.isPlayer == true and "player" or "npc", casterUnit.name, (previous and previous.spellName) or Spellcasting.ResolveSpellName(spellRef))
    refreshSpellcastVisualState("spellcast-complete-local", casterUnit.eventID)

    return sendSpellcastPacket(channelId, SPELLCAST_COMPLETE_OPCODE, {
        sessionState.channelName,
        eventState.id,
        casterUnit.eventID,
        spellRef,
        casterUnit.isPlayer == true and "player" or "npc",
    })
end

function Client:OnSpellcastInterrupted(spellRef, castEntryOverride)
    local sessionState, eventState = getActiveContext(self)
    if not sessionState or not eventState then
        return false
    end

    local channelId = Spellcasting.ResolveSessionChannelId(sessionState)
    if not channelId then
        return false
    end

    local activeCasterUnit = self:ResolveActiveSpellcasterUnit(eventState)
    local existingEntry = castEntryOverride
    if type(existingEntry) ~= "table" and type(Spellcasting.GetCastEntry) == "function" and type(activeCasterUnit) == "table" then
        existingEntry = Spellcasting.GetCastEntry(self, eventState.id, tonumber(activeCasterUnit.eventID) or 0)
    end
    local casterUnit = resolveLifecycleCasterUnit(self, eventState, existingEntry, activeCasterUnit)
    local dataset, spell = nil, nil
    if Registry.ResolveSpellReference then
        dataset, spell = Registry:ResolveSpellReference(spellRef)
    end
    if not casterUnit or not dataset or not spell then
        return false
    end

    local previousEntry = Spellcasting.GetCastEntry and Spellcasting.GetCastEntry(self, eventState.id, casterUnit.eventID) or existingEntry or nil
    local originalCosts = {}
    for index = 1, #(spell.resourceCosts or {}) do
        local cost = spell.resourceCosts[index]
        if type(cost) == "table" then
            originalCosts[index] = {
                resourceRef = cost.resourceRef,
                castPhase = cost.castPhase,
                amountMode = cost.amountMode,
                refundOnInterrupt = cost.refundOnInterrupt,
                amount = cost.amount,
            }
        end
    end
    if previousEntry and type(previousEntry.resolvedStartCostAmounts) == "table" then
        for index = 1, #originalCosts do
            local resolvedAmount = previousEntry.resolvedStartCostAmounts[index]
            if resolvedAmount ~= nil and type(originalCosts[index]) == "table" then
                originalCosts[index] = {
                    resourceRef = originalCosts[index].resourceRef,
                    castPhase = originalCosts[index].castPhase,
                    amountMode = "flat",
                    refundOnInterrupt = originalCosts[index].refundOnInterrupt,
                    amount = resolvedAmount,
                }
            end
        end
    end

    local interruptSpell = previousEntry and previousEntry.resolvedStartCostAmounts and {
        resourceCosts = originalCosts,
    } or spell
    local applied, updates = Spellcasting.ApplySpellResourceCostsToUnit(casterUnit, interruptSpell, "on_cast_start", true)
    if applied then
        sendSpellcasterResourceSync(self, casterUnit, "spellcast-interrupt-resource", updates)
    end

    local previous = Spellcasting.RemoveCastEntry(self, eventState.id, casterUnit.eventID)
    Spellcasting.LogLifecycle("interrupt", casterUnit.isPlayer == true and "player" or "npc", casterUnit.name, (previous and previous.spellName) or Spellcasting.ResolveSpellName(spellRef))
    refreshSpellcastVisualState("spellcast-interrupt-local", casterUnit.eventID)

    return sendSpellcastPacket(channelId, SPELLCAST_INTERRUPT_OPCODE, {
        sessionState.channelName,
        eventState.id,
        casterUnit.eventID,
        spellRef,
        casterUnit.isPlayer == true and "player" or "npc",
    })
end

function Client:OnSpellcastChannelTick(spellRef)
    local eventState = self.GetEventState and self:GetEventState() or nil
    if not eventState or eventState.active ~= true then
        return false
    end

    local casterUnit = self:ResolveActiveSpellcasterUnit(eventState)
    if not casterUnit then
        return false
    end

    Spellcasting.LogLifecycle("channel-tick", casterUnit.isPlayer == true and "player" or "npc", casterUnit.name, Spellcasting.ResolveSpellName(spellRef))
    return true
end
