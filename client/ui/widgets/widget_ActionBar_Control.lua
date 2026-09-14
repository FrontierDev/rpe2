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
local SPEAK_BUTTON_WIDTH = 54
local SPEAK_BUTTON_HEIGHT = 18
local SPEECH_EDITOR_WIDTH = 320
local SPEECH_EDITOR_HEIGHT = 144
local SPEECH_EDITOR_TEXT_MAX_BYTES = 500
local SPEECH_EDITOR_POLL_INTERVAL = 0.2
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

local function isStartupPending(eventState)
    return type(eventState) == "table"
        and eventState.active == true
        and (eventState.unitsReady ~= true or eventState.startupReady ~= true)
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

local function buildSpeakSpeakerLabel(controlledUnit)
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

    return ("Speaking as %s%s (#%d)"):format(raidMarkerPrefix, unitName, eventId)
end

local function sameSpeakIdentity(context, eventId, unitId)
    return type(context) == "table"
        and tostring(context.eventId or "") == tostring(eventId or "")
        and tonumber(context.unitId) == tonumber(unitId)
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

function ActionBarWidget:GetSpeakControlContext()
    local eventState = Client.GetEventState and Client:GetEventState() or Client.EventState
    if type(eventState) ~= "table" or eventState.active ~= true or eventState.ending == true then
        return nil, "The event is no longer active."
    end
    if not Client.IsLocalEventHost or Client:IsLocalEventHost(eventState) ~= true then
        return nil, "Only the event host can speak as a controlled NPC."
    end

    local context = Client.GetActionBarControlContext and Client:GetActionBarControlContext(eventState) or nil
    if type(context) ~= "table" or context.isControlled ~= true or type(context.controlledUnit) ~= "table" then
        return nil, "No NPC is currently controlled."
    end

    local controlledUnit = context.controlledUnit
    local unitId = tonumber(controlledUnit.eventID) or 0
    local eventId = tostring(eventState.id or "")
    if controlledUnit.isPlayer == true
        or unitId <= 0
        or unitId == math.huge
        or unitId == -math.huge
        or unitId ~= unitId
        or unitId ~= math.floor(unitId)
        or eventId == ""
    then
        return nil, "The controlled NPC is no longer valid."
    end

    local resolvedUnit = Client.ResolveControlledEventUnit and Client:ResolveControlledEventUnit(eventState) or nil
    if type(resolvedUnit) ~= "table"
        or (tonumber(resolvedUnit.eventID) or 0) ~= unitId
        or (tonumber(Client.ControlledEventUnitId) or 0) ~= unitId
        or not Client.CanControlEventUnit
        or Client:CanControlEventUnit(resolvedUnit, eventState) ~= true
    then
        return nil, "The controlled NPC is no longer valid."
    end

    return {
        eventId = eventId,
        unitId = unitId,
        eventState = eventState,
        controlledUnit = resolvedUnit,
    }
end

function ActionBarWidget:SetSpeakEditorStatus(message, isError)
    local statusText = self.speakEditorStatusText
    if not statusText then
        return false
    end

    statusText:SetText(tostring(message or ""))
    local color = isError and { r = 0.95, g = 0.42, b = 0.36, a = 1 } or UI.ResolveColor(nil, "text.muted")
    if color and statusText.SetTextColor then
        statusText:SetTextColor(color.r or 1, color.g or 1, color.b or 1, color.a or 1)
    end
    return true
end

function ActionBarWidget:InvalidateSpeakEditor(reason)
    if not self.speakEditorOpen then
        return false
    end

    self.speakEditorInvalid = true
    self.speakEditorDraftText = ""
    if self.speakEditorTextArea then
        self.speakEditorTextArea:SetText("")
        self.speakEditorTextArea:SetEnabled(false)
    end
    if self.speakSendButton then
        self.speakSendButton:SetEnabled(false)
    end
    self:SetSpeakEditorStatus(reason or "Control changed. Close this editor and open Speak again.", true)
    if self.speakEditorUpdater then
        self.speakEditorUpdater:Hide()
    end
    return true
end

function ActionBarWidget:CloseSpeakEditor()
    self.speakEditorOpen = false
    self.speakEditorInvalid = false
    self.speakEditorEventId = nil
    self.speakEditorUnitId = nil
    self.speakEditorDraftText = ""
    if self.speakEditorUpdater then
        self.speakEditorUpdater:Hide()
    end
    if self.speakEditorTextArea then
        self.speakEditorTextArea:ClearFocus()
        self.speakEditorTextArea:SetEnabled(true)
        self.speakEditorTextArea:SetText("")
    end
    if self.speakSendButton then
        self.speakSendButton:SetEnabled(true)
    end
    if self.speakEditorPanel and self.speakEditorPanel.Hide then
        self.speakEditorPanel:Hide()
    end
    self:SetSpeakEditorStatus("", false)
    return true
