local addonName, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Client.UI = Addon.Client.UI or {}

local Client = Addon.Client
local ClientUI = Addon.Client.UI
local UI = Addon.UI or {}
local Profile = Addon.Internal and Addon.Internal.Profile or {}

local ActionBarWidget = ClientUI.ActionBarWidget or {}
ClientUI.ActionBarWidget = ActionBarWidget
ActionBarWidget.__index = ActionBarWidget

local SLOT_SIZE = 36
local SLOT_SPACING = 6
local ROOT_PADDING = 8
local ROOT_HEIGHT = 52
local MODE_BUTTON_SIZE = 20
local MODE_BUTTON_GAP = 6
local VERTICAL_START_RATIO = 0.2
local LOCKED_BACKGROUND_ALPHA = 0
local UNLOCKED_BACKGROUND_ALPHA = 0.42
local BACKGROUND_COLOR_R = 0.05
local BACKGROUND_COLOR_G = 0.06
local BACKGROUND_COLOR_B = 0.08
local DEFAULT_ICON = "Interface\\Icons\\INV_Misc_QuestionMark"
local NORMAL_ABILITY_BORDER = { r = 0.32, g = 0.34, b = 0.4, a = 1 }
local CONTROLLED_NPC_BORDER = { r = 0.72, g = 0.44, b = 0.2, a = 1 }
local EMPTY_SLOT_BORDER = { r = 0.24, g = 0.24, b = 0.28, a = 1 }
local SPELL_MODE_BUTTON_TEXTURE = "Interface\\Icons\\INV_Misc_Book_09"
local SKILL_MODE_BUTTON_TEXTURE = "Interface\\Icons\\Ability_Hunter_FocusedAim"
local MOUNT_BUTTON_TEXTURE = "Interface\\Icons\\Ability_Mount_RidingHorse"
local DISMOUNT_BUTTON_TEXTURE = "Interface\\Icons\\INV_Misc_Foot_Centaur"
local PET_BUTTON_TEXTURE = "Interface\\Icons\\Ability_Hunter_BeastCall"

local function buildSignature(...)
    local parts = {}
    for index = 1, select("#", ...) do
        local value = select(index, ...)
        parts[index] = tostring(value == nil and "" or value)
    end

    return table.concat(parts, "\31")
end

local function buildResourceListSignature(resources)
    local parts = {}
    for index = 1, #((resources) or {}) do
        local entry = resources[index]
        parts[#parts + 1] = buildSignature(
            entry and entry.resourceRef or "",
            tonumber(entry and entry.currentValue) or 0,
            tonumber(entry and entry.maxValue) or 0
        )
    end

    return table.concat(parts, "\30")
end

local function resolveActionBarRefreshResources(controlContext, eventState)
    local activeEventUnit = type(controlContext) == "table" and controlContext.activeEventUnit or nil
    if type(activeEventUnit) == "table"
        and activeEventUnit.isPlayer == true
        and type(Client.ResolveLocalActiveSpellcasterResources) == "function"
    then
        local resources = Client:ResolveLocalActiveSpellcasterResources(eventState, activeEventUnit)
        if type(resources) == "table" and #resources > 0 then
            return resources
        end
    end

    return activeEventUnit and activeEventUnit.resources or nil
end

local function buildSpellStateSignature(spellState)
    if type(spellState) ~= "table" then
        return ""
    end

    return buildSignature(
        tonumber(spellState.remainingTurns) or 0,
        tonumber(spellState.lockoutRemainingTurns) or 0,
        tonumber(spellState.currentCharges) or 0,
        tonumber(spellState.maxCharges) or 0,
        spellState.usesCharges == true and 1 or 0,
        tonumber(spellState.cooldownTurns) or 0
    )
end

