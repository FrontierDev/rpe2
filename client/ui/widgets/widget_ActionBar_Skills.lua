local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Client.UI = Addon.Client.UI or {}

local Client = Addon.Client
local ClientUI = Addon.Client.UI
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
local FIRST_PORTRAIT_HELP_ID = "event.first-portrait"
local FIRST_PORTRAIT_HELP_TEXT = "Event portraits show the units taking part in the event. Their health, resources and turn state update here as the event progresses."
local FIRST_PLAYER_TURN_HELP_ID = "event.first-player-turn"
local FIRST_PLAYER_TURN_HELP_TEXT = "It is your turn. Use your RPE Action Bar to cast spells or perform actions, then click End Turn when you are finished."

local ACTION_BAR_BIND_HELP_ID = "actionbar.bind-spells"
local ACTION_BAR_AUTO_ATTACK_HELP_ID = "actionbar.auto-attacks"
local ACTION_BAR_SCROLLABLE_BINDS_HELP_ID = "actionbar.scrollable-binds"
local ACTION_BAR_SWITCH_HELP_ID = "actionbar.switch-bars"
local ACTION_BAR_MOVEMENT_HELP_ID = "actionbar.movement"
local ACTION_BAR_HELP_SEQUENCE = {
    ACTION_BAR_BIND_HELP_ID,
    ACTION_BAR_AUTO_ATTACK_HELP_ID,
    ACTION_BAR_SCROLLABLE_BINDS_HELP_ID,
    ACTION_BAR_SWITCH_HELP_ID,
}
local ACTION_BAR_HELP_IDS = {
    [ACTION_BAR_BIND_HELP_ID] = true,
    [ACTION_BAR_AUTO_ATTACK_HELP_ID] = true,
    [ACTION_BAR_SCROLLABLE_BINDS_HELP_ID] = true,
    [ACTION_BAR_SWITCH_HELP_ID] = true,
    [ACTION_BAR_MOVEMENT_HELP_ID] = true,
}
local ACTION_BAR_HELP_TEXT = {
    [ACTION_BAR_BIND_HELP_ID] = "Bind spells to your RPE Action Bar from the Spellbook in your Profile window.",
    [ACTION_BAR_AUTO_ATTACK_HELP_ID] = "These slots contain your auto attacks. Right-click an auto attack to toggle auto-cast on or off. They stay visible while you browse your other bound spells.",
    [ACTION_BAR_SCROLLABLE_BINDS_HELP_ID] = "These slots contain your bound spells. Use the mouse wheel over this section or the arrows to scroll through more bindings.",
    [ACTION_BAR_SWITCH_HELP_ID] = "Use these buttons to switch between Spells and Skills, and to use mounted or pet action bars when those are available.",
    [ACTION_BAR_MOVEMENT_HELP_ID] = "This bar shows how much RPE movement you have remaining. It updates as you move during an event.",
}

local LAUNCHER_SETUP_HELP_ID = "launcher.setup"
local LAUNCHER_SETUP_HELP_TEXT = "Set up your RPE character here. The Setup Wizard guides you through your character options, equipment and Action Bar."
local LAUNCHER_EXISTING_HELP_IDS = {
    "launcher.profile",
    "launcher.event",
    "launcher.content",
}

local PROFILE_EQUIPMENT_HELP_ID = "profile.equipment"
local PROFILE_EQUIPMENT_HELP_TEXT = "Equip RPE items here. Your resolved health, resources and combat stats are shown alongside your equipment."
local PROFILE_IDENTITY_HELP_SEQUENCE = {
    {
        id = "profile.identity.race",
        anchorKey = "race",
        text = "Your RPE race is selected here. Available races and their effects come from the active RPE data and rules.",
    },
    {
        id = "profile.identity.class",
        anchorKey = "class",
        text = "Your RPE class is selected here. Available classes and their effects come from the active RPE data and rules.",
    },
    {
        id = "profile.identity.level",
        anchorKey = "level",
        text = "Set your RPE character level here. Level is used by rules, conditions and effects that depend on character level.",
    },
    {
        id = "profile.identity.primary-resource",
        anchorKey = "primary-resource",
        text = "Choose the resource shown as your primary Action Bar resource here.",
    },
    {
        id = "profile.identity.special-resource",
        anchorKey = "special-resource",
        text = "Choose an additional special resource to track here when your character uses one.",
    },
}
local PROFILE_IDENTITY_HELP_IDS = {}
for index = 1, #PROFILE_IDENTITY_HELP_SEQUENCE do
    PROFILE_IDENTITY_HELP_IDS[PROFILE_IDENTITY_HELP_SEQUENCE[index].id] = true
