local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Client.UI = Addon.Client.UI or {}
Addon.Client.UI.Tooltips = Addon.Client.UI.Tooltips or {}

local Client = Addon.Client
local Tooltips = Addon.Client.UI.Tooltips
local UI = Addon.UI or {}
local Image = UI.Image
local Panel = UI.Panel
local ResourceBar = UI.ResourceBar
local CastBar = UI.CastBar
local Common = Addon.Utils and Addon.Utils.Common or {}
local Profile = Addon.Internal and Addon.Internal.Profile or {}
local Registry = Addon.Internal and Addon.Internal.Registry or {}
local ResourceSync = Addon.Internal and Addon.Internal.Comms and Addon.Internal.Comms.ResourceSync or {}

local PlayerTooltip = Tooltips.Player or {}
Tooltips.Player = PlayerTooltip

local DEFAULT_RESOURCE_ICON = "Interface\\Icons\\INV_Misc_QuestionMark"
local DEFAULT_CAST_ICON = "Interface\\Icons\\INV_Misc_QuestionMark"
local DEFAULT_CAST_BAR_COLOR = { r = 0.93, g = 0.63, b = 0.22, a = 1 }
local RESOURCE_BAR_HEIGHT = 14
local RESOURCE_BAR_SPACING = 3
local RESOURCE_ICON_SIZE = 14
local RESOURCE_VALUE_WIDTH = 44
local RESOURCE_STACK_MIN_WIDTH = 220
local TOOLTIP_CAST_FONT_SIZE = 12
local TOOLTIP_RESOURCE_FONT_SIZE = 10

local function normalizeName(name)
    if type(Common.NormalizeName) == "function" then
        return Common.NormalizeName(name)
    end

    if type(name) ~= "string" then
        return ""
    end

    return name
end

local function normalizeHealthLabel(text)
    local normalized = tostring(text or ""):lower()
    normalized = normalized:gsub("[%s_%-]", "")
    return normalized
end

local function getEventState()
    if type(Client.GetEventState) == "function" then
        return Client:GetEventState()
    end

    return Client.EventState
end

local function scheduleDeferred(callback)
    if type(C_Timer) == "table" and type(C_Timer.After) == "function" then
        C_Timer.After(0, callback)
        return true
    end

    callback()
    return false
end

local function isTooltipShown(tooltip)
    return type(tooltip) == "table"
        and type(tooltip.IsShown) == "function"
        and tooltip:IsShown() == true
end

local function isFrameShown(frame)
    return type(frame) == "table"
        and type(frame.IsShown) == "function"
        and frame:IsShown() == true
end

local function getFullUnitName(unitToken)
    if type(unitToken) ~= "string" or unitToken == "" then
        return ""
    end

    local name, realm = nil, nil
    if type(UnitFullName) == "function" then
        name, realm = UnitFullName(unitToken)
    end

    if type(name) ~= "string" or name == "" then
        name = type(GetUnitName) == "function" and GetUnitName(unitToken, true) or nil
    end

    if (type(name) ~= "string" or name == "") and type(UnitName) == "function" then
        name = UnitName(unitToken)
    end

    if type(name) ~= "string" or name == "" then
        return ""
    end

    if type(realm) == "string" and realm ~= "" and not string.find(name, "-", 1, true) then
        name = ("%s-%s"):format(name, realm)
    end

    return normalizeName(name)
end

local function getTooltipPrimaryText(tooltip)
    if type(tooltip) ~= "table" then
        return ""
    end

    local leftText = tooltip.TextLeft1
    if type(leftText) == "table" and type(leftText.GetText) == "function" then
        local text = leftText:GetText()
        if type(text) == "string" and text ~= "" then
            return normalizeName(text)
        end
    end

    local tooltipName = type(tooltip.GetName) == "function" and tooltip:GetName() or nil
    if type(tooltipName) == "string" and tooltipName ~= "" then
        local globalHeader = _G[("%sTextLeft1"):format(tooltipName)]
        if type(globalHeader) == "table" and type(globalHeader.GetText) == "function" then
            local text = globalHeader:GetText()
            if type(text) == "string" and text ~= "" then
                return normalizeName(text)
            end
        end
    end

    return ""
