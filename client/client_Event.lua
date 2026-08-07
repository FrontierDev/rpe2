local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Internal = Addon.Internal or {}
Addon.Utils = Addon.Utils or {}
Addon.Internal.Comms = Addon.Internal.Comms or {}

local Client = Addon.Client
local Debug = Addon.Debug
local Common = Addon.Utils.Common
local Commands = Addon.Commands
local Comms = Addon.Internal.Comms
local Event = Addon.Internal.Database.Classes.Event
local ResourceSync = Addon.Internal.Comms and Addon.Internal.Comms.ResourceSync or {}
local EventUnit = Addon.Internal.Database.Classes.EventUnit

local function getInline()
    return Addon.UI and Addon.UI.Inline or nil
end

local function getSound()
    return Addon.Core and Addon.Core.Sound or nil
end

local function getUI()
    return Addon.UI or nil
end

local function coerceEventUnitBoolean(value, defaultValue)
    local eventUnitClass = Addon.Internal
        and Addon.Internal.Database
        and Addon.Internal.Database.Classes
        and Addon.Internal.Database.Classes.EventUnit
        or nil
    if eventUnitClass and eventUnitClass.CoerceBoolean then
        return eventUnitClass.CoerceBoolean(value, defaultValue)
    end

    if value == nil then
        return defaultValue == true
    end

    if value == true or value == false then
        return value
    end

    local numericValue = tonumber(value)
    if numericValue ~= nil then
        return numericValue ~= 0
    end

    if type(value) == "string" then
        local normalized = string.lower(value)
        if normalized == "true" or normalized == "yes" or normalized == "on" then
            return true
        end
        if normalized == "false" or normalized == "no" or normalized == "off" then
            return false
        end
    end

    return defaultValue == true
end

Client.EventState = Client.EventState or nil
Client.LastEventEndReason = Client.LastEventEndReason or nil
Client.EventWidgetRefreshQueued = Client.EventWidgetRefreshQueued or false
Client.ControlledEventUnitId = Client.ControlledEventUnitId or nil
Client.TurnEndPending = Client.TurnEndPending or false
Client.EventUnitInteractionMarkers = Client.EventUnitInteractionMarkers or {}
Client.LastLocalInteractionMarker = Client.LastLocalInteractionMarker or nil

local function getMovementTracker()
    return type(RPE) == "table" and type(RPE.Core) == "table" and type(RPE.Core.Movement) == "table" and RPE.Core.Movement or nil
end

local function refreshActionBarBars(reason)
    if type(Client.QueueActionBarCompanionBarsRefresh) == "function" then
        Client:QueueActionBarCompanionBarsRefresh(reason)
        return
    end

    if type(Client.RefreshActionBarCompanionBars) == "function" then
        Client:RefreshActionBarCompanionBars(reason)
    end
end

local function queueSharedEventVisualRefresh(client, reason, options)
    if type(client) ~= "table" then
        return false
    end

    options = type(options) == "table" and options or {}
    local refreshed = false
    local normalizedReason = tostring(reason or "event")

    if options.eventWidget ~= false and type(client.QueueEventWidgetRefresh) == "function" then
        refreshed = client:QueueEventWidgetRefresh(normalizedReason) or refreshed
    end

    if options.targeting ~= false then
        if type(client.QueueTargetingWidgetRefresh) == "function" then
            refreshed = client:QueueTargetingWidgetRefresh(normalizedReason) or refreshed
        elseif type(client.RefreshTargetingWidget) == "function" then
            refreshed = client:RefreshTargetingWidget(normalizedReason) or refreshed
        end
    end

    if options.actionBar ~= false then
        if type(client.QueueActionBarRefresh) == "function" then
            refreshed = client:QueueActionBarRefresh(normalizedReason) or refreshed
        elseif type(client.RefreshActionBarWidget) == "function" then
            refreshed = client:RefreshActionBarWidget(normalizedReason) or refreshed
        else
            refreshActionBarBars(normalizedReason)
        end
    elseif options.companionBars == true then
        refreshActionBarBars(normalizedReason)
    end

    return refreshed
end

local function emitChatLine(line)
    local output = tostring(line or "")

    local function emit()
        if DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.AddMessage then
            DEFAULT_CHAT_FRAME:AddMessage(output)
            return
        end

        if print then
            print(output)
        end
    end

    if C_Timer and C_Timer.After then
        C_Timer.After(0, emit)
        return
    end

    emit()
end

local function getColorHex(token, fallback)
    local UI = getUI()
    local color = UI and type(UI.ResolveColor) == "function" and UI.ResolveColor(nil, token, fallback) or fallback
    local r = math.max(0, math.min(255, math.floor(((color and color.r) or 1) * 255 + 0.5)))
    local g = math.max(0, math.min(255, math.floor(((color and color.g) or 1) * 255 + 0.5)))
    local b = math.max(0, math.min(255, math.floor(((color and color.b) or 1) * 255 + 0.5)))
    return ("%02x%02x%02x"):format(r, g, b)
end

local function getEventDisplayName(eventState)
    if type(eventState) ~= "table" then
        return "Active Event"
    end

    local eventName = tostring(eventState.name or eventState.title or eventState.id or "Active Event")
    if eventName == "" then
        return "Active Event"
    end

    return eventName
end

local function getTurnAnnouncementIconMarkup()
    local Inline = getInline()
    local spec = Inline and type(Inline.GetSpec) == "function" and Inline:GetSpec("RPE") or nil
    local texture = spec and tostring(spec.texture or spec.file or spec.path or "") or ""
    if texture == "" then
        return Inline and type(Inline.Get) == "function" and Inline:Get("RPE", 14, 14) or ""
    end

    return ("|T%s:14:14:0:0|t"):format(texture)