end

function ActionBarWidget:EnsureSpeakEditor()
    if not self.rootPanel then
        return false
    end

    if self.speakButton and self.speakEditorPanel then
        return true
    end

    local rootFrame = self.rootPanel:GetFrame()
    if not self.speakButton then
        self.speakButton = UI.CreateButton(rootFrame, "RPEClientActionBarSpeakButton", "Speak", SPEAK_BUTTON_WIDTH, function()
            self:OpenSpeakEditor()
        end)
        local buttonFrame = self.speakButton:GetFrame()
        buttonFrame:SetHeight(SPEAK_BUTTON_HEIGHT)
        buttonFrame:Hide()
    end

    if not self.speakEditorPanel then
        self.speakEditorPanel = UI.CreatePanel(rootFrame, "RPEClientActionBarSpeakEditor", {
            width = SPEECH_EDITOR_WIDTH,
            height = SPEECH_EDITOR_HEIGHT,
            contentInset = 8,
            showBorder = true,
            panelBackgroundColor = UI.ResolveColor(nil, "panel.background"),
            panelBorderColor = UI.ResolveColor(nil, "panel.border"),
            frameStrata = "DIALOG",
            frameLevel = 70,
            hidden = true,
        })
        local panelFrame = self.speakEditorPanel:GetFrame()
        panelFrame:SetFrameStrata("DIALOG")
        panelFrame:SetFrameLevel(math.max(70, (rootFrame:GetFrameLevel() or 55) + 10))
        panelFrame:SetClampedToScreen(true)
        panelFrame:SetPoint("BOTTOMLEFT", rootFrame, "TOPLEFT", getHorizontalContentInset(self), 4)

        local content = self.speakEditorPanel:GetContentFrame()
        self.speakEditorSpeakerText = UI.CreateText(content, "RPEClientActionBarSpeakSpeaker", "", {
            width = SPEECH_EDITOR_WIDTH - 16,
            height = 16,
            fontSize = 9,
            fontFlags = "OUTLINE",
            justifyH = "LEFT",
            justifyV = "MIDDLE",
            wordWrap = false,
            textColor = UI.ResolveColor(nil, "text.primary"),
        })
        self.speakEditorSpeakerText:GetFrame():SetPoint("TOPLEFT", content, "TOPLEFT", 0, 0)

        self.speakEditorTextArea = UI.ClipboardTextArea:New({
            name = "RPEClientActionBarSpeakText",
            width = SPEECH_EDITOR_WIDTH - 16,
            height = 64,
            readOnly = false,
            autoResize = false,
            fontSize = 9,
            fontFlags = "OUTLINE",
            text = "",
            textColor = UI.ResolveColor(nil, "text.primary"),
            backgroundColor = UI.ResolveColor(nil, "panel.background"),
            borderColor = UI.ResolveColor(nil, "panel.border"),
        })
        self.speakEditorTextArea:SetParent(content)
        self.speakEditorTextArea:Create()
        local textFrame = self.speakEditorTextArea:GetFrame()
        textFrame:SetPoint("TOPLEFT", self.speakEditorSpeakerText:GetFrame(), "BOTTOMLEFT", 0, -4)
        textFrame:SetPoint("TOPRIGHT", content, "TOPRIGHT", 0, -20)
        textFrame:SetHeight(64)
        self.speakEditorTextArea:SetScript("OnTextChanged", function(_, text)
            if self.speakEditorOpen and not self.speakEditorInvalid then
                self.speakEditorDraftText = tostring(text or "")
                if #self.speakEditorDraftText > SPEECH_EDITOR_TEXT_MAX_BYTES then
                    self:SetSpeakEditorStatus(("Speech is too long (maximum %d bytes)."):format(SPEECH_EDITOR_TEXT_MAX_BYTES), true)
                else
                    self:SetSpeakEditorStatus("", false)
                end
            end
        end)

        self.speakEditorStatusText = UI.CreateText(content, "RPEClientActionBarSpeakStatus", "", {
            width = SPEECH_EDITOR_WIDTH - 16,
            height = 13,
            fontSize = 8,
            fontFlags = "OUTLINE",
            justifyH = "LEFT",
            justifyV = "MIDDLE",
            wordWrap = false,
            textColor = UI.ResolveColor(nil, "text.muted"),
        })
        local statusFrame = self.speakEditorStatusText:GetFrame()
        statusFrame:SetPoint("TOPLEFT", textFrame, "BOTTOMLEFT", 0, -4)
        statusFrame:SetPoint("RIGHT", content, "RIGHT", 0, 0)

        self.speakCancelButton = UI.CreateButton(content, "RPEClientActionBarSpeakCancelButton", "Cancel", 60, function()
            self:CloseSpeakEditor()
        end)
        self.speakSendButton = UI.CreateButton(content, "RPEClientActionBarSpeakSendButton", "Send", 60, function()
            self:SendSpeakEditorText()
        end)
        self.speakCancelButton:GetFrame():SetHeight(18)
        self.speakSendButton:GetFrame():SetHeight(18)
        self.speakSendButton:GetFrame():SetPoint("BOTTOMRIGHT", content, "BOTTOMRIGHT", 0, 0)
        self.speakCancelButton:GetFrame():SetPoint("RIGHT", self.speakSendButton:GetFrame(), "LEFT", -4, 0)
        self.speakEditorPanel:Hide()
    end

    if not self.speakEditorUpdater then
        self.speakEditorUpdater = CreateFrame("Frame", "RPEClientActionBarSpeakEditorUpdater", rootFrame)
        self.speakEditorUpdater:SetScript("OnUpdate", function(_, elapsed)
            if not self.speakEditorOpen or self.speakEditorInvalid then
                self.speakEditorUpdater:Hide()
                return
            end

            self._speakEditorPollElapsed = (self._speakEditorPollElapsed or 0) + (tonumber(elapsed) or 0)
            if self._speakEditorPollElapsed < SPEECH_EDITOR_POLL_INTERVAL then
                return
            end
            self._speakEditorPollElapsed = 0

            local currentContext = self:GetSpeakControlContext()
            if not sameSpeakIdentity(currentContext, self.speakEditorEventId, self.speakEditorUnitId) then
                self:InvalidateSpeakEditor("Control or event changed. Close this editor and open Speak again.")
            end
        end)
        self.speakEditorUpdater:Hide()
    end

    return true