local function buildCooldownBucketSignature(unitState)
    if type(unitState) ~= "table" then
        return ""
    end

    local spellRefs = {}
    for spellRef in pairs(unitState.spells or {}) do
        spellRefs[#spellRefs + 1] = spellRef
    end
    table.sort(spellRefs)

    local parts = {
        buildSignature(tonumber(unitState.globalCooldownRemaining) or 0),
    }
    for index = 1, #spellRefs do
        local spellRef = spellRefs[index]
        parts[#parts + 1] = buildSignature(spellRef, buildSpellStateSignature(unitState.spells[spellRef]))
    end

    return table.concat(parts, "\30")
end

local function buildTargetingSignature()
    local pending = type(Client.GetPendingSpellTargeting) == "function" and Client:GetPendingSpellTargeting() or nil
    if type(pending) ~= "table" then
        return ""
    end

    local parts = {
        tostring(pending.spellRef or ""),
    }
    local groups = type(pending.groups) == "table" and pending.groups or {}
    for index = 1, #groups do
        local group = groups[index]
        parts[#parts + 1] = buildSignature(
            tostring(group and group.key or ""),
            tonumber(group and group.focusedTargetEventId) or 0,
            table.concat(group and group.selectedTargetEventIds or {}, ",")
        )
    end

    return table.concat(parts, "\30")
end

local function buildActionBarRowsSignature(rows)
    local parts = {}
    for index = 1, #((rows) or {}) do
        local row = rows[index]
        local spell = type(row) == "table" and row.spell or nil
        parts[#parts + 1] = buildSignature(
            row and row.actionBarKind or "",
            row and row.spellRef or "",
            row and row.ref or "",
            row and row.name or "",
            row and row.icon or "",
            spell and spell.icon or "",
            spell and spell.name or "",
            tonumber(row and row.slotIndex) or 0
        )
    end

    return table.concat(parts, "\30")
end

local function buildActionBarRefreshSignature(widget, rows, controlContext, slotCount)
    local eventState = type(controlContext) == "table" and controlContext.eventState or (Client.GetEventState and Client:GetEventState() or nil)
    local activeEventUnit = type(controlContext) == "table" and controlContext.activeEventUnit or nil
    local eventId = tostring(eventState and eventState.id or "")
    local casterEventId = tonumber(activeEventUnit and activeEventUnit.eventID) or 0
    local spellcastEntry = eventId ~= "" and casterEventId > 0 and type(Client.GetSpellcastEntry) == "function"
        and Client:GetSpellcastEntry(eventId, casterEventId)
        or nil
    local cooldownBucket = eventId ~= ""
        and casterEventId > 0
        and type(Client.CooldownsByEventId) == "table"
        and type(Client.CooldownsByEventId[eventId]) == "table"
        and Client.CooldownsByEventId[eventId][casterEventId]
        or nil
    local resourceSignatureResources = resolveActionBarRefreshResources(controlContext, eventState)

    return buildSignature(
        slotCount,
        Profile.GetActionBarMode and Profile.GetActionBarMode() or "spells",
        Profile.ShouldUseMountedActionBar and Profile.ShouldUseMountedActionBar() and 1 or 0,
        widget.IsUnlocked and widget:IsUnlocked() and 1 or 0,
        type(controlContext) == "table" and controlContext.isControlled == true and 1 or 0,
        tonumber(type(controlContext) == "table" and controlContext.controlledUnit and controlContext.controlledUnit.eventID) or 0,
        eventId,
        tonumber(eventState and eventState.turnNumber) or 0,
        tonumber(eventState and eventState.tickNumber) or 0,
        tonumber(eventState and eventState.totalTicks) or 0,
        Client.TurnEndPending == true and 1 or 0,
        casterEventId,
        buildResourceListSignature(resourceSignatureResources),
        buildCooldownBucketSignature(cooldownBucket),
        buildSignature(
            spellcastEntry and spellcastEntry.spellRef or "",
            tonumber(spellcastEntry and spellcastEntry.turnsElapsed) or 0,
            tonumber(spellcastEntry and spellcastEntry.turnsTotal) or 0,
            tonumber(spellcastEntry and spellcastEntry.focusedTargetEventId) or 0
        ),
        buildTargetingSignature(),
        buildActionBarRowsSignature(rows)
    )
end

local function buildActionBarStructureSignature(widget, rows, controlContext, slotCount)
    return buildSignature(
        slotCount,
        Profile.GetActionBarMode and Profile.GetActionBarMode() or "spells",
        Profile.ShouldUseMountedActionBar and Profile.ShouldUseMountedActionBar() and 1 or 0,
        widget.IsUnlocked and widget:IsUnlocked() and 1 or 0,
        type(controlContext) == "table" and controlContext.isControlled == true and 1 or 0,
        tonumber(type(controlContext) == "table" and controlContext.controlledUnit and controlContext.controlledUnit.eventID) or 0,
        buildActionBarRowsSignature(rows)
    )
end

local function GetSpellTooltipBuilder()
    local tooltipNamespace = Addon.Client and Addon.Client.UI and Addon.Client.UI.Tooltips or nil
    local spellTooltip = tooltipNamespace and tooltipNamespace.Spell or nil
    if type(spellTooltip) == "table" and type(spellTooltip.Build) == "function" then
        return spellTooltip
    end

    return nil
end

local function GetSkillTooltipBuilder()
    local tooltipNamespace = Addon.Client and Addon.Client.UI and Addon.Client.UI.Tooltips or nil
    local skillTooltip = tooltipNamespace and tooltipNamespace.Skill or nil
    if type(skillTooltip) == "table" and type(skillTooltip.Build) == "function" then
        return skillTooltip
    end

    return nil
end

local function SetSlotTooltipProvider(slot, provider)
    if type(slot) ~= "table" then
        return nil
    end

    slot.tooltip = provider
    if slot.SetOption then
        slot:SetOption("tooltip", provider)
    end

    return provider
end

local function GetVerticalStartOffset()
    local parentHeight = UIParent and UIParent:GetHeight() or 0
    if parentHeight <= 0 then
        return -216
    end

    return -math.floor(parentHeight * VERTICAL_START_RATIO)
end

local function GetDefaultAnchor()
    return {
        point = "TOP",
        relativePoint = "CENTER",
        x = 0,
        y = GetVerticalStartOffset(),
    }
end

function ActionBarWidget:GetContentInset()
    return ROOT_PADDING
end

function ActionBarWidget:GetContentWidth(totalWidth)
    local inset = self.GetContentInset and self:GetContentInset() or ROOT_PADDING
    return math.max(0, (tonumber(totalWidth) or 0) - (inset * 2))
end

local function resolveRuntimeSpellDetail(detail)
    if type(detail) ~= "table" then
        return nil
    end

    local resolved = {}
    for key, value in pairs(detail) do
        resolved[key] = value
    end

    local eventState = type(Client.GetEventState) == "function" and Client:GetEventState() or nil
    local waitingForEventUnits = type(eventState) == "table"
        and eventState.active == true
        and eventState.unitsReady ~= true

    local activationState = type(Client.ResolveSpellActivationRuntimeState) == "function"
        and Client:ResolveSpellActivationRuntimeState(resolved.spellRef)
        or (type(Client.ResolveSpellActivationState) == "function" and Client:ResolveSpellActivationState(resolved.spellRef, {
            includeText = false,
            includeTargetCandidates = false,
        }) or nil)
    if type(activationState) ~= "table" then
        resolved.canCast = waitingForEventUnits
        resolved.cooldownOverlayText = resolved.cooldownOverlayText or ""
        resolved.pendingActivationState = waitingForEventUnits
        return resolved
    end

    resolved.canCast = activationState.canCast == true
    resolved.casterUnit = activationState.casterUnit
    resolved.cooldownRemaining = activationState.cooldownRemaining
    resolved.rechargeRemaining = activationState.rechargeRemaining
    resolved.lockoutRemaining = activationState.lockoutRemaining
    resolved.globalCooldownRemaining = activationState.globalCooldownRemaining
    resolved.currentCharges = activationState.currentCharges
    resolved.maxCharges = activationState.maxCharges
    resolved.cooldownText = activationState.cooldownText or resolved.cooldownText or "No Cooldown"
    resolved.cooldownOverlayText = ""
    local cooldownRemaining = math.max(0, math.floor(tonumber(activationState.cooldownRemaining) or 0))
    if cooldownRemaining > 0 then
        resolved.cooldownOverlayText = tostring(cooldownRemaining)
    end
    if resolved.canCast then
        resolved.statusText = detail.statusText
    else
        local failureText = type(activationState.failureText) == "string" and activationState.failureText or ""
        if failureText == "" then
            local reason = tostring(activationState.reason or "")
            if reason == "cooldown" or reason == "global-cooldown" or reason == "no-charges" then
                failureText = "Unavailable"
            elseif reason == "insufficient-resources" then
                failureText = "Insufficient Resources"
            elseif reason == "no-targets" then
                failureText = "No Valid Targets"
            elseif reason == "not-your-turn" then
                failureText = "Not Your Turn"
            else
                failureText = detail.statusText or "Unavailable"
            end
        end
        resolved.statusText = failureText
    end

    return resolved
end

local function resolveRuntimeSpellDetailWithActivationState(detail, activationState)
    if type(detail) ~= "table" then
        return nil
    end

    local resolved = {}
    for key, value in pairs(detail) do
        resolved[key] = value
    end

    local eventState = type(Client.GetEventState) == "function" and Client:GetEventState() or nil
    local waitingForEventUnits = type(eventState) == "table"
        and eventState.active == true
        and eventState.unitsReady ~= true

    if type(activationState) ~= "table" then
        resolved.canCast = waitingForEventUnits
        resolved.cooldownOverlayText = resolved.cooldownOverlayText or ""
        resolved.pendingActivationState = waitingForEventUnits
        resolved.activationState = nil
        return resolved
    end

    resolved.canCast = activationState.canCast == true
    resolved.casterUnit = activationState.casterUnit
    resolved.cooldownRemaining = activationState.cooldownRemaining
    resolved.rechargeRemaining = activationState.rechargeRemaining
    resolved.lockoutRemaining = activationState.lockoutRemaining
    resolved.globalCooldownRemaining = activationState.globalCooldownRemaining
    resolved.currentCharges = activationState.currentCharges
    resolved.maxCharges = activationState.maxCharges
    resolved.cooldownText = activationState.cooldownText or resolved.cooldownText or "No Cooldown"
    resolved.cooldownOverlayText = ""
    resolved.activationState = activationState
    local cooldownRemaining = math.max(0, math.floor(tonumber(activationState.cooldownRemaining) or 0))
    if cooldownRemaining > 0 then
        resolved.cooldownOverlayText = tostring(cooldownRemaining)
    end
    if resolved.canCast then
        resolved.statusText = detail.statusText
    else
        local failureText = type(activationState.failureText) == "string" and activationState.failureText or ""
        if failureText == "" then
            local reason = tostring(activationState.reason or "")
            if reason == "cooldown" or reason == "global-cooldown" or reason == "no-charges" then
                failureText = "Unavailable"
            elseif reason == "insufficient-resources" then
                failureText = "Insufficient Resources"
            elseif reason == "no-targets" then
                failureText = "No Valid Targets"
            elseif reason == "not-your-turn" then
                failureText = "Not Your Turn"
            else
                failureText = detail.statusText or "Unavailable"
            end
        end
        resolved.statusText = failureText
    end

    return resolved
end

local function isSkillActionBarDetail(detail)
    return type(detail) == "table" and tostring(detail.actionBarKind or "") == "skill"
end

local function resolveActionBarDetail(detail)
    if isSkillActionBarDetail(detail) then
        return detail
    end

    return resolveRuntimeSpellDetail(detail)
end

local function buildActionBarActivationStateMap(rows)
    local activationStatesBySpellRef = {}
    for index = 1, #((rows) or {}) do
        local row = rows[index]
        local spellRef = type(row) == "table" and tostring(row.spellRef or "") or ""
        if spellRef ~= "" and activationStatesBySpellRef[spellRef] == nil then
            activationStatesBySpellRef[spellRef] = type(Client.ResolveSpellActivationRuntimeState) == "function"
                and Client:ResolveSpellActivationRuntimeState(spellRef)
                or (type(Client.ResolveSpellActivationState) == "function"
                    and Client:ResolveSpellActivationState(spellRef, {
                        includeText = false,
                        includeTargetCandidates = false,
                    })
                    or false)
        end
    end

    return activationStatesBySpellRef
end

local function resolveActionBarDetailWithActivationState(detail, activationStatesBySpellRef)
    if isSkillActionBarDetail(detail) then
        return detail
    end

    local spellRef = type(detail) == "table" and tostring(detail.spellRef or "") or ""
    if spellRef == "" then
        return resolveRuntimeSpellDetailWithActivationState(detail, nil)
    end

    local activationState = type(activationStatesBySpellRef) == "table" and activationStatesBySpellRef[spellRef] or nil
    if activationState == false then
        activationState = nil
    end
    return resolveRuntimeSpellDetailWithActivationState(detail, activationState)
end

local function applyActionBarSlotDetail(self, slot, slotHost, index, detail, npcControlActive, contentInset)
    local frame = slot:GetFrame()
    frame:ClearAllPoints()
    frame:SetPoint("LEFT", slotHost, "LEFT", contentInset + ((index - 1) * (SLOT_SIZE + SLOT_SPACING)), 0)

    if detail then
        if detail.pendingActivationState == true then
            local previousDetail = slot.tooltipDetail
            if type(previousDetail) == "table"
                and tostring(previousDetail.spellRef or previousDetail.ref or "") == tostring(detail.spellRef or detail.ref or "")
            then
                local mergedDetail = {}
                for key, value in pairs(previousDetail) do
                    mergedDetail[key] = value
                end
                for key, value in pairs(detail) do
                    mergedDetail[key] = value
                end
                mergedDetail.cooldownOverlayText = detail.cooldownOverlayText ~= nil and detail.cooldownOverlayText or previousDetail.cooldownOverlayText
                mergedDetail.pendingActivationState = true
                detail = mergedDetail
            end
        end

        local icon = isSkillActionBarDetail(detail)
            and tostring(detail.icon or "")
            or (detail.spell and tostring(detail.spell.icon or "") or "")
        if icon == "" then
            icon = DEFAULT_ICON
        end

        local isPendingActivationState = detail.pendingActivationState == true and not isSkillActionBarDetail(detail)
        slot:SetIcon(icon)
        slot:SetEnabled(true)
        slot.enabled = isSkillActionBarDetail(detail) or (isPendingActivationState ~= true and detail.canCast == true)
        if slot.RefreshVisualState then
            slot:RefreshVisualState()
        end
        slot:SetCount(index)
        slot:SetOverlayText(isSkillActionBarDetail(detail) and "" or (detail.cooldownOverlayText or ""))
        slot.tooltipDetail = detail
        if npcControlActive then
            slot:SetBorderColor(CONTROLLED_NPC_BORDER.r, CONTROLLED_NPC_BORDER.g, CONTROLLED_NPC_BORDER.b, CONTROLLED_NPC_BORDER.a)
        elseif isSkillActionBarDetail(detail) then
            slot:SetBorderColor(0.3, 0.56, 0.92, 1)
        else
            slot:SetBorderColor(NORMAL_ABILITY_BORDER.r, NORMAL_ABILITY_BORDER.g, NORMAL_ABILITY_BORDER.b, NORMAL_ABILITY_BORDER.a)
        end
        slot.boundSpellRef = isSkillActionBarDetail(detail) and nil or detail.spellRef
        slot.boundSkillRef = isSkillActionBarDetail(detail) and detail.ref or nil
        slot.boundActionBarKind = detail.actionBarKind
    else
        slot:SetIcon(DEFAULT_ICON)
        slot:SetEnabled(false)
        slot:SetCount(index)
        slot:SetOverlayText("")
        slot.tooltipDetail = nil
        slot:SetBorderColor(EMPTY_SLOT_BORDER.r, EMPTY_SLOT_BORDER.g, EMPTY_SLOT_BORDER.b, EMPTY_SLOT_BORDER.a)
        slot.boundSpellRef = nil
        slot.boundSkillRef = nil
        slot.boundActionBarKind = nil
    end

    frame:Show()
    return true
end

local function RefreshVisibleProfileWindow()
    local profileWindow = Addon.Client and Addon.Client.UI and Addon.Client.UI.Profile and Addon.Client.UI.Profile.Window or nil
    if not (profileWindow and profileWindow.Get) then
        return false
    end

    local instance = profileWindow:Get()
    local window = instance and instance.window or nil
    local frame = window and window.GetFrame and window:GetFrame() or nil
    if not (frame and frame.IsShown and frame:IsShown() == true) then
        return false
    end

    if instance and instance.Refresh then
        instance:Refresh()
        return true
    end

    return false
end

local function getMountButtonTooltipText()
    local selectedMount = Profile.GetSelectedMount and Profile.GetSelectedMount() or nil
    local isMounted = Profile.IsMounted and Profile.IsMounted() or false
    if isMounted then
        return selectedMount and ("Dismount %s"):format(tostring(selectedMount.name or "mount")) or "Dismount"
    end

    local canMount, reason = false, nil
    if Profile.CanMount then
        canMount, reason = Profile.CanMount()
    end
    if type(canMount) == "boolean" and canMount then
        return selectedMount and ("Mount %s"):format(tostring(selectedMount.name or "mount")) or "Mount"
    end

    if reason == "combat-blocked" then
        return "Mounting is blocked during local combat."
    end
    if reason == "no-mount" then
        return "Select a mount first."
    end

    return "Mount unavailable."
end

local function applyImageButtonTexture(button, texture)
    if type(button) ~= "table" then
        return false
    end

    if button.SetNormalTexture then
        button:SetNormalTexture(texture)
    end
    if button.SetHighlightTexture then
        button:SetHighlightTexture(texture)
    end
    if button.SetPushedTexture then
        button:SetPushedTexture(texture)
    end
    if button.SetDisabledTexture then
        button:SetDisabledTexture(texture)
    end
    return true
end

local function getActionBarModeState(widget)
    local controlActive = widget and widget.IsActionBarControlActive and widget:IsActionBarControlActive() or false
    local mountedActionBarActive = Profile.ShouldUseMountedActionBar and Profile.ShouldUseMountedActionBar() or false
    local mode = Profile.GetActionBarMode and Profile.GetActionBarMode() or "spells"
    return controlActive, mountedActionBarActive, mode
end

local function setActionBarMode(widget, mode)
    if type(widget) ~= "table" then
        return false
    end

    local controlActive, mountedActionBarActive, currentMode = getActionBarModeState(widget)
    if controlActive or mountedActionBarActive or currentMode == mode or not Profile.SetActionBarMode then
        return currentMode == mode
    end

    Profile.SetActionBarMode(mode)
    local appliedMode = Profile.GetActionBarMode and Profile.GetActionBarMode() or mode
    if appliedMode == mode and Client.RefreshActionBarWidget then
        Client:RefreshActionBarWidget(("action-bar-mode-%s"):format(tostring(mode)))
    end
    if appliedMode == mode then
        RefreshVisibleProfileWindow()
    end
    return appliedMode == mode
end

local function getSpellModeButtonTooltipText(widget)
    local _, mountedActionBarActive, mode = getActionBarModeState(widget)
    if mountedActionBarActive then
        return "Mounted action bar active."
    end
    if mode == "spells" then
        return "Showing spell actions."
    end

    return "Show spell actions."
end

local function getSkillModeButtonTooltipText(widget)
    local _, mountedActionBarActive, mode = getActionBarModeState(widget)
    if mountedActionBarActive then
        return "Mounted action bar active."
    end
    if mode == "skills" then
        return "Showing skill actions."
    end

    return "Show skill actions."
end

local function getPetButtonTooltipText(widget, petUnit)
    if widget and widget.IsActionBarControlActive and widget:IsActionBarControlActive() then
        return "Release control to switch to a pet."
    end
    if type(petUnit) == "table" then
        return ("Control pet %s"):format(tostring(petUnit.name or "pet"))
    end
    if Profile.IsPetSelectionValid and Profile.IsPetSelectionValid() ~= true then
        return "Select an active pet first."
    end

    return "No controllable pet found."
end

function ActionBarWidget:Get()
    if self.Instance then
        return self.Instance
    end

    self.Instance = setmetatable({
        rootPanel = nil,
        slots = {},
        lastRefreshReason = nil,
    }, ActionBarWidget)

    return self.Instance
end

function ActionBarWidget:IsUnlocked()
    return Profile.AreWidgetsUnlocked and Profile.AreWidgetsUnlocked() == true or false
end

function ActionBarWidget:GetAnchor()
    local anchor = Profile.GetActionBarAnchor and Profile.GetActionBarAnchor() or nil
    if anchor and anchor.point and anchor.relativePoint then
        return {
            point = tostring(anchor.point),
            relativePoint = tostring(anchor.relativePoint),
            x = tonumber(anchor.x) or 0,
            y = tonumber(anchor.y) or 0,
        }
    end

    return GetDefaultAnchor()
end

function ActionBarWidget:ApplyAnchor()
    if not self.rootPanel then
        return false
    end

    local frame = self.rootPanel:GetFrame()
    local anchor = self:GetAnchor()
    frame:ClearAllPoints()
    frame:SetPoint(anchor.point, UIParent, anchor.relativePoint, anchor.x, anchor.y)
    return true
end

function ActionBarWidget:PersistAnchor()
    if not self.rootPanel or not Profile.SetActionBarAnchor then
        return nil
    end

    local point, _, relativePoint, x, y = self.rootPanel:GetFrame():GetPoint(1)
    if not point or not relativePoint then
        return nil
    end

    return Profile.SetActionBarAnchor({
        point = point,
        relativePoint = relativePoint,
        x = tonumber(x) or 0,
        y = tonumber(y) or 0,
    })
end

function ActionBarWidget:BeginMove()
    if not self:IsUnlocked() or not self.rootPanel then
        return
    end

    local frame = self.rootPanel:GetFrame()
    frame:StartMoving()
end

function ActionBarWidget:EndMove()
    if not self.rootPanel then
        return
    end

    local frame = self.rootPanel:GetFrame()
    frame:StopMovingOrSizing()

    if self:IsUnlocked() then
        self:PersistAnchor()
        self:ApplyAnchor()
    end
end

function ActionBarWidget:UpdateMovableState()
    if not self.rootPanel then
        return false
    end

    local frame = self.rootPanel:GetFrame()
    local unlocked = self:IsUnlocked()
    frame:EnableMouse(unlocked)

    local background = self.rootPanel.panelBackgroundTexture
    if background and background.SetColorTexture then
        background:SetColorTexture(
            BACKGROUND_COLOR_R,
            BACKGROUND_COLOR_G,
            BACKGROUND_COLOR_B,
            unlocked and UNLOCKED_BACKGROUND_ALPHA or LOCKED_BACKGROUND_ALPHA
        )
    end

    return true
end

function ActionBarWidget:Build()
    if self.rootPanel then
        self:ApplyAnchor()
        self:UpdateMovableState()
        return self.rootPanel
    end

    self.rootPanel = UI.CreatePanel(UIParent, "RPEClientActionBarWidgetRoot", {
        width = 240,
        height = ROOT_HEIGHT,
        contentInset = 0,
        showBorder = false,
        panelBackgroundColor = { r = 0, g = 0, b = 0, a = 0 },
        frameStrata = "MEDIUM",
        frameLevel = 55,
        hidden = true,
    })

    if self.EnsureControlChrome then
        self:EnsureControlChrome()
    end

    local rootFrame = self.rootPanel:GetFrame()
    rootFrame:SetMovable(true)
    rootFrame:SetClampedToScreen(true)
    rootFrame:RegisterForDrag("LeftButton")
    rootFrame:SetScript("OnDragStart", function()
        self:BeginMove()
    end)
    rootFrame:SetScript("OnDragStop", function()
        self:EndMove()
    end)

    self:ApplyAnchor()
    self:UpdateMovableState()
    return self.rootPanel
end

function ActionBarWidget:Show()
    self:Build()
    self.rootPanel:Show()
    if self.RefreshActionBarCompanionBars then
        self:RefreshActionBarCompanionBars("action-bar-show")
    end
    if self.RefreshControlState then
        self:RefreshControlState("action-bar-show")
    end
    return true
end

function ActionBarWidget:Hide()
    if self.rootPanel then
        self.rootPanel:Hide()
    end
    if self.HideActionBarCompanionBars then
        self:HideActionBarCompanionBars()
    end
    return true
end

function ActionBarWidget:GetUtilityButtonMetrics()
    return MODE_BUTTON_SIZE, MODE_BUTTON_GAP
end

function ActionBarWidget:EnsureSpellModeButton()
    self:Build()
    if self.spellModeButton then
        return self.spellModeButton
    end

    self.spellModeButton = UI.ImageButton:New({
        name = "RPEClientActionBarSpellModeButton",
        width = MODE_BUTTON_SIZE,
        height = MODE_BUTTON_SIZE,
        border = false,
        normalTexture = SPELL_MODE_BUTTON_TEXTURE,
        highlightTexture = SPELL_MODE_BUTTON_TEXTURE,
        pushedTexture = SPELL_MODE_BUTTON_TEXTURE,
        disabledTexture = SPELL_MODE_BUTTON_TEXTURE,
        tooltip = getSpellModeButtonTooltipText(self),
    })
    self.spellModeButton:SetParent(self.rootPanel:GetFrame())
    self.spellModeButton:Create()
    self.spellModeButton:SetScript("OnClick", function(_, button)
        if button ~= "LeftButton" then
            return
        end

        setActionBarMode(self, "spells")
    end)
    return self.spellModeButton
end

function ActionBarWidget:RefreshSpellModeButton()
    local spellModeButton = self:EnsureSpellModeButton()
    local frame = spellModeButton and spellModeButton.GetFrame and spellModeButton:GetFrame() or nil
    if not frame then
        return false
    end

    local controlActive, mountedActionBarActive, mode = getActionBarModeState(self)
    applyImageButtonTexture(spellModeButton, SPELL_MODE_BUTTON_TEXTURE)
    if spellModeButton.SetTooltip then
        spellModeButton:SetTooltip(getSpellModeButtonTooltipText(self))
    end
    if spellModeButton.SetEnabled then
        spellModeButton:SetEnabled(not controlActive and not mountedActionBarActive and mode ~= "spells")
    end
    return true
end

function ActionBarWidget:EnsureSkillModeButton()
    self:Build()
    if self.skillModeButton then
        return self.skillModeButton
    end

    self.skillModeButton = UI.ImageButton:New({
        name = "RPEClientActionBarSkillModeButton",
        width = MODE_BUTTON_SIZE,
        height = MODE_BUTTON_SIZE,
        border = false,
        normalTexture = SKILL_MODE_BUTTON_TEXTURE,
        highlightTexture = SKILL_MODE_BUTTON_TEXTURE,
        pushedTexture = SKILL_MODE_BUTTON_TEXTURE,
        disabledTexture = SKILL_MODE_BUTTON_TEXTURE,
        tooltip = getSkillModeButtonTooltipText(self),
    })
    self.skillModeButton:SetParent(self.rootPanel:GetFrame())
    self.skillModeButton:Create()
    self.skillModeButton:SetScript("OnClick", function(_, button)
        if button ~= "LeftButton" then
            return
        end

        setActionBarMode(self, "skills")
    end)
    return self.skillModeButton
end

function ActionBarWidget:RefreshSkillModeButton()
    local skillModeButton = self:EnsureSkillModeButton()
    local frame = skillModeButton and skillModeButton.GetFrame and skillModeButton:GetFrame() or nil
    if not frame then
        return false
    end

    local controlActive, mountedActionBarActive, mode = getActionBarModeState(self)
    applyImageButtonTexture(skillModeButton, SKILL_MODE_BUTTON_TEXTURE)
    if skillModeButton.SetTooltip then
        skillModeButton:SetTooltip(getSkillModeButtonTooltipText(self))
    end
    if skillModeButton.SetEnabled then
        skillModeButton:SetEnabled(not controlActive and not mountedActionBarActive and mode ~= "skills")
    end
    return true
end

function ActionBarWidget:EnsureMountButton()
    self:Build()
    if self.mountButton then
        return self.mountButton
    end

    self.mountButton = UI.ImageButton:New({
        name = "RPEClientActionBarMountButton",
        width = MODE_BUTTON_SIZE,
        height = MODE_BUTTON_SIZE,
        border = false,
        normalTexture = MOUNT_BUTTON_TEXTURE,
        highlightTexture = MOUNT_BUTTON_TEXTURE,
        pushedTexture = MOUNT_BUTTON_TEXTURE,
        disabledTexture = MOUNT_BUTTON_TEXTURE,
        tooltip = getMountButtonTooltipText(),
    })
    self.mountButton:SetParent(self.rootPanel:GetFrame())
    self.mountButton:Create()
    self.mountButton:SetScript("OnClick", function(_, button)
        if button ~= "LeftButton" or not Profile.ToggleMounted then
            return
        end

        local changed = Profile.ToggleMounted()
        if not changed then
            if Client.RefreshActionBarWidget then
                Client:RefreshActionBarWidget("action-bar-mount-blocked")
            end
            RefreshVisibleProfileWindow()
            return
        end

        if Client.RefreshActionBarWidget then
            Client:RefreshActionBarWidget("action-bar-mount-toggle")
        end
        RefreshVisibleProfileWindow()
    end)
    return self.mountButton
end

function ActionBarWidget:RefreshMountButton()
    local mountButton = self:EnsureMountButton()
    local frame = mountButton and mountButton.GetFrame and mountButton:GetFrame() or nil
    if not frame then
        return false
    end

    local selectedMount = Profile.GetSelectedMount and Profile.GetSelectedMount() or nil
    local isMounted = Profile.IsMounted and Profile.IsMounted() or false
    local mountTexture = nil
    if isMounted then
        mountTexture = DISMOUNT_BUTTON_TEXTURE
    else
        mountTexture = selectedMount and tostring(selectedMount.icon or "") or ""
        if mountTexture == "" then
            mountTexture = MOUNT_BUTTON_TEXTURE
        end
    end

    applyImageButtonTexture(mountButton, mountTexture)
    if mountButton.SetTooltip then
        mountButton:SetTooltip(getMountButtonTooltipText())
    end
    if mountButton.SetEnabled then
        mountButton:SetEnabled((Profile.IsMounted and Profile.IsMounted()) or (Profile.IsMountSelectionValid and Profile.IsMountSelectionValid()))
    end
    return true
end

function ActionBarWidget:EnsurePetButton()
    self:Build()
    if self.petButton then
        return self.petButton
    end

    self.petButton = UI.ImageButton:New({
        name = "RPEClientActionBarPetButton",
        width = MODE_BUTTON_SIZE,
        height = MODE_BUTTON_SIZE,
        border = false,
        normalTexture = PET_BUTTON_TEXTURE,
        highlightTexture = PET_BUTTON_TEXTURE,
        pushedTexture = PET_BUTTON_TEXTURE,
        disabledTexture = PET_BUTTON_TEXTURE,
        tooltip = getPetButtonTooltipText(self, nil),
    })
    self.petButton:SetParent(self.rootPanel:GetFrame())
    self.petButton:Create()
    self.petButton:SetScript("OnClick", function(_, button)
        if button ~= "LeftButton" or not Client.TakeControlOfEventUnit then
            return
        end

        local petUnit = self.ResolveControllablePetUnit and self:ResolveControllablePetUnit() or nil
        if not petUnit or not Client:TakeControlOfEventUnit(petUnit) then
            if Client.RefreshActionBarWidget then
                Client:RefreshActionBarWidget("action-bar-pet-unavailable")
            end
        end
    end)
    return self.petButton
end

function ActionBarWidget:RefreshPetButton()
    local petButton = self:EnsurePetButton()
    local frame = petButton and petButton.GetFrame and petButton:GetFrame() or nil
    if not frame then
        return false
    end

    local controlActive = self.IsActionBarControlActive and self:IsActionBarControlActive() or false
    local petUnit = self.ResolveControllablePetUnit and self:ResolveControllablePetUnit() or nil
    applyImageButtonTexture(petButton, PET_BUTTON_TEXTURE)
    if petButton.SetTooltip then
        petButton:SetTooltip(getPetButtonTooltipText(self, petUnit))
    end
    if petButton.SetEnabled then
        petButton:SetEnabled(not controlActive and petUnit ~= nil)
    end
    return true
end

function ActionBarWidget:GetActionRowButtons()
    return {
        self:EnsureSpellModeButton(),
        self:EnsureSkillModeButton(),
        self:EnsureMountButton(),
        self:EnsurePetButton(),
    }
end

function ActionBarWidget:RefreshActionRowButtons()
    self:RefreshSpellModeButton()
    self:RefreshSkillModeButton()
    self:RefreshMountButton()
    self:RefreshPetButton()
    return true
end

function ActionBarWidget:EnsureSlot(index)
    self:Build()
    local slot = self.slots[index]
    if slot then
        return slot
    end

    slot = UI.ObjectSlot:New({
        name = ("RPEClientActionBarSlot%d"):format(index),
        width = SLOT_SIZE,
        height = SLOT_SIZE,
        size = SLOT_SIZE,
        iconTexture = DEFAULT_ICON,
        border = false,
    })
    local slotHost = self.rootPanel.GetContentFrame and self.rootPanel:GetContentFrame() or self.rootPanel:GetFrame()
    slot:SetParent(slotHost)
    slot:Create()

    local frame = slot:GetFrame()
    local contentInset = self.GetContentInset and self:GetContentInset() or ROOT_PADDING
    frame:SetPoint("LEFT", slotHost, "LEFT", contentInset + ((index - 1) * (SLOT_SIZE + SLOT_SPACING)), 0)
    frame:EnableMouse(true)
    if frame.SetMotionScriptsWhileDisabled then
        frame:SetMotionScriptsWhileDisabled(true)
    end
    slot:SetScript("OnEnter", function()
        slot.isHovered = true
        if slot.RefreshVisualState then
            slot:RefreshVisualState()
        end
        if slot.ShowTooltip then
            slot:ShowTooltip()
        end
    end)
    slot:SetScript("OnLeave", function()
        slot.isHovered = false
        slot.isPressed = false
        if slot.RefreshVisualState then
            slot:RefreshVisualState()
        end
        if slot.HideTooltip then
            slot:HideTooltip()
        end
    end)
    slot:SetScript("OnMouseDown", function()
        if slot.enabled ~= false then
            slot.isPressed = true
            if slot.RefreshVisualState then
                slot:RefreshVisualState()
            end
        end
    end)
    slot:SetScript("OnMouseUp", function()
        if slot.isPressed then
            slot.isPressed = false
            if slot.RefreshVisualState then
                slot:RefreshVisualState()
            end
        end
    end)
    frame:HookScript("OnMouseUp", function(_, button)
        if button == "LeftButton"
            and slot.boundSpellRef
            and slot.enabled ~= false
            and not self:IsUnlocked()
            and Client.ActivateActionBarSpell
        then
            Client:ActivateActionBarSpell(slot.boundSpellRef)
            return
        end

        if button ~= "RightButton" or (self.IsActionBarControlActive and self:IsActionBarControlActive()) then
            return
        end

        local unbound = false
        if slot.boundSpellRef then
            if slot.boundActionBarKind == "mounted-spell" then
                return
            elseif Profile.UnbindSpellFromActionBar then
                unbound = Profile.UnbindSpellFromActionBar(slot.boundSpellRef) == true
            end
        elseif slot.boundSkillRef and Profile.UnbindSkillFromActionBar then
            unbound = Profile.UnbindSkillFromActionBar(slot.boundSkillRef) == true
        end

        if unbound then
            if Client.RefreshActionBarWidget then
                Client:RefreshActionBarWidget("action-bar-unbind")
            end
            RefreshVisibleProfileWindow()
        end
    end)
    frame:HookScript("OnHide", function()
        if slot.HideTooltip then
            slot:HideTooltip()
        end
    end)
    SetSlotTooltipProvider(slot, function(owner)
        local detail = slot.tooltipDetail
        if type(detail) ~= "table" then
            return nil
        end

        if isSkillActionBarDetail(detail) then
            local skillTooltip = GetSkillTooltipBuilder()
            return skillTooltip and skillTooltip:Build(detail, owner) or nil
        end

        local spellTooltip = GetSpellTooltipBuilder()
        return spellTooltip and spellTooltip:Build(detail, owner) or nil
    end)

    self.slots[index] = slot
    return slot
end

function ActionBarWidget:Refresh(reason)
    self.lastRefreshReason = reason
    self:Build()
    self:Show()

    local size = Profile.GetActionBarSize and Profile.GetActionBarSize() or 5
    local controlContext = Client.GetActionBarControlContext and Client:GetActionBarControlContext() or nil
    local npcControlActive = type(controlContext) == "table"
        and controlContext.isControlled == true
        and type(controlContext.controlledUnit) == "table"
    local rows = self.GetActionBarRows and self:GetActionBarRows() or (Profile.ListActionBarSlots and Profile.ListActionBarSlots() or {})
    local rootFrame = self.rootPanel:GetFrame()
    local slotHost = self.rootPanel.GetContentFrame and self.rootPanel:GetContentFrame() or rootFrame
    local slotCount = math.max(0, math.floor(tonumber(size) or 0))
    local contentInset = self.GetContentInset and self:GetContentInset() or ROOT_PADDING
    local refreshSignature = buildActionBarRefreshSignature(self, rows, controlContext, slotCount)
    local structureSignature = buildActionBarStructureSignature(self, rows, controlContext, slotCount)
    self:RefreshActionRowButtons()
    local baseWidth = (slotCount * SLOT_SIZE) + (math.max(0, slotCount - 1) * SLOT_SPACING) + (contentInset * 2)
    rootFrame:SetSize(baseWidth, ROOT_HEIGHT)

    self:ApplyAnchor()
    self:UpdateMovableState()

    if self.lastRefreshSignature == refreshSignature then
        if self.RefreshControlState then
            self:RefreshControlState(reason or "action-bar-refresh")
        end
        return true
    end

    local activationStatesBySpellRef = buildActionBarActivationStateMap(rows)

    for index = 1, size do
        local slot = self:EnsureSlot(index)
        local detail = resolveActionBarDetailWithActivationState(rows[index], activationStatesBySpellRef)
        applyActionBarSlotDetail(self, slot, slotHost, index, detail, npcControlActive, contentInset)
    end

    for index = size + 1, #(self.slots or {}) do
        local slot = self.slots[index]
        local frame = slot and slot.GetFrame and slot:GetFrame() or nil
        if frame then
            frame:Hide()
        end
    end

    if self.RefreshControlState then
        self:RefreshControlState(reason or "action-bar-refresh")
    end

    self.lastStructureSignature = structureSignature
    self.lastRefreshSignature = refreshSignature
    return true
end

function ActionBarWidget:BuildIncrementalRefreshPlan(reason)
    self:Build()
    self:Show()

    local size = Profile.GetActionBarSize and Profile.GetActionBarSize() or 5
    local controlContext = Client.GetActionBarControlContext and Client:GetActionBarControlContext() or nil
    local npcControlActive = type(controlContext) == "table"
        and controlContext.isControlled == true
        and type(controlContext.controlledUnit) == "table"
    local rows = self.GetActionBarRows and self:GetActionBarRows() or (Profile.ListActionBarSlots and Profile.ListActionBarSlots() or {})
    local rootFrame = self.rootPanel:GetFrame()
    local slotHost = self.rootPanel.GetContentFrame and self.rootPanel:GetContentFrame() or rootFrame
    local slotCount = math.max(0, math.floor(tonumber(size) or 0))
    local contentInset = self.GetContentInset and self:GetContentInset() or ROOT_PADDING
    local refreshSignature = buildActionBarRefreshSignature(self, rows, controlContext, slotCount)
    local structureSignature = buildActionBarStructureSignature(self, rows, controlContext, slotCount)
    local activationStatesBySpellRef = buildActionBarActivationStateMap(rows)
    self:RefreshActionRowButtons()
    local baseWidth = (slotCount * SLOT_SIZE) + (math.max(0, slotCount - 1) * SLOT_SPACING) + (contentInset * 2)
    rootFrame:SetSize(baseWidth, ROOT_HEIGHT)
    self:ApplyAnchor()
    self:UpdateMovableState()

    local plan = {
        reason = reason,
        rows = rows,
        controlContext = controlContext,
        npcControlActive = npcControlActive,
        rootFrame = rootFrame,
        slotHost = slotHost,
        slotCount = slotCount,
        contentInset = contentInset,
        refreshSignature = refreshSignature,
        structureSignature = structureSignature,
        actionBarRevision = type(Client.DirtyUiRefreshState) == "table"
            and math.max(0, math.floor(tonumber(Client.DirtyUiRefreshState.actionBarRevision) or 0))
            or 0,
        activationStatesBySpellRef = activationStatesBySpellRef,
        nextSlotIndex = 1,
        fullRefresh = false,
    }
    self.PendingIncrementalRefreshPlan = plan
    return plan
end

function ActionBarWidget:PrepareIncrementalRefresh(reason, dirtyState)
    local plan = self:BuildIncrementalRefreshPlan(reason)
    local structureChanged = self.lastStructureSignature ~= plan.structureSignature
        or (type(dirtyState) == "table" and dirtyState.actionBarStructuralDirty == true)
    if structureChanged then
        for index = 1, plan.slotCount do
            local slot = self:EnsureSlot(index)
            local frame = slot:GetFrame()
            frame:ClearAllPoints()
            frame:SetPoint("LEFT", plan.slotHost, "LEFT", plan.contentInset + ((index - 1) * (SLOT_SIZE + SLOT_SPACING)), 0)
            frame:Show()
        end
        for index = plan.slotCount + 1, #(self.slots or {}) do
            local slot = self.slots[index]
            local frame = slot and slot.GetFrame and slot:GetFrame() or nil
            if frame then
                frame:Hide()
            end
        end
        self.lastStructureSignature = plan.structureSignature
    end

    if self.RefreshControlState then
        self:RefreshControlState(reason or "action-bar-refresh")
    end

    plan.fullRefresh = structureChanged
        or type(dirtyState) ~= "table"
        or dirtyState.actionBarAllSlotsDirty == true
        or self.lastRefreshSignature ~= plan.refreshSignature

    return plan, structureChanged
end

function ActionBarWidget:DrainIncrementalRefresh(reason, dirtyState, maxSlots)
    local plan = self.PendingIncrementalRefreshPlan
    local currentRevision = type(dirtyState) == "table"
        and math.max(0, math.floor(tonumber(dirtyState.actionBarRevision) or 0))
        or 0
    if type(plan) ~= "table"
        or plan.reason ~= reason
        or math.max(0, math.floor(tonumber(plan.actionBarRevision) or 0)) ~= currentRevision
    then
        plan = self:PrepareIncrementalRefresh(reason, dirtyState)
    end

    local slotBudget = math.max(1, math.floor(tonumber(maxSlots) or 2))
    local dirtySlots = type(dirtyState) == "table" and dirtyState.actionBarSlots or {}
    local refreshAll = plan.fullRefresh == true

    local processed = 0
    local ran = false
    if refreshAll == true then
        for index = math.max(1, tonumber(plan.nextSlotIndex) or 1), plan.slotCount do
            local slot = self:EnsureSlot(index)
            local detail = resolveActionBarDetailWithActivationState(plan.rows[index], plan.activationStatesBySpellRef)
            applyActionBarSlotDetail(self, slot, plan.slotHost, index, detail, plan.npcControlActive, plan.contentInset)
            processed = processed + 1
            ran = true
            plan.nextSlotIndex = index + 1
            if processed >= slotBudget then
                break
            end
        end
    else
        for index = 1, plan.slotCount do
            if dirtySlots[index] == true then
                local slot = self:EnsureSlot(index)
                local detail = resolveActionBarDetailWithActivationState(plan.rows[index], plan.activationStatesBySpellRef)
                applyActionBarSlotDetail(self, slot, plan.slotHost, index, detail, plan.npcControlActive, plan.contentInset)
                dirtySlots[index] = nil
                processed = processed + 1
                ran = true
                if processed >= slotBudget then
                    break
                end
            end
        end
    end

    if refreshAll == true then
        if type(dirtyState) == "table" then
            dirtyState.actionBarAllSlotsDirty = false
            dirtyState.actionBarStructuralDirty = false
        end
    end

    local morePending = refreshAll == true
        and math.max(1, tonumber(plan.nextSlotIndex) or 1) <= plan.slotCount
        or next(dirtySlots) ~= nil

    if morePending ~= true then
        self.lastRefreshSignature = plan.refreshSignature
        self.PendingIncrementalRefreshPlan = nil
    end

    return ran, morePending
end

function Client:BuildActionBarWidget()
    return ActionBarWidget:Get():Build()
end

function Client:ShowActionBarWidget()
    return ActionBarWidget:Get():Show()
end

function Client:HideActionBarWidget()
    return ActionBarWidget:Get():Hide()
end

function Client:RefreshActionBarWidget(reason)
    return ActionBarWidget:Get():Refresh(reason)
end

function Client:DrainActionBarRefreshWork(reason)
    local dirtyState = self.DirtyUiRefreshState
    return ActionBarWidget:Get():DrainIncrementalRefresh(reason, dirtyState, 2)
end

local initializer = CreateFrame and CreateFrame("Frame")
if initializer then
    initializer:RegisterEvent("ADDON_LOADED")
    initializer:SetScript("OnEvent", function(_, event, loadedAddonName)
        if event ~= "ADDON_LOADED" or loadedAddonName ~= addonName then
            return
        end

        if Client.BuildActionBarWidget then
            Client:BuildActionBarWidget()
        end
        if Client.ShowActionBarWidget then
            Client:ShowActionBarWidget()
        end
        if Client.RefreshActionBarWidget then
            Client:RefreshActionBarWidget("addon-loaded")
        end
    end)
end

return ActionBarWidget