end

local function emitTurnStartAnnouncement(eventState)
    local turnNumber = math.max(1, tonumber(eventState and eventState.turnNumber) or 1)
    local icon = getTurnAnnouncementIconMarkup()
    local eventName = getEventDisplayName(eventState)
    local prefix = icon ~= "" and (icon .. " ") or ""
    emitChatLine(("|cffffff00%s%s: Turn %d|r"):format(prefix, eventName, turnNumber))
end

local function emitLocalTurnStartAnnouncement()
    local icon = getTurnAnnouncementIconMarkup()
    local prefix = icon ~= "" and (icon .. " ") or ""
    local hex = getColorHex("text.secondary", { r = 0.8, g = 0.82, b = 0.88, a = 1 })
    emitChatLine(("|cff%s%sYour turn begins.|r"):format(hex, prefix))
end

local function playEventStartSound()
    local sound = getSound()
    if type(sound) == "table" and type(sound.PlayEventStartCue) == "function" then
        return sound:PlayEventStartCue()
    end

    if type(PlaySound) == "function" then
        PlaySound(567438)
        return true
    end

    return false
end

local function playLocalTurnStartSound()
    local sound = getSound()
    if type(sound) == "table" and type(sound.PlayLocalTurnStartCue) == "function" then
        return sound:PlayLocalTurnStartCue()
    end

    if type(PlaySound) == "function" then
        PlaySound(567416)
        return true
    end

    return false
end

local function bumpEventTooltipContextRevision(eventState, casterEventId)
    local builder = Addon.Client and Addon.Client.Spellcasting and Addon.Client.Spellcasting.DescriptionBuilder or nil
    if type(builder) == "table" and type(builder.BumpEventTooltipContextRevision) == "function" then
        builder.BumpEventTooltipContextRevision(eventState and eventState.id or nil, casterEventId)
    end
end

local function bumpAllEventTooltipContextRevisions(eventState)
    local builder = Addon.Client and Addon.Client.Spellcasting and Addon.Client.Spellcasting.DescriptionBuilder or nil
    if type(builder) == "table" and type(builder.BumpEventTooltipContextRevisionForAllUnits) == "function" then
        builder.BumpEventTooltipContextRevisionForAllUnits(eventState)
    end
end

local function syncMovementTracking(client, wasLocalTurn, eventState, previousTurnNumber, previousTickNumber)
    local tracker = getMovementTracker()
    if not tracker then
        return false
    end

    local isLocalTurn = client.IsLocalTurnActive and client:IsLocalTurnActive(eventState) or false
    if isLocalTurn and wasLocalTurn ~= true then
        if type(tracker.OnPlayerTurnStart) == "function" then
            tracker:OnPlayerTurnStart()
        end
        queueSharedEventVisualRefresh(client, "local-turn-start", {
            eventWidget = false,
            targeting = false,
            actionBar = true,
        })
        return true
    end

    if wasLocalTurn == isLocalTurn then
        if isLocalTurn and type(tracker.RefreshMaxDistance) == "function" then
            tracker:RefreshMaxDistance()
        end
        return false
    end

    if type(tracker.OnPlayerTurnEnd) == "function" then
        tracker:OnPlayerTurnEnd()
    end
    queueSharedEventVisualRefresh(client, "local-turn-end", {
        eventWidget = false,
        targeting = false,
        actionBar = true,
    })
    return true
end

local function getEventUnitsOpcode()
    return  Addon.Internal.Comms.Operations:GetOpcode("EVENT_UNITS") or nil
end

local function isEventUnitActive(unit)
    if Event and Event.IsUnitActive then
        return Event.IsUnitActive(unit)
    end

    return type(unit) == "table" and (unit.isPlayer == true or coerceEventUnitBoolean(unit.active, true))
end

local function deferEventWidget(fn, ...)
    if Addon.Internal.Tasks then
        Addon.Internal.Tasks:Enqueue(fn, ...)
        return
    end

    fn(...)
end

local function hasLocalSessionMember(sessionState)
    if type(sessionState) ~= "table" or type(sessionState.membersByName) ~= "table" then
        return false
    end

    local playerName = Common.GetPlayerName and Common.GetPlayerName() or nil
    playerName = Common.NormalizeName and Common.NormalizeName(playerName) or playerName
    if type(playerName) ~= "string" or playerName == "" then
        return false
    end

    return sessionState.membersByName[playerName] ~= nil
end

function Client:GetEventState()
    return self.EventState
end

function Client:QueueEventWidgetRefresh(reason)
    self.PendingEventWidgetRefreshReason = tostring(reason or self.PendingEventWidgetRefreshReason or "event")
    self.PendingEventWidgetStructuralRefresh = true
    if self.EventWidgetRefreshQueued then
        return true
    end
    self.EventWidgetRefreshQueued = true
    if type(self.QueueVisualRefreshFlush) == "function" then
        return self:QueueVisualRefreshFlush()
    end

    local eventState = self:GetEventState()
    if not eventState or eventState.active ~= true then
        deferEventWidget(function(targetClient)
            targetClient.EventWidgetRefreshQueued = false
            targetClient.PendingEventWidgetRefreshReason = nil

            if targetClient.HideEventWidget then
                targetClient:HideEventWidget()
            end
        end, self)
        return true
    end

    deferEventWidget(function(targetClient, refreshReason)
        targetClient.EventWidgetRefreshQueued = false
        targetClient.PendingEventWidgetRefreshReason = nil

        local eventState = Addon.Client.EventState
        if eventState and eventState.active == true then
            if targetClient.BuildEventWidget then
                targetClient:BuildEventWidget()
            end
            if targetClient.ShowEventWidget then
                targetClient:ShowEventWidget()
            end
            if targetClient.RefreshEventWidget then
                targetClient:RefreshEventWidget(refreshReason)
            end
            return
        end

        if targetClient.HideEventWidget then
            targetClient:HideEventWidget()
        end
    end, self, reason)

    return true
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

