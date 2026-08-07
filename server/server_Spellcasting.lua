local _, Addon = ...

Addon.Server = Addon.Server or {}
Addon.Internal = Addon.Internal or {}
Addon.Utils = Addon.Utils or {}

local Server = Addon.Server
local Debug = Addon.Debug
local Common = Addon.Utils.Common or {}
local Comms = Addon.Internal.Comms or {}
local Operations = Comms.Operations or {}
local Registry = Addon.Internal.Registry or {}
local Profile = Addon.Internal.Profile or {}
local function getEventClass()
    return Addon.Internal
        and Addon.Internal.Database
        and Addon.Internal.Database.Classes
        and Addon.Internal.Database.Classes.Event
        or nil
end

local SPELLCAST_START_OPCODE = Operations:GetOpcode("SPELLCAST_START")
local SPELLCAST_COMPLETE_OPCODE = Operations:GetOpcode("SPELLCAST_COMPLETE")
local SPELLCAST_INTERRUPT_OPCODE = Operations:GetOpcode("SPELLCAST_INTERRUPT")

Server.ActiveSpellcastsByEventId = Server.ActiveSpellcastsByEventId or {}

local function normalizeName(name)
    if Common.NormalizeName then
        return Common.NormalizeName(name)
    end

    return type(name) == "string" and name or ""
end

local function getLocalPlayerName()
    return normalizeName(Common.GetPlayerName and Common.GetPlayerName() or nil)
end

local function buildSendMetadata(opcode)
    return {
        opcode = opcode,
        scope = "server",
    }
end

local function resolveOutboundSessionChannelId(sessionState)
    if not sessionState then
        return nil
    end

    local channelId = nil
    if type(sessionState.channelName) == "string" and sessionState.channelName ~= "" and Comms.ResolveChannelId then
        channelId = Comms:ResolveChannelId(sessionState.channelName)
    end

    if (channelId == nil or channelId == "") then
        channelId = sessionState.channelId
    end

    if channelId ~= nil and channelId ~= "" then
        sessionState.channelId = channelId
    end

    return channelId
end

local function buildSelectedPetSummonOptions(unitRef, sender)
    local selectedPet = type(Profile.GetSelectedPet) == "function" and Profile.GetSelectedPet() or nil
    if type(selectedPet) ~= "table" or selectedPet.isActive ~= true or selectedPet.hasUnit ~= true then
        return {
            ownerID = sender,
        }
    end

    local selectedUnitRef = tostring(selectedPet.unitRef or "")
    if selectedUnitRef == "" or selectedUnitRef ~= tostring(unitRef or "") then
        return {
            ownerID = sender,
        }
    end

    return {
        ownerID = sender,
        petRef = selectedPet.ref,
        stats = type(Profile.BuildSelectedPetRuntimeStats) == "function" and Profile.BuildSelectedPetRuntimeStats() or nil,
    }
end

local function getEventCastBucket(self, eventId, createIfMissing)
    local normalizedEventId = type(eventId) == "string" and eventId or ""
    if normalizedEventId == "" then
        return nil
    end

    self.ActiveSpellcastsByEventId = self.ActiveSpellcastsByEventId or {}
    local bucket = self.ActiveSpellcastsByEventId[normalizedEventId]
    if bucket or not createIfMissing then
        return bucket
    end

    bucket = {}
    self.ActiveSpellcastsByEventId[normalizedEventId] = bucket
    return bucket
end

local function clearEventCastBucket(self, eventId)
    local normalizedEventId = type(eventId) == "string" and eventId or ""
    if normalizedEventId == "" or type(self.ActiveSpellcastsByEventId) ~= "table" then
        return
    end

    self.ActiveSpellcastsByEventId[normalizedEventId] = nil
end

local function getCastEntry(self, eventId, casterEventId)
    local bucket = getEventCastBucket(self, eventId, false)
    if not bucket then
        return nil
    end

    return bucket[tonumber(casterEventId) or 0]
end

local function setCastEntry(self, eventId, casterEventId, value)
    local numericCasterEventId = tonumber(casterEventId) or 0
    if numericCasterEventId <= 0 then
        return nil
    end

    local bucket = getEventCastBucket(self, eventId, value ~= nil)
    if not bucket then
        return nil
    end

    bucket[numericCasterEventId] = value
    return value
end

local function removeCastEntry(self, eventId, casterEventId)
    local bucket = getEventCastBucket(self, eventId, false)
    if not bucket then
        return nil
    end

    local numericCasterEventId = tonumber(casterEventId) or 0
    if numericCasterEventId <= 0 then
        return nil
    end

    local previous = bucket[numericCasterEventId]
    bucket[numericCasterEventId] = nil
    if next(bucket) == nil then
        clearEventCastBucket(self, eventId)
    end
    return previous
