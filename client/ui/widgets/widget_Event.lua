local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Client.UI = Addon.Client.UI or {}

local Client = Addon.Client
local ClientUI = Addon.Client.UI
local UI = Addon.UI or {}
local Image = UI.Image
local Ruleset = Addon.Internal and Addon.Internal.Ruleset or {}
local Profile = Addon.Internal and Addon.Internal.Profile or {}
local ResourceSync = Addon.Internal and Addon.Internal.Comms and Addon.Internal.Comms.ResourceSync or {}
local Common = Addon.Utils and Addon.Utils.Common or {}

local function getTimings()
    return Addon.Debug and Addon.Debug.Timings or nil
end

local function measureEventWidgetTiming(label, fn)
    local timings = getTimings()
    if type(timings) ~= "table" or type(timings.Measure) ~= "function" or type(fn) ~= "function" then
        return fn()
    end

    return timings:Measure(label, fn, {
        context = "event-widget",
        thresholdMs = 15,
    })
end

local function getEventClass()
    return Addon.Internal and Addon.Internal.Database and Addon.Internal.Database.Classes and Addon.Internal.Database.Classes.Event or nil
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

local function isEventUnitActive(eventUnit)
    local eventClass = getEventClass()
    if eventClass and eventClass.IsUnitActive then
        return eventClass.IsUnitActive(eventUnit)
    end

    return type(eventUnit) == "table" and (eventUnit.isPlayer == true or coerceEventUnitBoolean(eventUnit.active, true))
end

local function isEventUnitBoss(eventUnit)
    local eventUnitClass = Addon.Internal
        and Addon.Internal.Database
        and Addon.Internal.Database.Classes
        and Addon.Internal.Database.Classes.EventUnit
        or nil
    if eventUnitClass and eventUnitClass.IsBoss then
        return eventUnitClass.IsBoss(eventUnit)
    end

    return type(eventUnit) == "table" and coerceEventUnitBoolean(eventUnit.boss, false)
end

local function isPlayerSharedTurnPet(eventUnit, units)
    local eventClass = getEventClass()
    if eventClass and type(eventClass.IsPlayerSharedTurnPet) == "function" then
        return eventClass.IsPlayerSharedTurnPet(units, eventUnit) == true
    end

    return false
end