local function findPlayerEventUnit(units, playerName)
    local normalizedPlayerName = Common.NormalizeName and Common.NormalizeName(playerName) or tostring(playerName or "")
    if normalizedPlayerName == "" then
        return nil
    end

    for index = 1, #(units or {}) do
        local unit = units[index]
        if unit and unit.isPlayer == true then
            local candidateName = Common.NormalizeName and Common.NormalizeName(unit.ownerID or unit.controllerID or unit.name) or tostring(unit.ownerID or unit.controllerID or unit.name or "")
            if candidateName == normalizedPlayerName then
                return unit, index
            end
        end
    end

    return nil
end

local function countPlayerUnits(units)
    local playerCount = 0
    for index = 1, #(units or {}) do
        if units[index] and units[index].isPlayer == true then
            playerCount = playerCount + 1
        end
    end

    return playerCount
end

local function tryQueueInitialLocalResourceSync(client, sessionState, eventState, reason)
    if type(client) ~= "table"
        or type(sessionState) ~= "table"
        or sessionState.active ~= true
        or type(eventState) ~= "table"
        or eventState.active ~= true
        or sessionState.lastResourceSyncEventId == eventState.id
        or not hasLocalSessionMember(sessionState)
        or type(client.QueueClientResourceSync) ~= "function"
    then
        return false
    end

    local queued = client:QueueClientResourceSync(reason or "event-start")
    if queued then
        sessionState.lastResourceSyncEventId = eventState.id
        return true
    end

    return false
end