end

function ActionBarWidget:OpenSpeakEditor()
    if not self:EnsureSpeakEditor() then
        return false
    end

    local context, reason = self:GetSpeakControlContext()
    if not context then
        self.speakEditorOpen = true
        self.speakEditorInvalid = true
        self.speakEditorEventId = nil
        self.speakEditorUnitId = nil
        self.speakEditorDraftText = ""
        self.speakEditorSpeakerText:SetText("Speaker unavailable")
        self.speakEditorTextArea:SetText("")
        self.speakEditorTextArea:SetEnabled(false)
        self.speakSendButton:SetEnabled(false)
        if self.speakEditorUpdater then
            self.speakEditorUpdater:Hide()
        end
        self:SetSpeakEditorStatus(reason or "The controlled NPC is no longer valid.", true)
        self.speakEditorPanel:Show()
        return false
    end

    self.speakEditorEventId = context.eventId
    self.speakEditorUnitId = context.unitId
    self.speakEditorDraftText = ""
    self.speakEditorOpen = true
    self.speakEditorInvalid = false
    self.speakEditorSpeakerText:SetText(buildSpeakSpeakerLabel(context.controlledUnit))
    self.speakEditorTextArea:SetEnabled(true)
    self.speakEditorTextArea:SetText("")
    self.speakSendButton:SetEnabled(true)
    self:SetSpeakEditorStatus("", false)
    self.speakEditorPanel:Show()
    self.speakEditorUpdater:Show()
    self.speakEditorTextArea:Focus()
    return true
end

