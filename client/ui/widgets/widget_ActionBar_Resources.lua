local addonName, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Client.UI = Addon.Client.UI or {}

local Client = Addon.Client
local ClientUI = Addon.Client.UI
local UI = Addon.UI or {}
local Panel = UI.Panel
local ResourceBar = UI.ResourceBar
local CastBar = UI.CastBar
local Profile = Addon.Internal and Addon.Internal.Profile or {}
local ResourceSync = Addon.Internal and Addon.Internal.Comms and Addon.Internal.Comms.ResourceSync or {}

local ActionBarWidget = ClientUI.ActionBarWidget or {}
ClientUI.ActionBarWidget = ActionBarWidget
ActionBarWidget.__index = ActionBarWidget
Client.ActionBarCompanionBarsRefreshQueued = Client.ActionBarCompanionBarsRefreshQueued or false

local ACTION_BAR_STATUS_GAP = 4
local ACTION_BAR_STATUS_BAR_HEIGHT = 16
local ACTION_BAR_STATUS_ROW_GAP = 4
local ACTION_BAR_STATUS_ICON_SIZE = 18
local ACTION_BAR_STATUS_VALUE_WIDTH = 44
local ACTION_BAR_CAST_WIDTH = 200
local RESOURCE_STACK_MIN_WIDTH = 220

local function getTasks()
    return Addon.Internal and Addon.Internal.Tasks or nil
end

local function enqueueCompanionBarWork(fn, ...)
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

local function getHorizontalContentInset(widget)
    return type(widget) == "table" and type(widget.GetContentInset) == "function" and widget:GetContentInset() or 8
end

local function normalizeName(name)
    if type(Addon.Utils and Addon.Utils.Common and Addon.Utils.Common.NormalizeName) == "function" then
        return Addon.Utils.Common.NormalizeName(name)
    end

    return type(name) == "string" and name or ""
end

local function cloneColor(color, fallback)
    local source = type(color) == "table" and color or fallback or { r = 1, g = 1, b = 1, a = 1 }
    return {
        r = tonumber(source.r) or 1,
        g = tonumber(source.g) or 1,
        b = tonumber(source.b) or 1,
        a = tonumber(source.a) or 1,
    }
end

local function dimColor(color)
    local source = cloneColor(color, { r = 0.18, g = 0.18, b = 0.18, a = 1 })
    return {
        r = math.max(0, math.min(1, source.r * 0.35)),
        g = math.max(0, math.min(1, source.g * 0.35)),
        b = math.max(0, math.min(1, source.b * 0.35)),
        a = source.a or 1,
    }
end

local function formatNumericValue(value)
    local numericValue = tonumber(value)
    if numericValue == nil then
        return "0"
    end

    return tostring(math.floor(numericValue))
end

local function normalizeResourceRef(value)
    if type(value) ~= "string" or value == "" then
        return nil
    end

    return value
end

local function buildExcludedResourceRefSet(...)
    local excluded = {}
    for index = 1, select("#", ...) do
        local resourceRef = normalizeResourceRef(select(index, ...))
        if resourceRef then
            excluded[resourceRef] = true
        end
    end
    return excluded
end

local function buildResolvedResourceLookup()
    local lookup = {}
    local rows = type(Profile.ListResolvedResources) == "function" and Profile.ListResolvedResources() or {}

    for index = 1, #rows do
        local row = rows[index]
        local resourceRef = type(row and row.ref) == "string" and row.ref or ""
        if resourceRef ~= "" then
            lookup[resourceRef] = row
        end
    end

    return rows, lookup
end

local function getLocalTrackedResources()
    local playerName = normalizeName(type(Addon.Utils and Addon.Utils.Common and Addon.Utils.Common.GetPlayerName) == "function" and Addon.Utils.Common.GetPlayerName() or nil)
    if playerName == "" then
        return nil
    end

    local sessionState = type(Client.GetState) == "function" and Client:GetState() or Client.State
    local member = type(sessionState) == "table" and type(sessionState.membersByName) == "table" and sessionState.membersByName[playerName] or nil
    local resources = member and member.resources or nil
    if type(resources) ~= "table" then
        return nil
    end

    return type(ResourceSync.CloneResources) == "function" and ResourceSync.CloneResources(resources) or resources
end

local function buildTrackedResourceLookup(resources)
    local lookup = {}
    for index = 1, #((resources) or {}) do
        local entry = resources[index]
        local resourceRef = normalizeResourceRef(type(entry) == "table" and entry.resourceRef or nil)
        if resourceRef then
            lookup[resourceRef] = entry
        end
    end

    return lookup
end