end

local function buildResourceLookup()
    local lookup = {}
    local rows = type(Profile.ListResolvedResources) == "function" and Profile.ListResolvedResources() or {}

    for index = 1, #rows do
        local row = rows[index]
        local resourceRef = type(row and row.ref) == "string" and row.ref or ""
        if resourceRef ~= "" then
            lookup[resourceRef] = row
        end
    end

    return lookup
end

local function resolveHealthResourceEntry(resources, eventState)
    if type(resources) ~= "table" then
        return nil
    end

    local healthResourceRef = type(eventState) == "table" and eventState.healthResourceRef or nil
    if type(healthResourceRef) == "string" and healthResourceRef ~= "" then
        for index = 1, #resources do
            local entry = resources[index]
            if entry and entry.resourceRef == healthResourceRef then
                return entry
            end
        end
    end

    local resourceLookup = buildResourceLookup()
    for index = 1, #resources do
        local entry = resources[index]
        local resourceRef = entry and entry.resourceRef or nil
        local resolved = resourceLookup[resourceRef] or nil
        local resourceName = resolved and resolved.name or nil
        if (type(resourceName) ~= "string" or resourceName == "") and type(ResourceSync.ResolveResourceName) == "function" then
            resourceName = ResourceSync.ResolveResourceName(resourceRef)
        end

        local normalizedName = normalizeHealthLabel(resourceName)
        if normalizedName == "health" or normalizedName == "hp" or normalizedName == "hitpoints" then
            return entry
        end
    end

    for index = 1, #resources do
        local entry = resources[index]
        if entry and (entry.currentValue ~= nil or entry.maxValue ~= nil or entry.value ~= nil) then
            return entry
        end
    end

    return nil
end

local function formatNumericValue(value)
    local numericValue = tonumber(value)
    if numericValue == nil then
        return "0"
    end

    return tostring(math.floor(numericValue))
end

local function buildHealthLineText(healthState)
    return ("Health: %s/%s"):format(
        formatNumericValue(healthState and healthState.currentValue),
        formatNumericValue(healthState and healthState.maxValue)
    )
end

local function formatTurnLabel(value)
    local numericValue = math.max(0, math.floor(tonumber(value) or 0))
    if numericValue == 1 then
        return "1 turn"
    end

    return ("%d turns"):format(numericValue)
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

function PlayerTooltip:ResolveTooltipUnit(tooltip)
    if type(UnitExists) == "function" then
        return UnitExists("mouseover") and "mouseover" or nil
    end

    return "mouseover"
end

function PlayerTooltip:ResolveEventUnit(unitToken, tooltip)
    local eventState = getEventState()
    if type(eventState) ~= "table" or eventState.active ~= true then
        return nil
    end

    local normalizedPlayerName = getFullUnitName(unitToken)
    if normalizedPlayerName == "" then
        normalizedPlayerName = getTooltipPrimaryText(tooltip)
    end
    if normalizedPlayerName == "" then
        return nil
    end

    for index = 1, #((eventState.units) or {}) do
        local unit = eventState.units[index]
        if unit and unit.isPlayer == true then
            local candidateName = normalizeName(unit.ownerID or unit.controllerID or unit.name)
            if candidateName == normalizedPlayerName then
                return unit, eventState
            end
        end
    end

    return nil
end

function PlayerTooltip:ResolveLocalEventUnit()
    local eventState = getEventState()
    if type(eventState) ~= "table" or eventState.active ~= true then
        return nil
    end

    local playerName = normalizeName(type(Common.GetPlayerName) == "function" and Common.GetPlayerName() or nil)
    if playerName == "" then
        return nil
    end

    for index = 1, #((eventState.units) or {}) do
        local unit = eventState.units[index]
        if unit and unit.isPlayer == true then
            local candidateName = normalizeName(unit.ownerID or unit.controllerID or unit.name)
            if candidateName == playerName then
                return unit, eventState
            end
        end
    end

    return nil