end

local function findEventUnitById(units, eventId)
    local numericEventId = tonumber(eventId) or 0
    if numericEventId <= 0 then
        return nil
    end

    for index = 1, #(units or {}) do
        local unit = units[index]
        if tonumber(unit and unit.eventID) == numericEventId then
            return unit, index
        end
    end

    return nil
end

local function resolveControllerPlayerUnit(eventState, casterUnit)
    local controllerId = tonumber(casterUnit and casterUnit.controllerID) or 0
    if controllerId <= 0 or type(eventState) ~= "table" then
        return nil
    end

    for index = 1, #((eventState.units) or {}) do
        local unit = eventState.units[index]
        if unit and unit.isPlayer == true and tonumber(unit.eventID) == controllerId then
            return unit
        end
    end

    return nil
end

local function resolveSpellName(spellRef)
    if Registry.ResolveSpellName then
        return Registry:ResolveSpellName(spellRef)
    end

    return type(spellRef) == "string" and spellRef or "unknown-spell"
end

local function isEventUnitActive(unit)
    local eventClass = getEventClass()
    if eventClass and eventClass.IsUnitActive then
        return eventClass.IsUnitActive(unit)
    end

    local eventUnitClass = Addon.Internal
        and Addon.Internal.Database
        and Addon.Internal.Database.Classes
        and Addon.Internal.Database.Classes.EventUnit
        or nil
    if type(unit) ~= "table" then
        return false
    end
    if unit.isPlayer == true then
        return true
    end
    if eventUnitClass and eventUnitClass.CoerceBoolean then
        return eventUnitClass.CoerceBoolean(unit.active, true)
    end

    if unit.active == nil then
        return true
    end

    if unit.active == true or unit.active == false then
        return unit.active
    end

    local numericValue = tonumber(unit.active)
    if numericValue ~= nil then
        return numericValue ~= 0
    end

    local normalized = type(unit.active) == "string" and string.lower(unit.active) or nil
    if normalized == "false" or normalized == "no" or normalized == "off" then
        return false
    end

    return true
end

local function normalizeTurnCount(turnCount)
    local numericTurns = tonumber(turnCount)
    if numericTurns == nil or numericTurns <= 0 then
        return nil
    end

    return math.max(1, math.ceil(numericTurns))
end

local function resolveSpellcastTurns(spell, turnCount)
    local resolvedTurns = normalizeTurnCount(turnCount)
    if resolvedTurns ~= nil then
        return resolvedTurns
    end

    if type(spell) ~= "table" then
        return nil
    end

    resolvedTurns = normalizeTurnCount(spell.totalTicks)
    if resolvedTurns ~= nil then
        return resolvedTurns
    end

    return normalizeTurnCount(spell.castTime)
end

local function formatTurnCount(turnCount)
    local numericTurns = math.max(0, tonumber(turnCount) or 0)
    local displayTurns = math.max(1, math.ceil(numericTurns))
    if displayTurns == 1 then
        return "1 turn"
    end

    return ("%d turns"):format(displayTurns)
end

local function logLifecycle(phase, authorityType, casterName, spellName, turnCount)
    return false
end

local function validateInboundSpellcast(self, arguments, sender)
    local sessionState = self.GetState and self:GetState() or nil
    local eventState = self.GetEventState and self:GetEventState() or nil
    if not sessionState or sessionState.active ~= true or not eventState or eventState.active ~= true then
        return nil
    end

    local channelName = arguments and arguments[1] or nil
    if type(channelName) ~= "string" or channelName == "" or channelName ~= sessionState.channelName then
        return nil
    end

    local eventId = arguments and arguments[2] or nil
    if type(eventId) ~= "string" or eventId == "" or eventState.id ~= eventId then
        return nil
    end

    local casterEventId = tonumber(arguments and arguments[3]) or 0
    if casterEventId <= 0 then
        return nil
    end

    local spellRef = arguments and arguments[4] or nil
    local dataset, spell = nil, nil
    if Registry.ResolveSpellReference then
        dataset, spell = Registry:ResolveSpellReference(spellRef)
    end
    if not dataset or not spell then
        return nil
    end

    local authorityType = tostring(arguments and arguments[6] or arguments and arguments[5] or "")
    if authorityType ~= "player" and authorityType ~= "npc" then
        return nil
    end

    local casterUnit = findEventUnitById(eventState.units, casterEventId)
    if not casterUnit or not isEventUnitActive(casterUnit) then
        return nil
    end

    if authorityType == "player" and casterUnit.isPlayer ~= true then
        return nil
    end

    if authorityType == "npc" and casterUnit.isPlayer == true then
        return nil
    end

    local normalizedSender = normalizeName(sender)
    if authorityType == "player" then
        local expectedSender = normalizeName(casterUnit.ownerID or casterUnit.controllerID or casterUnit.name)
        if normalizedSender == "" or expectedSender == "" or normalizedSender ~= expectedSender then
            return nil
        end
    else
        local controllerUnit = resolveControllerPlayerUnit(eventState, casterUnit)
        local expectedHost = normalizeName(controllerUnit and (controllerUnit.ownerID or controllerUnit.controllerID or controllerUnit.name) or nil)
        if normalizedSender == "" or expectedHost == "" or normalizedSender ~= expectedHost then
            return nil
        end
    end

    return {
        sessionState = sessionState,
        eventState = eventState,
        channelName = channelName,
        eventId = eventId,
        casterEventId = casterEventId,
        casterUnit = casterUnit,
        spellRef = spellRef,
        spell = spell,
        authorityType = authorityType,
        sender = normalizedSender,
        castTurns = normalizeTurnCount(arguments and arguments[5]),
    }