local function applyLocalProfileResourcesToEventUnits(sessionState, units)
    if type(units) ~= "table" then
        return false
    end

    local localPlayerName = Common.NormalizeName and Common.NormalizeName(Common.GetPlayerName and Common.GetPlayerName() or nil) or ""
    if localPlayerName == "" then
        return false
    end

    local resources = ResourceSync.BuildProfileResourceSnapshot and ResourceSync.BuildProfileResourceSnapshot() or nil
    if type(resources) ~= "table" or #resources == 0 then
        return false
    end

    local sessionMember = type(sessionState) == "table"
        and type(sessionState.membersByName) == "table"
        and sessionState.membersByName[localPlayerName]
        or nil
    if sessionMember and (type(sessionMember.resources) ~= "table" or #sessionMember.resources == 0) then
        sessionMember.resources = ResourceSync.CloneResources and ResourceSync.CloneResources(resources) or resources
    end

    local updated = false
    for index = 1, #units do
        local unit = units[index]
        if unit and unit.isPlayer == true then
            local ownerName = Common.NormalizeName and Common.NormalizeName(unit.ownerID or unit.controllerID or unit.name) or ""
            if ownerName == localPlayerName and (type(unit.resources) ~= "table" or #unit.resources == 0) then
                unit.resources = ResourceSync.CloneResources and ResourceSync.CloneResources(resources) or resources
                updated = true
            end
        end
    end

    return updated
end

local function hydrateInboundEventUnit(unit, eventState)
    if not EventUnit or type(EventUnit.HydrateNetworkUnit) ~= "function" then
        return unit
    end

    return EventUnit.HydrateNetworkUnit(unit, {
        playerCount = countPlayerUnits(eventState and eventState.units or nil),
    })
end

local function upsertSortedEventUnit(units, unit)
    if type(units) ~= "table" or not unit then
        return false
    end

    local replaced = false
    for index = 1, #units do
        if tonumber(units[index] and units[index].eventID) == tonumber(unit.eventID) then
            units[index] = unit
            replaced = true
            break
        end
    end

    if not replaced then
        units[#units + 1] = unit
    end

    if Event and Event.SortUnitsByInitiative then
        Event.SortUnitsByInitiative(units)
    end

    return true
end

local function upsertAppendedEventUnit(units, unit)
    if type(units) ~= "table" or not unit then
        return false
    end

    local replaced = false
    for index = 1, #units do
        if tonumber(units[index] and units[index].eventID) == tonumber(unit.eventID) then
            units[index] = unit
            replaced = true
            break
        end
    end

    if not replaced then
        units[#units + 1] = unit
    end

    return true
end

local function removeEventUnitById(units, eventId)
    local numericEventId = tonumber(eventId) or 0
    if numericEventId <= 0 or type(units) ~= "table" then
        return nil
    end

    for index = 1, #units do
        if tonumber(units[index] and units[index].eventID) == numericEventId then
            local removed = units[index]
            table.remove(units, index)
            return removed
        end
    end

    return nil
end

local function isLocalPlayerEventUnit(unit)
    if type(unit) ~= "table" or unit.isPlayer ~= true then
        return false
    end

    local localPlayerName = Common.NormalizeName and Common.NormalizeName(Common.GetPlayerName and Common.GetPlayerName() or nil) or ""
    if localPlayerName == "" then
        return false
    end

    local candidateName = Common.NormalizeName and Common.NormalizeName(unit.ownerID or unit.controllerID or unit.name) or tostring(unit.ownerID or unit.controllerID or unit.name or "")
    return candidateName ~= "" and candidateName == localPlayerName
end

local function isControlEligibleEventUnit(controlledUnit, localEventUnit)
    if type(controlledUnit) ~= "table" or controlledUnit.isPlayer == true then
        return false
    end

    local controllerId = tonumber(controlledUnit.controllerID) or nil
    if controllerId and tonumber(localEventUnit and localEventUnit.eventID) == controllerId then
        return true
    end

    local controllerName = Common.NormalizeName and Common.NormalizeName(controlledUnit.controllerID) or tostring(controlledUnit.controllerID or "")
    local localName = Common.NormalizeName and Common.NormalizeName(localEventUnit and (localEventUnit.ownerID or localEventUnit.controllerID or localEventUnit.name) or nil) or tostring(localEventUnit and (localEventUnit.ownerID or localEventUnit.controllerID or localEventUnit.name) or "")
    return controllerName ~= "" and localName ~= "" and controllerName == localName
end

local function isLocalPlayerTurnActive(client, eventState)
    if type(client) ~= "table" or type(eventState) ~= "table" or eventState.active ~= true then
        return false
    end

    local localEventUnit = client.ResolveLocalEventUnit and client:ResolveLocalEventUnit(eventState) or nil
    local localEventId = tonumber(localEventUnit and localEventUnit.eventID) or 0
    if localEventId <= 0 then
        return false
    end

    local spellcasting = client.Spellcasting or Addon.Client.Spellcasting or nil
    if spellcasting and type(spellcasting.IsCasterTurnOnTick) == "function" then
        return spellcasting.IsCasterTurnOnTick(eventState, localEventId) == true
    end

    return false
end

function Client:ResolveLocalEventUnit(eventState)
    local state = eventState or self:GetEventState()
    if type(state) ~= "table" or state.active ~= true then
        return nil
    end

    local playerName = Common.GetPlayerName and Common.GetPlayerName() or nil
    playerName = Common.NormalizeName and Common.NormalizeName(playerName) or playerName
    if type(playerName) ~= "string" or playerName == "" then
        return nil
    end

    return findPlayerEventUnit(state.units, playerName)
end

function Client:CanControlEventUnit(controlledUnit, eventState)
    local localEventUnit = self:ResolveLocalEventUnit(eventState)
    if not localEventUnit then
        return false
    end

    if not isEventUnitActive(controlledUnit) then
        return false
    end

    return isControlEligibleEventUnit(controlledUnit, localEventUnit)
end

function Client:ResolveControlledEventUnit(eventState)
    local state = eventState or self:GetEventState()
    if type(state) ~= "table" or state.active ~= true then
        return nil
    end

    local controlledEventUnitId = tonumber(self.ControlledEventUnitId) or 0
    if controlledEventUnitId <= 0 then
        return nil
    end

    local controlledUnit = findEventUnitById(state.units, controlledEventUnitId)
    if not controlledUnit or controlledUnit.isPlayer == true then
        self.ControlledEventUnitId = nil
        return nil
    end

    if not self:CanControlEventUnit(controlledUnit, state) then
        self.ControlledEventUnitId = nil
        return nil
    end

    return controlledUnit, state
end

function Client:GetActionBarControlContext(eventState)
    local state = eventState or self:GetEventState()
    if type(state) ~= "table" or state.active ~= true then
        return nil
    end

    local localEventUnit = self:ResolveLocalEventUnit(state)
    if not localEventUnit then
        return nil
    end

    local controlledUnit = self:ResolveControlledEventUnit(state)
    if controlledUnit then
        return {
            eventState = state,
            localEventUnit = localEventUnit,
            controlledUnit = controlledUnit,
            activeEventUnit = controlledUnit,
            isControlled = true,
        }
    end

    return {
        eventState = state,
        localEventUnit = localEventUnit,
        controlledUnit = nil,
        activeEventUnit = localEventUnit,
        isControlled = false,
    }
end

function Client:ResolveActiveSpellcasterUnit(eventState)
    local context = self:GetActionBarControlContext(eventState)
    if not context then
        return nil
    end

    return context.activeEventUnit, context.eventState, context
end

function Client:IsLocalTurnActive(eventState)
    if self.TurnEndPending == true then
        return false
    end

    local activeUnit, state = self:ResolveActiveSpellcasterUnit(eventState)
    if type(activeUnit) ~= "table" or type(state) ~= "table" or state.active ~= true then
        return false
    end

    local spellcasting = self.Spellcasting or Addon.Client.Spellcasting or nil
    if spellcasting and type(spellcasting.IsCasterTurnOnTick) == "function" then
        return spellcasting.IsCasterTurnOnTick(state, activeUnit.eventID) == true
    end

    return true
end

function Client:IsLocalEventHost(eventStateOverride)
    local eventState = eventStateOverride or (self.GetEventState and self:GetEventState() or self.EventState)
    local localPlayerName = Common.NormalizeName(Common.GetPlayerName and Common.GetPlayerName() or nil)
    local hostName = Common.NormalizeName(eventState and eventState.hostName or nil)
    return localPlayerName ~= "" and hostName ~= "" and localPlayerName == hostName
end

function Client:MarkEventUnitInteraction(eventState, casterUnit, targetUnit, result, spellRef)
    local targetEventId = tonumber(targetUnit and targetUnit.eventID) or 0
    local casterEventId = tonumber(casterUnit and casterUnit.eventID) or 0
    local effectType = tostring(type(result) == "table" and result.effectType or "")
    if type(eventState) ~= "table"
        or eventState.active ~= true
        or targetEventId <= 0
        or casterEventId <= 0
        or effectType ~= "damage"
    then
        return false
    end

    local marker = {
        eventId = tostring(eventState.id or ""),
        turnNumber = tonumber(eventState.turnNumber) or 0,
        tickNumber = tonumber(eventState.tickNumber) or 0,
        casterEventId = casterEventId,
        targetEventId = targetEventId,
        spellRef = tostring(spellRef or ""),
        effectType = effectType,
    }

    self.EventUnitInteractionMarkers = self.EventUnitInteractionMarkers or {}
    self.EventUnitInteractionMarkers[targetEventId] = marker
    self.LastLocalInteractionMarker = marker

    if self.QueueEventWidgetTargetedRefresh then
        self:QueueEventWidgetTargetedRefresh("event-unit-interaction", { targetEventId })
    elseif self.QueueEventWidgetRefresh then
        self:QueueEventWidgetRefresh("event-unit-interaction")
    end

    return true
end

function Client:ResolveEventUnitInteractionMarkerState(eventUnit, eventState)
    local eventUnitId = tonumber(eventUnit and eventUnit.eventID) or 0
    if type(eventState) ~= "table" or eventState.active ~= true or eventUnitId <= 0 then
        return {
            visible = false,
            alpha = 0,
        }
    end

    local marker = type(self.EventUnitInteractionMarkers) == "table" and self.EventUnitInteractionMarkers[eventUnitId] or nil
    if type(marker) ~= "table" then
        return {
            visible = false,
            alpha = 0,
        }
    end

    if tostring(marker.eventId or "") ~= tostring(eventState.id or "") then
        return {
            visible = false,
            alpha = 0,
        }
    end

    local currentTurnNumber = tonumber(eventState.turnNumber) or 0
    local markerTurnNumber = tonumber(marker.turnNumber) or 0
    if markerTurnNumber <= 0 or currentTurnNumber <= 0 then
        return {
            visible = false,
            alpha = 0,
        }
    end

    local turnDelta = currentTurnNumber - markerTurnNumber
    if turnDelta == 0 then
        return {
            visible = true,
            alpha = 1,
        }
    end
    if turnDelta == 1 then
        return {
            visible = true,
            alpha = 0.5,
        }
    end

    return {
        visible = false,
        alpha = 0,
    }
end

function Client:WasEventUnitInteractedWithLastAction(eventUnit, eventState)
    local state = self.ResolveEventUnitInteractionMarkerState and self:ResolveEventUnitInteractionMarkerState(eventUnit, eventState) or nil
    return type(state) == "table" and state.visible == true
end

function Client:FlushPendingTurnChanges(sessionStateOverride, eventStateOverride)
    local sessionState = sessionStateOverride or self:GetState()
    local eventState = eventStateOverride or self:GetEventState()
    if type(sessionState) ~= "table"
        or sessionState.active ~= true
        or type(eventState) ~= "table"
        or eventState.active ~= true
        or eventState.channelName ~= sessionState.channelName
    then
        return false
    end

    local flushed = false

    if type(self.FlushDeferredTurnResourceDeltas) == "function" then
        flushed = self:FlushDeferredTurnResourceDeltas(sessionState, eventState) or flushed
    end

    local auraManager = self.Spellcasting and self.Spellcasting.AuraManager or nil
    if type(auraManager) == "table" and type(auraManager.FlushOutboundAuraOperations) == "function" then
        flushed = auraManager:FlushOutboundAuraOperations(self) or flushed
    end

    if self.QueueActionBarRefresh then
        self:QueueActionBarRefresh("pending-flush")
    elseif self.RefreshActionBarWidget then
        self:RefreshActionBarWidget("pending-flush")
    end
    if self.RefreshPendingTurnChangesTooltip then
        self:RefreshPendingTurnChangesTooltip()
    end
    return flushed
end

function Client:EndTurn()
    local sessionState = self:GetState()
    local eventState = self:GetEventState()
    if type(sessionState) ~= "table"
        or sessionState.active ~= true
        or type(eventState) ~= "table"
        or eventState.active ~= true
        or self:IsLocalEventHost(eventState)
        or not self:IsLocalTurnActive(eventState)
    then
        return false
    end

    self.TurnEndPending = true
    local tracker = getMovementTracker()
    if tracker and type(tracker.OnPlayerTurnEnd) == "function" then
        tracker:OnPlayerTurnEnd()
    end
    self:FlushPendingTurnChanges(sessionState, eventState)
    return true
end

function Client:TakeControlOfEventUnit(eventUnit)
    local eventState = self:GetEventState()
    if type(eventState) ~= "table" or eventState.active ~= true then
        return false
    end

    local controlledUnit = type(eventUnit) == "table" and eventUnit or nil
    if not controlledUnit or controlledUnit.isPlayer == true or not self:CanControlEventUnit(controlledUnit, eventState) then
        return false
    end

    local nextControlledId = tonumber(controlledUnit.eventID) or 0
    if nextControlledId <= 0 then
        return false
    end

    if self.ControlledEventUnitId == nextControlledId then
        return true
    end

    self.ControlledEventUnitId = nextControlledId
    if self.CancelSpellTargeting then
        self:CancelSpellTargeting("control-changed")
    end
    bumpAllEventTooltipContextRevisions(eventState)
    queueSharedEventVisualRefresh(self, "control-take", {
        eventWidget = true,
        targeting = false,
        actionBar = true,
    })
    return true
end

function Client:ReleaseControl(reason)
    if self.ControlledEventUnitId == nil then
        return false
    end

    self.ControlledEventUnitId = nil
    if self.CancelSpellTargeting then
        self:CancelSpellTargeting(reason or "control-release")
    end
    bumpAllEventTooltipContextRevisions(self:GetEventState())
    queueSharedEventVisualRefresh(self, reason or "control-release", {
        eventWidget = true,
        targeting = false,
        actionBar = true,
    })
    return true
end

function Client:ResetEventState(reason)
    local state = self.EventState
    local sessionState = self:GetState()
    local tracker = getMovementTracker()
    if tracker and type(tracker.OnPlayerTurnEnd) == "function" then
        tracker:OnPlayerTurnEnd()
    end
    if state then
        state.active = false
        state.endedAt = Common.GetNow()
        self.LastEventEndReason = reason
        Debug.Info(
            "Event ended: %s.",
            tostring(state.name ~= "" and state.name or state.id or "unnamed")
        )
    end

    self.EventState = nil
    self.ControlledEventUnitId = nil
    self.TurnEndPending = false
    self.LastAppliedTurnRegenKey = nil
    self.EventUnitInteractionMarkers = {}
    self.LastLocalInteractionMarker = nil
    if self.ClearEventWidgetCombatLog then
        self:ClearEventWidgetCombatLog(reason or "ended")
    end
    if self.ResetSpellcastingState then
        self:ResetSpellcastingState(state and state.id or nil)
    end
    if self.ResetTraitRuntime then
        self:ResetTraitRuntime(state and state.id or nil)
    end
    if self.CancelSpellTargeting then
        self:CancelSpellTargeting("")
    end
    if sessionState then
        sessionState.lastResourceSyncEventId = nil
    end
    if self.InvalidatePendingSpellTargetingDisplayState then
        self:InvalidatePendingSpellTargetingDisplayState()
    end
    queueSharedEventVisualRefresh(self, reason or "ended", {
        eventWidget = true,
        targeting = false,
        actionBar = true,
    })
    return state
end

function Client:HandleEventStart(arguments, sender)
    local sessionState = self:GetState()
    if not sessionState or sessionState.active ~= true then
        return false
    end

    local channelName = arguments and arguments[1] or nil
    if type(channelName) ~= "string" or channelName == "" or sessionState.channelName ~= channelName then
        return false
    end

    local nextState = Event.FromStartArguments(arguments)

    nextState.hostName = Common.NormalizeName(nextState.hostName ~= "" and nextState.hostName or sender)
    nextState.channelName = channelName
    nextState.active = true
    nextState.endedAt = 0
    nextState.turnNumber = math.max(1, tonumber(nextState.turnNumber) or 1)
    nextState.tickNumber = math.max(1, tonumber(nextState.tickNumber) or 1)
    nextState.totalTicks = math.max(1, tonumber(nextState.totalTicks) or 1)
    nextState.rosterReady = true
    nextState.unitsReady = false
    nextState.unitsChunkReceived = 0
    nextState.unitsChunkExpected = 0

    if ResourceSync.ApplyTrackedPlayerResourcesToEventUnits then
        ResourceSync.ApplyTrackedPlayerResourcesToEventUnits(sessionState.membersByName, nextState.units)
    end
    applyLocalProfileResourcesToEventUnits(sessionState, nextState.units)
    if ResourceSync.UpdateEventReadiness then
        ResourceSync.UpdateEventReadiness(nextState)
    end

    self.EventState = nextState
    local wasLocalTurn = false
    self.EventUnitInteractionMarkers = {}
    self.LastLocalInteractionMarker = nil
    if self.ClearEventWidgetCombatLog then
        self:ClearEventWidgetCombatLog("event-start")
    end
    if self.ResetSpellcastingState then
        self:ResetSpellcastingState(nextState.id)
    end
    self.LastEventEndReason = nil
    playEventStartSound()

    tryQueueInitialLocalResourceSync(self, sessionState, nextState, "event-start")
    syncMovementTracking(self, wasLocalTurn, nextState)
    bumpAllEventTooltipContextRevisions(nextState)
    if self.InvalidatePendingSpellTargetingDisplayState then
        self:InvalidatePendingSpellTargetingDisplayState()
    end
    queueSharedEventVisualRefresh(self, "event-start", {
        eventWidget = true,
        targeting = true,
        actionBar = true,
    })
    if self.ActivateEventTraits and nextState and nextState.rosterReady == true and #(nextState.units or {}) > 0 then
        self:ActivateEventTraits(nextState)
    end
    if self.PromptPhaseConsumableTraits then
        self:PromptPhaseConsumableTraits(nextState, "event_start")
    end
    return true
end

function Client:HandleEventEnd(arguments)
    local state = self.EventState
    if not state then
        return false
    end

    local channelName = arguments and arguments[1] or nil
    if type(channelName) ~= "string" or channelName == "" or state.channelName ~= channelName then
        return false
    end

    local eventId = arguments and arguments[2] or nil
    if state.id and state.id ~= "" and eventId and eventId ~= "" and state.id ~= eventId then
        return false
    end

    local reason = arguments and arguments[3] or "ended"
    if self.PromptPhaseConsumableTraits then
        local prompted = self:PromptPhaseConsumableTraits(state, "event_end", function()
            Client:ResetEventState(reason)
        end)
        if prompted then
            return true
        end
    end

    return self:ResetEventState(reason) ~= nil
end

function Client:HandleEventUnits(arguments)
    local sessionState = self:GetState()
    local eventState = self.EventState
    if not sessionState or sessionState.active ~= true or not eventState or eventState.active ~= true then
        return false
    end

    local channelName = arguments and arguments[1] or nil
    if type(channelName) ~= "string" or channelName == "" or sessionState.channelName ~= channelName then
        return false
    end

    local eventId = arguments and arguments[2] or nil
    if eventState.id and eventState.id ~= "" and eventId and eventId ~= "" and eventState.id ~= eventId then
        return false
    end

    local wasLocalTurn = self.IsLocalTurnActive and self:IsLocalTurnActive(eventState) or false
    local units = Event.DeserializeUnitsFromNetwork(arguments and arguments[3] or "")
    if ResourceSync.ApplyTrackedPlayerResourcesToEventUnits then
        ResourceSync.ApplyTrackedPlayerResourcesToEventUnits(sessionState.membersByName, units)
    end
    applyLocalProfileResourcesToEventUnits(sessionState, units)
    eventState.units = units
    eventState.rosterReady = true
    eventState.unitsChunkReceived = eventState.unitsChunkExpected or eventState.unitsChunkReceived or 0
    if ResourceSync.UpdateEventReadiness then
        ResourceSync.UpdateEventReadiness(eventState)
    end
    tryQueueInitialLocalResourceSync(self, sessionState, eventState, "event-units")
    if self.PruneCooldownState then
        self:PruneCooldownState(eventState)
    end
    if Addon.Server and Addon.Server.EventState and Addon.Server.EventState.id == eventState.id then
        Addon.Server.EventState.healthResourceRef = eventState.healthResourceRef
        Addon.Server.EventState.rosterReady = eventState.rosterReady
        Addon.Server.EventState.unitsReady = eventState.unitsReady
        Addon.Server.EventState.resourcesReady = eventState.resourcesReady
        Addon.Server.EventState.unitsChunkReceived = eventState.unitsChunkReceived
        Addon.Server.EventState.unitsChunkExpected = eventState.unitsChunkExpected
        Addon.Server.EventState.healthResourcesReceived = eventState.healthResourcesReceived
        Addon.Server.EventState.healthResourcesExpected = eventState.healthResourcesExpected
        Addon.Server.EventState.readyProgressReceived = eventState.readyProgressReceived
        Addon.Server.EventState.readyProgressExpected = eventState.readyProgressExpected
    end
    syncMovementTracking(self, wasLocalTurn, eventState, previousTurnNumber, previousTickNumber)
    bumpAllEventTooltipContextRevisions(eventState)
    if self.InvalidatePendingSpellTargetingDisplayState then
        self:InvalidatePendingSpellTargetingDisplayState()
    end
    queueSharedEventVisualRefresh(self, "event-units", {
        eventWidget = true,
        targeting = true,
        actionBar = true,
    })
    if self.ActivateEventTraits then
        self:ActivateEventTraits(eventState)
    end
    return true
end

function Client:HandleEventUnitDeltaBatch(arguments)
    local sessionState = self:GetState()
    local eventState = self.EventState
    if not sessionState or sessionState.active ~= true or not eventState or eventState.active ~= true then
        return false
    end

    local channelName = arguments and arguments[1] or nil
    if type(channelName) ~= "string" or channelName == "" or sessionState.channelName ~= channelName then
        return false
    end

    local eventId = arguments and arguments[2] or nil
    if eventState.id and eventState.id ~= "" and eventId and eventId ~= "" and eventState.id ~= eventId then
        return false
    end

    local entries = Event and Event.DeserializeUnitDeltaBatchFromNetwork and Event.DeserializeUnitDeltaBatchFromNetwork(arguments and arguments[3] or "") or {}
    if #entries == 0 then
        return false
    end

    local wasLocalTurn = self.IsLocalTurnActive and self:IsLocalTurnActive(eventState) or false
    eventState.units = eventState.units or {}
    local changed = false
    for index = 1, #entries do
        local entry = entries[index]
        if entry.operation == "remove" then
            changed = removeEventUnitById(eventState.units, entry.eventID) ~= nil or changed
        elseif entry.operation == "upsert" and entry.unit then
            changed = upsertAppendedEventUnit(eventState.units, hydrateInboundEventUnit(entry.unit, eventState)) or changed
        end
    end

    if not changed then
        return false
    end

    if ResourceSync.ApplyTrackedPlayerResourcesToEventUnits then
        ResourceSync.ApplyTrackedPlayerResourcesToEventUnits(sessionState.membersByName, eventState.units)
    end
    applyLocalProfileResourcesToEventUnits(sessionState, eventState.units)
    if ResourceSync.UpdateEventReadiness then
        ResourceSync.UpdateEventReadiness(eventState)
    end
    tryQueueInitialLocalResourceSync(self, sessionState, eventState, "event-unit-delta-batch")
    if self.PruneCooldownState then
        self:PruneCooldownState(eventState)
    end
    syncMovementTracking(self, wasLocalTurn, eventState)
    bumpAllEventTooltipContextRevisions(eventState)
    if self.InvalidatePendingSpellTargetingDisplayState then
        self:InvalidatePendingSpellTargetingDisplayState()
    end
    queueSharedEventVisualRefresh(self, "event-unit-delta-batch", {
        eventWidget = true,
        targeting = true,
        actionBar = true,
    })
    if self.ActivateEventTraits then
        self:ActivateEventTraits(eventState)
    end
    return true
end

function Client:HandleInboundChunkProgress(packet, receivedCount)
    if not packet or packet.opcode ~= getEventUnitsOpcode() then
        return false
    end

    local eventState = self.EventState
    if not eventState or eventState.active ~= true or eventState.unitsReady == true then
        return false
    end

    local expectedCount = math.max(0, tonumber(packet.partCount) or 0)
    local received = math.max(0, tonumber(receivedCount) or 0)
    eventState.unitsChunkExpected = expectedCount
    eventState.unitsChunkReceived = received
    if ResourceSync.UpdateEventReadiness then
        ResourceSync.UpdateEventReadiness(eventState)
    end

    if Addon.Server and Addon.Server.EventState and Addon.Server.EventState.id == eventState.id then
        Addon.Server.EventState.healthResourceRef = eventState.healthResourceRef
        Addon.Server.EventState.rosterReady = eventState.rosterReady
        Addon.Server.EventState.unitsReady = eventState.unitsReady
        Addon.Server.EventState.resourcesReady = eventState.resourcesReady
        Addon.Server.EventState.unitsChunkExpected = eventState.unitsChunkExpected
        Addon.Server.EventState.unitsChunkReceived = eventState.unitsChunkReceived
        Addon.Server.EventState.healthResourcesReceived = eventState.healthResourcesReceived
        Addon.Server.EventState.healthResourcesExpected = eventState.healthResourcesExpected
        Addon.Server.EventState.readyProgressReceived = eventState.readyProgressReceived
        Addon.Server.EventState.readyProgressExpected = eventState.readyProgressExpected
    end

    self:QueueEventWidgetRefresh("event-units-progress")
    return true
end

function Comms:HandleInboundChunkProgress(packet, receivedCount, distribution, sender, target)
    return Client:HandleInboundChunkProgress(packet, receivedCount, distribution, sender, target)
end

function Client:HandleEventState(arguments)
    local sessionState = self:GetState()
    local eventState = self.EventState
    if not sessionState or sessionState.active ~= true or not eventState or eventState.active ~= true then
        return false
    end

    local channelName = arguments and arguments[1] or nil
    if type(channelName) ~= "string" or channelName == "" or sessionState.channelName ~= channelName then
        return false
    end

    local eventId = arguments and arguments[2] or nil
    if eventState.id and eventState.id ~= "" and eventId and eventId ~= "" and eventState.id ~= eventId then
        return false
    end

    local previousTurnNumber = tonumber(eventState.turnNumber) or 0
    local previousTickNumber = tonumber(eventState.tickNumber) or 0
    local wasLocalTurn = self.IsLocalTurnActive and self:IsLocalTurnActive(eventState) or false
    local wasLocalPlayerTurn = isLocalPlayerTurnActive(self, eventState)

    if Event and Event.ApplyStateArguments then
        Event.ApplyStateArguments(eventState, arguments)
    else
        eventState.turnNumber = tonumber(arguments and arguments[3]) or eventState.turnNumber or 0
        eventState.tickNumber = tonumber(arguments and arguments[4]) or eventState.tickNumber or 0
        eventState.totalTicks = tonumber(arguments and arguments[5]) or eventState.totalTicks or 0
    end
    if previousTurnNumber ~= (tonumber(eventState.turnNumber) or 0)
        or previousTickNumber ~= (tonumber(eventState.tickNumber) or 0)
    then
        self.TurnEndPending = false
    end
    if self.AdvanceSpellcastState then
        self:AdvanceSpellcastState(previousTurnNumber, previousTickNumber)
    end
    if self.AdvanceCooldownState then
        self:AdvanceCooldownState(previousTurnNumber, previousTickNumber)
    end
    if self.AdvanceAuraState then
        self:AdvanceAuraState(previousTurnNumber, previousTickNumber)
    end

    local isLocalTurn = self.IsLocalTurnActive and self:IsLocalTurnActive(eventState) or false
    local isLocalPlayerTurn = isLocalPlayerTurnActive(self, eventState)
    local stepAdvanced = previousTurnNumber ~= (tonumber(eventState.turnNumber) or 0)
        or previousTickNumber ~= (tonumber(eventState.tickNumber) or 0)
    if previousTurnNumber ~= (tonumber(eventState.turnNumber) or 0) then
        emitTurnStartAnnouncement(eventState)
    end
    if stepAdvanced and not wasLocalPlayerTurn and isLocalPlayerTurn then
        playLocalTurnStartSound()
        emitLocalTurnStartAnnouncement()
    end
    if previousTurnNumber ~= (tonumber(eventState.turnNumber) or 0)
        and isLocalTurn
        and type(self.ApplyLocalTurnStartResourceRegeneration) == "function"
    then
        self:ApplyLocalTurnStartResourceRegeneration(sessionState, eventState)
    end
    if stepAdvanced then
        local tracker = getMovementTracker()
        if tracker then
            if isLocalTurn and type(tracker.OnPlayerTurnStart) == "function" then
                tracker:OnPlayerTurnStart()
            elseif not isLocalTurn and type(tracker.OnPlayerTurnEnd) == "function" then
                tracker:OnPlayerTurnEnd()
            end
        end
    else
        syncMovementTracking(self, wasLocalTurn, eventState)
    end
    bumpAllEventTooltipContextRevisions(eventState)
    if self.InvalidatePendingSpellTargetingDisplayState then
        self:InvalidatePendingSpellTargetingDisplayState()
    end
    queueSharedEventVisualRefresh(self, "event-state", {
        eventWidget = true,
        targeting = true,
        actionBar = true,
    })
    return true
end
