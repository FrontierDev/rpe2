local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Client.Spellcasting = Addon.Client.Spellcasting or {}
Addon.Internal = Addon.Internal or {}

local Client = Addon.Client
local Spellcasting = Addon.Client.Spellcasting or {}
local Registry = Addon.Internal.Registry or {}

local INITIAL_REPEAT_SOURCE = "basic_attack_repeat"
local AUTOMATIC_REPEAT_SOURCE = "basic_attack_repeat_auto"
local REPEAT_OVERLAY_TEXTURE = "Interface\\Buttons\\UI-AutoCastableOverlay"

Client.BasicAttackRepeatByEventId = Client.BasicAttackRepeatByEventId or {}
Client.BasicAttackRepeatAttemptQueued = Client.BasicAttackRepeatAttemptQueued or {}

local function normalizeEventId(value)
    local eventId = tostring(value or "")
    return eventId ~= "" and eventId or nil
end

local function normalizeEventUnitId(value)
    local eventId = math.floor(tonumber(value) or 0)
    return eventId > 0 and eventId or nil
end

local function normalizeDamageType(value)
    local damageType = string.lower(tostring(value or ""))
    if damageType == "melee" or damageType == "ranged" or damageType == "spell" then
        return damageType
    end
    return damageType ~= "" and damageType or nil
end

local function resolveBasicAttackDamageType(spell)
    if type(spell) ~= "table" then
        return nil
    end

    for index = 1, #(spell.components or {}) do
        local component = spell.components[index]
        local effect = type(component) == "table" and component.effect or nil
        if type(effect) == "table"
            and tostring(effect.type or "") == "damage"
            and string.lower(tostring(effect.hitType or "")) == "auto"
        then
            return normalizeDamageType(effect.damageType)
        end
    end

    return nil
end

local function resolveSpell(spellRef)
    if type(Registry.ResolveSpellReference) ~= "function" then
        return nil
    end

    local _, spell = Registry:ResolveSpellReference(spellRef)
    return type(spell) == "table" and spell or nil
end

local function isBasicAttackSpellRef(spellRef)
    return resolveBasicAttackDamageType(resolveSpell(spellRef)) ~= nil
end

local function buildStepKey(eventState)
    if type(eventState) ~= "table" then
        return ""
    end

    return ("%d:%d"):format(
        math.max(1, math.floor(tonumber(eventState.turnNumber) or 1)),
        math.max(1, math.floor(tonumber(eventState.tickNumber) or 1))
    )
end

local function isLocalPlayerTurnActive(client, eventState)
    if type(client) ~= "table" or type(eventState) ~= "table" or eventState.active ~= true then
        return false
    end

    local localUnit = type(client.ResolveLocalEventUnit) == "function" and client:ResolveLocalEventUnit(eventState) or nil
    local localEventId = normalizeEventUnitId(localUnit and localUnit.eventID)
    if type(localUnit) ~= "table" or localUnit.isPlayer ~= true or not localEventId then
        return false
    end

    if type(Spellcasting.IsCasterTurnOnTick) == "function" then
        return Spellcasting.IsCasterTurnOnTick(eventState, localEventId) == true
    end

    local controlContext = type(client.GetActionBarControlContext) == "function" and client:GetActionBarControlContext(eventState) or nil
    return type(controlContext) == "table"
        and controlContext.isControlled ~= true
        and type(client.IsLocalTurnActive) == "function"
        and client:IsLocalTurnActive(eventState) == true
end