end

local function shouldSuppressLoopbackLog(self, eventId, casterEventId, spellRef, authorityType, sender, phase)
    if normalizeName(sender) ~= getLocalPlayerName() then
        return false
    end

    if authorityType == "player" then
        return true
    end

    local existing = getCastEntry(self, eventId, casterEventId)
    if phase == "start" then
        return existing ~= nil
            and existing.spellRef == spellRef
            and existing.authorityType == authorityType
    end

    if phase == "complete" or phase == "interrupt" then
        return existing == nil
    end

    return false
end

local function executeSummonPetComponents(self, payload)
    if type(self.SummonEventPetUnit) ~= "function" or type(payload) ~= "table" or type(payload.spell) ~= "table" then
        return false
    end

    local summoned = false
    for index = 1, #(payload.spell.components or {}) do
        local component = payload.spell.components[index]
        local castPhase = tostring(type(component) == "table" and component.castPhase or "on_cast_end")
        local effect = type(component) == "table" and component.effect or nil
        local effectType = tostring(type(effect) == "table" and effect.type or "")
        local unitRef = tostring(type(effect) == "table" and effect.unitRef or "")
        if castPhase == "on_cast_end" and effectType == "summon_pet" and unitRef ~= "" then
            summoned = self:SummonEventPetUnit(
                payload.casterUnit,
                unitRef,
                buildSelectedPetSummonOptions(unitRef, payload.sender)
            ) ~= nil or summoned
        end
    end

    return summoned
end

function Server:GetSpellcastEntry(eventId, casterEventId)
    return getCastEntry(self, eventId, casterEventId)
end

function Server:ResetSpellcastingState(eventId)
    if type(eventId) == "string" and eventId ~= "" then
        clearEventCastBucket(self, eventId)
        return true
    end

    self.ActiveSpellcastsByEventId = {}
    return true
end

function Server:HandleSpellcastStart(arguments, sender)
    local payload = validateInboundSpellcast(self, arguments, sender)
    if not payload then
        return false
    end

    if payload.castTurns == nil then
        return false
    end

    local suppressLog = shouldSuppressLoopbackLog(self, payload.eventId, payload.casterEventId, payload.spellRef, payload.authorityType, payload.sender, "start")
    setCastEntry(self, payload.eventId, payload.casterEventId, {
        spellRef = payload.spellRef,
        spellName = resolveSpellName(payload.spellRef),
        turnsTotal = payload.castTurns,
        authorityType = payload.authorityType,
        casterEventId = payload.casterEventId,
    })

    if not suppressLog then
        logLifecycle("start", payload.authorityType, payload.casterUnit.name, resolveSpellName(payload.spellRef), payload.castTurns)
    end

    return true
end

function Server:HandleSpellcastComplete(arguments, sender)
    local payload = validateInboundSpellcast(self, arguments, sender)
    if not payload then
        return false
    end

    local suppressLog = shouldSuppressLoopbackLog(self, payload.eventId, payload.casterEventId, payload.spellRef, payload.authorityType, payload.sender, "complete")
    local previous = removeCastEntry(self, payload.eventId, payload.casterEventId)
    if not suppressLog then
        logLifecycle("complete", payload.authorityType, payload.casterUnit.name, (previous and previous.spellName) or resolveSpellName(payload.spellRef))
    end

    executeSummonPetComponents(self, payload)

    return true
end

function Server:HandleSpellcastInterrupt(arguments, sender)
    local payload = validateInboundSpellcast(self, arguments, sender)
    if not payload then
        return false
    end

    local suppressLog = shouldSuppressLoopbackLog(self, payload.eventId, payload.casterEventId, payload.spellRef, payload.authorityType, payload.sender, "interrupt")
    local previous = removeCastEntry(self, payload.eventId, payload.casterEventId)
    if not suppressLog then
        logLifecycle("interrupt", payload.authorityType, payload.casterUnit.name, (previous and previous.spellName) or resolveSpellName(payload.spellRef))
    end

    return true
