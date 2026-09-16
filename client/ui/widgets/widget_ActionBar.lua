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
local COMPLEX_AUTO_SPELL_GAP = 24
local COMPLEX_SCROLL_ARROW_WIDTH = 16
local COMPLEX_SCROLL_ARROW_GAP = 3
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

local function isStartupPending(eventState)
    return type(eventState) == "table"
        and eventState.active == true
        and (eventState.ending == true
            or eventState.unitsReady ~= true
            or eventState.startupReady ~= true
            or (type(Client.EventTransition) == "table"
                and Client.EventTransition.eventState == eventState))
end

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

local function buildActionBarSlotIndexSignature(slotIndexes, slotCount)
    local parts = {}
    for index = 1, math.max(0, math.floor(tonumber(slotCount) or 0)) do
        parts[#parts + 1] = tostring((slotIndexes or {})[index] or "")
    end

    return table.concat(parts, ",")
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
        Profile.GetActionBarLayoutMode and Profile.GetActionBarLayoutMode() or "complex",
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
        buildActionBarRowsSignature(rows),
        buildActionBarSlotIndexSignature(widget.visibleActionBarSlotIndexes, slotCount)
    )
end

local function buildActionBarStructureSignature(widget, rows, controlContext, slotCount)
    return buildSignature(
        slotCount,
        Profile.GetActionBarMode and Profile.GetActionBarMode() or "spells",
        Profile.GetActionBarLayoutMode and Profile.GetActionBarLayoutMode() or "complex",
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
    local waitingForEventStartup = isStartupPending(eventState)
    local transitionStatus = eventState and eventState.ending == true and "Event ending" or "Event starting"

    local activationState = type(Client.ResolveSpellActivationRuntimeState) == "function"
        and Client:ResolveSpellActivationRuntimeState(resolved.spellRef)
        or (type(Client.ResolveSpellActivationState) == "function" and Client:ResolveSpellActivationState(resolved.spellRef, {
            includeText = false,
            includeTargetCandidates = false,
        }) or nil)
    if type(activationState) ~= "table" then
        resolved.canCast = false
        resolved.cooldownOverlayText = resolved.cooldownOverlayText or ""
        resolved.pendingActivationState = waitingForEventStartup
        resolved.statusText = waitingForEventStartup and transitionStatus or resolved.statusText
        return resolved
    end

    resolved.canCast = activationState.canCast == true
    if waitingForEventStartup then
        resolved.canCast = false
        resolved.pendingActivationState = true
        resolved.statusText = "Event starting"
    end
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
            if waitingForEventStartup then
                failureText = eventState and eventState.ending == true and "Event ending" or "Event starting"
            elseif reason == "cooldown" or reason == "global-cooldown" or reason == "no-charges" then
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
    local waitingForEventStartup = isStartupPending(eventState)
    local transitionStatus = eventState and eventState.ending == true and "Event ending" or "Event starting"

    if type(activationState) ~= "table" then
        resolved.canCast = false
        resolved.cooldownOverlayText = resolved.cooldownOverlayText or ""
        resolved.pendingActivationState = waitingForEventStartup
        resolved.statusText = waitingForEventStartup and transitionStatus or resolved.statusText
        resolved.activationState = nil
        return resolved
    end

    resolved.canCast = activationState.canCast == true
    if waitingForEventStartup then
        resolved.canCast = false
        resolved.pendingActivationState = true
        resolved.statusText = "Event starting"
    end
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
            if waitingForEventStartup then
                failureText = eventState and eventState.ending == true and "Event ending" or "Event starting"
            elseif reason == "cooldown" or reason == "global-cooldown" or reason == "no-charges" then
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

local function collectActionBarSpellRefs(rows)
    local refs = {}
    local seen = {}
    for index = 1, #((rows) or {}) do
        local row = rows[index]
        local spellRef = type(row) == "table" and tostring(row.spellRef or "") or ""
        if spellRef ~= "" and seen[spellRef] ~= true then
            seen[spellRef] = true
            refs[#refs + 1] = spellRef
        end
    end

    return refs
end

local function resolvePlanActivationState(plan, spellRef)
    if type(plan) ~= "table" then
        return nil
    end

    local normalizedSpellRef = tostring(spellRef or "")
    if normalizedSpellRef == "" or plan.deferActivation == true then
        return nil
    end

    plan.activationStatesBySpellRef = type(plan.activationStatesBySpellRef) == "table" and plan.activationStatesBySpellRef or {}
    local cached = plan.activationStatesBySpellRef[normalizedSpellRef]
    if cached ~= nil then
        return cached == false and nil or cached
    end

    local activationState = type(Client.ResolveSpellActivationRuntimeState) == "function"
        and Client:ResolveSpellActivationRuntimeState(normalizedSpellRef)
        or (type(Client.ResolveSpellActivationState) == "function"
            and Client:ResolveSpellActivationState(normalizedSpellRef, {
                includeText = false,
                includeTargetCandidates = false,
            })
            or nil)
    plan.activationStatesBySpellRef[normalizedSpellRef] = activationState or false
    return activationState
end

local function resolveActionBarDetailWithPlan(detail, plan)
    if isSkillActionBarDetail(detail) then
        return detail
    end

    local spellRef = type(detail) == "table" and tostring(detail.spellRef or "") or ""
    if spellRef == "" then
        return resolveRuntimeSpellDetailWithActivationState(detail, nil)
    end

    return resolveRuntimeSpellDetailWithActivationState(detail, resolvePlanActivationState(plan, spellRef))
end

local function isNormalSpellActionBar(npcControlActive)
    return npcControlActive ~= true
        and (Profile.GetActionBarMode and Profile.GetActionBarMode() or "spells") == "spells"
        and not (Profile.ShouldUseMountedActionBar and Profile.ShouldUseMountedActionBar())
end

local function buildActionBarDisplayRows(widget, rows, size, npcControlActive)
    local configuredSlotCount = math.max(0, math.floor(tonumber(size) or 0))
    if not isNormalSpellActionBar(npcControlActive) then
        widget.complexActionBarActive = false
        widget.complexActionBarMaxScrollOffset = 0
        widget.complexActionBarScrollOffset = 0
        return rows, configuredSlotCount, 0, nil
    end

    local autoHitSpellCount = math.max(0, math.floor(tonumber(rows.autoHitSpellCount) or 0))
    local layoutMode = Profile.GetActionBarLayoutMode and Profile.GetActionBarLayoutMode() or "complex"
    if layoutMode == "simple" then
        widget.complexActionBarActive = false
        widget.complexActionBarMaxScrollOffset = 0
        widget.complexActionBarScrollOffset = 0
        return rows, math.max(configuredSlotCount, #rows), autoHitSpellCount, nil
    end

    local visibleAutoHitSpellCount = math.min(configuredSlotCount, autoHitSpellCount)
    local visibleBoundSpellCount = math.max(0, configuredSlotCount - visibleAutoHitSpellCount)
    local totalBoundSpellCount = math.max(0, #rows - autoHitSpellCount)
    local maxScrollOffset = math.max(0, totalBoundSpellCount - visibleBoundSpellCount)
    local scrollOffset = math.max(0, math.min(maxScrollOffset, math.floor(tonumber(widget.complexActionBarScrollOffset) or 0)))
    local displayRows = {}
    local slotIndexes = {}

    for index = 1, visibleAutoHitSpellCount do
        displayRows[#displayRows + 1] = rows[index]
    end
    for index = 1, visibleBoundSpellCount do
        local sourceIndex = autoHitSpellCount + scrollOffset + index
        displayRows[#displayRows + 1] = rows[sourceIndex] or false
        slotIndexes[#displayRows] = scrollOffset + index
    end

    widget.complexActionBarActive = true
    widget.complexActionBarMaxScrollOffset = maxScrollOffset
    widget.complexActionBarScrollOffset = scrollOffset
    return displayRows, configuredSlotCount, visibleAutoHitSpellCount, slotIndexes
end

local function getActionBarSlotLabel(widget, index, detail)
    if type(detail) == "table" and detail.actionBarKind == "auto-spell" then
        return ""
    end

    local slotIndexes = widget and widget.visibleActionBarSlotIndexes or nil
    if type(slotIndexes) == "table" and slotIndexes[index] ~= nil then
        return slotIndexes[index]
    end

    local autoHitSpellCount = math.max(0, math.floor(tonumber(widget and widget.autoHitSpellCount) or 0))
    return math.max(1, index - autoHitSpellCount)
end

local function getComplexAutoSpellGap(widget, slotCount)
    local autoHitSpellCount = math.max(0, math.floor(tonumber(widget and widget.autoHitSpellCount) or 0))
    return widget and widget.complexActionBarActive == true
        and autoHitSpellCount > 0
        and math.max(0, math.floor(tonumber(slotCount) or 0)) > autoHitSpellCount
        and COMPLEX_AUTO_SPELL_GAP
        or 0
end

local function getComplexScrollNavigationWidth(widget)
    return widget and widget.complexActionBarActive == true
        and math.max(0, math.floor(tonumber(widget.complexActionBarMaxScrollOffset) or 0)) > 0
        and COMPLEX_SCROLL_ARROW_WIDTH + COMPLEX_SCROLL_ARROW_GAP
        or 0
end

local function getActionBarSlotOffset(widget, index, slotCount)
    local offset = (math.max(1, index) - 1) * (SLOT_SIZE + SLOT_SPACING)
    local autoHitSpellCount = math.max(0, math.floor(tonumber(widget and widget.autoHitSpellCount) or 0))
    if index > autoHitSpellCount then
        offset = offset + getComplexAutoSpellGap(widget, slotCount)
    end
    return offset
end

local function applyActionBarSlotDetail(self, slot, slotHost, index, detail, npcControlActive, contentInset)
    local frame = slot:GetFrame()
    frame:ClearAllPoints()
    frame:SetPoint("LEFT", slotHost, "LEFT", contentInset + getActionBarSlotOffset(self, index, self.currentActionBarSlotCount), 0)

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
        slot:SetCount(getActionBarSlotLabel(self, index, detail))
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
        slot:SetCount(getActionBarSlotLabel(self, index, nil))
        slot:SetOverlayText("")
        slot.tooltipDetail = nil
        slot:SetBorderColor(EMPTY_SLOT_BORDER.r, EMPTY_SLOT_BORDER.g, EMPTY_SLOT_BORDER.b, EMPTY_SLOT_BORDER.a)
        slot.boundSpellRef = nil
        slot.boundSkillRef = nil
        slot.boundActionBarKind = nil
    end

    slot.isScrollableActionBarSlot = self.complexActionBarActive == true
        and index > math.max(0, math.floor(tonumber(self.autoHitSpellCount) or 0))

    frame:Show()
    return true
end

function ActionBarWidget:ScrollComplexActionBar(delta)
    if self.complexActionBarActive ~= true then
        return false
    end

    local maxScrollOffset = math.max(0, math.floor(tonumber(self.complexActionBarMaxScrollOffset) or 0))
    local offset = math.max(0, math.floor(tonumber(self.complexActionBarScrollOffset) or 0))
    local nextOffset = math.max(0, math.min(maxScrollOffset, offset + ((tonumber(delta) or 0) < 0 and 1 or -1)))
    if nextOffset == offset then
        return false
    end

    self.complexActionBarScrollOffset = nextOffset
    if type(Client.MarkActionBarSlotsDirty) == "function" then
        Client:MarkActionBarSlotsDirty("complex-action-bar-scroll")
    elseif type(Client.RefreshActionBarWidget) == "function" then
        Client:RefreshActionBarWidget("complex-action-bar-scroll")
    end
    return true
end

function ActionBarWidget:EnsureComplexScrollIndicators()
    if not self.rootPanel then
        return false
    end

    local rootFrame = self.rootPanel:GetFrame()
    if not self.complexScrollPreviousIndicator then
        self.complexScrollPreviousIndicator = UI.CreateButton(rootFrame, "RPEClientActionBarScrollPrevious", "<", COMPLEX_SCROLL_ARROW_WIDTH, function()
            self:ScrollComplexActionBar(1)
        end, {
            height = 22,
            fontSize = 11,
            fontFlags = "OUTLINE",
            backgroundColor = UI.ResolveColor(nil, "panel.background"),
            labelColor = UI.ResolveColor(nil, "text.muted"),
        })
        self.complexScrollPreviousIndicator:GetFrame():Hide()
    end
    if not self.complexScrollNextIndicator then
        self.complexScrollNextIndicator = UI.CreateButton(rootFrame, "RPEClientActionBarScrollNext", ">", COMPLEX_SCROLL_ARROW_WIDTH, function()
            self:ScrollComplexActionBar(-1)
        end, {
            height = 22,
            fontSize = 11,
            fontFlags = "OUTLINE",
            backgroundColor = UI.ResolveColor(nil, "panel.background"),
            labelColor = UI.ResolveColor(nil, "text.muted"),
        })
        self.complexScrollNextIndicator:GetFrame():Hide()
    end

    return true
end

function ActionBarWidget:RefreshComplexScrollIndicators(slotCount, contentInset)
    self:EnsureComplexScrollIndicators()
    local slotHost = self.rootPanel.GetContentFrame and self.rootPanel:GetContentFrame() or self.rootPanel:GetFrame()
    local previousFrame = self.complexScrollPreviousIndicator and self.complexScrollPreviousIndicator:GetFrame() or nil
    local nextFrame = self.complexScrollNextIndicator and self.complexScrollNextIndicator:GetFrame() or nil
    local autoHitSpellCount = math.max(0, math.floor(tonumber(self.autoHitSpellCount) or 0))
    local maxScrollOffset = math.max(0, math.floor(tonumber(self.complexActionBarMaxScrollOffset) or 0))
    local scrollOffset = math.max(0, math.floor(tonumber(self.complexActionBarScrollOffset) or 0))
    local canScroll = self.complexActionBarActive == true
        and autoHitSpellCount > 0
        and maxScrollOffset > 0

    if previousFrame then
        previousFrame:ClearAllPoints()
        if canScroll and scrollOffset > 0 then
            previousFrame:SetPoint("LEFT", slotHost, "LEFT", contentInset + (autoHitSpellCount * (SLOT_SIZE + SLOT_SPACING)) + 1, 0)
            previousFrame:Show()
        else
            previousFrame:Hide()
        end
    end
    if nextFrame then
        nextFrame:ClearAllPoints()
        if canScroll and scrollOffset < maxScrollOffset then
            nextFrame:SetPoint("LEFT", slotHost, "LEFT", contentInset + getActionBarSlotOffset(self, slotCount, slotCount) + SLOT_SIZE + COMPLEX_SCROLL_ARROW_GAP, 0)
            nextFrame:Show()
        else
            nextFrame:Hide()
        end
    end
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
    if button.SetPushedTexture then
        button:SetPushedTexture(texture)
    end
    if button.SetDisabledTexture then
        button:SetDisabledTexture(texture)
    end
    return true
end

local function configureActionRowButton(button, tooltip, selected)
    if type(button) ~= "table" then
        return false
    end

    if button.SetSelected then
        button:SetSelected(selected == true)
    end
    if button.SetTooltip then
        button:SetTooltip(tooltip)
    end

    local frame = button.GetFrame and button:GetFrame() or nil
    if frame and frame.SetMotionScriptsWhileDisabled then
        -- The active mode and unavailable mount/pet actions are disabled, but still need to explain themselves.
        frame:SetMotionScriptsWhileDisabled(true)
    end
    return frame ~= nil
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
        suppressHighlight = true,
        normalTexture = SPELL_MODE_BUTTON_TEXTURE,
        pushedTexture = SPELL_MODE_BUTTON_TEXTURE,
        disabledTexture = SPELL_MODE_BUTTON_TEXTURE,
    })
    self.spellModeButton:SetParent(self.rootPanel:GetFrame())
    self.spellModeButton:Create()
    configureActionRowButton(self.spellModeButton, getSpellModeButtonTooltipText(self), true)
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
    configureActionRowButton(
        spellModeButton,
        getSpellModeButtonTooltipText(self),
        not controlActive and not mountedActionBarActive and mode == "spells"
    )
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
        suppressHighlight = true,
        normalTexture = SKILL_MODE_BUTTON_TEXTURE,
        pushedTexture = SKILL_MODE_BUTTON_TEXTURE,
        disabledTexture = SKILL_MODE_BUTTON_TEXTURE,
    })
    self.skillModeButton:SetParent(self.rootPanel:GetFrame())
    self.skillModeButton:Create()
    configureActionRowButton(self.skillModeButton, getSkillModeButtonTooltipText(self), false)
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
    configureActionRowButton(
        skillModeButton,
        getSkillModeButtonTooltipText(self),
        not controlActive and not mountedActionBarActive and mode == "skills"
    )
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
        suppressHighlight = true,
        normalTexture = MOUNT_BUTTON_TEXTURE,
        pushedTexture = MOUNT_BUTTON_TEXTURE,
        disabledTexture = MOUNT_BUTTON_TEXTURE,
    })
    self.mountButton:SetParent(self.rootPanel:GetFrame())
    self.mountButton:Create()
    configureActionRowButton(self.mountButton, getMountButtonTooltipText(), false)
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
    configureActionRowButton(mountButton, getMountButtonTooltipText(), isMounted)
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
        suppressHighlight = true,
        normalTexture = PET_BUTTON_TEXTURE,
        pushedTexture = PET_BUTTON_TEXTURE,
        disabledTexture = PET_BUTTON_TEXTURE,
    })
    self.petButton:SetParent(self.rootPanel:GetFrame())
    self.petButton:Create()
    configureActionRowButton(self.petButton, getPetButtonTooltipText(self, nil), false)
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
    configureActionRowButton(petButton, getPetButtonTooltipText(self, petUnit), false)
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
    frame:SetPoint("LEFT", slotHost, "LEFT", contentInset + getActionBarSlotOffset(self, index, self.currentActionBarSlotCount), 0)
    frame:EnableMouse(true)
    frame:EnableMouseWheel(true)
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
    frame:HookScript("OnMouseWheel", function(_, delta)
        if slot.isScrollableActionBarSlot == true then
            self:ScrollComplexActionBar(delta)
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
            if slot.boundActionBarKind == "mounted-spell" or slot.boundActionBarKind == "auto-spell" then
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
    local displayRows, slotCount, autoHitSpellCount, visibleActionBarSlotIndexes = buildActionBarDisplayRows(self, rows, size, npcControlActive)
    self.autoHitSpellCount = autoHitSpellCount
    self.visibleActionBarSlotIndexes = visibleActionBarSlotIndexes
    self.currentActionBarSlotCount = slotCount
    local contentInset = self.GetContentInset and self:GetContentInset() or ROOT_PADDING
    local refreshSignature = buildActionBarRefreshSignature(self, displayRows, controlContext, slotCount)
    local structureSignature = buildActionBarStructureSignature(self, displayRows, controlContext, slotCount)
    self:RefreshActionRowButtons()
    local baseWidth = (slotCount * SLOT_SIZE) + (math.max(0, slotCount - 1) * SLOT_SPACING) + getComplexAutoSpellGap(self, slotCount) + getComplexScrollNavigationWidth(self) + (contentInset * 2)
    rootFrame:SetSize(baseWidth, ROOT_HEIGHT)
    self:RefreshComplexScrollIndicators(slotCount, contentInset)

    self:ApplyAnchor()
    self:UpdateMovableState()

    local eventState = Client.GetEventState and Client:GetEventState() or nil
    if self.lastRefreshSignature == refreshSignature then
        if self.RefreshControlState and not isStartupPending(eventState) then
            self:RefreshControlState(reason or "action-bar-refresh")
        end
        return true
    end

    local plan = {
        activationStatesBySpellRef = {},
        deferActivation = isStartupPending(eventState),
    }

    for index = 1, slotCount do
        local slot = self:EnsureSlot(index)
        local detail = resolveActionBarDetailWithPlan(displayRows[index], plan)
        applyActionBarSlotDetail(self, slot, slotHost, index, detail, npcControlActive, contentInset)
    end

    for index = slotCount + 1, #(self.slots or {}) do
        local slot = self.slots[index]
        local frame = slot and slot.GetFrame and slot:GetFrame() or nil
        if frame then
            frame:Hide()
        end
    end

    if self.RefreshControlState and not isStartupPending(eventState) then
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
    local displayRows, slotCount, autoHitSpellCount, visibleActionBarSlotIndexes = buildActionBarDisplayRows(self, rows, size, npcControlActive)
    self.autoHitSpellCount = autoHitSpellCount
    self.visibleActionBarSlotIndexes = visibleActionBarSlotIndexes
    self.currentActionBarSlotCount = slotCount
    local contentInset = self.GetContentInset and self:GetContentInset() or ROOT_PADDING
    local refreshSignature = buildActionBarRefreshSignature(self, displayRows, controlContext, slotCount)
    local structureSignature = buildActionBarStructureSignature(self, displayRows, controlContext, slotCount)
    local eventState = Client.GetEventState and Client:GetEventState() or nil
    local plan = {
        rows = displayRows,
        controlContext = controlContext,
        npcControlActive = npcControlActive,
        rootFrame = rootFrame,
        slotHost = slotHost,
        slotCount = slotCount,
        contentInset = contentInset,
        refreshSignature = refreshSignature,
        structureSignature = structureSignature,
        deferActivation = isStartupPending(eventState),
        actionBarRevision = type(Client.DirtyUiRefreshState) == "table"
            and math.max(0, math.floor(tonumber(Client.DirtyUiRefreshState.actionBarRevision) or 0))
            or 0,
        activationStatesBySpellRef = {},
        pendingActivationSpellRefs = collectActionBarSpellRefs(displayRows),
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
        self:RefreshActionRowButtons()
        local baseWidth = (plan.slotCount * SLOT_SIZE) + (math.max(0, plan.slotCount - 1) * SLOT_SPACING) + getComplexAutoSpellGap(self, plan.slotCount) + getComplexScrollNavigationWidth(self) + (plan.contentInset * 2)
        plan.rootFrame:SetSize(baseWidth, ROOT_HEIGHT)
        self:ApplyAnchor()
        self:UpdateMovableState()
        for index = 1, plan.slotCount do
            local slot = self:EnsureSlot(index)
            local frame = slot:GetFrame()
            frame:ClearAllPoints()
            frame:SetPoint("LEFT", plan.slotHost, "LEFT", plan.contentInset + getActionBarSlotOffset(self, index, plan.slotCount), 0)
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

    self:RefreshComplexScrollIndicators(plan.slotCount, plan.contentInset)

    local eventState = Client.GetEventState and Client:GetEventState() or nil
    if self.RefreshControlState and not isStartupPending(eventState) then
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
        or math.max(0, math.floor(tonumber(plan.actionBarRevision) or 0)) ~= currentRevision
    then
        plan = self:PrepareIncrementalRefresh(reason, dirtyState)
    end

    local slotBudget = math.max(1, math.floor(tonumber(maxSlots) or 2))
    local dirtySlots = type(dirtyState) == "table" and dirtyState.actionBarSlots or {}
    local refreshAll = plan.fullRefresh == true

    local processed = 0
    local ran = false
    while processed < slotBudget and #(plan.pendingActivationSpellRefs or {}) > 0 do
        local spellRef = table.remove(plan.pendingActivationSpellRefs, 1)
        if spellRef and spellRef ~= "" then
            resolvePlanActivationState(plan, spellRef)
            processed = processed + 1
            ran = true
        end
    end
    if refreshAll == true then
        for index = math.max(1, tonumber(plan.nextSlotIndex) or 1), plan.slotCount do
            if processed >= slotBudget then
                break
            end
            local slot = self:EnsureSlot(index)
            local detail = resolveActionBarDetailWithPlan(plan.rows[index], plan)
            applyActionBarSlotDetail(self, slot, plan.slotHost, index, detail, plan.npcControlActive, plan.contentInset)
            processed = processed + 1
            ran = true
            plan.nextSlotIndex = index + 1
        end
    else
        for index = 1, plan.slotCount do
            if processed >= slotBudget then
                break
            end
            if dirtySlots[index] == true then
                local slot = self:EnsureSlot(index)
                local detail = resolveActionBarDetailWithPlan(plan.rows[index], plan)
                applyActionBarSlotDetail(self, slot, plan.slotHost, index, detail, plan.npcControlActive, plan.contentInset)
                dirtySlots[index] = nil
                processed = processed + 1
                ran = true
            end
        end
    end

    if refreshAll == true then
        if type(dirtyState) == "table" then
            dirtyState.actionBarAllSlotsDirty = false
            dirtyState.actionBarStructuralDirty = false
        end
    end

    local morePending = #(plan.pendingActivationSpellRefs or {}) > 0
        or (refreshAll == true and math.max(1, tonumber(plan.nextSlotIndex) or 1) <= plan.slotCount)
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
    if self:RequireSetupCompletion("action-bar-widget") ~= true then
        return nil
    end

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