local function cloneTargetSelections(targetSelections)
    local copy = {}
    for groupKey, selection in pairs(type(targetSelections) == "table" and targetSelections or {}) do
        if type(selection) == "table" then
            local targetEventIds = {}
            for index = 1, #(selection.targetEventIds or {}) do
                local eventId = normalizeEventUnitId(selection.targetEventIds[index])
                if eventId then
                    targetEventIds[#targetEventIds + 1] = eventId
                end
            end

            copy[groupKey] = {
                groupKey = tostring(selection.groupKey or groupKey),
                targetEventIds = targetEventIds,
                focusedTargetEventId = normalizeEventUnitId(selection.focusedTargetEventId) or 0,
            }
        end
    end
    return copy
end

local function capturePendingTargetSelections(client, pending)
    if type(client) ~= "table" or type(pending) ~= "table" or type(client.GetPendingSpellTargetingDisplayState) ~= "function" then
        return nil
    end

    local displayState = client:GetPendingSpellTargetingDisplayState()
    if type(displayState) ~= "table" then
        return nil
    end

    local targetSelections = {}
    local groupOrder = {}
    for index = 1, #(displayState.groups or {}) do
        local groupState = displayState.groups[index]
        local groupKey = tostring(groupState and groupState.key or "")
        if groupKey ~= "" then
            local selectedLookup = type(groupState.selectedTargetEventIds) == "table" and groupState.selectedTargetEventIds or {}
            local focusedTargetEventId = normalizeEventUnitId(groupState.focusedTargetEventId) or 0
            local ordered = {}
            local seen = {}

            if focusedTargetEventId > 0 and selectedLookup[focusedTargetEventId] == true then
                ordered[#ordered + 1] = focusedTargetEventId
                seen[focusedTargetEventId] = true
            end

            for candidateIndex = 1, #(groupState.candidates or {}) do
                local candidateEventId = normalizeEventUnitId(groupState.candidates[candidateIndex] and groupState.candidates[candidateIndex].eventID)
                if candidateEventId
                    and selectedLookup[candidateEventId] == true
                    and seen[candidateEventId] ~= true
                then
                    ordered[#ordered + 1] = candidateEventId
                    seen[candidateEventId] = true
                end
            end

            targetSelections[groupKey] = {
                groupKey = groupKey,
                targetEventIds = ordered,
                focusedTargetEventId = focusedTargetEventId,
            }
            groupOrder[#groupOrder + 1] = groupKey
        end
    end

    return targetSelections, groupOrder
end

local function buildCandidateLookup(candidates)
    local lookup = {}
    for index = 1, #(candidates or {}) do
        local eventId = normalizeEventUnitId(candidates[index] and candidates[index].eventID)
        if eventId then
            lookup[eventId] = true
        end
    end
    return lookup
end

local function applyRepeatTargetsToPending(pending, repeatState)
    if type(pending) ~= "table" or type(repeatState) ~= "table" then
        return false
    end

    local activationSnapshot = pending.activationSnapshot
    local candidatesByGroup = type(activationSnapshot) == "table" and activationSnapshot.targetCandidatesByGroup or nil
    local savedSelections = type(repeatState.targetSelections) == "table" and repeatState.targetSelections or {}

    for index = 1, #(pending.groups or {}) do
        local group = pending.groups[index]
        local groupKey = tostring(group and group.key or "")
        local policy = type(group) == "table" and type(group.policy) == "table" and group.policy or {}
        local saved = savedSelections[groupKey]
        local savedTargetEventIds = type(saved) == "table" and saved.targetEventIds or {}
        local minTargets = math.max(0, math.floor(tonumber(policy.minTargets) or 0))
        local maxTargets = math.max(minTargets, math.floor(tonumber(policy.maxTargets) or minTargets))
        local candidateLookup = buildCandidateLookup(type(candidatesByGroup) == "table" and candidatesByGroup[groupKey] or {})
        local selectedLookup = {}
        local selectedCount = 0
        local firstSelectedEventId = 0

        for targetIndex = 1, #savedTargetEventIds do
            local targetEventId = normalizeEventUnitId(savedTargetEventIds[targetIndex])
            if not targetEventId or candidateLookup[targetEventId] ~= true then
                return false
            end
            if selectedLookup[targetEventId] ~= true then
                selectedLookup[targetEventId] = true
                selectedCount = selectedCount + 1
                if firstSelectedEventId == 0 then
                    firstSelectedEventId = targetEventId
                end
            end
        end

        if selectedCount < minTargets or (maxTargets > 0 and selectedCount > maxTargets) then
            return false
        end

        local focusedTargetEventId = type(saved) == "table" and normalizeEventUnitId(saved.focusedTargetEventId) or nil
        if not focusedTargetEventId or selectedLookup[focusedTargetEventId] ~= true then
            focusedTargetEventId = firstSelectedEventId
        end

        group.selectedTargetEventIds = selectedLookup
        group.focusedTargetEventId = focusedTargetEventId or 0
    end

    return true
end

function Client:GetBasicAttackRepeatState(eventIdOverride)
    local eventState = type(self.GetEventState) == "function" and self:GetEventState() or nil
    local eventId = normalizeEventId(eventIdOverride) or normalizeEventId(eventState and eventState.id)
    if not eventId then
        return nil
    end

    local state = type(self.BasicAttackRepeatByEventId) == "table" and self.BasicAttackRepeatByEventId[eventId] or nil
    return type(state) == "table" and state or nil
end

function Client:IsBasicAttackRepeatActive(spellRef, eventIdOverride)
    local state = self:GetBasicAttackRepeatState(eventIdOverride)
    return type(state) == "table" and tostring(state.spellRef or "") == tostring(spellRef or "")
end

function Client:ClearBasicAttackRepeat(eventIdOverride)
    local eventState = type(self.GetEventState) == "function" and self:GetEventState() or nil
    local eventId = normalizeEventId(eventIdOverride) or normalizeEventId(eventState and eventState.id)
    if not eventId or type(self.BasicAttackRepeatByEventId) ~= "table" then
        return false
    end

    local changed = self.BasicAttackRepeatByEventId[eventId] ~= nil
    self.BasicAttackRepeatByEventId[eventId] = nil
    if type(self.BasicAttackRepeatAttemptQueued) == "table" then
        self.BasicAttackRepeatAttemptQueued[eventId] = nil
    end

    if changed and type(self.RefreshActionBarWidget) == "function" then
        self:RefreshActionBarWidget("basic-attack-repeat-clear")
    end
    return changed
end

function Client:SetBasicAttackRepeat(spellRef, activationSnapshot, targetSelections, groupOrder)
    local eventState = type(activationSnapshot) == "table" and activationSnapshot.eventState or nil
    local casterUnit = type(activationSnapshot) == "table" and activationSnapshot.casterUnit or nil
    local eventId = normalizeEventId(eventState and eventState.id)
    local casterEventId = normalizeEventUnitId(casterUnit and casterUnit.eventID)
    if not eventId or not casterEventId or not isBasicAttackSpellRef(spellRef) then
        return false
    end

    local localUnit = type(self.ResolveLocalEventUnit) == "function" and self:ResolveLocalEventUnit(eventState) or nil
    if type(localUnit) ~= "table"
        or localUnit.isPlayer ~= true
        or normalizeEventUnitId(localUnit.eventID) ~= casterEventId
    then
        return false
    end

    self.BasicAttackRepeatByEventId = self.BasicAttackRepeatByEventId or {}
    self.BasicAttackRepeatByEventId[eventId] = {
        eventId = eventId,
        casterEventId = casterEventId,
        spellRef = tostring(spellRef),
        damageType = resolveBasicAttackDamageType(activationSnapshot.spell),
        targetSelections = cloneTargetSelections(targetSelections),
        groupOrder = type(groupOrder) == "table" and { unpack(groupOrder) } or {},
        lastAttemptStepKey = buildStepKey(eventState),
    }

    if type(self.RefreshActionBarWidget) == "function" then
        self:RefreshActionBarWidget("basic-attack-repeat-set")
    end
    return true
end

function Client:ToggleBasicAttackRepeat(spellRef)
    local normalizedSpellRef = tostring(spellRef or "")
    local eventState = type(self.GetEventState) == "function" and self:GetEventState() or nil
    local eventId = normalizeEventId(eventState and eventState.id)
    if normalizedSpellRef == "" or not eventId or not isBasicAttackSpellRef(normalizedSpellRef) then
        return false
    end

    if self:IsBasicAttackRepeatActive(normalizedSpellRef, eventId) then
        return self:ClearBasicAttackRepeat(eventId)
    end

    local controlContext = type(self.GetActionBarControlContext) == "function" and self:GetActionBarControlContext(eventState) or nil
    if type(controlContext) ~= "table" or controlContext.isControlled == true then
        return false
    end

    local sourceContext = {
        eventId = eventId,
        spellRef = normalizedSpellRef,
        targetSelections = {},
        groupOrder = {},
    }
    local activated = self.ActivateSpellReference and self:ActivateSpellReference(normalizedSpellRef, {
        sourceType = INITIAL_REPEAT_SOURCE,
        targetingReason = "basic-attack-repeat-target",
        sourceContext = sourceContext,
        onCastAccepted = function(context, acceptedSpellRef, activationSnapshot)
            if type(context) ~= "table" then
                return true
            end
            self:SetBasicAttackRepeat(
                acceptedSpellRef,
                activationSnapshot,
                context.targetSelections,
                context.groupOrder
            )
            return true
        end,
    }) or false

    return activated == true
end

function Client:TryBasicAttackRepeat(eventStateOverride)
    local eventState = eventStateOverride or (type(self.GetEventState) == "function" and self:GetEventState() or nil)
    local eventId = normalizeEventId(eventState and eventState.id)
    if not eventId or type(eventState) ~= "table" or eventState.active ~= true or eventState.ending == true then
        return false
    end
    if not isLocalPlayerTurnActive(self, eventState) or self.PendingSpellTargeting ~= nil then
        return false
    end

    local repeatState = self:GetBasicAttackRepeatState(eventId)
    if type(repeatState) ~= "table" or not isBasicAttackSpellRef(repeatState.spellRef) then
        return false
    end

    local localUnit = type(self.ResolveLocalEventUnit) == "function" and self:ResolveLocalEventUnit(eventState) or nil
    if normalizeEventUnitId(localUnit and localUnit.eventID) ~= normalizeEventUnitId(repeatState.casterEventId) then
        return false
    end

    local stepKey = buildStepKey(eventState)
    if stepKey == "" or tostring(repeatState.lastAttemptStepKey or "") == stepKey then
        return false
    end
    repeatState.lastAttemptStepKey = stepKey

    local activated = self.ActivateSpellReference and self:ActivateSpellReference(repeatState.spellRef, {
        sourceType = AUTOMATIC_REPEAT_SOURCE,
        targetingReason = "basic-attack-repeat-auto",
        sourceContext = {
            eventId = eventId,
            spellRef = repeatState.spellRef,
        },
    }) or false
    if activated ~= true then
        return false
    end

    local pending = self.PendingSpellTargeting
    if type(pending) ~= "table" then
        return true
    end
    if not pending.activationOptions or pending.activationOptions.sourceType ~= AUTOMATIC_REPEAT_SOURCE then
        return false
    end
    if tostring(pending.eventId or "") ~= eventId
        or normalizeEventUnitId(pending.casterEventId) ~= normalizeEventUnitId(repeatState.casterEventId)
        or tostring(pending.spellRef or "") ~= tostring(repeatState.spellRef or "")
    then
        if type(self.CancelSpellTargeting) == "function" then
            self:CancelSpellTargeting("basic-attack-repeat-stale")
        end
        return false
    end

    if not applyRepeatTargetsToPending(pending, repeatState) then
        if type(self.CancelSpellTargeting) == "function" then
            self:CancelSpellTargeting("basic-attack-repeat-target-invalid")
        end
        return false
    end

    if type(self.InvalidatePendingSpellTargetingDisplayState) == "function" then
        self:InvalidatePendingSpellTargetingDisplayState()
    end
    return type(self.ConfirmPendingSpellTargeting) == "function" and self:ConfirmPendingSpellTargeting() == true
end

function Client:QueueBasicAttackRepeatAttempt(eventStateOverride)
    local eventState = eventStateOverride or (type(self.GetEventState) == "function" and self:GetEventState() or nil)
    local eventId = normalizeEventId(eventState and eventState.id)
    if not eventId then
        return false
    end

    self.BasicAttackRepeatAttemptQueued = self.BasicAttackRepeatAttemptQueued or {}
    local stepKey = buildStepKey(eventState)
    if self.BasicAttackRepeatAttemptQueued[eventId] == stepKey then
        return false
    end
    self.BasicAttackRepeatAttemptQueued[eventId] = stepKey

    local function run()
        if type(self.BasicAttackRepeatAttemptQueued) == "table" and self.BasicAttackRepeatAttemptQueued[eventId] == stepKey then
            self.BasicAttackRepeatAttemptQueued[eventId] = nil
        end
        local currentEventState = type(self.GetEventState) == "function" and self:GetEventState() or nil
        if normalizeEventId(currentEventState and currentEventState.id) ~= eventId
            or buildStepKey(currentEventState) ~= stepKey
        then
            return
        end
        self:TryBasicAttackRepeat(currentEventState)
    end

    if C_Timer and type(C_Timer.After) == "function" then
        C_Timer.After(0, run)
        return true
    end

    run()
    return true
end

local baseConfirmPendingSpellTargeting = Client.ConfirmPendingSpellTargeting
if type(baseConfirmPendingSpellTargeting) == "function" then
    function Client:ConfirmPendingSpellTargeting(...)
        local pending = self.PendingSpellTargeting
        local activationOptions = type(pending) == "table" and pending.activationOptions or nil
        if type(activationOptions) == "table" and activationOptions.sourceType == INITIAL_REPEAT_SOURCE then
            local targetSelections, groupOrder = capturePendingTargetSelections(self, pending)
            local sourceContext = type(activationOptions.sourceContext) == "table" and activationOptions.sourceContext or nil
            if sourceContext and targetSelections then
                sourceContext.targetSelections = cloneTargetSelections(targetSelections)
                sourceContext.groupOrder = groupOrder or {}
            end
        end

        return baseConfirmPendingSpellTargeting(self, ...)
    end
end

local baseRefreshTargetingWidget = Client.RefreshTargetingWidget
if type(baseRefreshTargetingWidget) == "function" then
    function Client:RefreshTargetingWidget(reason, ...)
        local pending = self.PendingSpellTargeting
        local activationOptions = type(pending) == "table" and pending.activationOptions or nil
        if type(activationOptions) == "table" and activationOptions.sourceType == AUTOMATIC_REPEAT_SOURCE then
            return true
        end
        return baseRefreshTargetingWidget(self, reason, ...)
    end
end

local baseHandleEventState = Client.HandleEventState
if type(baseHandleEventState) == "function" then
    function Client:HandleEventState(arguments, ...)
        local previousEventState = type(self.GetEventState) == "function" and self:GetEventState() or nil
        local previousStepKey = buildStepKey(previousEventState)
        local wasLocalPlayerTurn = isLocalPlayerTurnActive(self, previousEventState)
        local result = baseHandleEventState(self, arguments, ...)
        if result == true then
            local currentEventState = type(self.GetEventState) == "function" and self:GetEventState() or nil
            local currentStepKey = buildStepKey(currentEventState)
            local isLocalPlayerTurn = isLocalPlayerTurnActive(self, currentEventState)
            if isLocalPlayerTurn
                and currentStepKey ~= ""
                and (not wasLocalPlayerTurn or currentStepKey ~= previousStepKey)
            then
                self:QueueBasicAttackRepeatAttempt(currentEventState)
            end
        end
        return result
    end
end

local baseResetSpellcastingState = Client.ResetSpellcastingState
if type(baseResetSpellcastingState) == "function" then
    function Client:ResetSpellcastingState(eventId, ...)
        self:ClearBasicAttackRepeat(eventId)
        return baseResetSpellcastingState(self, eventId, ...)
    end
end

local function ensureRepeatOverlay(slot)
    if type(slot) ~= "table" then
        return nil
    end
    if slot.basicAttackRepeatOverlay then
        return slot.basicAttackRepeatOverlay
    end

    local frame = type(slot.GetFrame) == "function" and slot:GetFrame() or nil
    if not frame or type(frame.CreateTexture) ~= "function" then
        return nil
    end

    local overlay = frame:CreateTexture(nil, "OVERLAY", nil, 7)
    overlay:SetTexture(REPEAT_OVERLAY_TEXTURE)
    overlay:SetBlendMode("ADD")
    overlay:SetPoint("CENTER", frame, "CENTER", 0, 0)
    overlay:SetSize(58, 58)
    overlay:SetAlpha(1)
    overlay:Hide()

    local animation = overlay:CreateAnimationGroup()
    local fadeDown = animation:CreateAnimation("Alpha")
    fadeDown:SetFromAlpha(1)
    fadeDown:SetToAlpha(0.45)
    fadeDown:SetDuration(0.45)
    fadeDown:SetOrder(1)
    local fadeUp = animation:CreateAnimation("Alpha")
    fadeUp:SetFromAlpha(0.45)
    fadeUp:SetToAlpha(1)
    fadeUp:SetDuration(0.45)
    fadeUp:SetOrder(2)
    animation:SetLooping("REPEAT")

    slot.basicAttackRepeatOverlay = overlay
    slot.basicAttackRepeatAnimation = animation
    return overlay
end

local function setRepeatOverlayShown(slot, shown)
    local overlay = ensureRepeatOverlay(slot)
    if not overlay then
        return false
    end

    local animation = slot.basicAttackRepeatAnimation
    if shown == true then
        overlay:Show()
        if animation and type(animation.Play) == "function"
            and (type(animation.IsPlaying) ~= "function" or animation:IsPlaying() ~= true)
        then
            animation:Play()
        end
    else
        if animation and type(animation.Stop) == "function" then
            animation:Stop()
        end
        overlay:SetAlpha(1)
        overlay:Hide()
    end
    return true
end

local function installActionBarRepeatHooks()
    local ActionBarWidget = Addon.Client
        and Addon.Client.UI
        and Addon.Client.UI.ActionBarWidget
        or nil
    if type(ActionBarWidget) ~= "table" or ActionBarWidget._basicAttackRepeatHooksInstalled == true then
        return false
    end

    local baseEnsureSlot = ActionBarWidget.EnsureSlot
    local baseRefresh = ActionBarWidget.Refresh
    if type(baseEnsureSlot) ~= "function" or type(baseRefresh) ~= "function" then
        return false
    end

    function ActionBarWidget:EnsureSlot(index)
        local slot = baseEnsureSlot(self, index)
        if type(slot) ~= "table" or slot._basicAttackRepeatMouseHookInstalled == true then
            return slot
        end

        local frame = type(slot.GetFrame) == "function" and slot:GetFrame() or nil
        if frame and type(frame.HookScript) == "function" then
            frame:HookScript("OnMouseUp", function(_, button)
                if button ~= "RightButton"
                    or slot.boundActionBarKind ~= "auto-spell"
                    or type(slot.boundSpellRef) ~= "string"
                    or slot.boundSpellRef == ""
                    or (self.IsUnlocked and self:IsUnlocked())
                    or (self.IsActionBarControlActive and self:IsActionBarControlActive())
                then
                    return
                end

                Client:ToggleBasicAttackRepeat(slot.boundSpellRef)
            end)
            slot._basicAttackRepeatMouseHookInstalled = true
        end
        ensureRepeatOverlay(slot)
        return slot
    end

    function ActionBarWidget:RefreshBasicAttackRepeatVisuals()
        for index = 1, #(self.slots or {}) do
            local slot = self.slots[index]
            local active = type(slot) == "table"
                and slot.boundActionBarKind == "auto-spell"
                and type(slot.boundSpellRef) == "string"
                and Client:IsBasicAttackRepeatActive(slot.boundSpellRef)
            setRepeatOverlayShown(slot, active == true)
        end
        return true
    end

    function ActionBarWidget:Refresh(reason, ...)
        local results = { baseRefresh(self, reason, ...) }
        self:RefreshBasicAttackRepeatVisuals()
        return unpack(results)
    end

    ActionBarWidget._basicAttackRepeatHooksInstalled = true
    return true
end

if C_Timer and type(C_Timer.After) == "function" then
    C_Timer.After(0, installActionBarRepeatHooks)
elseif type(CreateFrame) == "function" then
    local loader = CreateFrame("Frame")
    loader:RegisterEvent("PLAYER_LOGIN")
    loader:SetScript("OnEvent", function(self)
        self:UnregisterEvent("PLAYER_LOGIN")
        installActionBarRepeatHooks()
    end)
end

return Client