end

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

local function getEventState()
    if type(Client.GetEventState) == "function" then
        return Client:GetEventState()
    end
    return Client.EventState
end

local function hideActiveEventHelp()
    local activeTipId = Help.ActiveTipId
    if (activeTipId == FIRST_EVENT_HELP_ID
            or activeTipId == FIRST_PORTRAIT_HELP_ID
            or activeTipId == FIRST_PLAYER_TURN_HELP_ID)
        and type(Help.Hide) == "function"
    then
        return Help:Hide(activeTipId)
    end

    return false
end

if type(EventWidget) == "table" then
    function EventWidget:GetFirstVisiblePortraitHelpAnchor()
        local portraitGroups = {
            self.portraitSlots,
            self.bossPortraitSlots,
        }
        for groupIndex = 1, #portraitGroups do
            local slots = portraitGroups[groupIndex]
            for index = 1, #(slots or {}) do
                local slot = slots[index]
                local frame = getFrame(slot)
                if slot and slot.portraitUnit ~= nil and isFrameShown(frame) then
                    return frame
                end
            end
        end
        return nil
    end

    function EventWidget:RegisterFirstPortraitHelp()
        if type(Help.Register) ~= "function" then
            return false
        end

        return Help:Register(FIRST_PORTRAIT_HELP_ID, {
            text = FIRST_PORTRAIT_HELP_TEXT,
        })
    end

    function EventWidget:ShowFirstPortraitHelp(state)
        if type(state) ~= "table"
            or state.active ~= true
            or state.unitsReady ~= true
            or state.startupReady ~= true
            or type(Help.IsAcknowledged) ~= "function"
            or Help:IsAcknowledged(FIRST_EVENT_HELP_ID) ~= true
        then
            return false
        end

        self:RegisterFirstPortraitHelp()
        if Help:IsAcknowledged(FIRST_PORTRAIT_HELP_ID) then
            return false
        end

        if Help.ActiveTipId == FIRST_PORTRAIT_HELP_ID then
            return true
        end
        if Help.ActiveTipId ~= nil then
            return false
        end

        local anchor = self:GetFirstVisiblePortraitHelpAnchor()
        if not isFrameShown(anchor) or type(Help.Show) ~= "function" then
            return false
        end

        return Help:Show(FIRST_PORTRAIT_HELP_ID, anchor) == true
    end

    function EventWidget:RegisterFirstEventHelp()
        if type(Help.Register) ~= "function" then
            return false
        end

        Help:Register(FIRST_PORTRAIT_HELP_ID, {
            text = FIRST_PORTRAIT_HELP_TEXT,
        })
        return Help:Register(FIRST_EVENT_HELP_ID, {
            text = FIRST_EVENT_HELP_TEXT,
            onAcknowledgeCallback = function()
                self:ShowFirstPortraitHelp(getEventState())
            end,
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
            local state = getEventState()
            if result ~= false and type(state) == "table" and state.active == true and state.startupReady == true then
                self:ShowFirstEventHelp(state)
                self:ShowFirstPortraitHelp(state)
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

    if type(Help.IsAcknowledged) == "function" and Help:IsAcknowledged(FIRST_EVENT_HELP_ID) ~= true then
        return false
    end

    if Help.ActiveTipId == FIRST_PLAYER_TURN_HELP_ID then
        self._firstPlayerTurnHelpPresentedForActionableState = true
        return true
    end

    if Help.ActiveTipId ~= nil then
        return false
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

local function isActionBarHelpId(id)
    return ACTION_BAR_HELP_IDS[tostring(id or "")] == true
end

function ActionBarWidget:RegisterIssue250ActionBarHelp()
    if type(Help.Register) ~= "function" then
        return false
    end

    for index = 1, #ACTION_BAR_HELP_SEQUENCE do
        local id = ACTION_BAR_HELP_SEQUENCE[index]
        Help:Register(id, {
            text = ACTION_BAR_HELP_TEXT[id],
            onAcknowledgeCallback = function()
                self:UpdateIssue250ActionBarHelp()
            end,
        })
    end
    Help:Register(ACTION_BAR_MOVEMENT_HELP_ID, {
        text = ACTION_BAR_HELP_TEXT[ACTION_BAR_MOVEMENT_HELP_ID],
    })
    return true
end

function ActionBarWidget:GetIssue250ActionBarHelpAnchor(id)
    if id == ACTION_BAR_BIND_HELP_ID then
        local firstSlot = type(self.slots) == "table" and self.slots[1] or nil
        local firstSlotFrame = getFrame(firstSlot)
        if isFrameShown(firstSlotFrame) then
            return firstSlotFrame
        end
        return getFrame(self.rootPanel)
    end

    if id == ACTION_BAR_AUTO_ATTACK_HELP_ID then
        if self.complexActionBarActive ~= true or (tonumber(self.autoHitSpellCount) or 0) < 1 then
            return nil
        end

        local firstAutoAttackSlot = type(self.slots) == "table" and self.slots[1] or nil
        local frame = getFrame(firstAutoAttackSlot)
        return isFrameShown(frame) and frame or nil
    end

    if id == ACTION_BAR_SCROLLABLE_BINDS_HELP_ID then
        local autoHitSpellCount = math.max(0, math.floor(tonumber(self.autoHitSpellCount) or 0))
        if self.complexActionBarActive ~= true
            or math.max(0, math.floor(tonumber(self.currentActionBarSlotCount) or 0)) <= autoHitSpellCount
        then
            return nil
        end

        local firstBindableSlot = type(self.slots) == "table" and self.slots[autoHitSpellCount + 1] or nil
        local frame = getFrame(firstBindableSlot)
        return isFrameShown(frame) and frame or nil
    end

    if id == ACTION_BAR_SWITCH_HELP_ID then
        local modeButtons = {
            self.spellModeButton,
            self.skillModeButton,
            self.mountButton,
            self.petButton,
        }
        for index = 1, #modeButtons do
            local frame = getFrame(modeButtons[index])
            if isFrameShown(frame) then
                return frame
            end
        end
        return nil
    end

    if id == ACTION_BAR_MOVEMENT_HELP_ID then
        local movementFrame = getFrame(self.movementRangeBar)
        return isFrameShown(movementFrame) and movementFrame or nil
    end

    return nil
end

function ActionBarWidget:HideIssue250ActionBarHelp()
    if not isActionBarHelpId(Help.ActiveTipId) or type(Help.Hide) ~= "function" then
        return false
    end
    return Help:Hide(Help.ActiveTipId)
end

function ActionBarWidget:UpdateIssue250ActionBarHelp()
    local rootFrame = getFrame(self.rootPanel)
    if not isFrameShown(rootFrame) then
        self:HideIssue250ActionBarHelp()
        return false
    end

    if type(self.IsActionBarControlActive) == "function" and self:IsActionBarControlActive() then
        self:HideIssue250ActionBarHelp()
        return false
    end

    self:RegisterIssue250ActionBarHelp()

    local activeTipId = Help.ActiveTipId
    if isActionBarHelpId(activeTipId) then
        local activeAnchor = self:GetIssue250ActionBarHelpAnchor(activeTipId)
        if isFrameShown(activeAnchor) then
            return true
        end
        self:HideIssue250ActionBarHelp()
        activeTipId = nil
    elseif activeTipId ~= nil then
        return false
    end

    if type(Help.IsAcknowledged) ~= "function" or type(Help.Show) ~= "function" then
        return false
    end

    for index = 1, #ACTION_BAR_HELP_SEQUENCE do
        local id = ACTION_BAR_HELP_SEQUENCE[index]
        if not Help:IsAcknowledged(id) then
            local anchor = self:GetIssue250ActionBarHelpAnchor(id)
            if isFrameShown(anchor) then
                return Help:Show(id, anchor) == true
            end
        end
    end

    if not Help:IsAcknowledged(ACTION_BAR_MOVEMENT_HELP_ID) then
        local movementAnchor = self:GetIssue250ActionBarHelpAnchor(ACTION_BAR_MOVEMENT_HELP_ID)
        if isFrameShown(movementAnchor) then
            return Help:Show(ACTION_BAR_MOVEMENT_HELP_ID, movementAnchor) == true
        end
    end

    return false
end

local issue250BaseRefreshControlState = ActionBarWidget.RefreshControlState
if type(issue250BaseRefreshControlState) == "function" then
    function ActionBarWidget:RefreshControlState(...)
        local result = issue250BaseRefreshControlState(self, ...)
        self:UpdateIssue250ActionBarHelp()
        return result
    end
end

local issue250BaseActionBarHide = ActionBarWidget.Hide
if type(issue250BaseActionBarHide) == "function" then
    function ActionBarWidget:Hide(...)
        self:HideIssue250ActionBarHelp()
        return issue250BaseActionBarHide(self, ...)
    end
end

local function installLauncherIssue250Help()
    local LauncherMenu = ClientUI and ClientUI.LauncherMenu or nil
    if type(LauncherMenu) ~= "table"
        or LauncherMenu._issue250HelpInstalled == true
        or type(LauncherMenu.ShowNextHelpTip) ~= "function"
    then
        return false
    end

    local baseRegisterHelpTips = LauncherMenu.RegisterHelpTips
    local baseShowNextHelpTip = LauncherMenu.ShowNextHelpTip
    local baseHideHelpTip = LauncherMenu.HideHelpTip
    local baseBuildWindow = LauncherMenu.BuildWindow

    function LauncherMenu:RegisterHelpTips()
        local result = type(baseRegisterHelpTips) == "function" and baseRegisterHelpTips(self) or true
        if type(Help.Register) == "function" then
            Help:Register(LAUNCHER_SETUP_HELP_ID, {
                text = LAUNCHER_SETUP_HELP_TEXT,
            })
        end
        return result ~= false
    end

    function LauncherMenu:ShowNextHelpTip()
        if type(baseShowNextHelpTip) == "function" and baseShowNextHelpTip(self) == true then
            return true
        end

        if not self:IsVisible()
            or type(Help.IsAcknowledged) ~= "function"
            or type(Help.Show) ~= "function"
        then
            return false
        end

        for index = 1, #LAUNCHER_EXISTING_HELP_IDS do
            if not Help:IsAcknowledged(LAUNCHER_EXISTING_HELP_IDS[index]) then
                return false
            end
        end

        if Help:IsAcknowledged(LAUNCHER_SETUP_HELP_ID) then
            return false
        end
        if Help.ActiveTipId == LAUNCHER_SETUP_HELP_ID then
            return true
        end
        if Help.ActiveTipId ~= nil then
            return false
        end

        self:RegisterHelpTips()
        local anchor = type(self.buttons) == "table" and self.buttons.Setup or nil
        return anchor ~= nil and Help:Show(LAUNCHER_SETUP_HELP_ID, anchor) == true or false
    end

    function LauncherMenu:HideHelpTip()
        if Help.ActiveTipId == LAUNCHER_SETUP_HELP_ID and type(Help.Hide) == "function" then
            return Help:Hide(LAUNCHER_SETUP_HELP_ID)
        end
        return type(baseHideHelpTip) == "function" and baseHideHelpTip(self) or false
    end

    function LauncherMenu:BuildWindow(...)
        local window = type(baseBuildWindow) == "function" and baseBuildWindow(self, ...) or self.window
        local setupButton = type(self.buttons) == "table" and self.buttons.Setup or nil
        local setupFrame = getFrame(setupButton)
        if setupFrame and setupFrame._issue250HelpHookInstalled ~= true and type(setupFrame.HookScript) == "function" then
            setupFrame:HookScript("OnClick", function()
                if type(Help.Acknowledge) == "function" then
                    Help:Acknowledge(LAUNCHER_SETUP_HELP_ID)
                end
            end)
            setupFrame._issue250HelpHookInstalled = true
        end
        return window
    end

    LauncherMenu._issue250HelpInstalled = true
    return true
end

local function installProfileIssue250Help()
    local ProfileUI = ClientUI and ClientUI.Profile or nil
    local ProfileWindow = ProfileUI and ProfileUI.Window or nil
    local EquipmentStatsPage = ProfileUI and ProfileUI.EquipmentStatsPage or nil
    if type(ProfileWindow) ~= "table"
        or type(EquipmentStatsPage) ~= "table"
        or ProfileWindow._issue250HelpInstalled == true
        or type(ProfileWindow.ShowHelpForTab) ~= "function"
    then
        return false
    end

    local identityAnchorFields = {
        race = "RaceDropdown",
        class = "ClassDropdown",
        level = "LevelInput",
        ["primary-resource"] = "PrimaryResourceDropdown",
        ["special-resource"] = "SpecialResourceDropdown",
    }

    function EquipmentStatsPage:GetIssue250HelpAnchor(key)
        local fieldName = identityAnchorFields[tostring(key or "")]
        local frame = fieldName and getFrame(self[fieldName]) or nil
        return isFrameShown(frame) and frame or nil
    end

    local baseRegisterHelpTips = ProfileWindow.RegisterHelpTips
    local baseHideHelpTip = ProfileWindow.HideHelpTip
    local baseShowHelpForTab = ProfileWindow.ShowHelpForTab

    function ProfileWindow:RegisterHelpTips()
        local result = type(baseRegisterHelpTips) == "function" and baseRegisterHelpTips(self) or true
        if type(Help.Register) ~= "function" then
            return result ~= false
        end

        Help:Register(PROFILE_EQUIPMENT_HELP_ID, {
            text = PROFILE_EQUIPMENT_HELP_TEXT,
            onAcknowledgeCallback = function()
                if self:IsVisible() and self:GetActiveTabKey() == "equipment" then
                    self:ShowHelpForTab("equipment")
                end
            end,
        })
        for index = 1, #PROFILE_IDENTITY_HELP_SEQUENCE do
            local definition = PROFILE_IDENTITY_HELP_SEQUENCE[index]
            Help:Register(definition.id, {
                text = definition.text,
                onAcknowledgeCallback = function()
                    if self:IsVisible() and self:GetActiveTabKey() == "equipment" then
                        self:ShowHelpForTab("equipment")
                    end
                end,
            })
        end
        return result ~= false
    end

    function ProfileWindow:HideHelpTip()
        if PROFILE_IDENTITY_HELP_IDS[Help.ActiveTipId] == true and type(Help.Hide) == "function" then
            return Help:Hide(Help.ActiveTipId)
        end
        return type(baseHideHelpTip) == "function" and baseHideHelpTip(self) or false
    end

    function ProfileWindow:ShowHelpForTab(tabKey)
        local normalizedKey = tostring(tabKey or self:GetActiveTabKey())
        if normalizedKey ~= "equipment" then
            if PROFILE_IDENTITY_HELP_IDS[Help.ActiveTipId] == true then
                self:HideHelpTip()
            end
            return type(baseShowHelpForTab) == "function" and baseShowHelpForTab(self, normalizedKey) or false
        end

        if not self:IsVisible() or type(Help.Show) ~= "function" or type(Help.IsAcknowledged) ~= "function" then
            return false
        end

        self:RegisterHelpTips()

        local activeTipId = Help.ActiveTipId
        if activeTipId == PROFILE_EQUIPMENT_HELP_ID or PROFILE_IDENTITY_HELP_IDS[activeTipId] == true then
            return true
        end
        if type(activeTipId) == "string" and string.sub(activeTipId, 1, 8) == "profile." then
            self:HideHelpTip()
        elseif activeTipId ~= nil then
            return false
        end

        if not Help:IsAcknowledged(PROFILE_EQUIPMENT_HELP_ID) then
            local pageAnchor = self:GetHelpAnchor("equipment")
            return pageAnchor ~= nil and Help:Show(PROFILE_EQUIPMENT_HELP_ID, pageAnchor) == true or false
        end

        for index = 1, #PROFILE_IDENTITY_HELP_SEQUENCE do
            local definition = PROFILE_IDENTITY_HELP_SEQUENCE[index]
            if not Help:IsAcknowledged(definition.id) then
                local anchor = self.equipmentStatsPage
                    and self.equipmentStatsPage.GetIssue250HelpAnchor
                    and self.equipmentStatsPage:GetIssue250HelpAnchor(definition.anchorKey)
                    or nil
                if isFrameShown(anchor) then
                    return Help:Show(definition.id, anchor) == true
                end
            end
        end

        return false
    end

    ProfileWindow._issue250HelpInstalled = true
    return true
end

local function installLateIssue250Help()
    installLauncherIssue250Help()
    installProfileIssue250Help()
end

if type(C_Timer) == "table" and type(C_Timer.After) == "function" then
    C_Timer.After(0, installLateIssue250Help)
elseif type(CreateFrame) == "function" then
    local installer = CreateFrame("Frame")
    installer:RegisterEvent("PLAYER_LOGIN")
    installer:SetScript("OnEvent", function(frame)
        frame:UnregisterAllEvents()
        installLateIssue250Help()
    end)
end

ActionBarWidget._skillRollActivationExtensionInstalled = true
return true