end

function Server:OnSpellcastStart(casterEventId, spellRef, castTime)
    local sessionState = self.GetState and self:GetState() or nil
    local eventState = self.GetEventState and self:GetEventState() or nil
    if not sessionState or sessionState.active ~= true or not eventState or eventState.active ~= true then
        return false
    end

    local casterUnit = findEventUnitById(eventState.units, casterEventId)
    local dataset, spell = nil, nil
    if Registry.ResolveSpellReference then
        dataset, spell = Registry:ResolveSpellReference(spellRef)
    end
    if not casterUnit or casterUnit.isPlayer == true or not isEventUnitActive(casterUnit) or not dataset or not spell then
        return false
    end

    local channelId = resolveOutboundSessionChannelId(sessionState)
    if not channelId then
        return false
    end

    local numericCastTime = resolveSpellcastTurns(spell, castTime)
    if numericCastTime == nil then
        return false
    end

    setCastEntry(self, eventState.id, casterUnit.eventID, {
        spellRef = spellRef,
        spellName = resolveSpellName(spellRef),
        turnsTotal = numericCastTime,
        authorityType = "npc",
        casterEventId = casterUnit.eventID,
    })
    logLifecycle("start", "npc", casterUnit.name, resolveSpellName(spellRef), numericCastTime)

    return Comms:SendToChannel(channelId, SPELLCAST_START_OPCODE, {
        sessionState.channelName,
        eventState.id,
        casterUnit.eventID,
        spellRef,
        numericCastTime,
        "npc",
    }, buildSendMetadata(SPELLCAST_START_OPCODE))
end

function Server:OnSpellcastComplete(casterEventId, spellRef)
    local sessionState = self.GetState and self:GetState() or nil
    local eventState = self.GetEventState and self:GetEventState() or nil
    if not sessionState or sessionState.active ~= true or not eventState or eventState.active ~= true then
        return false
    end

    local casterUnit = findEventUnitById(eventState.units, casterEventId)
    local dataset, spell = nil, nil
    if Registry.ResolveSpellReference then
        dataset, spell = Registry:ResolveSpellReference(spellRef)
    end
    if not casterUnit or casterUnit.isPlayer == true or not isEventUnitActive(casterUnit) or not dataset or not spell then
        return false
    end

    local channelId = resolveOutboundSessionChannelId(sessionState)
    if not channelId then
        return false
    end

    local previous = removeCastEntry(self, eventState.id, casterUnit.eventID)
    logLifecycle("complete", "npc", casterUnit.name, (previous and previous.spellName) or resolveSpellName(spellRef))

    return Comms:SendToChannel(channelId, SPELLCAST_COMPLETE_OPCODE, {
        sessionState.channelName,
        eventState.id,
        casterUnit.eventID,
        spellRef,
        "npc",
    }, buildSendMetadata(SPELLCAST_COMPLETE_OPCODE))
end

function Server:OnSpellcastInterrupted(casterEventId, spellRef)
    local sessionState = self.GetState and self:GetState() or nil
    local eventState = self.GetEventState and self:GetEventState() or nil
    if not sessionState or sessionState.active ~= true or not eventState or eventState.active ~= true then
        return false
    end

    local casterUnit = findEventUnitById(eventState.units, casterEventId)
    local dataset, spell = nil, nil
    if Registry.ResolveSpellReference then
        dataset, spell = Registry:ResolveSpellReference(spellRef)
    end
    if not casterUnit or casterUnit.isPlayer == true or not isEventUnitActive(casterUnit) or not dataset or not spell then
        return false
    end

    local channelId = resolveOutboundSessionChannelId(sessionState)
    if not channelId then
        return false
    end

    local previous = removeCastEntry(self, eventState.id, casterUnit.eventID)
    logLifecycle("interrupt", "npc", casterUnit.name, (previous and previous.spellName) or resolveSpellName(spellRef))

    return Comms:SendToChannel(channelId, SPELLCAST_INTERRUPT_OPCODE, {
        sessionState.channelName,
        eventState.id,
        casterUnit.eventID,
        spellRef,
        "npc",
    }, buildSendMetadata(SPELLCAST_INTERRUPT_OPCODE))
end

function Server:OnSpellcastChannelTick(casterEventId, spellRef)
    local eventState = self.GetEventState and self:GetEventState() or nil
    if not eventState or eventState.active ~= true then
        return false
    end

    local casterUnit = findEventUnitById(eventState.units, casterEventId)
    if not casterUnit or casterUnit.isPlayer == true or not isEventUnitActive(casterUnit) then
        return false
    end

    logLifecycle("channel-tick", "npc", casterUnit.name, resolveSpellName(spellRef))
    return true
end
