local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Client.UI = Addon.Client.UI or {}

local Client = Addon.Client
local ActionBarWidget = Client.UI.ActionBarWidget
local EventWidget = Client.UI.EventWidget
local Help = Addon.Client and Addon.Client.Help or {}

if type(ActionBarWidget) ~= "table"
    or type(ActionBarWidget.EnsureSlot) ~= "function"
    or ActionBarWidget._skillRollActivationExtensionInstalled == true
then
    return true
end

local FIRST_EVENT_HELP_ID = "event.first-start"
local FIRST_EVENT_HELP_TEXT = "This is the RPE event display. It shows the event, participating units, turn state and recent event messages."
local FIRST_PLAYER_TURN_HELP_ID = "event.first-player-turn"
local FIRST_PLAYER_TURN_HELP_TEXT = "It is your turn. Use your RPE Action Bar to cast spells or perform actions, then click End Turn when you are finished."

local baseEnsureSlot = ActionBarWidget.EnsureSlot
local baseRefreshControlState = ActionBarWidget.RefreshControlState
local baseEventRefresh = type(EventWidget) == "table" and EventWidget.Refresh or nil
local baseEventHide = type(EventWidget) == "table" and EventWidget.Hide or nil

local function getFrame(element)
    if type(element) == "table" and type(element.GetFrame) == "function" then
        return element:GetFrame()
    end

    return element
end

local function isFrameShown(frame)
    return frame ~= nil and type(frame.IsShown) == "function" and frame:IsShown() == true
end

local function isButtonActionable(button)
    local frame = getFrame(button)
    if not isFrameShown(frame) then
        return false
    end

    if type(frame.IsEnabled) == "function" then
        return frame:IsEnabled() == true
    end

    return button and button.enabled ~= false
end

local function hideActiveEventHelp()
    local activeTipId = Help.ActiveTipId
    if (activeTipId == FIRST_EVENT_HELP_ID or activeTipId == FIRST_PLAYER_TURN_HELP_ID)
        and type(Help.Hide) == "function"
    then
        return Help:Hide(activeTipId)
    end

    return false
end

if type(EventWidget) == "table" then
    function EventWidget:RegisterFirstEventHelp()
        if type(Help.Register) ~= "function" then
            return false
        end

        return Help:Register(FIRST_EVENT_HELP_ID, {
            text = FIRST_EVENT_HELP_TEXT,
        })
    end

    function EventWidget:ShowFirstEventHelp(state)
        if type(state) ~= "table"
            or state.active ~= true
            or state.unitsReady ~= true
            or state.startupReady ~= true
        then
            return false
        end

        local eventId = tostring(state.id or "")
        if eventId == "" then
            return false
        end

        self:RegisterFirstEventHelp()

        if type(Help.IsAcknowledged) == "function" and Help:IsAcknowledged(FIRST_EVENT_HELP_ID) then
            return false
        end

        if Help.ActiveTipId == FIRST_EVENT_HELP_ID then
            self._firstEventHelpPresentedEventId = eventId
            return true
        end

        if self._firstEventHelpPresentedEventId == eventId then
            return true
        end

        local anchor = self.headerBannerPanel and getFrame(self.headerBannerPanel) or getFrame(self.rootPanel)
        if not isFrameShown(anchor) or type(Help.Show) ~= "function" then
            return false
        end

        local shown = Help:Show(FIRST_EVENT_HELP_ID, anchor)
        if shown == true then
            self._firstEventHelpPresentedEventId = eventId
        end
        return shown == true
    end

    if type(baseEventRefresh) == "function" then
        function EventWidget:Refresh(...)
            local result = baseEventRefresh(self, ...)
            local state = type(Client.GetEventState) == "function" and Client:GetEventState() or Client.EventState
            if result ~= false and type(state) == "table" and state.active == true and state.startupReady == true then
                self:ShowFirstEventHelp(state)
            end
            return result
        end
    end

    if type(baseEventHide) == "function" then
        function EventWidget:Hide(...)
            self._firstEventHelpPresentedEventId = nil
            hideActiveEventHelp()
            return baseEventHide(self, ...)
        end
    end
end

function ActionBarWidget:RegisterFirstPlayerTurnHelp()
    if type(Help.Register) ~= "function" then
        return false
    end

    return Help:Register(FIRST_PLAYER_TURN_HELP_ID, {
        text = FIRST_PLAYER_TURN_HELP_TEXT,
    })
end

function ActionBarWidget:HideFirstPlayerTurnHelp()
    if Help.ActiveTipId ~= FIRST_PLAYER_TURN_HELP_ID or type(Help.Hide) ~= "function" then
        return false
    end

    return Help:Hide(FIRST_PLAYER_TURN_HELP_ID)
end

function ActionBarWidget:UpdateFirstPlayerTurnHelp()
    local actionable = isButtonActionable(self.endTurnButton)
    if actionable ~= true then
        self._firstPlayerTurnHelpPresentedForActionableState = false
        self:HideFirstPlayerTurnHelp()
        return false
    end

    self:RegisterFirstPlayerTurnHelp()

    if type(Help.IsAcknowledged) == "function" and Help:IsAcknowledged(FIRST_PLAYER_TURN_HELP_ID) then
        self._firstPlayerTurnHelpPresentedForActionableState = true
        return false
    end

    if Help.ActiveTipId == FIRST_PLAYER_TURN_HELP_ID then
        self._firstPlayerTurnHelpPresentedForActionableState = true
        return true
    end

    if self._firstPlayerTurnHelpPresentedForActionableState == true then
        return true
    end

    local frame = getFrame(self.endTurnButton)
    if not frame or type(Help.Show) ~= "function" then
        return false
    end

    local shown = Help:Show(FIRST_PLAYER_TURN_HELP_ID, frame)
    if shown == true then
        self._firstPlayerTurnHelpPresentedForActionableState = true
    end
    return shown == true
end

function ActionBarWidget:EnsureSlot(index)
    local slot = baseEnsureSlot(self, index)
    if type(slot) ~= "table" or slot._skillRollActivationHookInstalled == true then
        return slot
    end

    local frame = type(slot.GetFrame) == "function" and slot:GetFrame() or nil
    if frame and type(frame.HookScript) == "function" then
        frame:HookScript("OnMouseUp", function(_, button)
            if button ~= "LeftButton"
                or not slot.boundSkillRef
                or slot.enabled == false
                or (type(self.IsUnlocked) == "function" and self:IsUnlocked())
                or type(Client.ActivateActionBarSkill) ~= "function"
            then
                return
            end

            Client:ActivateActionBarSkill(slot.boundSkillRef)
        end)
        slot._skillRollActivationHookInstalled = true
    end

    return slot
end

if type(baseRefreshControlState) == "function" then
    function ActionBarWidget:RefreshControlState(...)
        local result = baseRefreshControlState(self, ...)
        self:UpdateFirstPlayerTurnHelp()
        return result
    end
end

ActionBarWidget._skillRollActivationExtensionInstalled = true
return true