local function appendSelectedResourceEntry(baseResources, resourceRef, trackedByRef, resolvedByRef)
    resourceRef = normalizeResourceRef(resourceRef)
    if not resourceRef then
        return
    end

    for index = 1, #baseResources do
        local entry = baseResources[index]
        if normalizeResourceRef(type(entry) == "table" and entry.resourceRef or nil) == resourceRef then
            return
        end
    end

    local trackedEntry = trackedByRef[resourceRef]
    local resolvedRow = resolvedByRef[resourceRef]
    if not trackedEntry and not resolvedRow then
        return
    end

    if trackedEntry then
        baseResources[#baseResources + 1] = trackedEntry
        return
    end

    local maxValue = tonumber(resolvedRow and resolvedRow.value) or 0
    local startsAtZero = resolvedRow
        and resolvedRow.resource
        and resolvedRow.resource.startsAtZero == true
    baseResources[#baseResources + 1] = {
        resourceRef = resourceRef,
        currentValue = startsAtZero and 0 or maxValue,
        maxValue = maxValue,
    }
end

local function hasResourceEntries(resources)
    return type(resources) == "table" and #resources > 0
end

local function resolveActionBarHealthResourceRef(eventState)
    local eventHealthResourceRef = normalizeResourceRef(type(eventState) == "table" and eventState.healthResourceRef or nil)
    if eventHealthResourceRef then
        return eventHealthResourceRef
    end

    return Profile.GetHealthResourceRef and Profile.GetHealthResourceRef() or nil
end

local function buildActionBarResourceState(resourceRef, entry, resolvedRow)
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

    local currentText = formatNumericValue(currentValue)
    return {
        kind = "resource",
        resourceRef = resourceRef,
        name = tostring(resolvedRow and resolvedRow.name or ResourceSync.ResolveResourceName and ResourceSync.ResolveResourceName(resourceRef) or resourceRef or "Resource"),
        description = tostring(resolvedRow and resolvedRow.description or ""),
        icon = tostring(resolvedRow and resolvedRow.icon or "") ~= "" and tostring(resolvedRow.icon) or "Interface\\Icons\\INV_Misc_QuestionMark",
        color = cloneColor(resolvedRow and resolvedRow.color or nil, { r = 0.42, g = 0.66, b = 0.98, a = 1 }),
        currentValue = currentValue,
        maxValue = math.max(1, maxValue),
        currentText = currentText,
        progressText = currentText,
        valuePlacement = "bar",
    }
end

local function addActionBarAbsorptionState(healthState, eventState, eventUnit)
    if type(healthState) ~= "table" then
        return healthState
    end

    local localEventUnit = eventUnit
    if type(localEventUnit) ~= "table" and type(Client.ResolveLocalEventUnit) == "function" then
        localEventUnit = Client:ResolveLocalEventUnit(eventState)
    end

    local totalAbsorption = 0
    local absorptionRevision = 0
    local auraManager = Client.Spellcasting and Client.Spellcasting.AuraManager or nil
    local targetEventId = tonumber(localEventUnit and localEventUnit.eventID) or 0
    if auraManager
        and type(eventState) == "table"
        and eventState.active == true
        and targetEventId > 0
    then
        if type(auraManager.GetTotalAbsorption) == "function" then
            totalAbsorption = math.max(0, tonumber(auraManager:GetTotalAbsorption(Client, eventState, targetEventId)) or 0)
        end
        if type(auraManager.GetEventAuraRevision) == "function" then
            absorptionRevision = math.max(0, math.floor(tonumber(auraManager:GetEventAuraRevision(Client, eventState.id)) or 0))
        end
    end

    healthState.absorption = totalAbsorption
    healthState.absorptionRevision = absorptionRevision
    return healthState
end

local function buildResourceTooltipSpec(state)
    if type(state) ~= "table" or tostring(state.kind or "") ~= "resource" then
        return nil
    end

    local lines = {}
    local description = tostring(state.description or "")
    if description ~= "" then
        lines[#lines + 1] = {
            text = description,
        }
    end

    return {
        type = "custom",
        title = tostring(state.name or "Resource"),
        titleFontSize = 12,
        lines = lines,
    }
end

local function findFirstResourceRef(baseResources, stateByRef, resolvedByRef, excludedRefs, predicate)
    for index = 1, #baseResources do
        local baseEntry = baseResources[index]
        local resourceRef = normalizeResourceRef(type(baseEntry) == "table" and baseEntry.resourceRef or nil)
        if resourceRef
            and stateByRef[resourceRef]
            and not excludedRefs[resourceRef]
        then
            local resolvedRow = resolvedByRef[resourceRef]
            if type(predicate) ~= "function" or predicate(resourceRef, resolvedRow, baseEntry) == true then
                return resourceRef
            end
        end
    end

    return nil
end

local function isLocalPlayerResourceContext(eventState, eventUnit)
    if type(eventUnit) ~= "table" then
        return true
    end

    local localEventUnit = type(Client.ResolveLocalEventUnit) == "function" and Client:ResolveLocalEventUnit(eventState) or nil
    local localEventId = tonumber(localEventUnit and localEventUnit.eventID) or 0
    local targetEventId = tonumber(eventUnit and eventUnit.eventID) or 0
    if localEventId > 0 and targetEventId > 0 then
        return localEventId == targetEventId and eventUnit.isPlayer == true
    end

    return eventUnit.isPlayer == true
end

function ActionBarWidget:BuildActionBarResourceContext(eventState)
    local _, resolvedByRef = buildResolvedResourceLookup()
    local localEventUnit = type(Client.ResolveLocalEventUnit) == "function" and Client:ResolveLocalEventUnit(eventState) or nil
    local localActiveResources, _, localActiveResourceSource = type(Client.ResolveLocalActiveSpellcasterResources) == "function"
        and Client:ResolveLocalActiveSpellcasterResources(eventState, localEventUnit, {
            clone = true,
        })
        or nil

    return {
        eventState = eventState,
        resolvedByRef = resolvedByRef,
        localTrackedResources = getLocalTrackedResources(),
        localActiveResources = localActiveResources,
        localActiveResourceSource = localActiveResourceSource,
        profileResourceSnapshot = type(ResourceSync.BuildProfileResourceSnapshot) == "function" and ResourceSync.BuildProfileResourceSnapshot() or {},
        healthResourceRef = resolveActionBarHealthResourceRef(eventState),
        localEventUnitId = tonumber(localEventUnit and localEventUnit.eventID) or 0,
        primaryResourceRef = normalizeResourceRef(Profile.GetPrimaryResourceRef and Profile.GetPrimaryResourceRef() or nil),
        specialResourceRef = normalizeResourceRef(Profile.GetSpecialResourceRef and Profile.GetSpecialResourceRef() or nil),
    }
end

local function buildResolvedResourceRowSignature(resolvedByRef)
    local refs = {}
    for resourceRef in pairs(type(resolvedByRef) == "table" and resolvedByRef or {}) do
        refs[#refs + 1] = resourceRef
    end
    table.sort(refs)

    local parts = {}
    for index = 1, #refs do
        local resourceRef = refs[index]
        local row = resolvedByRef[resourceRef]
        parts[#parts + 1] = table.concat({
            tostring(resourceRef or ""),
            tostring(tonumber(row and row.value) or 0),
            tostring(tonumber(row and row.baseResourceValue) or 0),
            tostring(row and row.isSpecial == true and 1 or 0),
        }, "\31")
    end

    return table.concat(parts, "\30")
end

local function buildTrackedResourceSignature(resources)
    local parts = {}
    for index = 1, #((resources) or {}) do
        local entry = resources[index]
        parts[#parts + 1] = table.concat({
            tostring(entry and entry.resourceRef or ""),
            tostring(tonumber(entry and entry.currentValue) or 0),
            tostring(tonumber(entry and entry.maxValue) or 0),
        }, "\31")
    end

    return table.concat(parts, "\30")
