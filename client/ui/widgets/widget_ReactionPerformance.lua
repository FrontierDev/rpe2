local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Client.UI = Addon.Client.UI or {}
Addon.Internal = Addon.Internal or {}

local Client = Addon.Client
local ClientUI = Addon.Client.UI
local UI = Addon.UI or {}
local Combat = Client.Combat or {}
local Tasks = Addon.Internal.Tasks or {}
local ReactionWidget = ClientUI.ReactionWidget

if type(ReactionWidget) ~= "table" or type(ReactionWidget.Get) ~= "function" then
    return true
end

local DEFAULT_ICON = "Interface\\Icons\\INV_Misc_QuestionMark"
local baseShowCombatReaction = Client.ShowCombatReaction
local baseShowNextQueuedCombatReaction = Client.ShowNextQueuedCombatReaction
local baseHideCombatReaction = Client.HideCombatReaction

local function getActiveEntry()
    return type(Client.ActiveCombatReactionEntry) == "table" and Client.ActiveCombatReactionEntry or nil
end

local function getCheckId(entry)
    return tostring(type(entry) == "table" and entry.checkId or "")
end

local function shouldYield(deadlineMs)
    return type(Tasks.ShouldYield) == "function" and Tasks:ShouldYield(deadlineMs) == true
end

local function getFrame(element)
    return type(element) == "table" and type(element.GetFrame) == "function" and element:GetFrame() or element
end

local function setShown(element, shown)
    local frame = getFrame(element)
    if not frame then
        return false
    end
    if type(frame.SetShown) == "function" then
        frame:SetShown(shown == true)
    elseif shown == true and type(frame.Show) == "function" then
        frame:Show()
    elseif shown ~= true and type(frame.Hide) == "function" then
        frame:Hide()
    end
    return true
end

local function rawUnitField(unit, key)
    if type(unit) ~= "table" then
        return nil
    end
    local value = rawget(unit, key)
    if value ~= nil then
        return value
    end
    if key == "eventID" or key == "isPlayer" or key == "registryID"
        or key == "presetIndex" or key == "appearanceIndex"
        or key == "ownerID" or key == "controllerID" or key == "name"
        or key == "__rpeCombatRevision"
    then
        return unit[key]
    end
    return nil
end

local function buildPortraitSignature(entry, unit)
    local eventState = type(entry) == "table" and entry.eventState or nil
    return table.concat({
        tostring(type(eventState) == "table" and eventState.id or ""),
        tostring(rawUnitField(unit, "eventID") or 0),
        tostring(rawUnitField(unit, "isPlayer") == true and 1 or 0),
        tostring(rawUnitField(unit, "registryID") or ""),
        tostring(rawUnitField(unit, "presetIndex") or 0),
        tostring(rawUnitField(unit, "appearanceIndex") or 0),
        tostring(rawUnitField(unit, "ownerID") or ""),
        tostring(rawUnitField(unit, "controllerID") or ""),
        tostring(rawUnitField(unit, "name") or ""),
        tostring(rawUnitField(unit, "__rpeCombatRevision") or 0),
        tostring(Addon.Internal and Addon.Internal.ConfigurationRevision or 0),
    }, "\31")
end