function ActionBarWidget:SendSpeakEditorText()
    if not self.speakEditorOpen or self.speakEditorInvalid then
        self:SetSpeakEditorStatus("Control changed. Close this editor and open Speak again.", true)
        return false
    end

    local context = self:GetSpeakControlContext()
    if not sameSpeakIdentity(context, self.speakEditorEventId, self.speakEditorUnitId) then
        self:InvalidateSpeakEditor("Control or event changed. This speech was not sent.")
        return false
    end

    local text = self.speakEditorTextArea and self.speakEditorTextArea:GetText() or self.speakEditorDraftText or ""
    if not tostring(text):match("%S") then
        self:SetSpeakEditorStatus("Enter some speech before sending.", true)
        return false
    end
    if #tostring(text) > SPEECH_EDITOR_TEXT_MAX_BYTES then
        self:SetSpeakEditorStatus(("Speech is too long (maximum %d bytes)."):format(SPEECH_EDITOR_TEXT_MAX_BYTES), true)
        return false
    end
    if type(Client.EmitNPCSpeech) ~= "function" then
        self:SetSpeakEditorStatus("NPC speech is unavailable right now.", true)
        return false
    end

    local callOk, emitted = pcall(function()
        return Client:EmitNPCSpeech(context.unitId, text)
    end)
    if not callOk or emitted ~= true then
        local currentContext = self:GetSpeakControlContext()
        if not sameSpeakIdentity(currentContext, self.speakEditorEventId, self.speakEditorUnitId) then
            self:InvalidateSpeakEditor("Control or event changed. This speech was not sent.")
        else
            self:SetSpeakEditorStatus("The NPC speech service rejected this message.", true)
        end
        return false
    end

    self.speakEditorDraftText = ""
    self.speakEditorTextArea:SetText("")
    self:SetSpeakEditorStatus("Speech sent.", false)
    self.speakEditorTextArea:Focus()
    return true
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

    self:EnsureSpeakEditor()
    if not self._speakEditorRootHideHooked and rootFrame.HookScript then
        rootFrame:HookScript("OnHide", function()
            self:CloseSpeakEditor()
        end)
        self._speakEditorRootHideHooked = true
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

    local controlContext = Client.GetActionBarControlContext and Client:GetActionBarControlContext() or nil
    local hasEventContext = type(controlContext) == "table" and type(controlContext.eventState) == "table"
    local eventState = hasEventContext and controlContext.eventState or nil
    local startupPending = isStartupPending(eventState)
    local movementTracker = self.BindMovementTracker and self:BindMovementTracker() or getMovementTracker()
    if not startupPending and movementTracker and type(movementTracker.RefreshMaxDistance) == "function" then
        movementTracker:RefreshMaxDistance()
    end
    local isControlled = type(controlContext) == "table" and controlContext.isControlled == true and controlContext.controlledUnit ~= nil
    local controlledUnit = isControlled and controlContext.controlledUnit or nil
    local speakContext = self:GetSpeakControlContext()
    if self.speakEditorOpen and not self.speakEditorInvalid
        and not sameSpeakIdentity(speakContext, self.speakEditorEventId, self.speakEditorUnitId)
    then
        self:InvalidateSpeakEditor("Control or event changed. Close this editor and open Speak again.")
    end
    local rootFrame = self.rootPanel:GetFrame()
    local baseWidth = rootFrame and rootFrame.GetWidth and rootFrame:GetWidth() or 0
    local contentInset = getHorizontalContentInset(self)
    local labelText = isControlled and buildControlLabel(controlledUnit) or ""
    local isLocalTurn = not startupPending and Client.IsLocalTurnActive and Client:IsLocalTurnActive(eventState) or false
    local isLocalHost = Client.IsLocalEventHost and Client:IsLocalEventHost(eventState) or false
    local showMovementBar = isMovementBarActive(controlContext)
    local movementDisplayState = (not startupPending) and showMovementBar and buildMovementDisplayState() or nil
    local showCloseButton = isControlled and labelText ~= ""
    local showSpeakButton = speakContext ~= nil and showCloseButton
    local showEndTurnButton = hasEventContext and not isLocalHost
    local showActionRowButtons = not isControlled
    local labelRightReservedWidth = 0
    local visibleControlButtonCount = 0
    local actionRowButtonSize, actionRowButtonGap = getActionRowButtonMetrics(self)
    local actionRowButtonFrames = {}
    local actionRowButtons = self.GetActionRowButtons and self:GetActionRowButtons() or {}

    self:SyncControlUpdaterState(false)

    if showCloseButton then
        labelRightReservedWidth = labelRightReservedWidth + CONTROL_BUTTON_SIZE
        visibleControlButtonCount = visibleControlButtonCount + 1
    end
    if showSpeakButton then
        if visibleControlButtonCount > 0 then
            labelRightReservedWidth = labelRightReservedWidth + CONTROL_BUTTON_GAP
        end
        labelRightReservedWidth = labelRightReservedWidth + SPEAK_BUTTON_WIDTH
        visibleControlButtonCount = visibleControlButtonCount + 1
    end
    if showEndTurnButton then
        if visibleControlButtonCount > 0 then
            labelRightReservedWidth = labelRightReservedWidth + CONTROL_BUTTON_GAP
        end
        labelRightReservedWidth = labelRightReservedWidth + END_TURN_BUTTON_WIDTH
        visibleControlButtonCount = visibleControlButtonCount + 1
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

    if self.speakButton and self.speakButton.GetFrame then
        local buttonFrame = self.speakButton:GetFrame()
        if showSpeakButton then
            buttonFrame:Show()
        else
            buttonFrame:Hide()
        end
        buttonFrame:ClearAllPoints()
        if showCloseButton and self.closeButton and self.closeButton.GetFrame then
            buttonFrame:SetPoint("TOPRIGHT", self.closeButton:GetFrame(), "TOPLEFT", -CONTROL_BUTTON_GAP, 0)
        else
            buttonFrame:SetPoint("TOPRIGHT", rootFrame, "BOTTOMRIGHT", -contentInset, -getControlRowTopGap())
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
        if showSpeakButton and self.speakButton and self.speakButton.GetFrame then
            buttonFrame:SetPoint("TOPRIGHT", self.speakButton:GetFrame(), "TOPLEFT", -CONTROL_BUTTON_GAP, 0)
        elseif showCloseButton and self.closeButton and self.closeButton.GetFrame then
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