end

local function buildActionBarResourceContextSignature(resourceContext)
    if type(resourceContext) ~= "table" then
        return ""
    end

    return table.concat({
        tostring(resourceContext.eventState and resourceContext.eventState.id or ""),
        tostring(tonumber(resourceContext.eventState and resourceContext.eventState.turnNumber) or 0),
        tostring(tonumber(resourceContext.eventState and resourceContext.eventState.tickNumber) or 0),
        tostring(resourceContext.healthResourceRef or ""),
        tostring(resourceContext.primaryResourceRef or ""),
        tostring(resourceContext.specialResourceRef or ""),
        tostring(tonumber(resourceContext.localEventUnitId) or 0),
        buildResolvedResourceRowSignature(resourceContext.resolvedByRef),
        tostring(resourceContext.localActiveResourceSource or ""),
        buildTrackedResourceSignature(resourceContext.localActiveResources),
        buildTrackedResourceSignature(resourceContext.localTrackedResources),
        buildTrackedResourceSignature(resourceContext.profileResourceSnapshot),
    }, "\29")
end

local function buildActionBarCompanionStateSignature(eventUnit, resourceContext, castState, layoutWidth, healthState)
    local unitResources = type(eventUnit) == "table" and type(eventUnit.resources) == "table" and eventUnit.resources or nil
    if type(eventUnit) == "table"
        and eventUnit.isPlayer == true
        and tonumber(eventUnit.eventID) == tonumber(resourceContext and resourceContext.localEventUnitId)
        and hasResourceEntries(resourceContext and resourceContext.localActiveResources)
    then
        unitResources = resourceContext.localActiveResources
    end
    return table.concat({
        buildActionBarResourceContextSignature(resourceContext),
        tostring(tonumber(eventUnit and eventUnit.eventID) or 0),
        tostring(tonumber(eventUnit and eventUnit.team) or 0),
        tostring(type(eventUnit) == "table" and eventUnit.isPlayer == true and 1 or 0),
        buildTrackedResourceSignature(unitResources),
        tostring(tonumber(healthState and healthState.absorption) or 0),
        tostring(tonumber(healthState and healthState.absorptionRevision) or 0),
        tostring(type(castState) == "table" and castState.spellRef or ""),
        tostring(tonumber(type(castState) == "table" and castState.turnsElapsed) or 0),
        tostring(tonumber(type(castState) == "table" and castState.turnsTotal) or 0),
        tostring(tonumber(layoutWidth) or 0),
    }, "\29")