end

function PlayerTooltip:ResolveHealthState(eventUnit, eventState)
    local healthEntry = resolveHealthResourceEntry(eventUnit and eventUnit.resources or nil, eventState)
    if not healthEntry then
        return nil
    end

    local currentValue = tonumber(healthEntry.currentValue)
    local maxValue = tonumber(healthEntry.maxValue)
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
        resourceRef = healthEntry.resourceRef,
        currentValue = currentValue,
        maxValue = maxValue,
    }
end

function PlayerTooltip:ClearTooltipState(tooltip)
    if type(tooltip) ~= "table" then
        return false
    end

    tooltip.__RPEngineEventHealthLineToken = nil
    return true
end

function PlayerTooltip:BuildResourceStates(eventUnit, eventState)
    local resources = type(eventUnit) == "table" and eventUnit.resources or nil
    if type(resources) ~= "table" then
        return {}
    end

    local resourceLookup = buildResourceLookup()
    local states = {}

    for index = 1, #resources do
        local entry = resources[index]
        if type(entry) == "table" then
            local currentValue = tonumber(entry.currentValue)
            local maxValue = tonumber(entry.maxValue)
            if currentValue == nil and maxValue ~= nil then
                currentValue = maxValue
            end
            if maxValue == nil and currentValue ~= nil then
                maxValue = currentValue
            end

            if currentValue ~= nil and maxValue ~= nil then
                local resolved = resourceLookup[entry.resourceRef] or nil
                local resourceColor = cloneColor(resolved and resolved.color or nil, { r = 0.42, g = 0.66, b = 0.98, a = 1 })
                states[#states + 1] = {
                    resourceRef = entry.resourceRef,
                    name = tostring(resolved and resolved.name or ResourceSync.ResolveResourceName and ResourceSync.ResolveResourceName(entry.resourceRef) or entry.resourceRef or "Resource"),
                    icon = tostring(resolved and resolved.icon or "") ~= "" and tostring(resolved and resolved.icon) or DEFAULT_RESOURCE_ICON,
                    color = resourceColor,
                    currentValue = currentValue,
                    maxValue = math.max(1, maxValue),
                    currentText = formatNumericValue(currentValue),
                }
            end
        end
    end

    return states
end

function PlayerTooltip:BuildPrimaryPlayerResourceStates(eventUnit, eventState)
    local resourceStates = self:BuildResourceStates(eventUnit, eventState)
    return self:SelectPrimaryResourceStates(resourceStates, eventState)
end

function PlayerTooltip:BuildVisibleResourceStates(eventUnit, eventState)
    if type(eventUnit) == "table" and eventUnit.isPlayer == true then
        return self:BuildPrimaryPlayerResourceStates(eventUnit, eventState)
    end

    return self:BuildResourceStates(eventUnit, eventState)
end