local function getWidgetUnitsForPage(units, pageNumber, pageSize)
    local normalizedPageNumber = math.max(1, math.floor(tonumber(pageNumber) or 1))
    local normalizedPageSize = math.max(1, math.floor(tonumber(pageSize) or 5))
    local startIndex = ((normalizedPageNumber - 1) * normalizedPageSize) + 1
    local activeIndex = 0
    local pageUnits = {}

    for index = 1, #(units or {}) do
        local eventUnit = units[index]
        if isEventUnitActive(eventUnit) and not isEventUnitBoss(eventUnit) and not isPlayerSharedTurnPet(eventUnit, units) then
            activeIndex = activeIndex + 1
            if activeIndex >= startIndex and #pageUnits < normalizedPageSize then
                pageUnits[#pageUnits + 1] = eventUnit
            elseif #pageUnits >= normalizedPageSize then
                break
            end
        end
    end

    return pageUnits
end

local function findPageUnitIndexByEventId(pageUnits, targetEventId)
    local numericTargetEventId = tonumber(targetEventId) or 0
    if numericTargetEventId <= 0 then
        return nil
    end

    for index = 1, #(pageUnits or {}) do
        local unit = pageUnits[index]
        if tonumber(unit and unit.eventID) == numericTargetEventId then
            return index, unit
        end
    end

    return nil
end

local function findUnitIndexByEventId(units, targetEventId)
    local numericTargetEventId = tonumber(targetEventId) or 0
    if numericTargetEventId <= 0 then
        return nil
    end

    for index = 1, #(units or {}) do
        local unit = units[index]
        if tonumber(unit and unit.eventID) == numericTargetEventId then
            return index, unit
        end
    end

    return nil
end

local function collectBossUnits(units)
    local bossUnits = {}

    for index = 1, #(units or {}) do
        local eventUnit = units[index]
        if isEventUnitActive(eventUnit) and isEventUnitBoss(eventUnit) and not isPlayerSharedTurnPet(eventUnit, units) then
            bossUnits[#bossUnits + 1] = eventUnit
        end
    end

    return bossUnits
end

local TOP_OFFSET = -56
local ROOT_WIDTH = 720
local ROOT_HEIGHT = 322
local HEADER_WIDTH = ROOT_WIDTH
local HEADER_HEIGHT = 84
local HEADER_TEXT_GAP = 12
local HEADER_HORIZONTAL_PAD = 8
local TITLE_HEIGHT = 20
local SUBTITLE_HEIGHT = 16
local HEADER_BANNER_WIDTH = 388
local HEADER_BANNER_HEIGHT = 44
local HEADER_BANNER_TOP_OFFSET = 6
local HEADER_ICON_OFFSET_X = -22
local HEADER_ICON_BANNER_Y = 0
local HEADER_BANNER_INSET_LEFT = 44
local HEADER_BANNER_TEXT_RIGHT = 18
local HEADER_STATUS_WIDTH = 36
local HEADER_CONTROL_TAB_HEIGHT = 20
local PORTRAIT_TOP_OFFSET = 16
local PORTRAIT_SIZE = 48
local PORTRAIT_SPACING = 28
local BOSS_PORTRAIT_SIZE = 64
local BOSS_PORTRAIT_SPACING = 36
local PORTRAIT_HEALTH_BAR_HEIGHT = 5
local PORTRAIT_PRIMARY_BAR_HEIGHT = 4
local PORTRAIT_BAR_SPACING = 3
local PORTRAIT_SECONDARY_BAR_SPACING = 2
local PORTRAIT_CAST_ICON_SIZE = 18
local PORTRAIT_CAST_ICON_SPACING = 3
local PORTRAIT_FRAME_HEIGHT = (
    PORTRAIT_SIZE
    + PORTRAIT_BAR_SPACING
    + PORTRAIT_HEALTH_BAR_HEIGHT
    + PORTRAIT_SECONDARY_BAR_SPACING
    + PORTRAIT_PRIMARY_BAR_HEIGHT
    + PORTRAIT_CAST_ICON_SPACING
    + PORTRAIT_CAST_ICON_SIZE
)
local BOSS_PORTRAIT_FRAME_HEIGHT = (
    BOSS_PORTRAIT_SIZE
    + PORTRAIT_BAR_SPACING
    + PORTRAIT_HEALTH_BAR_HEIGHT
    + PORTRAIT_SECONDARY_BAR_SPACING
    + PORTRAIT_PRIMARY_BAR_HEIGHT
    + PORTRAIT_CAST_ICON_SPACING
    + PORTRAIT_CAST_ICON_SIZE
)
local PORTRAIT_SECTION_SPACING = 10
local PORTRAIT_PANEL_BASE_PADDING = 8
local EVENT_ICON_SIZE = 54
local EVENT_ICON_TEXTURE = "Interface\\Challenges\\challenges-bronze"
local EVENT_HEROIC_ICON_TEXTURE = "Interface\\Challenges\\challenges-silver"
local EVENT_MYTHIC_ICON_TEXTURE = "Interface\\Challenges\\challenges-gold"
local TURN_PROGRESS_WIDTH = 32
local TURN_PROGRESS_HEIGHT = 6
local DEFAULT_MAX_EVENT_UNITS = 5
local CONTROL_BUTTON_SPACING = 4
local CONTROL_BUTTON_ROW_OFFSET = 4
local CONTROL_BUTTON_MANAGE_WIDTH = 74
local CONTROL_BUTTON_STOP_WIDTH = 68
local CONTROL_BUTTON_ADVANCE_WIDTH = 86
local HEADER_MIN_CONTENT_WIDTH = HEADER_WIDTH - (HEADER_HORIZONTAL_PAD * 2)
local HEADER_SUBTITLE_MIN_WIDTH = 320
local HEADER_SUBTITLE_MAX_WIDTH = 280
local HEADER_TEXT_WIDTH_FUDGE = 6
local INACTIVE_PORTRAIT_ALPHA = 0.4
local ACTIVE_PORTRAIT_ALPHA = 1
local COMBAT_LOG_TOP_OFFSET = -12
local COMBAT_LOG_PANEL_HEIGHT = 34
local COMBAT_LOG_TIME_VISIBLE = 5
local COMBAT_LOG_FADE_IN_DURATION = 0.18
local COMBAT_LOG_FADE_OUT_DURATION = 0.22
local TOOLTIP_HINT_COLOR = { r = 0.38, g = 0.9, b = 0.42, a = 1 }
local UNKNOWN_UNIT_NAME = "Unknown Unit"

local function getEventHeaderIconTexture(difficulty)
    local normalizedDifficulty = string.lower(tostring(difficulty or "normal"))
    if normalizedDifficulty == "heroic" then
        return EVENT_HEROIC_ICON_TEXTURE
    end
    if normalizedDifficulty == "mythic" then
        return EVENT_MYTHIC_ICON_TEXTURE
    end

    return EVENT_ICON_TEXTURE
end

local function getPortraitPanelHeight(hasBossUnits)
    if hasBossUnits == true then
        return BOSS_PORTRAIT_FRAME_HEIGHT + PORTRAIT_SECTION_SPACING + PORTRAIT_FRAME_HEIGHT + PORTRAIT_PANEL_BASE_PADDING
    end

    return PORTRAIT_FRAME_HEIGHT + PORTRAIT_PANEL_BASE_PADDING
end

ClientUI.EventWidget = ClientUI.EventWidget or {}
local EventWidget = ClientUI.EventWidget
EventWidget.__index = EventWidget

local function isLocalHostForEvent(state)
    local server = Addon.Server
    if type(server) ~= "table" or type(server.IsActive) ~= "function" or not server:IsActive() then
        return false
    end

    local serverEventState = server.EventState
    if type(serverEventState) ~= "table" or serverEventState.active ~= true then
        return false
    end
    if tostring(serverEventState.id or "") ~= "" and tostring(serverEventState.id or "") ~= tostring(state and state.id or "") then
        return false
    end

    local common = Addon.Utils and Addon.Utils.Common or {}
    local normalizeName = common.NormalizeName or function(value) return tostring(value or "") end
    local localPlayerName = normalizeName(common.GetPlayerName and common.GetPlayerName() or nil)
    local hostName = normalizeName(state and state.hostName or "")
    return localPlayerName ~= "" and hostName ~= "" and localPlayerName == hostName
end

local function advanceEventStepFromWidget()
    local server = Addon.Server
    if type(server) ~= "table" or type(server.AdvanceEventStep) ~= "function" then
        return false
    end

    local client = Addon.Client
    local eventState = type(client) == "table"
        and type(client.GetEventState) == "function"
        and client:GetEventState()
        or nil
    if type(client) ~= "table"
        or type(eventState) ~= "table"
        or not isLocalHostForEvent(eventState)
        or type(client.CanPerformEventAction) ~= "function"
    then
        return false
    end

    if client:CanPerformEventAction(eventState, "advance-event-step") ~= true then
        return false
    end

    local advanced = server:AdvanceEventStep()
    local eventManage = server.UI and server.UI.EventManage or nil
    if advanced and eventManage and type(eventManage.RefreshDashboard) == "function" then
        eventManage:RefreshDashboard()
    end
    return advanced
end

local function showEventManageFromWidget()
    local server = Addon.Server
    if type(server) ~= "table" or type(server.ShowEventManageWindow) ~= "function" then
        return false
    end

    server:ShowEventManageWindow()
    return true
end

local function stopEventFromWidget()
    local server = Addon.Server
    if type(server) ~= "table" or type(server.EndEvent) ~= "function" then
        return false
    end

    return server:EndEvent("widget-stop")
end

local function buildPortraitDisplayKey(eventState, eventUnit, healthState, primaryState, castState, isPet, targetIndicatorState, turnComplete)
    if type(eventUnit) ~= "table" then
        return ""
    end

    return table.concat({
        tostring(eventState and eventState.id or ""),
        tostring(eventUnit.eventID or 0),
        tostring(tonumber(eventUnit.team) or 0),
        tostring(tonumber(eventUnit.raidMarker) or 0),
        tostring(tonumber(healthState and healthState.currentValue) or 0),
        tostring(tonumber(healthState and healthState.maxValue) or 0),
        tostring(healthState and healthState.resourceRef or ""),
        tostring(primaryState and primaryState.resourceRef or ""),
        tostring(tonumber(primaryState and primaryState.currentValue) or 0),
        tostring(tonumber(primaryState and primaryState.maxValue) or 0),
        tostring(castState and castState.icon or ""),
        isPet == true and "1" or "0",
        tostring(math.floor((tonumber(targetIndicatorState and targetIndicatorState.alpha) or 0) * 100 + 0.5)),
        turnComplete == true and "1" or "0",
    }, "\31")
end

local function buildPortraitVisualKey(eventState, eventUnit)
    if type(eventUnit) ~= "table" then
        return ""
    end

    return table.concat({
        tostring(eventState and eventState.id or ""),
        tostring(eventUnit.eventID or 0),
        tostring(eventUnit.name or ""),
        tostring(eventUnit.description or ""),
        tostring(tonumber(eventUnit.team) or 0),
        tostring(tonumber(eventUnit.raidMarker) or 0),
        eventUnit.hidden == true and "1" or "0",
        eventUnit.active == true and "1" or "0",
        eventUnit.isPlayer == true and "1" or "0",
        tostring(eventUnit.modelDisplayId or eventUnit.displayId or eventUnit.ModelID or ""),
        tostring(eventUnit.fileDataId or ""),
        tostring(eventUnit.cam or ""),
        tostring(eventUnit.rot or ""),
        tostring(eventUnit.z or ""),
        tostring(eventUnit.ownerID or ""),
        tostring(eventUnit.controllerID or ""),
    }, "\31")
end

local function buildCombatLogText(entry)
    if type(Client.BuildCombatLogDisplayText) == "function" then
        return Client:BuildCombatLogDisplayText(entry)
    end

    return ""
end

local function attachControlHandler(slot)
    if type(slot) ~= "table" or slot._controlHandlerAttached == true then
        return false
    end

    local portraitFrame = slot.portraitFrame
    if not portraitFrame then
        return false
    end

    if portraitFrame.EnableMouse then
        portraitFrame:EnableMouse(true)
    end

    local function handleMouseUp(_, button)
        if button ~= "RightButton" then
            return
        end

        if Client and type(Client.TakeControlOfEventUnit) == "function" then
            Client:TakeControlOfEventUnit(slot.portraitUnit)
        end
    end

    if portraitFrame.HookScript then
        portraitFrame:HookScript("OnMouseUp", handleMouseUp)
    else
        portraitFrame:SetScript("OnMouseUp", handleMouseUp)
    end

    slot._controlHandlerAttached = true
    return true
end

local function getSubtitleText(state)
    local subtext = tostring(state and state.subtext or "")
    if subtext ~= "" then
        return subtext
    end

    local description = tostring(state and state.description or "")
    if description ~= "" then
        return description
    end

    return " "
end

local function measureFontStringWidth(fontString, text)
    if not fontString or type(text) ~= "string" then
        return 0
    end

    if fontString.SetText then
        fontString:SetText(text)
    end

    if fontString.GetUnboundedStringWidth then
        return math.max(0, tonumber(fontString:GetUnboundedStringWidth()) or 0)
    end

    if fontString.GetStringWidth then
        return math.max(0, tonumber(fontString:GetStringWidth()) or 0)
    end

    return 0
end

local function getTeamColor(state, team)
    local eventClass = getEventClass()
    local color = eventClass and eventClass.GetTeamColor and eventClass.GetTeamColor(state, team) or nil
    if type(color) ~= "table" then
        return UI.ResolveColor(nil, "panel.border")
    end

    return {
        r = tonumber(color.r) or 0.16,
        g = tonumber(color.g) or 0.18,
        b = tonumber(color.b) or 0.22,
        a = tonumber(color.a) or 1,
    }
end

local function normalizeName(value)
    if type(Common.NormalizeName) == "function" then
        return Common.NormalizeName(value)
    end

    return tostring(value or "")
end

local function getActionBarWidget()
    local actionBarWidget = ClientUI.ActionBarWidget or nil
    if type(actionBarWidget) ~= "table" or type(actionBarWidget.Get) ~= "function" then
        return nil
    end

    return actionBarWidget:Get()
end

local function cloneResourceColor(color, fallback)
    local source = type(color) == "table" and color or fallback or { r = 0.42, g = 0.66, b = 0.98, a = 1 }
    return {
        r = tonumber(source.r) or 0.42,
        g = tonumber(source.g) or 0.66,
        b = tonumber(source.b) or 0.98,
        a = tonumber(source.a) or 1,
    }
end

local function normalizeResourceRef(resourceRef)
    if type(resourceRef) ~= "string" or resourceRef == "" then
        return nil
    end

    return resourceRef
end

local function buildPortraitResourceState(resourceRef, entry, resolvedRow)
    local currentValue = tonumber(entry and entry.currentValue)
    local maxValue = tonumber(entry and entry.maxValue)
    if currentValue == nil and maxValue ~= nil then
        currentValue = maxValue
    end
    if maxValue == nil and currentValue ~= nil then
        maxValue = currentValue
    end
    if currentValue == nil or maxValue == nil then
        return nil
    end

    return {
        resourceRef = resourceRef,
        icon = tostring(resolvedRow and resolvedRow.icon or "") ~= "" and tostring(resolvedRow.icon) or "Interface\\Icons\\INV_Misc_QuestionMark",
        color = cloneResourceColor(resolvedRow and resolvedRow.color or nil),
        currentValue = currentValue,
        maxValue = math.max(1, maxValue),
    }
end

local function buildPortraitResourceStates(actionBarWidget, eventUnit, eventState, resourceContext)
    if type(eventUnit) ~= "table" then
        if type(actionBarWidget) ~= "table" or type(actionBarWidget.BuildActionBarResourceStates) ~= "function" then
            return nil, nil
        end

        local fallbackStates = actionBarWidget:BuildActionBarResourceStates(eventState, eventUnit, resourceContext)
        if type(fallbackStates) ~= "table" then
            return nil, nil
        end

        return fallbackStates.health, fallbackStates.primary
    end

    resourceContext = type(resourceContext) == "table" and resourceContext or nil
    local resources = type(eventUnit.resources) == "table" and eventUnit.resources or nil
    if type(resources) ~= "table" or #resources == 0 then
        if type(actionBarWidget) ~= "table" or type(actionBarWidget.BuildActionBarResourceStates) ~= "function" then
            return nil, nil
        end

        local fallbackStates = actionBarWidget:BuildActionBarResourceStates(eventState, eventUnit, resourceContext)
        if type(fallbackStates) ~= "table" then
            return nil, nil
        end

        return fallbackStates.health, fallbackStates.primary
    end

    local resolvedByRef = type(resourceContext) == "table" and type(resourceContext.resolvedByRef) == "table" and resourceContext.resolvedByRef or {}
    local healthResourceRef = normalizeResourceRef(type(resourceContext) == "table" and resourceContext.healthResourceRef or nil)
        or normalizeResourceRef(type(eventState) == "table" and eventState.healthResourceRef or nil)
        or normalizeResourceRef(type(Profile.GetHealthResourceRef) == "function" and Profile.GetHealthResourceRef() or nil)
    local localEventUnitId = tonumber(type(resourceContext) == "table" and resourceContext.localEventUnitId or 0) or 0
    local localPlayerContext = localEventUnitId > 0 and tonumber(eventUnit.eventID) == localEventUnitId and eventUnit.isPlayer == true
    local preferredPrimaryRef = nil
    if localPlayerContext then
        preferredPrimaryRef = normalizeResourceRef(type(resourceContext) == "table" and resourceContext.primaryResourceRef or nil)
            or normalizeResourceRef(type(Profile.GetPrimaryResourceRef) == "function" and Profile.GetPrimaryResourceRef() or nil)
    end

    local healthState = nil
    local primaryState = nil
    local firstFallbackState = nil

    for index = 1, #resources do
        local entry = resources[index]
        local resourceRef = normalizeResourceRef(type(entry) == "table" and entry.resourceRef or nil)
        if resourceRef then
            local state = buildPortraitResourceState(resourceRef, entry, resolvedByRef[resourceRef])
            if state then
                if not firstFallbackState then
                    firstFallbackState = state
                end
                if healthResourceRef and resourceRef == healthResourceRef then
                    healthState = state
                elseif preferredPrimaryRef and resourceRef == preferredPrimaryRef then
                    primaryState = state
                elseif not preferredPrimaryRef and not primaryState then
                    primaryState = state
                end
            end
        end
    end

    if not healthState then
        healthState = firstFallbackState
    end
    if primaryState and primaryState.resourceRef == (healthState and healthState.resourceRef or nil) then
        primaryState = nil
    end
    if not primaryState and not localPlayerContext then
        for index = 1, #resources do
            local entry = resources[index]
            local resourceRef = normalizeResourceRef(type(entry) == "table" and entry.resourceRef or nil)
            if resourceRef and resourceRef ~= (healthState and healthState.resourceRef or nil) then
                primaryState = buildPortraitResourceState(resourceRef, entry, resolvedByRef[resourceRef])
                if primaryState then
                    break
                end
            end
        end
    end

    if healthState or primaryState then
        return healthState, primaryState
    end

    if type(actionBarWidget) ~= "table" or type(actionBarWidget.BuildActionBarResourceStates) ~= "function" then
        return nil, nil
    end

    local fallbackStates = actionBarWidget:BuildActionBarResourceStates(eventState, eventUnit, resourceContext)
    if type(fallbackStates) ~= "table" then
        return nil, nil
    end

    return fallbackStates.health, fallbackStates.primary
end

local function buildPortraitCastState(actionBarWidget, eventUnit, eventState)
    if type(actionBarWidget) ~= "table" or type(actionBarWidget.ResolveActionBarCastState) ~= "function" then
        return nil
    end

    return actionBarWidget:ResolveActionBarCastState(eventUnit, eventState)
end

local function isLocalPlayerPet(eventUnit, localEventUnit)
    if type(eventUnit) ~= "table" or type(localEventUnit) ~= "table" or eventUnit.isPlayer == true then
        return false
    end

    local localEventId = tonumber(localEventUnit.eventID) or 0
    if localEventId > 0 and tonumber(eventUnit.summonedByEventID) == localEventId then
        return true
    end

    local controllerId = tonumber(eventUnit.controllerID) or 0
    if controllerId > 0 and controllerId == localEventId and tostring(eventUnit.petRef or "") ~= "" then
        return true
    end

    local localOwnerName = normalizeName(localEventUnit.ownerID or localEventUnit.controllerID or localEventUnit.name)
    local eventOwnerName = normalizeName(eventUnit.ownerID)
    return tostring(eventUnit.petRef or "") ~= "" and localOwnerName ~= "" and eventOwnerName == localOwnerName
end

local function buildMaskedWidgetUnit(eventUnit)
    if type(eventUnit) ~= "table" then
        return nil
    end

    return {
        eventID = eventUnit.eventID,
        team = eventUnit.team,
        initiative = eventUnit.initiative,
        name = UNKNOWN_UNIT_NAME,
        description = "",
        isPlayer = false,
        hidden = true,
        active = true,
        resources = {},
    }
end

local function buildWidgetDisplayUnit(eventUnit, isHost)
    if type(eventUnit) ~= "table" then
        return nil
    end

    if isHost == true or eventUnit.hidden ~= true then
        return eventUnit
    end

    return buildMaskedWidgetUnit(eventUnit)
end

local function resolveTeamName(eventUnit)
    local eventState = Client.GetEventState and Client:GetEventState() or nil
    local eventClass = getEventClass()
    local teamName = type(eventUnit) == "table" and tostring(eventUnit.teamName or "") or ""
    if teamName ~= "" then
        return teamName
    end

    local teamId = tonumber(eventUnit and eventUnit.team) or 0
    if teamId > 0 then
        return eventClass and eventClass.GetTeamName and eventClass.GetTeamName(eventState, teamId) or ("Team %d"):format(teamId)
    end

    return "Unassigned Team"
end

local function formatTooltipResourceValue(state)
    local currentValue = tonumber(state and state.currentValue)
    local maxValue = tonumber(state and state.maxValue)
    if currentValue == nil and maxValue ~= nil then
        currentValue = maxValue
    end
    if maxValue == nil and currentValue ~= nil then
        maxValue = currentValue
    end
    if currentValue == nil and maxValue == nil then
        return ""
    end

    currentValue = tonumber(currentValue) or 0
    maxValue = tonumber(maxValue) or currentValue
    return ("%.0f / %.0f"):format(currentValue, maxValue)
end

local function buildPortraitTooltipResourceLine(state)
    if type(state) ~= "table" then
        return nil
    end

    local text = formatTooltipResourceValue(state)
    if text == "" then
        return nil
    end

    return {
        icon = tostring(state.icon or ""),
        text = text,
    }
end

local function collectPlayerPetUnits(eventUnit, eventState)
    if type(eventUnit) ~= "table" or eventUnit.isPlayer ~= true or type(eventState) ~= "table" then
        return {}
    end

    local pets = {}
    local ownerEventId = tonumber(eventUnit.eventID) or 0
    local ownerName = normalizeName(eventUnit.ownerID or eventUnit.controllerID or eventUnit.name)
    for index = 1, #(eventState.units or {}) do
        local candidate = eventState.units[index]
        if isPlayerSharedTurnPet(candidate, eventState.units) then
            local candidateControllerId = tonumber(candidate.controllerID) or 0
            local candidateOwnerName = normalizeName(candidate.ownerID)
            if (ownerEventId > 0 and tonumber(candidate.summonedByEventID) == ownerEventId)
                or (ownerEventId > 0 and candidateControllerId == ownerEventId)
                or (ownerName ~= "" and candidateOwnerName == ownerName)
            then
                pets[#pets + 1] = candidate
            end
        end
    end

    return pets
end

local function appendPlayerPetTooltipLines(tooltip, ownerEventUnit, eventState, actionBarWidget, resourceContext)
    if type(tooltip) ~= "table" or type(tooltip.lines) ~= "table" then
        return tooltip
    end

    local pets = collectPlayerPetUnits(ownerEventUnit, eventState)
    if #pets == 0 then
        return tooltip
    end

    tooltip.lines[#tooltip.lines + 1] = {
        text = " ",
    }

    for index = 1, #pets do
        local petUnit = pets[index]
        local healthState, primaryState = buildPortraitResourceStates(actionBarWidget, petUnit, eventState, resourceContext)
        tooltip.lines[#tooltip.lines + 1] = {
            text = ("Pet: %s"):format(tostring(petUnit.name or "Pet")),
            colorToken = "text.secondary",
        }

        local healthLine = buildPortraitTooltipResourceLine(healthState)
        if healthLine then
            tooltip.lines[#tooltip.lines + 1] = healthLine
        end

        if type(primaryState) == "table" and primaryState.resourceRef ~= (healthState and healthState.resourceRef or nil) then
            local primaryLine = buildPortraitTooltipResourceLine(primaryState)
            if primaryLine then
                tooltip.lines[#tooltip.lines + 1] = primaryLine
            end
        end

        local petDescription = ""
        if petUnit.GetResolvedValue then
            petDescription = tostring(petUnit:GetResolvedValue("description", petUnit.description or "") or "")
        else
            petDescription = tostring(petUnit.description or "")
        end
        if petDescription ~= "" then
            tooltip.lines[#tooltip.lines + 1] = {
                text = petDescription,
                colorToken = "text.muted",
            }
        end
    end

    return tooltip
end

local function buildEventPortraitTooltip(eventUnit, eventState, healthState, primaryState)
    if type(eventUnit) ~= "table" then
        return nil
    end

    local tooltip = {
        type = "custom",
        title = tostring(eventUnit.name or ""),
        titleFontSize = 12,
        titleColor = getTeamColor(eventState, eventUnit and eventUnit.team),
        titleRight = tonumber(eventUnit.eventID) and tonumber(eventUnit.eventID) > 0 and ("#%d"):format(tonumber(eventUnit.eventID)) or "",
        titleRightColor = UI.ResolveColor(nil, "text.muted"),
        lines = {},
    }

    tooltip.lines[#tooltip.lines + 1] = {
        text = resolveTeamName(eventUnit),
        colorToken = "text.muted",
    }

    local healthLine = buildPortraitTooltipResourceLine(healthState)
    if healthLine then
        tooltip.lines[#tooltip.lines + 1] = healthLine
    end

    if type(primaryState) == "table" and primaryState.resourceRef ~= (healthState and healthState.resourceRef or nil) then
        local primaryLine = buildPortraitTooltipResourceLine(primaryState)
        if primaryLine then
            tooltip.lines[#tooltip.lines + 1] = primaryLine
        end
    end

    if eventUnit.isPlayer ~= true then
        local localEventUnit = Client.ResolveLocalEventUnit and Client:ResolveLocalEventUnit(eventState) or nil
        local localEventId = math.floor(tonumber(localEventUnit and localEventUnit.eventID) or 0)
        local threatValue = localEventId > 0 and tonumber(eventUnit.threatTable and eventUnit.threatTable[localEventId]) or 0
        tooltip.lines[#tooltip.lines + 1] = {
            left = "Threat",
            right = tostring(math.max(0, math.floor(tonumber(threatValue) or 0))),
            colorToken = "text.muted",
        }
    end

    local auraManager = Client.Spellcasting and Client.Spellcasting.AuraManager or nil
    local unitEventId = tonumber(eventUnit and eventUnit.eventID) or 0
    if auraManager
        and type(auraManager.BuildUnitAuraTooltipLines) == "function"
        and type(eventState) == "table"
        and eventState.active == true
        and unitEventId > 0
    then
        local auraLines = auraManager:BuildUnitAuraTooltipLines(Client, eventState, unitEventId)
        for index = 1, #auraLines do
            tooltip.lines[#tooltip.lines + 1] = auraLines[index]
        end
    end

    local description = ""
    if eventUnit.GetResolvedValue then
        description = tostring(eventUnit:GetResolvedValue("description", eventUnit.description or "") or "")
    else
        description = tostring(eventUnit.description or "")
    end
    if description ~= "" then
        tooltip.lines[#tooltip.lines + 1] = description
    end

    local localEventUnit = Client.ResolveLocalEventUnit and Client:ResolveLocalEventUnit(eventState) or nil
    local controlledEventUnit = Client.ResolveControlledEventUnit and Client:ResolveControlledEventUnit(eventState) or nil
    local eventUnitId = tonumber(eventUnit.eventID) or 0
    local localEventUnitId = tonumber(localEventUnit and localEventUnit.eventID) or 0
    local controlledEventUnitId = tonumber(controlledEventUnit and controlledEventUnit.eventID) or 0

    if eventUnitId > 0 and eventUnitId == localEventUnitId then
        tooltip.lines[#tooltip.lines + 1] = {
            text = "<Your character>",
            r = TOOLTIP_HINT_COLOR.r,
            g = TOOLTIP_HINT_COLOR.g,
            b = TOOLTIP_HINT_COLOR.b,
            a = TOOLTIP_HINT_COLOR.a,
        }
    elseif eventUnitId > 0
        and eventUnitId ~= controlledEventUnitId
        and Client.CanControlEventUnit
        and Client:CanControlEventUnit(eventUnit, eventState)
    then
        tooltip.lines[#tooltip.lines + 1] = {
            text = "<Right-click to take control>",
            r = TOOLTIP_HINT_COLOR.r,
            g = TOOLTIP_HINT_COLOR.g,
            b = TOOLTIP_HINT_COLOR.b,
            a = TOOLTIP_HINT_COLOR.a,
        }
    end

    return tooltip
end

function EventWidget:BuildPortraitTooltip(eventUnit, eventState)
    local resolvedEventState = type(eventState) == "table" and eventState or (Client.GetEventState and Client:GetEventState() or nil)
    if type(eventUnit) ~= "table" or type(resolvedEventState) ~= "table" then
        return nil
    end

    local actionBarWidget = getActionBarWidget()
    local resourceContext = type(actionBarWidget) == "table"
        and type(actionBarWidget.BuildActionBarResourceContext) == "function"
        and actionBarWidget:BuildActionBarResourceContext(resolvedEventState)
        or nil
    local healthState, primaryState = buildPortraitResourceStates(actionBarWidget, eventUnit, resolvedEventState, resourceContext)
    local tooltip = buildEventPortraitTooltip(eventUnit, resolvedEventState, healthState, primaryState)
    return appendPlayerPetTooltipLines(tooltip, eventUnit, resolvedEventState, actionBarWidget, resourceContext)
end

function EventWidget:Get()
    if self.Instance then
        return self.Instance
    end

    self.Instance = setmetatable({
        rootPanel = nil,
        headerPanel = nil,
        headerBannerPanel = nil,
        headerIcon = nil,
        tickProgressBar = nil,
        turnNumberText = nil,
        turnStatusText = nil,
        turnProgressBar = nil,
        waitingPanel = nil,
        waitingProgressPanel = nil,
        waitingText = nil,
        namePanel = nil,
        titleText = nil,
        subtitleText = nil,
        portraitPanel = nil,
        bossPortraitPanel = nil,
        initiativePortraitPanel = nil,
        combatLogPanel = nil,
        combatLogText = nil,
        combatLogQueue = {},
        currentCombatLogEntry = nil,
        combatLogTickerToken = 0,
        combatLogTransitionToken = 0,
        portraitSlots = {},
        bossPortraitSlots = {},
        portraitSlotCount = 0,
        bossPortraitSlotCount = 0,
        currentKeys = {},
        currentVisualKeys = {},
        bossCurrentKeys = {},
        bossCurrentVisualKeys = {},
        portraitRefreshToken = 0,
        pendingTargetedPortraitRefreshPlan = nil,
        lastRefreshReason = nil,
    }, EventWidget)

    return self.Instance
end

local function enqueueEventPortraitRefreshWork(fn)
    if C_Timer and C_Timer.After then
        C_Timer.After(0, fn)
        return true
    end

    fn()
    return true
end

local function getMaxEventUnits()
    local activeRuleset = Ruleset and Ruleset.GetActiveRuleset and Ruleset.GetActiveRuleset() or nil
    local ruleDefinition = Ruleset and Ruleset.GetRulesetRuleDefinition and Ruleset.GetRulesetRuleDefinition("event", "max_event_units") or nil
    local maxEventUnits = Ruleset and Ruleset.GetRulesetRuleValue and Ruleset.GetRulesetRuleValue(activeRuleset, "event", ruleDefinition) or nil
    maxEventUnits = math.floor(tonumber(maxEventUnits) or DEFAULT_MAX_EVENT_UNITS)
    if maxEventUnits <= 0 then
        return DEFAULT_MAX_EVENT_UNITS
    end

    return maxEventUnits
end

local function buildPortraitSlot(parentFrame, name, portraitSize)
    local slot = UI.UnitPortrait:New({
        name = name,
        width = portraitSize,
        height = portraitSize,
        portraitWidth = portraitSize,
        portraitHeight = portraitSize,
        portraitBorderColor = UI.ResolveColor(nil, "panel.border"),
        progressHeight = PORTRAIT_HEALTH_BAR_HEIGHT,
        progressSpacing = PORTRAIT_BAR_SPACING,
        secondaryProgressHeight = PORTRAIT_PRIMARY_BAR_HEIGHT,
        secondaryProgressSpacing = PORTRAIT_SECONDARY_BAR_SPACING,
        castIconSize = PORTRAIT_CAST_ICON_SIZE,
        castIconSpacing = PORTRAIT_CAST_ICON_SPACING,
        unit = nil,
    })
    slot:SetParent(parentFrame)
    slot:Create()
    attachControlHandler(slot)
    return slot
end

local function buildHeaderTabButton(parentFrame, name, text, width, onClick)
    local tabBackgroundColor = UI.ResolveColor(nil, "tab.bar")
    local tabHoverColor = UI.ResolveColor(nil, "panel.background")
    local tabPressedColor = UI.ResolveColor(nil, "window.headerBackground")
    local tabLabelColor = UI.ResolveColor(nil, "tab.inactive")
    local tabBorderColor = UI.ResolveColor(nil, "panel.border")
    local button = UI.TextButton:New({
        name = name,
        width = width,
        height = HEADER_CONTROL_TAB_HEIGHT,
        text = text,
        fontSize = 9,
        fontFlags = "OUTLINE",
        labelColor = tabLabelColor,
        hoverLabelColor = UI.ResolveColor(nil, "text.primary"),
        pressedLabelColor = UI.ResolveColor(nil, "text.primary"),
        backgroundColor = tabBackgroundColor,
        hoverColor = tabHoverColor,
        pressedColor = tabPressedColor,
        borderTopColor = tabBorderColor,
        borderBottomColor = tabBorderColor,
        borderSize = 1,
    })
    button:SetParent(parentFrame)
    button:Create()
    button:SetScript("OnClick", onClick)
    local frame = button:GetFrame()
    if frame and frame.CreateTexture then
        button.leftBorder = frame:CreateTexture(nil, "ARTWORK")
        button.leftBorder:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
        button.leftBorder:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 0)
        button.leftBorder:SetWidth(1)
        button.leftBorder:SetColorTexture(
            tabBorderColor.r,
            tabBorderColor.g,
            tabBorderColor.b,
            tabBorderColor.a
        )

        button.rightBorder = frame:CreateTexture(nil, "ARTWORK")
        button.rightBorder:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
        button.rightBorder:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
        button.rightBorder:SetWidth(1)
        button.rightBorder:SetColorTexture(
            tabBorderColor.r,
            tabBorderColor.g,
            tabBorderColor.b,
            tabBorderColor.a
        )
    end
    return button
end

function EventWidget:Build()
    if self.rootPanel then
        return self.rootPanel
    end

    self.rootPanel = UI.CreatePanel(UIParent, "RPEClientEventWidgetRoot", {
        width = ROOT_WIDTH,
        height = ROOT_HEIGHT,
        contentInset = 0,
        showBorder = false,
        panelBackgroundColor = { r = 0, g = 0, b = 0, a = 0 },
        frameStrata = "MEDIUM",
        frameLevel = 60,
        hidden = true,
    })
    local rootFrame = self.rootPanel:GetFrame()
    rootFrame:SetPoint("TOP", UIParent, "TOP", 0, TOP_OFFSET)

    self.headerPanel = UI.CreatePanel(rootFrame, "RPEClientEventWidgetHeader", {
        width = HEADER_WIDTH,
        height = HEADER_HEIGHT,
        contentInset = 0,
        showBorder = false,
        panelBackgroundColor = { r = 0, g = 0, b = 0, a = 0 },
    })
    local headerFrame = self.headerPanel:GetFrame()
    headerFrame:SetPoint("TOP", rootFrame, "TOP", 0, 0)

    self.controlButtonRow = UI.CreateLayout(UI.HorizontalLayoutGroup, rootFrame, "RPEClientEventWidgetControlButtonRow", {
        spacing = CONTROL_BUTTON_SPACING,
        autoSize = true,
        fitChildrenWidth = false,
        fitChildrenHeight = false,
    })
    local controlRowFrame = self.controlButtonRow:GetFrame()
    controlRowFrame:SetPoint("BOTTOM", headerFrame, "TOP", 0, CONTROL_BUTTON_ROW_OFFSET)

    self.manageEventButton = buildHeaderTabButton(
        controlRowFrame,
        "RPEClientEventWidgetManageButton",
        "Manage",
        CONTROL_BUTTON_MANAGE_WIDTH,
        function()
            showEventManageFromWidget()
        end
    )
    self.controlButtonRow:AddChild(self.manageEventButton)

    self.stopEventButton = buildHeaderTabButton(
        controlRowFrame,
        "RPEClientEventWidgetStopButton",
        "Stop",
        CONTROL_BUTTON_STOP_WIDTH,
        function()
            stopEventFromWidget()
        end
    )
    self.controlButtonRow:AddChild(self.stopEventButton)

    self.advanceStepButton = buildHeaderTabButton(
        controlRowFrame,
        "RPEClientEventWidgetAdvanceStepButton",
        "Advance",
        CONTROL_BUTTON_ADVANCE_WIDTH,
        function()
            advanceEventStepFromWidget()
        end
    )
    self.controlButtonRow:AddChild(self.advanceStepButton)

    self.headerContentPanel = UI.CreatePanel(headerFrame, "RPEClientEventWidgetHeaderContent", {
        width = HEADER_WIDTH,
        height = HEADER_HEIGHT,
        contentInset = 0,
        showBorder = false,
        panelBackgroundColor = { r = 0, g = 0, b = 0, a = 0 },
    })
    local headerContentFrame = self.headerContentPanel:GetFrame()
    headerContentFrame:SetPoint("CENTER", headerFrame, "CENTER", 0, 0)

    self.headerBannerPanel = UI.CreatePanel(headerContentFrame, "RPEClientEventWidgetHeaderBanner", {
        width = HEADER_BANNER_WIDTH,
        height = HEADER_BANNER_HEIGHT,
        contentInset = 0,
        showBorder = true,
        panelBorderSize = 1,
        panelBorderTopColor = UI.ResolveColor(nil, "window.border"),
        panelBorderBottomColor = UI.ResolveColor(nil, "window.border"),
        panelBorderLeftColor = UI.ResolveColor(nil, "window.border"),
        panelBorderRightColor = UI.ResolveColor(nil, "window.border"),
        panelBackgroundColor = UI.ResolveColor(nil, "window.headerBackground"),
    })
    local headerBannerFrame = self.headerBannerPanel:GetFrame()
    headerBannerFrame:SetPoint("TOP", headerContentFrame, "TOP", 0, HEADER_BANNER_TOP_OFFSET)

    self.headerBannerShade = headerBannerFrame:CreateTexture(nil, "BACKGROUND")
    self.headerBannerShade:SetAllPoints(headerBannerFrame)
    self.headerBannerShade:SetTexture("Interface\\Buttons\\WHITE8x8")
    do
        local shadeColor = UI.ResolveColor(nil, "panel.background")
        self.headerBannerShade:SetVertexColor(shadeColor.r, shadeColor.g, shadeColor.b, 0.22)
    end

    self.headerBannerHighlight = headerBannerFrame:CreateTexture(nil, "BORDER")
    self.headerBannerHighlight:SetPoint("TOPLEFT", headerBannerFrame, "TOPLEFT", 1, -1)
    self.headerBannerHighlight:SetPoint("TOPRIGHT", headerBannerFrame, "TOPRIGHT", -1, -1)
    self.headerBannerHighlight:SetHeight(12)
    self.headerBannerHighlight:SetTexture("Interface\\Buttons\\WHITE8x8")
    do
        local highlightColor = UI.ResolveColor(nil, "text.primary")
        self.headerBannerHighlight:SetVertexColor(highlightColor.r, highlightColor.g, highlightColor.b, 0.05)
    end

    self.headerIcon = Image:New({
        name = "RPEClientEventWidgetHeaderIcon",
        width = EVENT_ICON_SIZE,
        height = EVENT_ICON_SIZE,
        texture = EVENT_ICON_TEXTURE,
        textureInsetLeft = 0,
        textureInsetTop = 0,
        textureInsetRight = 0,
        textureInsetBottom = 0,
        border = false,
    })
    self.headerIcon:SetParent(headerBannerFrame)
    self.headerIcon:Create()
    local headerIconFrame = self.headerIcon:GetFrame()
    headerIconFrame:ClearAllPoints()
    headerIconFrame:SetPoint("LEFT", headerBannerFrame, "LEFT", HEADER_ICON_OFFSET_X, HEADER_ICON_BANNER_Y)

    self.headerMeasureText = headerContentFrame:CreateFontString(nil, "OVERLAY")
    if self.headerMeasureText and self.headerMeasureText.Hide then
        self.headerMeasureText:Hide()
    end

    self.turnProgressBar = UI.ProgressBar:New({
        name = "RPEClientEventWidgetTurnProgress",
        width = 200,
        height = 8,
        minValue = 0,
        maxValue = 1,
        value = 0,
        text = "",
        backgroundToken = "progress.background",
        borderToken = "progress.border",
        primaryToken = "progress.barPrimary",
        secondaryToken = "progress.barSecondary",
        textToken = "progress.text",
    })
    self.waitingPanel = UI.CreatePanel(rootFrame, "RPEClientEventWidgetWaitingPanel", {
        width = ROOT_WIDTH,
        height = 34,
        contentInset = 0,
        showBorder = false,
        panelBackgroundColor = { r = 0, g = 0, b = 0, a = 0 },
    })
    local waitingFrame = self.waitingPanel:GetFrame()
    waitingFrame:SetPoint("TOP", headerFrame, "BOTTOM", 0, -4)

    self.waitingText = UI.CreateText(waitingFrame, "RPEClientEventWidgetWaitingText", "Waiting for Server", {
        fontSize = 10,
        fontFlags = "OUTLINE",
        justifyH = "CENTER",
        justifyV = "MIDDLE",
        wordWrap = false,
        textColor = UI.ResolveColor(nil, "text.primary"),
    })
    local waitingTextFrame = self.waitingText:GetFrame()
    waitingTextFrame:SetPoint("TOP", waitingFrame, "TOP", 0, 0)
    waitingTextFrame:SetPoint("LEFT", waitingFrame, "LEFT", 0, 0)
    waitingTextFrame:SetPoint("RIGHT", waitingFrame, "RIGHT", 0, 0)
    waitingTextFrame:SetHeight(16)

    self.waitingProgressPanel = UI.CreatePanel(waitingFrame, "RPEClientEventWidgetWaitingProgressPanel", {
        width = 200,
        height = 8,
        contentInset = 0,
        showBorder = false,
        panelBackgroundColor = { r = 0, g = 0, b = 0, a = 0 },
    })
    local waitingProgressFrame = self.waitingProgressPanel:GetFrame()
    waitingProgressFrame:SetPoint("TOP", waitingTextFrame, "BOTTOM", 0, 2)
    waitingProgressFrame:SetPoint("CENTER", waitingFrame, "CENTER", 0, -2)

    self.turnProgressBar:SetParent(waitingProgressFrame)
    self.turnProgressBar:Create()
    local turnProgressFrame = self.turnProgressBar:GetFrame()
    turnProgressFrame:ClearAllPoints()
    turnProgressFrame:SetPoint("TOPLEFT", waitingProgressFrame, "TOPLEFT", 0, 0)
    turnProgressFrame:SetPoint("BOTTOMRIGHT", waitingProgressFrame, "BOTTOMRIGHT", 0, 0)
    if self.turnProgressBar.label and self.turnProgressBar.label.Hide then
        self.turnProgressBar.label:Hide()
    end

    self.namePanel = UI.CreatePanel(headerBannerFrame, "RPEClientEventWidgetNameHost", {
        width = HEADER_BANNER_WIDTH - HEADER_BANNER_INSET_LEFT - HEADER_BANNER_TEXT_RIGHT - HEADER_STATUS_WIDTH,
        height = HEADER_BANNER_HEIGHT,
        contentInset = 0,
        showBorder = false,
        panelBackgroundColor = { r = 0, g = 0, b = 0, a = 0 },
    })
    local nameFrame = self.namePanel:GetFrame()
    nameFrame:SetPoint("LEFT", headerBannerFrame, "LEFT", HEADER_BANNER_INSET_LEFT, 0)
    nameFrame:SetPoint("RIGHT", headerBannerFrame, "RIGHT", -(HEADER_BANNER_TEXT_RIGHT + HEADER_STATUS_WIDTH), 0)
    nameFrame:SetPoint("TOP", headerBannerFrame, "TOP", 0, 0)
    nameFrame:SetPoint("BOTTOM", headerBannerFrame, "BOTTOM", 0, 0)

    self.titleText = UI.CreateText(nameFrame, "RPEClientEventWidgetTitle", "Active Event", {
        fontSize = 15,
        fontFlags = "OUTLINE",
        justifyH = "CENTER",
        justifyV = "TOP",
        wordWrap = false,
        textColor = UI.ResolveColor(nil, "text.primary"),
    })
    local titleFrame = self.titleText:GetFrame()
    titleFrame:SetPoint("TOP", nameFrame, "TOP", 0, -2)
    titleFrame:SetHeight(TITLE_HEIGHT)

    self.subtitleText = UI.CreateText(nameFrame, "RPEClientEventWidgetSubtitle", " ", {
        fontSize = 9,
        justifyH = "CENTER",
        justifyV = "TOP",
        wordWrap = false,
        textColor = UI.ResolveColor(nil, "text.muted"),
    })
    local subtitleFrame = self.subtitleText:GetFrame()
    subtitleFrame:SetPoint("TOP", titleFrame, "BOTTOM", 0, -1)
    subtitleFrame:SetHeight(SUBTITLE_HEIGHT)

    self.turnStatusText = UI.CreateText(headerBannerFrame, "RPEClientEventWidgetTurnStatus", "1", {
        width = HEADER_STATUS_WIDTH,
        height = 20,
        fontSize = 13,
        fontFlags = "OUTLINE",
        justifyH = "CENTER",
        justifyV = "MIDDLE",
        wordWrap = false,
        textColor = UI.ResolveColor(nil, "text.secondary"),
    })
    local turnStatusFrame = self.turnStatusText:GetFrame()
    turnStatusFrame:SetPoint("RIGHT", headerBannerFrame, "RIGHT", -12, 0)

    self.portraitPanel = UI.CreatePanel(rootFrame, "RPEClientEventWidgetPortraitHost", {
        width = ROOT_WIDTH,
        height = getPortraitPanelHeight(false),
        contentInset = 0,
        showBorder = false,
        panelBackgroundColor = { r = 0, g = 0, b = 0, a = 0 },
    })
    local portraitFrame = self.portraitPanel:GetFrame()
    portraitFrame:SetPoint("TOP", self.waitingPanel:GetFrame(), "BOTTOM", 0, PORTRAIT_TOP_OFFSET)

    self.bossPortraitPanel = UI.CreatePanel(portraitFrame, "RPEClientEventWidgetBossPortraitHost", {
        width = ROOT_WIDTH,
        height = BOSS_PORTRAIT_FRAME_HEIGHT + 8,
        contentInset = 0,
        showBorder = false,
        panelBackgroundColor = { r = 0, g = 0, b = 0, a = 0 },
    })
    local bossPortraitFrame = self.bossPortraitPanel:GetFrame()
    bossPortraitFrame:SetPoint("TOP", portraitFrame, "TOP", 0, 0)

    self.initiativePortraitPanel = UI.CreatePanel(portraitFrame, "RPEClientEventWidgetInitiativePortraitHost", {
        width = ROOT_WIDTH,
        height = PORTRAIT_FRAME_HEIGHT + 8,
        contentInset = 0,
        showBorder = false,
        panelBackgroundColor = { r = 0, g = 0, b = 0, a = 0 },
    })
    local initiativePortraitFrame = self.initiativePortraitPanel:GetFrame()
    initiativePortraitFrame:SetPoint("TOP", bossPortraitFrame, "BOTTOM", 0, -PORTRAIT_SECTION_SPACING)

    self.combatLogPanel = UI.CreatePanel(rootFrame, "RPEClientEventWidgetCombatLogPanel", {
        width = 336,
        height = COMBAT_LOG_PANEL_HEIGHT,
        contentInset = 0,
        showBorder = true,
        panelBorderSize = 1,
        panelBorderColor = UI.ResolveColor(nil, "panel.border"),
        panelBackgroundColor = UI.ResolveColor(nil, "panel.background"),
        alpha = 1,
    })
    local combatLogFrame = self.combatLogPanel:GetFrame()
    combatLogFrame:SetPoint("TOP", portraitFrame, "BOTTOM", 0, COMBAT_LOG_TOP_OFFSET)
    combatLogFrame:Hide()

    self.combatLogText = UI.CreateText(combatLogFrame, "RPEClientEventWidgetCombatLogText", "", {
        width = 304,
        height = COMBAT_LOG_PANEL_HEIGHT,
        fontSize = 12,
        fontFlags = "OUTLINE",
        justifyH = "CENTER",
        justifyV = "MIDDLE",
        wordWrap = false,
        textColor = UI.ResolveColor(nil, "text.primary"),
    })
    local combatLogTextFrame = self.combatLogText:GetFrame()
    combatLogTextFrame:SetPoint("TOP", combatLogFrame, "TOP", 0, 0)
    combatLogTextFrame:SetPoint("BOTTOM", combatLogFrame, "BOTTOM", 0, 0)
    combatLogTextFrame:SetPoint("LEFT", combatLogFrame, "LEFT", 12, 0)
    combatLogTextFrame:SetPoint("RIGHT", combatLogFrame, "RIGHT", -12, 0)

    self.advanceStepButton:SetScript("OnEnter", function()
        if Client.ShowPendingTurnChangesTooltip then
            Client:ShowPendingTurnChangesTooltip(self.advanceStepButton)
        end
    end)
    self.advanceStepButton:SetScript("OnLeave", function()
        if Client.HidePendingTurnChangesTooltip then
            Client:HidePendingTurnChangesTooltip()
        end
    end)
    self.advanceStepButton:SetScript("OnHide", function()
        if Client.HidePendingTurnChangesTooltip then
            Client:HidePendingTurnChangesTooltip()
        end
    end)

    local manageFrame = self.manageEventButton:GetFrame()
    local stopFrame = self.stopEventButton:GetFrame()
    local advanceFrame = self.advanceStepButton:GetFrame()
    if manageFrame and manageFrame.Hide then
        manageFrame:Hide()
    end
    if stopFrame and stopFrame.Hide then
        stopFrame:Hide()
    end
    if advanceFrame and advanceFrame.Hide then
        advanceFrame:Hide()
    end
    if controlRowFrame and controlRowFrame.Hide then
        controlRowFrame:Hide()
    end

    rootFrame:Hide()
    return self.rootPanel
end

function EventWidget:EnsurePortraitSlot(index)
    local slot = self.portraitSlots[index]
    if slot then
        return slot
    end

    slot = buildPortraitSlot(self.initiativePortraitPanel:GetFrame(), ("RPEClientEventWidgetPortrait%d"):format(index), PORTRAIT_SIZE)
    self.portraitSlots[index] = slot
    return slot
end

function EventWidget:EnsureBossPortraitSlot(index)
    local slot = self.bossPortraitSlots[index]
    if slot then
        return slot
    end

    slot = buildPortraitSlot(self.bossPortraitPanel:GetFrame(), ("RPEClientEventWidgetBossPortrait%d"):format(index), BOSS_PORTRAIT_SIZE)
    self.bossPortraitSlots[index] = slot
    return slot
end

function EventWidget:EnsurePortraitPool(slotCount)
    slotCount = math.max(1, math.floor(tonumber(slotCount) or DEFAULT_MAX_EVENT_UNITS))
    self.portraitSlotCount = slotCount

    for index = 1, slotCount do
        self:EnsurePortraitSlot(index)
    end

    for index = slotCount + 1, #(self.portraitSlots or {}) do
        local slot = self.portraitSlots[index]
        local frame = slot and slot.GetFrame and slot:GetFrame() or nil
        if frame and frame.Hide then
            frame:Hide()
        end
    end

    return self.portraitSlots
end

function EventWidget:EnsureBossPortraitPool(slotCount)
    slotCount = math.max(0, math.floor(tonumber(slotCount) or 0))
    self.bossPortraitSlotCount = slotCount

    for index = 1, slotCount do
        self:EnsureBossPortraitSlot(index)
    end

    for index = slotCount + 1, #(self.bossPortraitSlots or {}) do
        local slot = self.bossPortraitSlots[index]
        local frame = slot and slot.GetFrame and slot:GetFrame() or nil
        if frame and frame.Hide then
            frame:Hide()
        end
    end

    return self.bossPortraitSlots
end

function EventWidget:UpdateHeaderLayout()
    if not self.headerPanel
        or not self.headerContentPanel
        or not self.headerBannerPanel
        or not self.namePanel
        or not self.titleText
        or not self.subtitleText
    then
        return false
    end

    local titleText = tostring(self.titleText.GetText and self.titleText:GetText() or "")
    local subtitleText = tostring(self.subtitleText.GetText and self.subtitleText:GetText() or "")
    local measureText = self.headerMeasureText
    local titleRegion = self.titleText.textRegion
    local subtitleRegion = self.subtitleText.textRegion
    local headerFrame = self.headerPanel:GetFrame()
    local headerContentFrame = self.headerContentPanel:GetFrame()
    local headerBannerFrame = self.headerBannerPanel:GetFrame()
    local nameFrame = self.namePanel:GetFrame()
    local titleFrame = self.titleText:GetFrame()
    local subtitleFrame = self.subtitleText:GetFrame()
    local headerIconFrame = self.headerIcon and self.headerIcon.GetFrame and self.headerIcon:GetFrame() or nil
    local turnStatusFrame = self.turnStatusText and self.turnStatusText.GetFrame and self.turnStatusText:GetFrame() or nil

    if measureText and titleRegion and titleRegion.GetFont and measureText.SetFont then
        local fontFile, fontSize, fontFlags = titleRegion:GetFont()
        if fontFile then
            measureText:SetFont(fontFile, fontSize, fontFlags)
        end
    end
    local measuredTitleWidth = measureFontStringWidth(measureText, titleText)

    if measureText and subtitleRegion and subtitleRegion.GetFont and measureText.SetFont then
        local fontFile, fontSize, fontFlags = subtitleRegion:GetFont()
        if fontFile then
            measureText:SetFont(fontFile, fontSize, fontFlags)
        end
    end
    local measuredSubtitleWidth = measureFontStringWidth(measureText, subtitleText)

    local statusWidth = turnStatusFrame and turnStatusFrame.IsShown and turnStatusFrame:IsShown() and HEADER_STATUS_WIDTH or 0
    local rightReservedWidth = statusWidth + 12
    local maxTextWidth = HEADER_BANNER_WIDTH - HEADER_BANNER_INSET_LEFT - HEADER_BANNER_TEXT_RIGHT - rightReservedWidth
    local titleWidth = math.max(24, math.min(maxTextWidth, measuredTitleWidth + HEADER_TEXT_WIDTH_FUDGE))
    local subtitleWidth = math.max(
        math.min(maxTextWidth, math.max(titleWidth, measuredSubtitleWidth + HEADER_TEXT_WIDTH_FUDGE)),
        math.min(maxTextWidth, math.max(120, measuredSubtitleWidth + HEADER_TEXT_WIDTH_FUDGE))
    )

    headerFrame:SetWidth(HEADER_WIDTH)
    headerContentFrame:SetWidth(HEADER_WIDTH)
    headerBannerFrame:SetWidth(HEADER_BANNER_WIDTH)
    headerBannerFrame:SetHeight(HEADER_BANNER_HEIGHT)

    nameFrame:ClearAllPoints()
    nameFrame:SetPoint("LEFT", headerBannerFrame, "LEFT", HEADER_BANNER_INSET_LEFT, 0)
    nameFrame:SetPoint("RIGHT", headerBannerFrame, "RIGHT", -(HEADER_BANNER_TEXT_RIGHT + rightReservedWidth), 0)
    nameFrame:SetPoint("TOP", headerBannerFrame, "TOP", 0, 0)
    nameFrame:SetPoint("BOTTOM", headerBannerFrame, "BOTTOM", 0, 0)

    titleFrame:ClearAllPoints()
    titleFrame:SetPoint("TOP", nameFrame, "TOP", 0, -2)
    titleFrame:SetWidth(titleWidth)

    subtitleFrame:ClearAllPoints()
    subtitleFrame:SetPoint("TOP", titleFrame, "BOTTOM", 0, -1)
    subtitleFrame:SetWidth(subtitleWidth)
    subtitleFrame:SetShown(subtitleText ~= "" and subtitleText ~= " ")

    if headerIconFrame then
        headerIconFrame:ClearAllPoints()
        headerIconFrame:SetPoint("LEFT", headerBannerFrame, "LEFT", HEADER_ICON_OFFSET_X, HEADER_ICON_BANNER_Y)
    end

    return true
end

function EventWidget:Show()
    self:Build()
    self.rootPanel:Show()
    return true
end

function EventWidget:Hide()
    if not self.rootPanel then
        return true
    end

    self:ClearCombatLogTicker("hide")
    self.rootPanel:Hide()
    return true
end

function EventWidget:StartCombatLogTickerTimer()
    self.combatLogTickerToken = math.max(0, tonumber(self.combatLogTickerToken) or 0) + 1
    local token = self.combatLogTickerToken
    if type(C_Timer) == "table" and type(C_Timer.NewTimer) == "function" then
        C_Timer.NewTimer(COMBAT_LOG_TIME_VISIBLE, function()
            if self.combatLogTickerToken == token then
                self:AdvanceCombatLogTicker()
            end
        end)
        return true
    end
    if type(C_Timer) == "table" and type(C_Timer.After) == "function" then
        C_Timer.After(COMBAT_LOG_TIME_VISIBLE, function()
            if self.combatLogTickerToken == token then
                self:AdvanceCombatLogTicker()
            end
        end)
        return true
    end

    return false
end

function EventWidget:StopCombatLogTransitions()
    if self.combatLogPanel and self.combatLogPanel.StopFade then
        self.combatLogPanel:StopFade()
    end
end

function EventWidget:ShowCurrentCombatLogEntry(useFade)
    if not self.combatLogPanel or not self.combatLogText then
        return false
    end

    local frame = self.combatLogPanel.GetFrame and self.combatLogPanel:GetFrame() or nil
    if type(self.currentCombatLogEntry) ~= "table" then
        if self.combatLogText.SetText then
            self.combatLogText:SetText("")
        end
        if frame and frame.Hide then
            frame:Hide()
        end
        return false
    end

    if self.combatLogText.SetText then
        self.combatLogText:SetText(buildCombatLogText(self.currentCombatLogEntry))
    end
    self:StopCombatLogTransitions()
    if useFade ~= false and self.combatLogPanel.FadeIn then
        self.combatLogPanel:FadeIn(COMBAT_LOG_FADE_IN_DURATION)
    elseif frame and frame.Show then
        if frame.SetAlpha then
            frame:SetAlpha(1)
        end
        frame:Show()
    end
    self:StartCombatLogTickerTimer()
    return true
end

function EventWidget:AdvanceCombatLogTicker()
    self.combatLogTickerToken = math.max(0, tonumber(self.combatLogTickerToken) or 0) + 1
    self.combatLogTransitionToken = math.max(0, tonumber(self.combatLogTransitionToken) or 0) + 1
    local transitionToken = self.combatLogTransitionToken

    local function completeAdvance()
        if self.combatLogTransitionToken ~= transitionToken then
            return false
        end

        local nextEntry = nil
        if type(self.combatLogQueue) == "table" and #self.combatLogQueue > 0 then
            nextEntry = table.remove(self.combatLogQueue, 1)
        end
        self.currentCombatLogEntry = nextEntry
        return self:ShowCurrentCombatLogEntry(true)
    end

    if type(self.currentCombatLogEntry) ~= "table" then
        return completeAdvance()
    end

    self:StopCombatLogTransitions()
    if self.combatLogPanel and self.combatLogPanel.FadeOut then
        self.combatLogPanel:FadeOut(COMBAT_LOG_FADE_OUT_DURATION, function()
            completeAdvance()
        end)
        return true
    end

    return completeAdvance()
end

function EventWidget:ClearCombatLogTicker(reason)
    self.combatLogTickerToken = math.max(0, tonumber(self.combatLogTickerToken) or 0) + 1
    self.combatLogTransitionToken = math.max(0, tonumber(self.combatLogTransitionToken) or 0) + 1
    self.currentCombatLogEntry = nil
    self.combatLogQueue = {}
    self.lastCombatLogReason = reason
    self:StopCombatLogTransitions()
    if self.combatLogText and self.combatLogText.SetText then
        self.combatLogText:SetText("")
    end
    local frame = self.combatLogPanel and self.combatLogPanel.GetFrame and self.combatLogPanel:GetFrame() or nil
    if frame and frame.Hide then
        if frame.SetAlpha then
            frame:SetAlpha(1)
        end
        frame:Hide()
    end
    return true
end

function EventWidget:QueueCombatLogEntry(entry)
    if type(entry) ~= "table" then
        return false
    end

    self:Build()
    self.combatLogQueue = self.combatLogQueue or {}
    self.combatLogQueue[#self.combatLogQueue + 1] = entry
    if type(self.currentCombatLogEntry) ~= "table" then
        return self:AdvanceCombatLogTicker()
    end

    return true
end

function EventWidget:LayoutPortraitRow(panel, slots, slotCount, portraitSize, portraitSpacing)
    if not panel then
        return false
    end

    local count = math.max(0, math.floor(tonumber(slotCount) or 0))
    if count == 0 then
        return true
    end

    local totalWidth = (count * portraitSize) + ((count - 1) * portraitSpacing)
    local startOffset = -(totalWidth / 2)

    for index = 1, count do
        local portrait = slots[index]
        local frame = portrait and portrait.GetFrame and portrait:GetFrame() or nil

        if frame then
            frame:ClearAllPoints()
            frame:SetPoint("TOPLEFT", panel:GetFrame(), "TOP", startOffset + ((index - 1) * (portraitSize + portraitSpacing)), 0)
        end
    end

    return true
end

function EventWidget:BuildPortraitRefreshContext(state)
    local maxEventUnits = getMaxEventUnits()
    local units = state and state.units or {}
    local pageNumber = math.max(1, math.floor(tonumber(state and state.tickNumber) or 1))
    local isHost = isLocalHostForEvent(state)
    local pageUnits = getWidgetUnitsForPage(units, pageNumber, maxEventUnits)
    local bossUnits = collectBossUnits(units)
    local controlContext = Client.GetActionBarControlContext and Client:GetActionBarControlContext(state) or nil
    local controlledUnitId = tonumber(controlContext and controlContext.isControlled == true and controlContext.controlledUnit and controlContext.controlledUnit.eventID or 0) or 0
    local dimOtherPortraits = controlledUnitId > 0
    local actionBarWidget = getActionBarWidget()
    local actionBarResourceContext = type(actionBarWidget) == "table"
        and type(actionBarWidget.BuildActionBarResourceContext) == "function"
        and actionBarWidget:BuildActionBarResourceContext(state)
        or nil
    local localEventUnit = Client.ResolveLocalEventUnit and Client:ResolveLocalEventUnit(state) or nil

    return {
        maxEventUnits = maxEventUnits,
        pageUnits = pageUnits,
        bossUnits = bossUnits,
        isHost = isHost,
        controlledUnitId = controlledUnitId,
        dimOtherPortraits = dimOtherPortraits,
        actionBarWidget = actionBarWidget,
        actionBarResourceContext = actionBarResourceContext,
        localEventUnit = localEventUnit,
    }
end

function EventWidget:RefreshPortraitSlot(index, eventUnit, state, context, options)
    context = type(context) == "table" and context or self:BuildPortraitRefreshContext(state)
    options = type(options) == "table" and options or {}
    local portrait = options.ensureSlot and options.ensureSlot(self, index) or self:EnsurePortraitSlot(index)
    local frame = portrait and portrait.GetFrame and portrait:GetFrame() or nil
    local displayUnit = buildWidgetDisplayUnit(eventUnit, context.isHost)
    local desiredUnit = state.unitsReady == true and displayUnit or nil
    local healthState, primaryState = buildPortraitResourceStates(
        context.actionBarWidget,
        desiredUnit,
        state,
        context.actionBarResourceContext
    )
    local castState = buildPortraitCastState(context.actionBarWidget, desiredUnit, state)
    local isPet = desiredUnit and isLocalPlayerPet(desiredUnit, context.localEventUnit) or false
    local targetIndicatorState = desiredUnit
        and Client.ResolveEventUnitInteractionMarkerState
        and Client:ResolveEventUnitInteractionMarkerState(desiredUnit, state)
        or { visible = false, alpha = 0 }
    local isHiddenUnit = type(eventUnit) == "table" and eventUnit.hidden == true
    local hideHiddenUnitDetails = isHiddenUnit and context.isHost ~= true
    local turnComplete = desiredUnit
        and Client.IsEventUnitTurnComplete
        and Client:IsEventUnitTurnComplete(desiredUnit, state)
        or false
    local nextKey = buildPortraitDisplayKey(state, desiredUnit or eventUnit, healthState, primaryState, castState, isPet, targetIndicatorState, turnComplete)
        .. "\31" .. (isHiddenUnit and "hidden" or "visible")
        .. "\31" .. (context.isHost == true and "host" or "client")
    local currentKeys = type(options.currentKeys) == "table" and options.currentKeys or self.currentKeys
    local currentVisualKeys = type(options.currentVisualKeys) == "table" and options.currentVisualKeys or self.currentVisualKeys
    local previousKey = currentKeys[index]
    local visualKey = buildPortraitVisualKey(state, desiredUnit or eventUnit)
    local previousVisualKey = currentVisualKeys[index]
    local desiredUnitChanged = portrait and portrait.portraitUnit ~= desiredUnit
    local portraitStateChanged = desiredUnitChanged or previousKey ~= nextKey
    local portraitVisualChanged = desiredUnitChanged or previousVisualKey ~= visualKey

    if portrait and portrait.SetUnit and desiredUnitChanged then
        portrait:SetUnit(desiredUnit)
    elseif portrait and portraitVisualChanged and portrait.RefreshPortrait then
        portrait:RefreshPortrait()
    end

    if portrait and portraitVisualChanged and portrait.SetTooltip then
        local tooltip = state.unitsReady == true and desiredUnit and function()
            local currentState = Client.GetEventState and Client:GetEventState() or state
            return EventWidget:BuildPortraitTooltip(portrait.portraitUnit or desiredUnit, currentState)
        end or nil
        portrait:SetTooltip(tooltip)
        if portrait.portraitPanel and portrait.portraitPanel.SetTooltip then
            portrait.portraitPanel:SetTooltip(tooltip)
        end
    end
    if portrait and portraitStateChanged and portrait.SetBorderColor and desiredUnit then
        local teamColor = getTeamColor(state, eventUnit and eventUnit.team)
        portrait:SetBorderColor(teamColor.r, teamColor.g, teamColor.b, teamColor.a)
    end
    if portrait and portraitStateChanged and portrait.SetProgressState then
        portrait:SetProgressState(healthState)
    end
    if portrait and portraitStateChanged and portrait.SetSecondaryProgressState then
        portrait:SetSecondaryProgressState(primaryState and primaryState.resourceRef ~= (healthState and healthState.resourceRef or nil) and primaryState or nil)
    end
    if portrait and portraitStateChanged and portrait.SetRaidMarker then
        portrait:SetRaidMarker(desiredUnit and desiredUnit.raidMarker or 0)
    end
    if portrait and portraitStateChanged and portrait.SetPetIndicatorVisible then
        portrait:SetPetIndicatorVisible(isPet)
    end
    if portrait and portraitStateChanged and portrait.SetTargetIndicatorVisible then
        portrait:SetTargetIndicatorVisible(targetIndicatorState and targetIndicatorState.visible == true)
    end
    if portrait and portraitStateChanged and portrait.SetTargetIndicatorAlpha then
        portrait:SetTargetIndicatorAlpha(tonumber(targetIndicatorState and targetIndicatorState.alpha) or 0)
    end
    if portrait and portraitStateChanged and portrait.SetTurnCompleteIndicatorVisible then
        portrait:SetTurnCompleteIndicatorVisible(turnComplete)
    end
    if portrait and portraitStateChanged and portrait.SetCastIcon then
        portrait:SetCastIcon(castState and castState.icon or nil)
    end
    if portrait and portraitStateChanged and portrait.SetHiddenPresentation then
        portrait:SetHiddenPresentation(isHiddenUnit, hideHiddenUnitDetails)
    end

    if frame then
        if state.unitsReady == true and eventUnit then
            if frame.SetAlpha then
                if context.dimOtherPortraits and tonumber(eventUnit.eventID) ~= context.controlledUnitId then
                    frame:SetAlpha(INACTIVE_PORTRAIT_ALPHA)
                else
                    frame:SetAlpha(ACTIVE_PORTRAIT_ALPHA)
                end
            end
            frame:Show()
        else
            if frame.SetAlpha then
                frame:SetAlpha(ACTIVE_PORTRAIT_ALPHA)
            end
            frame:Hide()
        end
    end

    currentKeys[index] = nextKey
    currentVisualKeys[index] = visualKey
    return true
end

function EventWidget:CancelPendingTargetedPortraitRefresh()
    self.portraitRefreshToken = math.max(0, math.floor(tonumber(self.portraitRefreshToken) or 0)) + 1
    self.pendingTargetedPortraitRefreshPlan = nil
    return self.portraitRefreshToken
end

function EventWidget:BuildTargetedPortraitRefreshPlan(eventIds, reason)
    local state = Client:GetEventState()
    if not state or state.active ~= true then
        return nil
    end

    self:Build()
    self:Show()

    local context = self:BuildPortraitRefreshContext(state)
    self:EnsurePortraitPool(context.maxEventUnits)
    self:EnsureBossPortraitPool(#(context.bossUnits or {}))

    local targetEventIds = {}
    for eventId in pairs(eventIds or {}) do
        local numericEventId = tonumber(eventId) or 0
        if numericEventId > 0 then
            targetEventIds[#targetEventIds + 1] = numericEventId
        end
    end

    return {
        token = self.portraitRefreshToken,
        reason = reason,
        state = state,
        context = context,
        targetEventIds = targetEventIds,
        nextIndex = 1,
        refreshed = false,
    }
end

function EventWidget:DrainTargetedPortraitRefreshPlan(token)
    local plan = self.pendingTargetedPortraitRefreshPlan
    if type(plan) ~= "table" or tonumber(plan.token) ~= tonumber(token) then
        return false
    end

    local processed = 0
    while processed < 1 and plan.nextIndex <= #(plan.targetEventIds or {}) do
        local eventId = plan.targetEventIds[plan.nextIndex]
        local slotIndex = findPageUnitIndexByEventId(plan.context.pageUnits, eventId)
        if slotIndex then
            self:RefreshPortraitSlot(slotIndex, plan.context.pageUnits[slotIndex], plan.state, plan.context)
            plan.refreshed = true
        end

        local bossSlotIndex = findUnitIndexByEventId(plan.context.bossUnits, eventId)
        if bossSlotIndex then
            self:RefreshPortraitSlot(bossSlotIndex, plan.context.bossUnits[bossSlotIndex], plan.state, plan.context, {
                ensureSlot = self.EnsureBossPortraitSlot,
                currentKeys = self.bossCurrentKeys,
                currentVisualKeys = self.bossCurrentVisualKeys,
            })
            plan.refreshed = true
        end

        plan.nextIndex = plan.nextIndex + 1
        processed = processed + 1
    end

    local morePending = plan.nextIndex <= #(plan.targetEventIds or {})
    if morePending then
        enqueueEventPortraitRefreshWork(function()
            self:DrainTargetedPortraitRefreshPlan(token)
        end)
        return plan.refreshed
    end

    self.pendingTargetedPortraitRefreshPlan = nil
    return plan.refreshed
end

function EventWidget:RefreshPortraitsForEventIds(eventIds, reason)
    self.lastRefreshReason = reason
    local token = self:CancelPendingTargetedPortraitRefresh()
    local plan = self:BuildTargetedPortraitRefreshPlan(eventIds, reason)
    if type(plan) ~= "table" then
        self:Hide()
        return false
    end
    plan.token = token
    self.pendingTargetedPortraitRefreshPlan = plan
    return self:DrainTargetedPortraitRefreshPlan(token)
end

function EventWidget:Refresh(reason)
    self.lastRefreshReason = reason
    local maxEventUnits = getMaxEventUnits()
    local state = Client:GetEventState()
    if not state or state.active ~= true then
        self:Hide()
        return false
    end

    self:Build()
    self:Show()
    self:EnsurePortraitPool(maxEventUnits)

    self.titleText:SetText(tostring(state.name ~= "" and state.name or state.id or "Active Event"))
    self.subtitleText:SetText(getSubtitleText(state))
    if self.headerIcon and self.headerIcon.SetTexture then
        self.headerIcon:SetTexture(getEventHeaderIconTexture(state.difficulty))
    end
    if self.turnStatusText and self.turnStatusText.SetText then
        self.turnStatusText:SetText(tostring(math.max(1, tonumber(state.turnNumber) or 1)))
    end
    local startupPending = state.unitsReady ~= true or state.startupReady ~= true
    local startupPhase = tostring(
        state.transitionPhase
            or state.startupPhase
            or (state.unitsReady == true and "syncing-local" or "waiting-units")
    )
    if self.waitingPanel and self.waitingPanel.GetFrame then
        local waitingFrame = self.waitingPanel:GetFrame()
        if waitingFrame then
            if startupPending then
                waitingFrame:Show()
            else
                waitingFrame:Hide()
            end
        end
    end
    if self.portraitPanel and self.portraitPanel.GetFrame then
        local portraitFrame = self.portraitPanel:GetFrame()
        local headerFrame = self.headerPanel and self.headerPanel.GetFrame and self.headerPanel:GetFrame() or nil
        local waitingFrame = self.waitingPanel and self.waitingPanel.GetFrame and self.waitingPanel:GetFrame() or nil
        if portraitFrame and headerFrame then
            portraitFrame:ClearAllPoints()
            if startupPending and waitingFrame then
                portraitFrame:SetPoint("TOP", waitingFrame, "BOTTOM", 0, PORTRAIT_TOP_OFFSET)
            else
                portraitFrame:SetPoint("TOP", headerFrame, "BOTTOM", 0, PORTRAIT_TOP_OFFSET)
            end
        end
    end
    if self.waitingText and self.waitingText.SetText then
        local waitingText = ""
        if startupPending then
            if startupPhase == "starting" then
                waitingText = "Starting Event"
            elseif startupPhase == "ending" then
                waitingText = "Ending Event"
            elseif startupPhase == "apply-validate-state" then
                waitingText = "Applying Event State"
            elseif startupPhase == "waiting-state" then
                waitingText = "Waiting for Server State"
            elseif startupPhase == "action-bar-metadata" then
                waitingText = "Preparing Action Bar"
            elseif startupPhase == "trait-runtime" then
                waitingText = "Preparing Traits"
            elseif startupPhase == "automatic-auras" then
                waitingText = "Syncing Automatic Auras"
            elseif startupPhase == "event-auras" then
                waitingText = "Syncing Event Auras"
            elseif startupPhase == "resolved-trait" then
                waitingText = "Resolving Traits"
            elseif startupPhase == "resource-sync" then
                waitingText = "Syncing Resources"
            elseif startupPhase == "waiting-resources" then
                waitingText = "Waiting for Player Resources"
            elseif startupPhase == "consumable-prompts" then
                waitingText = "Waiting for Consumable Choice"
            elseif startupPhase == "achievement" then
                waitingText = "Completing Event"
            elseif startupPhase == "clear-combat-log" then
                waitingText = "Clearing Event Log"
            elseif startupPhase == "clear-spellcasting" then
                waitingText = "Clearing Spellcasting"
            elseif startupPhase == "clear-traits" then
                waitingText = "Clearing Traits"
            elseif startupPhase == "clear-targeting" then
                waitingText = "Clearing Targeting"
            elseif startupPhase == "clear-revisions" then
                waitingText = "Clearing Event State"
            elseif startupPhase == "commit" then
                waitingText = "Saving Event Results"
            elseif startupPhase == "visual-teardown" then
                waitingText = "Closing Event"
            elseif startupPhase == "syncing-local" then
                waitingText = "Preparing Event"
            else
                waitingText = "Waiting for Event Units"
            end
        end
        self.waitingText:SetText(waitingText)
    end
    if self.turnProgressBar and self.turnProgressBar.SetMinMax and self.turnProgressBar.SetValue then
        local progressFrame = self.turnProgressBar.GetFrame and self.turnProgressBar:GetFrame() or nil

        if startupPending then
            local expectedCount = math.max(
                0,
                tonumber(state.startupProgressExpected)
                    or tonumber(state.readyProgressExpected)
                    or tonumber(state.unitsChunkExpected)
                    or 0
            )
            local receivedCount = math.max(
                0,
                tonumber(state.startupProgressReceived)
                    or tonumber(state.readyProgressReceived)
                    or tonumber(state.unitsChunkReceived)
                    or 0
            )
            if expectedCount > 0 then
                self.turnProgressBar:SetMinMax(0, expectedCount)
                self.turnProgressBar:SetValue(math.min(receivedCount, expectedCount))
            else
                self.turnProgressBar:SetMinMax(0, 1)
                self.turnProgressBar:SetValue(0)
            end
            if progressFrame and progressFrame.Show then
                progressFrame:Show()
            end
        else
            local totalTicks = math.max(0, tonumber(state.totalTicks) or 0)
            local tickNumber = math.max(0, tonumber(state.tickNumber) or 0)
            if totalTicks > 1 then
                self.turnProgressBar:SetMinMax(0, totalTicks)
                self.turnProgressBar:SetValue(math.min(tickNumber, totalTicks))
                if progressFrame and progressFrame.Show then
                    progressFrame:Show()
                end
            elseif progressFrame and progressFrame.Hide then
                progressFrame:Hide()
            end
        end
    end
    local manageFrame = self.manageEventButton and self.manageEventButton.GetFrame and self.manageEventButton:GetFrame() or nil
    local stopFrame = self.stopEventButton and self.stopEventButton.GetFrame and self.stopEventButton:GetFrame() or nil
    local advanceFrame = self.advanceStepButton and self.advanceStepButton.GetFrame and self.advanceStepButton:GetFrame() or nil
    local controlRowFrame = self.controlButtonRow and self.controlButtonRow.GetFrame and self.controlButtonRow:GetFrame() or nil
    if advanceFrame or manageFrame or stopFrame or controlRowFrame then
        local isHost = isLocalHostForEvent(state)
        local canManage = isHost == true
            and type(Addon.Server) == "table"
            and type(Addon.Server.ShowEventManageWindow) == "function"
        local canStop = isHost == true
            and type(Addon.Server) == "table"
            and type(Addon.Server.EndEvent) == "function"
        local canAdvance = false
        if isHost == true
            and type(Client.CanPerformEventAction) == "function"
            and type(Addon.Server) == "table"
            and type(Addon.Server.AdvanceEventStep) == "function"
        then
            local clientEventState = type(Client.GetEventState) == "function" and Client:GetEventState() or nil
            canAdvance = type(clientEventState) == "table"
                and clientEventState == state
                and clientEventState.unitsReady == true
                and Client:CanPerformEventAction(clientEventState, "advance-event-step") == true
        end
        if controlRowFrame then
            if isHost then
                controlRowFrame:Show()
            else
                controlRowFrame:Hide()
            end
        end
        if manageFrame then
            if isHost then
                manageFrame:Show()
            else
                manageFrame:Hide()
            end
        end
        if stopFrame then
            if isHost then
                stopFrame:Show()
            else
                stopFrame:Hide()
            end
        end
        if advanceFrame then
            if isHost then
                advanceFrame:Show()
            else
                advanceFrame:Hide()
            end
        end
        if self.manageEventButton and self.manageEventButton.SetEnabled then
            self.manageEventButton:SetEnabled(canManage)
        end
        if self.stopEventButton and self.stopEventButton.SetEnabled then
            self.stopEventButton:SetEnabled(canStop)
        end
        if self.advanceStepButton.SetEnabled then
            self.advanceStepButton:SetEnabled(canAdvance)
        end
    end
    self:UpdateHeaderLayout()

    local context = self:BuildPortraitRefreshContext(state)
    local pageUnits = context.pageUnits
    local bossUnits = context.bossUnits or {}
    local bossHostFrame = self.bossPortraitPanel and self.bossPortraitPanel.GetFrame and self.bossPortraitPanel:GetFrame() or nil
    local initiativeHostFrame = self.initiativePortraitPanel and self.initiativePortraitPanel.GetFrame and self.initiativePortraitPanel:GetFrame() or nil
    local portraitHostFrame = self.portraitPanel and self.portraitPanel.GetFrame and self.portraitPanel:GetFrame() or nil

    if portraitHostFrame and portraitHostFrame.SetHeight then
        portraitHostFrame:SetHeight(getPortraitPanelHeight(#bossUnits > 0))
    end

    self:EnsureBossPortraitPool(#bossUnits)

    for index = 1, #bossUnits do
        self:RefreshPortraitSlot(index, bossUnits[index], state, context, {
            ensureSlot = self.EnsureBossPortraitSlot,
            currentKeys = self.bossCurrentKeys,
            currentVisualKeys = self.bossCurrentVisualKeys,
        })
    end

    for index = #bossUnits + 1, #(self.bossPortraitSlots or {}) do
        local portrait = self.bossPortraitSlots[index]
        local frame = portrait and portrait.GetFrame and portrait:GetFrame() or nil
        if frame and frame.Hide then
            if frame.SetAlpha then
                frame:SetAlpha(ACTIVE_PORTRAIT_ALPHA)
            end
            frame:Hide()
        end
        self.bossCurrentKeys[index] = nil
        self.bossCurrentVisualKeys[index] = nil
    end

    if bossHostFrame and initiativeHostFrame then
        initiativeHostFrame:ClearAllPoints()
        if #bossUnits > 0 then
            bossHostFrame:Show()
            initiativeHostFrame:SetPoint("TOP", bossHostFrame, "BOTTOM", 0, -PORTRAIT_SECTION_SPACING)
        else
            bossHostFrame:Hide()
            initiativeHostFrame:SetPoint("TOP", self.portraitPanel:GetFrame(), "TOP", 0, 0)
        end
    end

    for index = 1, maxEventUnits do
        self:RefreshPortraitSlot(index, pageUnits[index] or nil, state, context)
    end

    for index = maxEventUnits + 1, #(self.portraitSlots or {}) do
        local portrait = self.portraitSlots[index]
        local frame = portrait and portrait.GetFrame and portrait:GetFrame() or nil
        if frame and frame.Hide then
            if frame.SetAlpha then
                frame:SetAlpha(ACTIVE_PORTRAIT_ALPHA)
            end
            frame:Hide()
        end
        self.currentKeys[index] = nil
        self.currentVisualKeys[index] = nil
    end

    self:LayoutPortraitRow(self.bossPortraitPanel, self.bossPortraitSlots, #bossUnits, BOSS_PORTRAIT_SIZE, BOSS_PORTRAIT_SPACING)
    self:LayoutPortraitRow(self.initiativePortraitPanel, self.portraitSlots, maxEventUnits, PORTRAIT_SIZE, PORTRAIT_SPACING)
    return true
end

function Client:BuildEventWidget()
    return measureEventWidgetTiming("BuildEventWidget", function()
        return EventWidget:Get():Build()
    end)
end

function Client:ShowEventWidget()
    return EventWidget:Get():Show()
end

function Client:HideEventWidget()
    return EventWidget:Get():Hide()
end

function Client:RefreshEventWidget(reason)
    return measureEventWidgetTiming("RefreshEventWidget", function()
        return EventWidget:Get():Refresh(reason)
    end)
end

function Client:RefreshEventWidgetPortraits(eventIds, reason)
    return measureEventWidgetTiming("RefreshEventWidgetPortraits", function()
        return EventWidget:Get():RefreshPortraitsForEventIds(eventIds, reason)
    end)
end