end

function ActionBarWidget:BuildActionBarResourceStates(eventState, eventUnit, resourceContext)
    resourceContext = type(resourceContext) == "table" and resourceContext or self:BuildActionBarResourceContext(eventState)
    local unitResources = type(eventUnit) == "table" and type(eventUnit.resources) == "table" and eventUnit.resources or nil
    local resolvedByRef = resourceContext.resolvedByRef or select(2, buildResolvedResourceLookup())

    local healthResourceRef = resourceContext.healthResourceRef or resolveActionBarHealthResourceRef(eventState)
    local primaryResourceRef = nil
    local specialResourceRef = nil
    local localPlayerContext = false
    if type(eventUnit) ~= "table" then
        localPlayerContext = true
    else
        local localEventId = tonumber(resourceContext.localEventUnitId) or 0
        local targetEventId = tonumber(eventUnit and eventUnit.eventID) or 0
        if localEventId > 0 and targetEventId > 0 then
            localPlayerContext = localEventId == targetEventId and eventUnit.isPlayer == true
        else
            localPlayerContext = isLocalPlayerResourceContext(eventState, eventUnit)
        end
    end

    local effectiveLocalResources = nil
    if localPlayerContext and type(Client.ResolveLocalActiveSpellcasterResources) == "function" then
        effectiveLocalResources = Client:ResolveLocalActiveSpellcasterResources(eventState, eventUnit, {
            clone = true,
        })
    end

    local baseResources = hasResourceEntries(effectiveLocalResources)
        and effectiveLocalResources
        or (type(unitResources) == "table"
            and (type(ResourceSync.CloneResources) == "function" and ResourceSync.CloneResources(unitResources) or unitResources)
            or resourceContext.profileResourceSnapshot
            or (type(ResourceSync.BuildProfileResourceSnapshot) == "function" and ResourceSync.BuildProfileResourceSnapshot() or {}))
    if type(ResourceSync.CloneResources) == "function" then
        baseResources = ResourceSync.CloneResources(baseResources)
    end
    baseResources = type(baseResources) == "table" and baseResources or {}

    local trackedResources = hasResourceEntries(effectiveLocalResources)
        and effectiveLocalResources
        or unitResources
        or resourceContext.localTrackedResources
        or getLocalTrackedResources()
    local trackedByRef = buildTrackedResourceLookup(trackedResources)
    local supplementalTrackedResources = resourceContext.localTrackedResources
    if not hasResourceEntries(supplementalTrackedResources) then
        supplementalTrackedResources = getLocalTrackedResources()
    end
    local supplementalTrackedByRef = buildTrackedResourceLookup(
        supplementalTrackedResources
    )
    for resourceRef, entry in pairs(supplementalTrackedByRef) do
        if not trackedByRef[resourceRef] then
            trackedByRef[resourceRef] = entry
        end
    end

    -- The live event unit often contains only the resources currently being
    -- synchronized. Explicit local selections must still be rendered when a
    -- selected resource is available from the resolved profile data.
    if localPlayerContext then
        appendSelectedResourceEntry(baseResources, resourceContext.primaryResourceRef, trackedByRef, resolvedByRef)
        appendSelectedResourceEntry(baseResources, resourceContext.specialResourceRef, trackedByRef, resolvedByRef)
    end

    if #baseResources == 0 then
        return {
            health = nil,
            primary = nil,
            special = nil,
        }
    end

    local stateByRef = {}
    for index = 1, #baseResources do
        local baseEntry = baseResources[index]
        local resourceRef = normalizeResourceRef(type(baseEntry) == "table" and baseEntry.resourceRef or nil)
        if resourceRef then
            local resolvedRow = resolvedByRef[resourceRef]
            local profileValue = tonumber(resolvedRow and resolvedRow.value) or nil
            local entry = trackedByRef[resourceRef] or {
                resourceRef = resourceRef,
                currentValue = profileValue,
                maxValue = profileValue,
            }
            local state = buildActionBarResourceState(resourceRef, entry, resolvedRow)
            if state then
                stateByRef[resourceRef] = state
            end
        end
    end

    if localPlayerContext then
        primaryResourceRef = resourceContext.primaryResourceRef
        specialResourceRef = resourceContext.specialResourceRef
    else
        specialResourceRef = findFirstResourceRef(baseResources, stateByRef, resolvedByRef, buildExcludedResourceRefSet(healthResourceRef), function(_, resolvedRow)
            return resolvedRow and resolvedRow.isSpecial == true
        end)
        primaryResourceRef = findFirstResourceRef(baseResources, stateByRef, resolvedByRef, buildExcludedResourceRefSet(healthResourceRef, specialResourceRef))
    end

    if primaryResourceRef == healthResourceRef or primaryResourceRef == specialResourceRef then
        primaryResourceRef = nil
    end
    if specialResourceRef == healthResourceRef then
        specialResourceRef = nil
    end
    if specialResourceRef and not (resolvedByRef[specialResourceRef] and resolvedByRef[specialResourceRef].isSpecial == true) then
        specialResourceRef = nil
    end

    local healthState = healthResourceRef and stateByRef[healthResourceRef] or nil
    local specialState = specialResourceRef and stateByRef[specialResourceRef] or nil
    local primaryState = primaryResourceRef and stateByRef[primaryResourceRef] or nil

    if not healthState then
        healthResourceRef = findFirstResourceRef(baseResources, stateByRef, resolvedByRef, buildExcludedResourceRefSet(specialResourceRef, primaryResourceRef))
        healthState = healthResourceRef and stateByRef[healthResourceRef] or nil
    end

    healthState = addActionBarAbsorptionState(healthState, eventState, eventUnit)

    if not primaryState and not localPlayerContext then
        primaryResourceRef = findFirstResourceRef(baseResources, stateByRef, resolvedByRef, buildExcludedResourceRefSet(healthResourceRef, specialResourceRef))
        primaryState = primaryResourceRef and stateByRef[primaryResourceRef] or nil
    end

    if not specialState and not localPlayerContext then
        specialResourceRef = findFirstResourceRef(baseResources, stateByRef, resolvedByRef, buildExcludedResourceRefSet(healthResourceRef, primaryResourceRef), function(_, resolvedRow)
            return resolvedRow and resolvedRow.isSpecial == true
        end)
        specialState = specialResourceRef and stateByRef[specialResourceRef] or nil
    end

    return {
        health = healthState,
        primary = primaryState,
        special = specialState,
    }