function PlayerTooltip:SelectPrimaryResourceStates(resourceStates, eventState)
    if type(resourceStates) ~= "table" or #resourceStates == 0 then
        return {}
    end

    local selected = {}
    local healthEntry = resolveHealthResourceEntry(resourceStates, eventState)
    local healthResourceRef = healthEntry and healthEntry.resourceRef or nil
    if type(healthResourceRef) == "string" and healthResourceRef ~= "" then
        for index = 1, #resourceStates do
            local state = resourceStates[index]
            if state.resourceRef == healthResourceRef then
                selected[#selected + 1] = state
                break
            end
        end
    end

    for index = 1, #resourceStates do
        local state = resourceStates[index]
        if #selected == 0 or state.resourceRef ~= selected[1].resourceRef then
            selected[#selected + 1] = state
            break
        end
    end

    while #selected > 2 do
        table.remove(selected)
    end

    return selected
end

function PlayerTooltip:ResolveSpellcastState(eventUnit, eventState)
    if type(eventUnit) ~= "table" or type(eventState) ~= "table" then
        return nil
    end

    if type(Client.GetSpellcastEntry) ~= "function" then
        return nil
    end

    local eventId = tostring(eventState.id or "")
    local casterEventId = tonumber(eventUnit.eventID)
    if eventId == "" or casterEventId == nil then
        return nil
    end

    local entry = Client:GetSpellcastEntry(eventId, casterEventId)
    if type(entry) ~= "table" then
        return nil
    end

    local spellName = tostring(entry.spellName or "")
    local spellIcon = ""
    if type(Registry.ResolveSpellReference) == "function" then
        local _, spell = Registry:ResolveSpellReference(entry.spellRef)
        if type(spell) == "table" then
            spellName = spellName ~= "" and spellName or tostring(spell.name or "")
            spellIcon = tostring(spell.icon or "")
        end
    end
    if spellName == "" and type(Registry.ResolveSpellName) == "function" then
        spellName = tostring(Registry:ResolveSpellName(entry.spellRef) or "")
    end
    if spellName == "" then
        spellName = "Casting"
    end
    if spellIcon == "" then
        spellIcon = DEFAULT_CAST_ICON
    end

    local turnsTotal = tonumber(entry.turnsTotal)
    if turnsTotal == nil or turnsTotal <= 0 then
        return nil
    end
    turnsTotal = math.max(1, math.floor(turnsTotal))
    local turnsElapsed = math.max(0, math.floor(tonumber(entry.turnsElapsed) or 0))
    if turnsElapsed > turnsTotal then
        turnsElapsed = turnsTotal
    end
    local turnsRemaining = math.max(0, turnsTotal - turnsElapsed)

    return {
        kind = "cast",
        spellRef = entry.spellRef,
        name = spellName,
        icon = spellIcon,
        color = cloneColor(DEFAULT_CAST_BAR_COLOR),
        currentValue = turnsElapsed,
        maxValue = turnsTotal,
        currentText = formatTurnLabel(turnsRemaining),
        progressText = spellName,
    }
end

function PlayerTooltip:EnsureResourceContainer()
    if self.ResourceContainer then
        return self.ResourceContainer
    end

    if type(Panel) ~= "table" or type(Panel.New) ~= "function" then
        return nil
    end

    local container = Panel:New({
        name = "RPEnginePlayerTooltipResourceContainer",
        width = RESOURCE_STACK_MIN_WIDTH,
        height = RESOURCE_BAR_HEIGHT,
        border = false,
        showBorder = false,
        contentInset = 0,
        panelBackgroundColor = { r = 0, g = 0, b = 0, a = 0 },
        showWhenUIHidden = false,
        hidden = true,
    })
    container:SetParent(UIParent)
    container:Create()

    local frame = container:GetFrame()
    if frame and frame.SetFrameStrata then
        frame:SetFrameStrata("TOOLTIP")
    end
    if frame and frame.SetFrameLevel then
        frame:SetFrameLevel(10010)
    end
    container:Hide()

    self.ResourceContainer = container
    self.ResourceRows = self.ResourceRows or {}
    return self.ResourceContainer
end

function PlayerTooltip:EnsureResourceRow(index, kind)
    self.ResourceRows = self.ResourceRows or {}
    local row = self.ResourceRows[index]
    if row and row.barKind == kind then
        return row
    end
    if row then
        local previousFrame = row.GetFrame and row:GetFrame() or nil
        if previousFrame and previousFrame.Hide then
            previousFrame:Hide()
        end
    end

    local container = self:EnsureResourceContainer()
    if not container then
        return nil
    end

    local barClass = kind == "cast" and CastBar or ResourceBar
    local resourceBar = barClass:New({
        name = ("RPEnginePlayerTooltipResourceRow%d"):format(index),
        width = RESOURCE_STACK_MIN_WIDTH,
        height = RESOURCE_BAR_HEIGHT,
        iconSize = RESOURCE_ICON_SIZE,
        valueWidth = RESOURCE_VALUE_WIDTH,
        progressFontSize = kind == "cast" and TOOLTIP_CAST_FONT_SIZE or TOOLTIP_RESOURCE_FONT_SIZE,
        valueFontSize = TOOLTIP_RESOURCE_FONT_SIZE,
        iconTexture = DEFAULT_RESOURCE_ICON,
        border = false,
        showWhenUIHidden = false,
    })
    resourceBar:SetParent(container:GetFrame())
    resourceBar:Create()
    resourceBar.barKind = kind
    row = resourceBar
    self.ResourceRows[index] = row
    return row
end

function PlayerTooltip:HideResourceBars(targetTooltip)
    local container = self.ResourceContainer
    if not container or not container.Hide then
        return false
    end

    if targetTooltip ~= nil and self.ActiveHealthTooltip ~= targetTooltip then
        return false
    end

    container:Hide()
    self.ActiveHealthTooltip = nil
    return true
end

function PlayerTooltip:ShowResourceBars(tooltip, eventUnit, eventState, unitToken)
    local container = self:EnsureResourceContainer()
    if not container or type(tooltip) ~= "table" then
        return false, "missing-resource-container"
    end

    local resourceStates = self:BuildVisibleResourceStates(eventUnit, eventState)
    local castState = self:ResolveSpellcastState(eventUnit, eventState)
    local rowStates = {}

    if castState then
        rowStates[#rowStates + 1] = castState
    end
    for index = 1, #resourceStates do
        rowStates[#rowStates + 1] = resourceStates[index]
    end

    if #rowStates == 0 then
        self:HideResourceBars(tooltip)
        return false, "no-tooltip-rows"
    end

    local containerFrame = container.GetFrame and container:GetFrame() or nil
    local tooltipFrame = tooltip
    local tooltipWidth = tooltipFrame.GetWidth and tooltipFrame:GetWidth() or RESOURCE_STACK_MIN_WIDTH
    local stackWidth = math.max(RESOURCE_STACK_MIN_WIDTH, math.floor(tonumber(tooltipWidth) or RESOURCE_STACK_MIN_WIDTH))
    local stackHeight = (#rowStates * RESOURCE_BAR_HEIGHT) + (math.max(0, #rowStates - 1) * RESOURCE_BAR_SPACING)

    container:SetParent(tooltipFrame)
    if containerFrame and containerFrame.SetWidth then
        containerFrame:SetWidth(stackWidth)
    end
    if containerFrame and containerFrame.SetHeight then
        containerFrame:SetHeight(stackHeight)
    end
    if containerFrame and containerFrame.ClearAllPoints then
        containerFrame:ClearAllPoints()
        containerFrame:SetPoint("BOTTOMLEFT", tooltipFrame, "TOPLEFT", 0, 2)
        containerFrame:SetPoint("BOTTOMRIGHT", tooltipFrame, "TOPRIGHT", 0, 2)
    end

    for index = 1, #rowStates do
        local state = rowStates[index]
        local row = self:EnsureResourceRow(index, state and state.kind == "cast" and "cast" or "resource")
        local rowFrame = row and row.GetFrame and row:GetFrame() or nil
        local iconFrame = row and row.icon and row.icon.GetFrame and row.icon:GetFrame() or nil
        local valueFrame = row and row.valueText and row.valueText.GetFrame and row.valueText:GetFrame() or nil
        local progressFrame = row and row.progressBar and row.progressBar.GetFrame and row.progressBar:GetFrame() or nil
        local progressWidth = stackWidth - RESOURCE_ICON_SIZE - RESOURCE_VALUE_WIDTH - 8

        if rowFrame and rowFrame.ClearAllPoints then
            rowFrame:ClearAllPoints()
            rowFrame:SetPoint("TOPLEFT", containerFrame, "TOPLEFT", 0, -((index - 1) * (RESOURCE_BAR_HEIGHT + RESOURCE_BAR_SPACING)))
            rowFrame:SetPoint("TOPRIGHT", containerFrame, "TOPRIGHT", 0, -((index - 1) * (RESOURCE_BAR_HEIGHT + RESOURCE_BAR_SPACING)))
            rowFrame:SetHeight(RESOURCE_BAR_HEIGHT)
            rowFrame:Show()
        end

        if row and row:SetState() then
            row:SetState(state)
        end
        if row and row:SetBarWidth() then
            row:SetBarWidth(progressWidth)
        end

        if iconFrame and iconFrame.ClearAllPoints then
            iconFrame:ClearAllPoints()
            iconFrame:SetPoint("LEFT", rowFrame, "LEFT", 0, 0)
            iconFrame:SetWidth(RESOURCE_ICON_SIZE)
            iconFrame:SetHeight(RESOURCE_ICON_SIZE)
            iconFrame:Show()
        end

        if valueFrame and valueFrame.ClearAllPoints then
            valueFrame:ClearAllPoints()
            valueFrame:SetPoint("RIGHT", rowFrame, "RIGHT", 0, 0)
            valueFrame:SetWidth(RESOURCE_VALUE_WIDTH)
            valueFrame:SetHeight(RESOURCE_BAR_HEIGHT)
            valueFrame:Show()
            if state and state.valuePlacement == "bar" and valueFrame.Hide then
                valueFrame:Hide()
            end
        end

        if progressFrame and progressFrame.ClearAllPoints then
            progressFrame:ClearAllPoints()
            progressFrame:SetPoint("LEFT", iconFrame, "RIGHT", 4, 0)
            progressFrame:SetPoint("RIGHT", valueFrame, "LEFT", -4, 0)
            progressFrame:SetHeight(RESOURCE_BAR_HEIGHT)
            progressFrame:Show()
        end

        if row and row.valueText and row.valueText.SetText then
            row.valueText:SetText(state.currentText or "")
        end
    end

    for index = #rowStates + 1, #(self.ResourceRows or {}) do
        local row = self.ResourceRows[index]
        local rowFrame = row and row.GetFrame and row:GetFrame() or nil
        if rowFrame and rowFrame.Hide then
            rowFrame:Hide()
        end
    end

    container:Show()
    self.ActiveHealthTooltip = tooltipFrame
    tooltip.__RPEngineEventHealthLineToken = table.concat({
        tostring(type(eventState) == "table" and eventState.id or ""),
        tostring(unitToken or ""),
        tostring(#rowStates),
    }, ":")
    return true, "shown"
end

function PlayerTooltip:HandleTooltipSetUnit(tooltip)
    local unitToken = self:ResolveTooltipUnit(tooltip)
    if type(unitToken) ~= "string" or unitToken == "" then
        self:ClearTooltipState(tooltip)
        self:HideResourceBars(tooltip)
        return false
    end

    local eventUnit, eventState = self:ResolveEventUnit(unitToken, tooltip)
    if not eventUnit then
        self:ClearTooltipState(tooltip)
        self:HideResourceBars(tooltip)
        return false
    end

    local resourceStates = self:BuildVisibleResourceStates(eventUnit, eventState)
    if #resourceStates == 0 then
        self:ClearTooltipState(tooltip)
        self:HideResourceBars(tooltip)
        return false
    end

    local appended = self:ShowResourceBars(tooltip, eventUnit, eventState, unitToken)
    return appended
end

function PlayerTooltip:QueueTooltipRefresh(tooltip, source)
    if type(tooltip) ~= "table" then
        return false
    end

    self.RefreshSequence = (tonumber(self.RefreshSequence) or 0) + 1
    local refreshSequence = self.RefreshSequence
    tooltip.__RPEngineEventHealthLineToken = nil

    scheduleDeferred(function()
        if self.RefreshSequence ~= refreshSequence then
            return
        end

        if not isTooltipShown(tooltip) then
            return
        end

        self:HandleTooltipSetUnit(tooltip)
    end)

    return true
end

function PlayerTooltip:ShouldRefreshTooltipForPayload(tooltip, payload)
    if type(payload) ~= "table" then
        return true
    end

    local eventIds = type(payload.eventIds) == "table" and payload.eventIds or nil
    if eventIds == nil or next(eventIds) == nil then
        return true
    end

    local unitToken = self:ResolveTooltipUnit(tooltip)
    local eventUnit = unitToken and self:ResolveEventUnit(unitToken) or nil
    local eventId = tonumber(type(eventUnit) == "table" and eventUnit.eventID or 0) or 0
    return eventId > 0 and eventIds[eventId] == true
end

function PlayerTooltip:RefreshVisibleTooltips(source, payload)
    local refreshed = false
    local tooltip = _G.GameTooltip
    local trp3Tooltip = _G.TRP3_CharacterTooltip

    if isTooltipShown(tooltip) and self:ShouldRefreshTooltipForPayload(tooltip, payload) then
        self:QueueTooltipRefresh(tooltip, source or "visible-refresh")
        refreshed = true
    end
    if isTooltipShown(trp3Tooltip) and self:ShouldRefreshTooltipForPayload(trp3Tooltip, payload) then
        self:QueueTooltipRefresh(trp3Tooltip, source or "visible-refresh-trp3")
        refreshed = true
    end

    return refreshed
end

function PlayerTooltip:InstallTooltipHooks(tooltip, label, options)
    if type(tooltip) ~= "table" then
        return false
    end

    options = options or {}
    local installedHook = false

    if options.unitDataPostCall == true
        and type(TooltipDataProcessor) == "table"
        and type(TooltipDataProcessor.AddTooltipPostCall) == "function"
        and type(Enum) == "table"
        and type(Enum.TooltipDataType) == "table"
        and Enum.TooltipDataType.Unit ~= nil
    then
        TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit, function(frame)
            if frame == tooltip then
                PlayerTooltip:QueueTooltipRefresh(frame, ("%s-tooltip-data-postcall"):format(tostring(label or "tooltip")))
            end
        end)
        installedHook = true
    end

    if options.setUnitHook == true and type(hooksecurefunc) == "function" and type(tooltip.SetUnit) == "function" then
        hooksecurefunc(tooltip, "SetUnit", function(frame)
            PlayerTooltip:QueueTooltipRefresh(frame, ("%s-set-unit"):format(tostring(label or "tooltip")))
        end)
        installedHook = true
    end

    if type(tooltip.HookScript) == "function" then
        tooltip:HookScript("OnShow", function(frame)
            PlayerTooltip:QueueTooltipRefresh(frame, ("%s-onshow"):format(tostring(label or "tooltip")))
        end)
        tooltip:HookScript("OnHide", function(frame)
            PlayerTooltip:ClearTooltipState(frame)
            PlayerTooltip:HideResourceBars(frame)
        end)
        installedHook = true
    end

    return installedHook
end

function PlayerTooltip:Install()
    if self.Installed then
        return true
    end

    local tooltip = _G.GameTooltip
    if type(tooltip) ~= "table" then
        return false
    end

    local installedHook = false
    installedHook = self:InstallTooltipHooks(tooltip, "blizzard", {
        unitDataPostCall = true,
        setUnitHook = true,
    }) or installedHook

    local trp3Tooltip = _G.TRP3_CharacterTooltip
    installedHook = self:InstallTooltipHooks(trp3Tooltip, "trp3", {
        unitDataPostCall = false,
        setUnitHook = false,
    }) or installedHook

    if not self.MouseoverObserver then
        local observer = CreateFrame and CreateFrame("Frame", nil, UIParent) or nil
        if observer and observer.RegisterEvent and observer.SetScript then
            observer:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
            observer:SetScript("OnEvent", function()
                local unitToken = PlayerTooltip:ResolveTooltipUnit(tooltip)
                local trp3Shown = isTooltipShown(_G.TRP3_CharacterTooltip)

                if isTooltipShown(tooltip) then
                    PlayerTooltip:QueueTooltipRefresh(tooltip, "update-mouseover-unit")
                end
                if trp3Shown then
                    PlayerTooltip:QueueTooltipRefresh(_G.TRP3_CharacterTooltip, "update-mouseover-unit-trp3")
                end
            end)
            self.MouseoverObserver = observer
            installedHook = true
        end
    end

    if not installedHook then
        return false
    end

    self.Installed = true
    return true
end

PlayerTooltip:Install()

return PlayerTooltip
