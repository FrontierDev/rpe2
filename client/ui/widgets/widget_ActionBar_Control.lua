local addonName, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Client.UI = Addon.Client.UI or {}

local Client = Addon.Client
local ClientUI = Addon.Client.UI
local UI = Addon.UI or {}
local Inline = UI.Inline or {}
local Profile = Addon.Internal and Addon.Internal.Profile or {}
local Common = Addon.Common or {}

local ActionBarWidget = ClientUI.ActionBarWidget or {}
ClientUI.ActionBarWidget = ActionBarWidget
ActionBarWidget.__index = ActionBarWidget

local CONTROL_LABEL_HEIGHT = 14
local CONTROL_LABEL_GAP = 4
local CONTROL_BUTTON_SIZE = 16
local CONTROL_BUTTON_GAP = 4
local END_TURN_BUTTON_WIDTH = 76
local END_TURN_BUTTON_HEIGHT = 20
local CONTROL_BUTTON_TEXTURE = "Interface\\AddOns\\RPEngine_Dev\\data\\textures\\ui\\close_button.png"
local MOVEMENT_BAR_HEIGHT = 12
local MOVEMENT_BAR_GAP = 2
local MOVEMENT_BAR_MIN = 0
local MOVEMENT_BAR_MAX = 100
local MOVEMENT_BAR_ICON = 132307
local MOVEMENT_BAR_ICON_SIZE = 18
local MOVEMENT_BAR_ICON_GAP = 4
local MOVEMENT_POLL_INTERVAL = 0.2

local function getHorizontalContentInset(widget)
    return type(widget) == "table" and type(widget.GetContentInset) == "function" and widget:GetContentInset() or 8
end

local function getControlRowTopGap()
    return CONTROL_LABEL_GAP
end

local function getControlRowCenterOffset(height)
    local rowHeight = math.max(0, tonumber(height) or 0)
    return -(getControlRowTopGap() + (rowHeight * 0.5))
end

local function getMovementTracker()
    return type(RPE) == "table" and type(RPE.Core) == "table" and type(RPE.Core.Movement) == "table" and RPE.Core.Movement or nil
end

local function normalizeName(value)
    if Common.NormalizeName then
        return Common.NormalizeName(value)
    end

    return tostring(value or "")
end

local function getActionRowButtonMetrics(widget)
    local size, gap = nil, nil
    if widget and widget.GetUtilityButtonMetrics then
        size, gap = widget:GetUtilityButtonMetrics()
    end
    if type(size) ~= "number" or type(gap) ~= "number" then
        size = CONTROL_BUTTON_SIZE
        gap = CONTROL_BUTTON_GAP
    end

    return size, gap
end

local function buildMovementDisplayState()
    local movementRangeValue = type(Profile.GetMovementRangeValue) == "function" and tonumber(Profile.GetMovementRangeValue()) or nil
    if movementRangeValue == nil then
        return nil
    end

    local tracker = getMovementTracker()
    local remainingValue = movementRangeValue
    if tracker and type(tracker.GetTraveledDistance) == "function" then
        remainingValue = math.max(0, movementRangeValue - (tonumber(tracker:GetTraveledDistance()) or 0))
    elseif tracker and type(tracker.GetRemainingDistance) == "function" then
        remainingValue = math.max(0, tonumber(tracker:GetRemainingDistance()) or 0)
    end

    return {
        minValue = 0,
        maxValue = math.max(0, movementRangeValue),
        value = math.max(0, remainingValue),
    }
end

local function buildMovementDisplayKey(state)
    if type(state) ~= "table" then
        return ""
    end

    return ("%0.3f:%0.3f"):format(tonumber(state.value) or 0, tonumber(state.maxValue) or 0)
end