end

function ActionBarWidget:EnsureActionBarStatusContainer(parentFrame)
    if self.ActionBarStatusContainer then
        return self.ActionBarStatusContainer
    end

    if type(parentFrame) ~= "table" or type(Panel) ~= "table" or type(Panel.New) ~= "function" then
        return nil
    end

    local container = Panel:New({
        name = "RPEnginePlayerActionBarStatusContainer",
        width = parentFrame.GetWidth and parentFrame:GetWidth() or RESOURCE_STACK_MIN_WIDTH,
        height = ACTION_BAR_STATUS_BAR_HEIGHT,
        border = false,
        showBorder = false,
        contentInset = 0,
        panelBackgroundColor = { r = 0, g = 0, b = 0, a = 0 },
        showWhenUIHidden = false,
        hidden = true,
    })
    container:SetParent(parentFrame)
    container:Create()

    local frame = container:GetFrame()
    local contentInset = getHorizontalContentInset(self)
    if frame and frame.ClearAllPoints then
        frame:ClearAllPoints()
        frame:SetPoint("BOTTOMLEFT", parentFrame, "TOPLEFT", contentInset, ACTION_BAR_STATUS_GAP)
        frame:SetPoint("BOTTOMRIGHT", parentFrame, "TOPRIGHT", -contentInset, ACTION_BAR_STATUS_GAP)
    end
    container:Hide()

    self.ActionBarStatusContainer = container
    self.ActionBarStatusRows = self.ActionBarStatusRows or {}
    return self.ActionBarStatusContainer
end