local function resolveLayoutShape(widget, displayState)
    local actions = type(displayState) == "table" and displayState.actions or {}
    local options = widget.actionsLayout and widget.actionsLayout.options or {}
    local contentWidth = math.max(1, tonumber(options and options.width) or 264)
    local spacing = math.max(0, tonumber(options and options.spacing) or 2)
    local actionCount = math.max(1, #actions)
    local columns = actionCount
    local cellWidth = math.max(40, math.floor((contentWidth - ((columns - 1) * spacing)) / columns))
    local previewVisible = tostring(type(displayState) == "table" and displayState.failurePreviewText or "") ~= ""
    local signature = table.concat({
        tostring(actionCount),
        tostring(columns),
        tostring(cellWidth),
        previewVisible and "1" or "0",
    }, ":")
    return {
        signature = signature,
        actionCount = actionCount,
        columns = columns,
        cellWidth = cellWidth,
        spacing = spacing,
        previewVisible = previewVisible,
        actionsHeight = math.max(1, tonumber(options and options.height) or 46),
    }
end

local function applyHeaderContent(widget, displayState)
    if widget.headerPromptText and type(widget.headerPromptText.SetText) == "function" then
        widget.headerPromptText:SetText("You are defending against:")
    end
    if widget.headerNameText and type(widget.headerNameText.SetText) == "function" then
        widget.headerNameText:SetText(tostring(displayState.attackerName or "Unknown Attacker"))
    end
    if widget.failurePreviewText and type(widget.failurePreviewText.SetText) == "function" then
        widget.failurePreviewText:SetText(tostring(displayState.failurePreviewText or ""))
    end
    if widget.failurePreviewIcon and type(widget.failurePreviewIcon.SetTexture) == "function" then
        local texture = tostring(displayState.failurePreviewIcon or "")
        widget.failurePreviewIcon:SetTexture(texture ~= "" and texture or DEFAULT_ICON)
    end
end

local function applyActionContent(widget, slot, action, cellWidth)
    if type(slot) ~= "table" then
        return false
    end
    slot.actionId = type(action) == "table" and action.id or nil
    if slot.button then
        local icon = type(action) == "table" and action.icon or DEFAULT_ICON
        if type(slot.button.SetNormalTexture) == "function" then slot.button:SetNormalTexture(icon) end
        if type(slot.button.SetHighlightTexture) == "function" then slot.button:SetHighlightTexture(icon) end
        if type(slot.button.SetPushedTexture) == "function" then slot.button:SetPushedTexture(icon) end
        if type(slot.button.SetDisabledTexture) == "function" then slot.button:SetDisabledTexture(icon) end
        setShown(slot.button, true)
        if type(slot.button.SetEnabled) == "function" then
            slot.button:SetEnabled(type(action) == "table" and action.enabled ~= false and slot.actionId ~= nil)
        end
    end
    if slot.label and type(slot.label.SetText) == "function" then
        slot.label:SetText(tostring(type(action) == "table" and action.label or ""))
        if type(slot.label.SetWidth) == "function" then
            slot.label:SetWidth(cellWidth)
        end
        if type(slot.label.SetTextColor) == "function" and type(UI.ResolveColor) == "function" then
            local color = action and action.enabled ~= false
                and UI.ResolveColor(nil, "text.primary")
                or UI.ResolveColor(nil, "text.secondary")
            color = type(color) == "table" and color or {}
            slot.label:SetTextColor(color.r or 1, color.g or 1, color.b or 1, color.a or 1)
        end
    end
    setShown(slot.panel, true)
    return true
end

local function applyLayoutShape(widget, shape)
    if type(shape) ~= "table" then
        return false
    end
    if widget.lastReactionLayoutSignature == shape.signature then
        return false
    end

    local layout = widget.actionsLayout
    if layout and type(layout.SetOption) == "function" then
        layout:SetOption("columns", shape.columns)
        layout:SetOption("cellWidth", shape.cellWidth)
        layout:SetOption("cellHeight", tonumber(layout.options and layout.options.cellHeight) or 46)
        layout:SetOption("spacing", shape.spacing)
    elseif layout and type(layout.options) == "table" then
        layout.options.columns = shape.columns
        layout.options.cellWidth = shape.cellWidth
        layout.options.spacing = shape.spacing
    end

    if layout and type(layout.SetHeight) == "function" then
        layout:SetHeight(shape.actionsHeight)
    end

    for index = 1, math.min(shape.actionCount, #(widget.actionSlots or {})) do
        local slot = widget.actionSlots[index]
        if slot and type(slot.panel) == "table" and type(slot.panel.SetWidth) == "function" then
            slot.panel:SetWidth(shape.cellWidth)
        end
        if slot and type(slot.label) == "table" and type(slot.label.SetWidth) == "function" then
            slot.label:SetWidth(shape.cellWidth)
        end
    end

    setShown(widget.failurePreviewRow, shape.previewVisible)
    if widget.headerTextColumn and type(widget.headerTextColumn.RefreshLayout) == "function" then
        widget.headerTextColumn:RefreshLayout()
    end
    if widget.headerRow and type(widget.headerRow.RefreshLayout) == "function" then
        widget.headerRow:RefreshLayout()
    end
    if layout and type(layout.RefreshLayout) == "function" then
        layout:RefreshLayout()
    end
    if widget.rootLayout and type(widget.rootLayout.RefreshLayout) == "function" then
        widget.rootLayout:RefreshLayout()
    end

    widget.lastReactionLayoutSignature = shape.signature
    return true
end

local function isPresentationStateStale(state)
    local active = getActiveEntry()
    return type(state) ~= "table"
        or type(active) ~= "table"
        or active ~= state.entry
        or getCheckId(active) ~= tostring(state.checkId or "")
end

local function stepPresentation(state, deadlineMs)
    local widget = state.widget
    if type(widget) ~= "table" or isPresentationStateStale(state) then
        return true
    end

    while true do
        if state.phase == "build" then
            widget:Build()
            state.phase = "actions"
        elseif state.phase == "actions" then
            if type(Combat.BuildReactionActions) == "function" then
                Combat:BuildReactionActions(state.entry)
            end
            state.phase = "preview"
        elseif state.phase == "preview" then
            if type(Combat.BuildDamagePreview) == "function" then
                Combat:BuildDamagePreview(state.entry)
            end
            state.phase = "display"
        elseif state.phase == "display" then
            state.displayState = type(Client.GetReactionDisplayState) == "function"
                and Client:GetReactionDisplayState()
                or nil
            if type(state.displayState) ~= "table" then
                return true
            end
            state.layoutShape = resolveLayoutShape(widget, state.displayState)
            state.slotIndex = 1
            state.phase = "slots"
        elseif state.phase == "slots" then
            local actions = state.displayState.actions or {}
            if state.slotIndex <= #actions then
                widget:EnsureActionSlot(state.slotIndex)
                state.slotIndex = state.slotIndex + 1
            else
                state.phase = "portrait"
            end
        elseif state.phase == "portrait" then
            local signature = buildPortraitSignature(state.entry, state.displayState.attackerUnit)
            if widget.lastReactionPortraitSignature ~= signature
                and widget.portrait
                and type(widget.portrait.SetUnit) == "function"
            then
                widget.portrait:SetUnit(state.displayState.attackerUnit)
                widget.lastReactionPortraitSignature = signature
            end
            state.phase = "header"
        elseif state.phase == "header" then
            applyHeaderContent(widget, state.displayState)
            state.actionIndex = 1
            state.phase = "actions-content"
        elseif state.phase == "actions-content" then
            local actions = state.displayState.actions or {}
            if state.actionIndex <= #actions then
                local slot = widget.actionSlots[state.actionIndex]
                applyActionContent(widget, slot, actions[state.actionIndex], state.layoutShape.cellWidth)
                state.actionIndex = state.actionIndex + 1
            else
                state.hideIndex = #actions + 1
                state.phase = "hide-unused"
            end
        elseif state.phase == "hide-unused" then
            local slots = widget.actionSlots or {}
            if state.hideIndex <= #slots then
                local slot = slots[state.hideIndex]
                if slot then
                    slot.actionId = nil
                    setShown(slot.panel, false)
                end
                state.hideIndex = state.hideIndex + 1
            else
                state.phase = "layout"
            end
        elseif state.phase == "layout" then
            applyLayoutShape(widget, state.layoutShape)
            state.phase = "show"
        elseif state.phase == "show" then
            if isPresentationStateStale(state) then
                return true
            end
            if type(widget.Show) == "function" then
                widget:Show()
            end
            widget.presentedReactionCheckId = state.checkId
            return true
        else
            return true
        end

        if shouldYield(deadlineMs) then
            return false
        end
    end
end

function ReactionWidget:CancelQueuedPresentation(reason)
    local job = self.reactionPresentationJob
    self.reactionPresentationJob = nil
    self.reactionPresentationState = nil
    if type(job) == "table" and type(Tasks.Cancel) == "function" then
        return Tasks:Cancel(job, reason or "reaction-replaced")
    end
    return false
end

function ReactionWidget:QueueRefresh(reason)
    local entry = getActiveEntry()
    local checkId = getCheckId(entry)
    if type(entry) ~= "table" or checkId == "" then
        self:CancelQueuedPresentation("reaction-unavailable")
        if type(self.Hide) == "function" then
            self:Hide()
        end
        return false
    end

    local existingState = self.reactionPresentationState
    local existingJob = self.reactionPresentationJob
    if type(existingState) == "table"
        and existingState.entry == entry
        and tostring(existingState.checkId or "") == checkId
        and type(existingJob) == "table"
        and existingJob.completed ~= true
        and existingJob.cancelled ~= true
    then
        existingState.reason = reason or existingState.reason
        return existingJob
    end

    self:CancelQueuedPresentation("reaction-replaced")
    if type(Tasks.EnqueueSliceable) ~= "function" then
        return type(self.Refresh) == "function" and self:Refresh(reason) or false
    end

    local state = {
        widget = self,
        entry = entry,
        checkId = checkId,
        reason = reason,
        phase = "build",
        displayState = nil,
        layoutShape = nil,
        slotIndex = 1,
        actionIndex = 1,
        hideIndex = 1,
    }
    self.reactionPresentationState = state

    local job = Tasks:EnqueueSliceable({
        label = "Reaction presentation " .. checkId,
        scope = "reaction-presentation",
        state = state,
        isStale = function(presentationState)
            return isPresentationStateStale(presentationState)
        end,
        step = function(presentationState, deadlineMs)
            return stepPresentation(presentationState, deadlineMs)
        end,
        onCancel = function(presentationState, _, cancelledJob)
            if self.reactionPresentationJob == cancelledJob then
                self.reactionPresentationJob = nil
                self.reactionPresentationState = nil
            end
        end,
        onComplete = function(presentationState, completedJob)
            if self.reactionPresentationJob == completedJob then
                self.reactionPresentationJob = nil
                self.reactionPresentationState = nil
            end
        end,
    })
    self.reactionPresentationJob = job
    return job
end

function Client:QueueReactionWidgetRefresh(reason)
    return ReactionWidget:Get():QueueRefresh(reason)
end

function Client:CancelReactionWidgetRefresh(reason)
    return ReactionWidget:Get():CancelQueuedPresentation(reason)
end

-- Replace only the presentation scheduling boundary. Queue ownership, reaction
-- ordering, resolution, and combat semantics remain in client/combat/Reaction.lua.
if type(baseShowCombatReaction) == "function" then
    function Client:ShowCombatReaction(entry)
        if type(entry) ~= "table" then
            return false
        end
        if type(self.ActiveCombatReactionEntry) == "table" then
            return type(self.EnqueueCombatReaction) == "function" and self:EnqueueCombatReaction(entry) or false
        end
        if type(self.SetActiveCombatReaction) ~= "function" then
            return baseShowCombatReaction(self, entry)
        end

        self:SetActiveCombatReaction(entry)
        if type(self.QueueReactionWidgetRefresh) == "function" then
            self:QueueReactionWidgetRefresh("combat-hit-check")
        elseif type(self.RefreshReactionWidget) == "function" then
            self:RefreshReactionWidget("combat-hit-check")
        end
        return true
    end
end

if type(baseShowNextQueuedCombatReaction) == "function" then
    function Client:ShowNextQueuedCombatReaction()
        if type(self.DequeueCombatReaction) ~= "function" or type(self.SetActiveCombatReaction) ~= "function" then
            return baseShowNextQueuedCombatReaction(self)
        end
        local nextEntry = self:DequeueCombatReaction()
        if type(nextEntry) ~= "table" then
            return false
        end

        self:SetActiveCombatReaction(nextEntry)
        if type(self.QueueReactionWidgetRefresh) == "function" then
            self:QueueReactionWidgetRefresh("combat-hit-check-queue")
        elseif type(self.RefreshReactionWidget) == "function" then
            self:RefreshReactionWidget("combat-hit-check-queue")
        end
        return true
    end
end

if type(baseHideCombatReaction) == "function" then
    function Client:HideCombatReaction()
        local result = baseHideCombatReaction(self)
        if type(self.CancelReactionWidgetRefresh) == "function" then
            self:CancelReactionWidgetRefresh("reaction-hidden")
        end
        return result
    end
end

ReactionWidget._reactionPerformancePresentationInstalled = true
return true
