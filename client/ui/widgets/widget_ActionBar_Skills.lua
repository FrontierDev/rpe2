local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Client.UI = Addon.Client.UI or {}

local Client = Addon.Client
local ActionBarWidget = Client.UI.ActionBarWidget
local Help = Addon.Client and Addon.Client.Help or {}

if type(ActionBarWidget) ~= "table"
    or type(ActionBarWidget.EnsureSlot) ~= "function"
    or ActionBarWidget._skillRollActivationExtensionInstalled == true
then
    return true
end

local FIRST_PLAYER_TURN_HELP_ID = "event.first-player-turn"
local FIRST_PLAYER_TURN_HELP_TEXT = "It is your turn. Use your RPE Action Bar to cast spells or perform actions, then click End Turn when you are finished."

local baseEnsureSlot = ActionBarWidget.EnsureSlot
local baseRefreshControlState = ActionBarWidget.RefreshControlState

local function getFrame(element)
    if type(element) == "table" and type(element.GetFrame) == "function" then
        return element:GetFrame()
    end

    return element
end

local function isButtonActionable(button)
    local frame = getFrame(button)
    if not frame or type(frame.IsShown) ~= "function" or frame:IsShown() ~= true then
        return false
    end

    if type(frame.IsEnabled) == "function" then
        return frame:IsEnabled() == true
    end

    return button and button.enabled ~= false
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