function ActionBarWidget:EnsureActionBarStatusRow(index, kind)
    self.ActionBarStatusRows = self.ActionBarStatusRows or {}
    local row = self.ActionBarStatusRows[index]
    if row and row.barKind == kind then
        return row
    end

    if row then
        local previousFrame = row.GetFrame and row:GetFrame() or nil
        if previousFrame and previousFrame.Hide then
            previousFrame:Hide()
        end
    end

    local container = self.ActionBarStatusContainer
    if not container then
        return nil
    end

    local barClass = kind == "cast" and CastBar or ResourceBar
    local bar = barClass:New({
        name = ("RPEnginePlayerActionBarStatusRow%d"):format(index),
        width = RESOURCE_STACK_MIN_WIDTH,
        height = ACTION_BAR_STATUS_BAR_HEIGHT,
        iconSize = ACTION_BAR_STATUS_ICON_SIZE,
        valueWidth = ACTION_BAR_STATUS_VALUE_WIDTH,
        progressFontSize = kind == "cast" and 12 or 10,
        valueFontSize = 10,
        iconTexture = "Interface\\Icons\\INV_Misc_QuestionMark",
        border = false,
        showWhenUIHidden = false,
    })
    bar:SetParent(container:GetFrame())
    bar:Create()
    bar.barKind = kind

    local rowFrame = bar:GetFrame()
    if rowFrame and rowFrame.RegisterForClicks then
        rowFrame:RegisterForClicks("AnyUp")
    end
    if rowFrame and rowFrame.SetScript and kind == "cast" then
        rowFrame:SetScript("OnMouseUp", function(_, button)
            if button ~= "RightButton" then
                return
            end

            local activeState = bar.state
            if type(activeState) ~= "table" or activeState.kind ~= "cast" or type(activeState.spellRef) ~= "string" or activeState.spellRef == "" then
                return
            end

            if type(Client.OnSpellcastInterrupted) == "function" then
                Client:OnSpellcastInterrupted(activeState.spellRef, activeState.castEntry)
            end
        end)
    end

    row = bar
    self.ActionBarStatusRows[index] = row
    return row
end

function ActionBarWidget:HideActionBarCompanionBars()
    local container = self.ActionBarStatusContainer
    self.lastCompanionRefreshSignature = nil
    if not container or not container.Hide then
        return false
    end

    container:Hide()
    return true
end

function ActionBarWidget:LayoutStatusRow(row, state, leftOffset, rightOffset, width, height)
    local rowFrame = row and row.GetFrame and row:GetFrame() or nil
    local iconFrame = row and row.icon and row.icon.GetFrame and row.icon:GetFrame() or nil
    local valueFrame = row and row.valueText and row.valueText.GetFrame and row.valueText:GetFrame() or nil
    local progressFrame = row and row.progressBar and row.progressBar.GetFrame and row.progressBar:GetFrame() or nil
    local valueInBar = state and state.valuePlacement == "bar"
    local iconSide = state and state.iconSide == "right" and "right" or "left"
    if not rowFrame then
        return false
    end

    row.state = state

    rowFrame:SetHeight(height)
    rowFrame:Show()

    if iconFrame and iconFrame.ClearAllPoints then
        iconFrame:ClearAllPoints()
        if iconSide == "right" then
            iconFrame:SetPoint("RIGHT", rowFrame, "RIGHT", 0, 0)
        else
            iconFrame:SetPoint("LEFT", rowFrame, "LEFT", 0, 0)
        end
        iconFrame:SetWidth(ACTION_BAR_STATUS_ICON_SIZE)
        iconFrame:SetHeight(ACTION_BAR_STATUS_ICON_SIZE)
        iconFrame:Show()
    end
    if row.icon and row.icon.SetTexture then
        row.icon:SetTexture(state.icon)
    end

    if valueFrame and valueFrame.ClearAllPoints then
        valueFrame:ClearAllPoints()
        if valueInBar then
            valueFrame:Hide()
        else
            valueFrame:SetPoint("RIGHT", rowFrame, "RIGHT", 0, 0)
            valueFrame:SetWidth(ACTION_BAR_STATUS_VALUE_WIDTH)
            valueFrame:SetHeight(height)
            valueFrame:Show()
        end
    end
    if row.valueText and row.valueText.SetText and not valueInBar then
        row.valueText:SetText(state.currentText)
    end

    if progressFrame and progressFrame.ClearAllPoints then
        progressFrame:ClearAllPoints()
        if iconSide == "right" then
            progressFrame:SetPoint("LEFT", rowFrame, "LEFT", 0, 0)
            progressFrame:SetPoint("RIGHT", iconFrame, "LEFT", -4, 0)
        else
            progressFrame:SetPoint("LEFT", iconFrame, "RIGHT", 4, 0)
        end
        if valueInBar and iconSide ~= "right" then
            progressFrame:SetPoint("RIGHT", rowFrame, "RIGHT", 0, 0)
        elseif not valueInBar then
            progressFrame:SetPoint("RIGHT", valueFrame, "LEFT", -4, 0)
        end
        progressFrame:SetHeight(height)
        progressFrame:Show()
    end
    if row.SetState then
        row:SetState(state)
    end
    if row.progressBar and row.progressBar.UpdateLayout then
        row.progressBar:UpdateLayout()
    end
    if row.SetTooltip then
        row:SetTooltip(buildResourceTooltipSpec(state))
    end

    if row.progressBar and row.progressBar.label then
        if state.progressText and state.progressText ~= "" then
            row.progressBar.label:Show()
        else
            row.progressBar.label:Hide()
        end
    end

    return true
end