local function applyMovementDisplayState(widget, state)
    local movementBar = widget and widget.movementRangeBar or nil
    if not movementBar then
        return false
    end

    local maxValue = math.max(MOVEMENT_BAR_MIN, tonumber(state and state.maxValue) or MOVEMENT_BAR_MIN)
    local currentValue = math.max(MOVEMENT_BAR_MIN, math.min(maxValue, tonumber(state and state.value) or MOVEMENT_BAR_MIN))
    movementBar:SetMinMax(MOVEMENT_BAR_MIN, maxValue)
    movementBar:SetValue(currentValue)
    movementBar:SetText("")
    if movementBar.label and movementBar.label.Hide then
        movementBar.label:Hide()
    end

    widget._lastMovementDisplayKey = buildMovementDisplayKey(state)
    return true
end

local function getControlledSpellRefs(controlledUnit)
    if type(controlledUnit) ~= "table" then
        return {}
    end

    local spellRefs = controlledUnit.spells or {}
    if controlledUnit.GetResolvedValue then
        spellRefs = controlledUnit:GetResolvedValue("spells", spellRefs)
    end

    if type(spellRefs) == "string" then
        if spellRefs == "" then
            return {}
        end

        return { spellRefs }
    end

    if type(spellRefs) ~= "table" then
        return {}
    end

    return spellRefs
end