function ActionBarWidget:RefreshActionBarCompanionBars(source)
    local actionBarRoot = self and self.rootPanel and self.rootPanel.GetFrame and self.rootPanel:GetFrame() or nil
    if not actionBarRoot or not actionBarRoot.IsShown or not actionBarRoot:IsShown() then
        return self:HideActionBarCompanionBars()
    end

    local controlContext = type(Client.GetActionBarControlContext) == "function" and Client:GetActionBarControlContext() or nil
    local eventState = type(controlContext) == "table" and controlContext.eventState or (Client.GetEventState and Client:GetEventState() or nil)
    local eventUnit = type(controlContext) == "table" and controlContext.activeEventUnit or nil
    if not eventUnit and type(Client.ResolveLocalEventUnit) == "function" then
        eventUnit, eventState = Client:ResolveLocalEventUnit(eventState)
    end

    local contentInset = getHorizontalContentInset(self)
    local totalWidth = self.GetContentWidth and self:GetContentWidth(actionBarRoot.GetWidth and actionBarRoot:GetWidth() or RESOURCE_STACK_MIN_WIDTH)
        or math.max(0, (actionBarRoot.GetWidth and actionBarRoot:GetWidth() or RESOURCE_STACK_MIN_WIDTH) - (contentInset * 2))
    local resourceContext = self.BuildActionBarResourceContext and self:BuildActionBarResourceContext(eventState) or nil
    local resourceStates = self:BuildActionBarResourceStates(eventState, eventUnit, resourceContext)
    local healthState = type(resourceStates) == "table" and resourceStates.health or nil
    local primaryState = type(resourceStates) == "table" and resourceStates.primary or nil
    local specialState = type(resourceStates) == "table" and resourceStates.special or nil
    local castState = self.ResolveActionBarCastState and self:ResolveActionBarCastState(eventUnit, eventState) or nil
    local refreshSignature = buildActionBarCompanionStateSignature(eventUnit, resourceContext, castState, totalWidth, healthState)

    local bottomStates = {}
    if healthState then
        bottomStates[#bottomStates + 1] = healthState
    end
    if primaryState and primaryState.resourceRef ~= (healthState and healthState.resourceRef or nil) then
        bottomStates[#bottomStates + 1] = primaryState
    end

    if #bottomStates == 0 and not specialState and not castState then
        self.lastCompanionRefreshSignature = nil
        return self:HideActionBarCompanionBars()
    end

    if self.lastCompanionRefreshSignature == refreshSignature then
        return true
    end

    local container = self:EnsureActionBarStatusContainer(actionBarRoot)
    if not container then
        return false
    end

    local containerFrame = container.GetFrame and container:GetFrame() or nil
    local rowCount = 0
    if castState then
        rowCount = rowCount + 1
    end
    if specialState then
        rowCount = rowCount + 1
    end
    if #bottomStates > 0 then
        rowCount = rowCount + 1
    end
    local totalHeight = (rowCount * ACTION_BAR_STATUS_BAR_HEIGHT) + ((rowCount - 1) * ACTION_BAR_STATUS_ROW_GAP)
    if containerFrame and containerFrame.SetHeight then
        containerFrame:SetHeight(totalHeight)
    end
    if containerFrame and containerFrame.ClearAllPoints then
        containerFrame:ClearAllPoints()
        containerFrame:SetPoint("BOTTOMLEFT", actionBarRoot, "TOPLEFT", contentInset, ACTION_BAR_STATUS_GAP)
        containerFrame:SetPoint("BOTTOMRIGHT", actionBarRoot, "TOPRIGHT", -contentInset, ACTION_BAR_STATUS_GAP)
    end

    local nextRowIndex = 1
    local nextRowTopOffset = 0
    if castState then
        local castRow = self:EnsureActionBarStatusRow(nextRowIndex, "cast")
        local castWidth = math.min(ACTION_BAR_CAST_WIDTH, totalWidth)
        local castLeftOffset = math.floor((totalWidth - castWidth) / 2)
        local castRightOffset = castLeftOffset + castWidth
        if castRow and castRow.GetFrame and castRow:GetFrame() and castRow:GetFrame().ClearAllPoints then
            castRow:GetFrame():ClearAllPoints()
            castRow:GetFrame():SetPoint("TOPLEFT", containerFrame, "TOPLEFT", castLeftOffset, nextRowTopOffset)
            castRow:GetFrame():SetPoint("TOPRIGHT", containerFrame, "TOPLEFT", castRightOffset, nextRowTopOffset)
        end
        self:LayoutStatusRow(castRow, castState, castLeftOffset, castRightOffset, castWidth, ACTION_BAR_STATUS_BAR_HEIGHT)
        nextRowTopOffset = nextRowTopOffset - (ACTION_BAR_STATUS_BAR_HEIGHT + ACTION_BAR_STATUS_ROW_GAP)
        nextRowIndex = nextRowIndex + 1
    end

    if specialState then
        local specialRow = self:EnsureActionBarStatusRow(nextRowIndex, "resource")
        local specialWidth = math.min(ACTION_BAR_CAST_WIDTH, totalWidth)
        local specialLeftOffset = math.floor((totalWidth - specialWidth) / 2)
        local specialRightOffset = specialLeftOffset + specialWidth
        if specialRow and specialRow.GetFrame and specialRow:GetFrame() and specialRow:GetFrame().ClearAllPoints then
            specialRow:GetFrame():ClearAllPoints()
            specialRow:GetFrame():SetPoint("TOPLEFT", containerFrame, "TOPLEFT", specialLeftOffset, nextRowTopOffset)
            specialRow:GetFrame():SetPoint("TOPRIGHT", containerFrame, "TOPLEFT", specialRightOffset, nextRowTopOffset)
        end
        self:LayoutStatusRow(specialRow, specialState, specialLeftOffset, specialRightOffset, specialWidth, ACTION_BAR_STATUS_BAR_HEIGHT)
        nextRowTopOffset = nextRowTopOffset - (ACTION_BAR_STATUS_BAR_HEIGHT + ACTION_BAR_STATUS_ROW_GAP)
        nextRowIndex = nextRowIndex + 1
    end

    for index = 1, #bottomStates do
        local state = bottomStates[index]
        local row = self:EnsureActionBarStatusRow(nextRowIndex + index - 1, "resource")
        local barWidth = #bottomStates == 1 and totalWidth or math.floor((totalWidth - ACTION_BAR_STATUS_ROW_GAP) / 2)
        local leftOffset = #bottomStates == 1 and 0 or ((index - 1) * (barWidth + ACTION_BAR_STATUS_ROW_GAP))
        local rightOffset = leftOffset + barWidth
        if row and row.GetFrame and row:GetFrame() and row:GetFrame().ClearAllPoints then
            row:GetFrame():ClearAllPoints()
            row:GetFrame():SetPoint("TOPLEFT", containerFrame, "TOPLEFT", leftOffset, nextRowTopOffset)
            row:GetFrame():SetPoint("TOPRIGHT", containerFrame, "TOPLEFT", rightOffset, nextRowTopOffset)
        end
        self:LayoutStatusRow(row, state, leftOffset, rightOffset, barWidth, ACTION_BAR_STATUS_BAR_HEIGHT)
    end

    local usedRowCount = nextRowIndex + #bottomStates - 1

    for index = usedRowCount + 1, #(self.ActionBarStatusRows or {}) do
        local row = self.ActionBarStatusRows[index]
        local rowFrame = row and row.GetFrame and row:GetFrame() or nil
        if rowFrame and rowFrame.Hide then
            rowFrame:Hide()
        end
    end

    container:Show()
    self.lastCompanionRefreshSignature = refreshSignature
    return true
end

function Client:RefreshActionBarCompanionBars(reason)
    return ActionBarWidget:Get():RefreshActionBarCompanionBars(reason)
end

function Client:QueueActionBarCompanionBarsRefresh(reason, options)
    if type(self.MarkActionBarCompanionBarsDirty) == "function" then
        return self:MarkActionBarCompanionBarsDirty(reason, options)
    end

    self.PendingActionBarCompanionBarsRefreshReason = tostring(
        reason or self.PendingActionBarCompanionBarsRefreshReason or "action-bar-companion"
    )
    local immediate = type(options) == "table" and options.immediate == true
    if immediate then
        self.PendingActionBarCompanionBarsRefreshImmediate = true
    elseif self.PendingActionBarCompanionBarsRefreshImmediate ~= true then
        self.PendingActionBarCompanionBarsRefreshImmediate = false
    end

    if self.ActionBarCompanionBarsRefreshQueued == true then
        return true
    end

    self.ActionBarCompanionBarsRefreshQueued = true
    if type(self.QueueVisualRefreshFlush) == "function" then
        return self:QueueVisualRefreshFlush()
    end

    return enqueueCompanionBarWork(function(targetClient)
        if type(targetClient) ~= "table" then
            return
        end

        local refreshReason = targetClient.PendingActionBarCompanionBarsRefreshReason or "action-bar-companion"
        targetClient.PendingActionBarCompanionBarsRefreshReason = nil
        targetClient.ActionBarCompanionBarsRefreshQueued = false
        targetClient.PendingActionBarCompanionBarsRefreshImmediate = false
        if targetClient.ActionBarRefreshQueued == true then
            return
        end

        if type(targetClient.RefreshActionBarCompanionBars) == "function" then
            targetClient:RefreshActionBarCompanionBars(refreshReason)
        end
    end, self)
end

return ActionBarWidget