local function buildControlledActionBarRows(controlledUnit)
    local rows = {}
    local spellRefs = getControlledSpellRefs(controlledUnit)

    for index = 1, #spellRefs do
        local spellRef = spellRefs[index]
        if type(spellRef) == "table" then
            spellRef = spellRef.spellRef or spellRef.spellID or spellRef.id or spellRef.name
        end
        if type(spellRef) == "string" and spellRef ~= "" then
            local detail = Profile.GetKnownSpellDetails and Profile.GetKnownSpellDetails(spellRef) or nil
            if detail then
                rows[#rows + 1] = detail
            else
                rows[#rows + 1] = {
                    spellRef = spellRef,
                    name = spellRef,
                    statusText = "Unknown",
                    cooldownText = "No Cooldown",
                    datasetName = "",
                    descriptionText = "",
                    spell = nil,
                }
            end
        end
    end

    return rows
end

local function buildControlLabel(controlledUnit)
    if type(controlledUnit) ~= "table" then
        return ""
    end

    local raidMarker = tonumber(controlledUnit.raidMarker) or 0
    local raidMarkerText = raidMarker > 0 and type(Inline.RaidMarker) == "function" and Inline:RaidMarker(raidMarker, 12, 12) or ""
    local raidMarkerPrefix = raidMarkerText ~= "" and (raidMarkerText .. " ") or ""
    local unitName = tostring(controlledUnit.name or "Unnamed Unit")
    local eventId = tonumber(controlledUnit.eventID) or 0
    if eventId <= 0 then
        return ""
    end

    return ("Controlling %s%s (#%d)"):format(raidMarkerPrefix, unitName, eventId)
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

function ActionBarWidget:IsActionBarControlActive()
    local controlContext = Client.GetActionBarControlContext and Client:GetActionBarControlContext() or nil
    return type(controlContext) == "table" and controlContext.isControlled == true and controlContext.controlledUnit ~= nil
end

function ActionBarWidget:ResolveControllablePetUnit(controlContext)
    local context = type(controlContext) == "table" and controlContext or (Client.GetActionBarControlContext and Client:GetActionBarControlContext() or nil)
    local eventState = type(context) == "table" and context.eventState or nil
    local localEventUnit = type(context) == "table" and context.localEventUnit or nil
    local eventUnits = type(eventState) == "table" and type(eventState.units) == "table" and eventState.units or nil
    if type(localEventUnit) ~= "table" or type(eventUnits) ~= "table" then
        return nil
    end

    local preferredPetRef = Profile.GetPetRef and tostring(Profile.GetPetRef() or "") or ""
    local fallbackPet = nil

    for index = 1, #eventUnits do
        local eventUnit = eventUnits[index]
        if isLocalPlayerPet(eventUnit, localEventUnit)
            and Client.CanControlEventUnit
            and Client:CanControlEventUnit(eventUnit, eventState)
        then
            if preferredPetRef ~= "" and tostring(eventUnit.petRef or "") == preferredPetRef then
                return eventUnit
            end
            if fallbackPet == nil then
                fallbackPet = eventUnit
            end
        end
    end

    return fallbackPet
end

function ActionBarWidget:GetActionBarRows()
    local controlContext = Client.GetActionBarControlContext and Client:GetActionBarControlContext() or nil
    local isControlled = type(controlContext) == "table" and controlContext.isControlled == true and controlContext.controlledUnit ~= nil
    if isControlled then
        return buildControlledActionBarRows(controlContext.controlledUnit)
    end

    if Profile.ShouldUseMountedActionBar and Profile.ShouldUseMountedActionBar() then
        return Profile.ListMountedActionBarSlots and Profile.ListMountedActionBarSlots() or {}
    end

    local actionBarMode = Profile.GetActionBarMode and Profile.GetActionBarMode() or "spells"
    if actionBarMode == "skills" then
        return Profile.ListSkillActionBarSlots and Profile.ListSkillActionBarSlots() or {}
    end

    return Profile.ListActionBarSlots and Profile.ListActionBarSlots() or {}
end

local function isMovementBarActive(controlContext)
    return (type(controlContext) ~= "table" or controlContext.isControlled ~= true)
        and buildMovementDisplayState() ~= nil
end

function ActionBarWidget:SyncControlUpdaterState(enabled)
    local updater = self.controlStateUpdater
    if not updater then
        return false
    end

    local rootFrame = self.rootPanel and self.rootPanel.GetFrame and self.rootPanel:GetFrame() or nil
    local shouldEnable = enabled == true
        and rootFrame ~= nil
        and rootFrame.IsShown ~= nil
        and rootFrame:IsShown() == true
    if self._controlStateUpdaterEnabled == shouldEnable then
        return shouldEnable
    end

    self._controlStateUpdaterEnabled = shouldEnable
    self._controlStatePollElapsed = 0
    updater:Hide()

    return false
end

function ActionBarWidget:BindMovementTracker()
    local tracker = getMovementTracker()
    if self._boundMovementTracker == tracker then
        return tracker
    end

    local previousTracker = self._boundMovementTracker
    if previousTracker and previousTracker._boundActionBarWidget == self then
        previousTracker.OnDistanceUpdate = nil
        previousTracker._boundActionBarWidget = nil
    end

    self._boundMovementTracker = tracker
    if tracker then
        tracker._boundActionBarWidget = self
        tracker.OnDistanceUpdate = function(_, remaining, maximum)
            applyMovementDisplayState(self, {
                minValue = 0,
                maxValue = math.max(0, tonumber(maximum) or 0),
                value = math.max(0, tonumber(remaining) or 0),
            })
        end
    end

    return tracker
end

function ActionBarWidget:EnsureControlChrome()
    if not self.rootPanel then
        return true
    end

    local rootFrame = self.rootPanel:GetFrame()
    if not self.controlLabel then
        self.controlLabel = UI.CreateText(rootFrame, "RPEClientActionBarControlLabel", "", {
            width = 320,
            height = CONTROL_LABEL_HEIGHT,
            fontSize = 10,
            fontFlags = "OUTLINE",
            justifyH = "LEFT",
            justifyV = "TOP",
            wordWrap = false,
            textColor = UI.ResolveColor(nil, "text.muted"),
        })
        self.controlLabel:GetFrame():Hide()
    end

    if not self.closeButton then
        self.closeButton = UI.ImageButton:New({
            name = "RPEClientActionBarControlCloseButton",
            width = CONTROL_BUTTON_SIZE,
            height = CONTROL_BUTTON_SIZE,
            border = false,
            normalTexture = CONTROL_BUTTON_TEXTURE,
            highlightTexture = CONTROL_BUTTON_TEXTURE,
            pushedTexture = CONTROL_BUTTON_TEXTURE,
            disabledTexture = CONTROL_BUTTON_TEXTURE,
        })
        self.closeButton:SetParent(rootFrame)
        self.closeButton:Create()
        self.closeButton:SetScript("OnClick", function()
            if Client.ReleaseControl then
                Client:ReleaseControl("control-closed")
            end
        end)
        self.closeButton:GetFrame():Hide()
    end

    if not self.endTurnButton then
        self.endTurnButton = UI.CreateButton(rootFrame, "RPEClientActionBarEndTurnButton", "End Turn", END_TURN_BUTTON_WIDTH, function()
            if Client.EndTurn then
                Client:EndTurn()
            end
        end)
        self.endTurnButton:SetScript("OnEnter", function()
            if Client.ShowPendingTurnChangesTooltip then
                Client:ShowPendingTurnChangesTooltip(self.endTurnButton)
            end
        end)
        self.endTurnButton:SetScript("OnLeave", function()
            if Client.HidePendingTurnChangesTooltip then
                Client:HidePendingTurnChangesTooltip()
            end
        end)
        self.endTurnButton:SetScript("OnHide", function()
            if Client.HidePendingTurnChangesTooltip then
                Client:HidePendingTurnChangesTooltip()
            end
        end)
        self.endTurnButton:GetFrame():SetHeight(END_TURN_BUTTON_HEIGHT)
        self.endTurnButton:GetFrame():Hide()
    end

    if not self.movementRangeBar then
        self.movementRangeBar = UI.ProgressBar:New({
            name = "RPEClientActionBarMovementRangeBar",
            width = 220,
            height = MOVEMENT_BAR_HEIGHT,
            minValue = MOVEMENT_BAR_MIN,
            maxValue = MOVEMENT_BAR_MAX,
            value = MOVEMENT_BAR_MIN,
            text = "",
            backgroundToken = "progress.background",
            borderToken = "progress.border",
            primaryColor = { r = 0.22, g = 0.62, b = 0.48, a = 1 },
            secondaryColor = { r = 0.14, g = 0.34, b = 0.28, a = 1 },
            textToken = "progress.text",
            fontFlags = "OUTLINE",
        })
        self.movementRangeBar:SetParent(rootFrame)
        self.movementRangeBar:Create()
        self.movementRangeBar:GetFrame():Hide()
        if self.movementRangeBar.label and self.movementRangeBar.label.Hide then
            self.movementRangeBar.label:Hide()
        end
    end

    if not self.movementRangeIcon then
        self.movementRangeIcon = UI.Image:New({
            name = "RPEClientActionBarMovementRangeIcon",
            width = MOVEMENT_BAR_ICON_SIZE,
            height = MOVEMENT_BAR_ICON_SIZE,
            texture = MOVEMENT_BAR_ICON,
            border = false,
            showWhenUIHidden = false,
        })
        self.movementRangeIcon:SetParent(rootFrame)
        self.movementRangeIcon:Create()
        self.movementRangeIcon:GetFrame():Hide()
    end

    if not self.controlStateUpdater then
        self.controlStateUpdater = CreateFrame("Frame", nil, rootFrame)
        self.controlStateUpdater:Hide()
    end

    return true
end

function ActionBarWidget:RefreshControlState(reason)
    if not self.rootPanel then
        return false
    end

    self:EnsureControlChrome()
    if self.RefreshActionRowButtons then
        self:RefreshActionRowButtons()
    end
    local movementTracker = self.BindMovementTracker and self:BindMovementTracker() or getMovementTracker()
    if movementTracker and type(movementTracker.RefreshMaxDistance) == "function" then
        movementTracker:RefreshMaxDistance()
    end

    local controlContext = Client.GetActionBarControlContext and Client:GetActionBarControlContext() or nil
    local hasEventContext = type(controlContext) == "table" and type(controlContext.eventState) == "table"
    local isControlled = type(controlContext) == "table" and controlContext.isControlled == true and controlContext.controlledUnit ~= nil
    local controlledUnit = isControlled and controlContext.controlledUnit or nil
    local rootFrame = self.rootPanel:GetFrame()
    local baseWidth = rootFrame and rootFrame.GetWidth and rootFrame:GetWidth() or 0
    local contentInset = getHorizontalContentInset(self)
    local labelText = isControlled and buildControlLabel(controlledUnit) or ""
    local isLocalTurn = Client.IsLocalTurnActive and Client:IsLocalTurnActive(controlContext and controlContext.eventState) or false
    local isLocalHost = Client.IsLocalEventHost and Client:IsLocalEventHost(controlContext and controlContext.eventState) or false
    local showMovementBar = isMovementBarActive(controlContext)
    local movementDisplayState = showMovementBar and buildMovementDisplayState() or nil
    local showCloseButton = isControlled and labelText ~= ""
    local showEndTurnButton = hasEventContext and not isLocalHost
    local showActionRowButtons = not isControlled
    local labelRightReservedWidth = 0
    local actionRowButtonSize, actionRowButtonGap = getActionRowButtonMetrics(self)
    local actionRowButtonFrames = {}
    local actionRowButtons = self.GetActionRowButtons and self:GetActionRowButtons() or {}

    self:SyncControlUpdaterState(false)

    if showCloseButton then
        labelRightReservedWidth = CONTROL_BUTTON_SIZE
    end
    if showEndTurnButton then
        labelRightReservedWidth = labelRightReservedWidth + END_TURN_BUTTON_WIDTH
        if showCloseButton then
            labelRightReservedWidth = labelRightReservedWidth + CONTROL_BUTTON_GAP
        end
    end
    if labelRightReservedWidth > 0 then
        labelRightReservedWidth = labelRightReservedWidth + contentInset
    end
    for index = 1, #actionRowButtons do
        local button = actionRowButtons[index]
        local buttonFrame = button and button.GetFrame and button:GetFrame() or nil
        if buttonFrame then
            if showActionRowButtons then
                actionRowButtonFrames[#actionRowButtonFrames + 1] = buttonFrame
            else
                buttonFrame:Hide()
            end
        end
    end
    local actionRowWidth = 0
    if #actionRowButtonFrames > 0 then
        actionRowWidth = (#actionRowButtonFrames * actionRowButtonSize) + ((#actionRowButtonFrames - 1) * actionRowButtonGap)
    end
    local bottomLeftReservedWidth = actionRowWidth > 0 and (actionRowWidth + actionRowButtonGap) or 0
    local bottomRightReservedWidth = showEndTurnButton and (END_TURN_BUTTON_WIDTH + contentInset) or 0
    local labelContentWidth = math.max(48, baseWidth - (contentInset * 2) - labelRightReservedWidth)
    local bottomContentWidth = math.max(48, baseWidth - (contentInset * 2) - bottomLeftReservedWidth - bottomRightReservedWidth)

    if self.controlLabel and self.controlLabel.SetText then
        self.controlLabel:SetText(labelText)
    end
    if self.controlLabel and self.controlLabel.GetFrame then
        local labelFrame = self.controlLabel:GetFrame()
        if labelFrame then
            if labelFrame.SetWidth then
                labelFrame:SetWidth(labelContentWidth)
            end
            if showCloseButton then
                labelFrame:Show()
            else
                labelFrame:Hide()
            end
            labelFrame:ClearAllPoints()
            labelFrame:SetPoint("TOPLEFT", rootFrame, "BOTTOMLEFT", contentInset, -getControlRowTopGap())
        end
    end

    if self.closeButton and self.closeButton.GetFrame then
        local closeFrame = self.closeButton:GetFrame()
        if closeFrame then
            if showCloseButton then
                closeFrame:Show()
            else
                closeFrame:Hide()
            end
            closeFrame:ClearAllPoints()
            closeFrame:SetPoint("TOPRIGHT", rootFrame, "BOTTOMRIGHT", -contentInset, -getControlRowTopGap())
        end
    end

    if self.endTurnButton and self.endTurnButton.GetFrame then
        local buttonFrame = self.endTurnButton:GetFrame()
        if showEndTurnButton then
            buttonFrame:Show()
        else
            buttonFrame:Hide()
        end
        if self.endTurnButton.SetEnabled then
            self.endTurnButton:SetEnabled(isLocalTurn == true and not isLocalHost)
        elseif buttonFrame.Enable and buttonFrame.Disable then
            if isLocalTurn and not isLocalHost then
                buttonFrame:Enable()
            else
                buttonFrame:Disable()
            end
        end
        buttonFrame:ClearAllPoints()
        if showCloseButton and self.closeButton and self.closeButton.GetFrame then
            buttonFrame:SetPoint("TOPRIGHT", self.closeButton:GetFrame(), "TOPLEFT", -CONTROL_BUTTON_GAP, 0)
        else
            buttonFrame:SetPoint("TOPRIGHT", rootFrame, "BOTTOMRIGHT", -contentInset, -getControlRowTopGap())
        end
    end

    for index = 1, #actionRowButtonFrames do
        local buttonFrame = actionRowButtonFrames[index]
        buttonFrame:ClearAllPoints()
        buttonFrame:SetSize(actionRowButtonSize, actionRowButtonSize)
        buttonFrame:Show()
    end
    for index = 1, #actionRowButtonFrames do
        local buttonFrame = actionRowButtonFrames[index]
        if index == 1 then
            buttonFrame:SetPoint("LEFT", rootFrame, "BOTTOMLEFT", contentInset, getControlRowCenterOffset(actionRowButtonSize))
        else
            buttonFrame:SetPoint("LEFT", actionRowButtonFrames[index - 1], "RIGHT", actionRowButtonGap, 0)
        end
    end

    if self.movementRangeIcon and self.movementRangeIcon.GetFrame then
        local iconFrame = self.movementRangeIcon:GetFrame()
        if iconFrame then
            if showMovementBar then
                iconFrame:Show()
            else
                iconFrame:Hide()
            end
            iconFrame:ClearAllPoints()
            if #actionRowButtonFrames > 0 then
                iconFrame:SetPoint("LEFT", actionRowButtonFrames[#actionRowButtonFrames], "RIGHT", actionRowButtonGap, 0)
            else
                iconFrame:SetPoint("LEFT", rootFrame, "BOTTOMLEFT", contentInset, getControlRowCenterOffset(MOVEMENT_BAR_HEIGHT))
            end
            iconFrame:SetWidth(MOVEMENT_BAR_ICON_SIZE)
            iconFrame:SetHeight(MOVEMENT_BAR_ICON_SIZE)
        end
    end

    if self.movementRangeBar and self.movementRangeBar.GetFrame then
        local movementFrame = self.movementRangeBar:GetFrame()
        local movementBarWidth = math.max(0, bottomContentWidth - MOVEMENT_BAR_ICON_SIZE - MOVEMENT_BAR_ICON_GAP)
        if movementFrame then
            if showMovementBar then
                movementFrame:Show()
            else
                movementFrame:Hide()
            end
            movementFrame:ClearAllPoints()
            if self.movementRangeIcon and self.movementRangeIcon.GetFrame then
                movementFrame:SetPoint("LEFT", self.movementRangeIcon:GetFrame(), "RIGHT", MOVEMENT_BAR_ICON_GAP, 0)
            else
                movementFrame:SetPoint("LEFT", rootFrame, "BOTTOMLEFT", contentInset, getControlRowCenterOffset(MOVEMENT_BAR_HEIGHT))
            end
            movementFrame:SetWidth(movementBarWidth)
            movementFrame:SetHeight(MOVEMENT_BAR_HEIGHT)
        end
        if showMovementBar then
            applyMovementDisplayState(self, movementDisplayState)
        end
    end

    self._lastMovementDisplayKey = buildMovementDisplayKey(movementDisplayState)

    return true
end

return ActionBarWidget
