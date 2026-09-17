local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Client.UI = Addon.Client.UI or {}
Addon.Client.UI.Editor = Addon.Client.UI.Editor or {}

local DataEditor = Addon.Client.UI.Editor
local UI = Addon.UI or {}

function DataEditor:BuildAuraInspectorEventsPage(page)
    local function handleMouseWheel(_, delta)
        local _, maxValue = self.AuraInspectorEventsScrollBar:GetMinMaxValues()
        local current = self.AuraInspectorEventsScrollBar:GetValue() or 0
        local nextValue = math.max(0, math.min(maxValue or 0, current - ((delta or 0) * 24)))
        self.AuraInspectorEventsScrollBar:SetValue(nextValue)
    end

    local function attachMouseWheel(target)
        local frame = target and target.GetFrame and target:GetFrame() or target
        if not frame then
            return
        end

        if frame.EnableMouseWheel then
            frame:EnableMouseWheel(true)
        end

        if frame.HookScript then
            frame:HookScript("OnMouseWheel", handleMouseWheel)
        elseif frame.SetScript then
            frame:SetScript("OnMouseWheel", handleMouseWheel)
        end
    end

    self.AuraInspectorEventsScrollFrame = CreateFrame("ScrollFrame", "RPEDataEditorAuraInspectorEventsScrollFrame", page)
    self.AuraInspectorEventsScrollFrame:SetPoint("TOPLEFT", page, "TOPLEFT", 0, 0)
    self.AuraInspectorEventsScrollFrame:SetPoint("BOTTOMRIGHT", page, "BOTTOMRIGHT", -20, 0)
    self.AuraInspectorEventsScrollFrame:EnableMouseWheel(true)
    self.AuraInspectorEventsScrollFrame:SetClipsChildren(true)
    attachMouseWheel(page)
    attachMouseWheel(self.AuraInspectorEventsScrollFrame)

    self.AuraInspectorEventsScrollBar = CreateFrame("Slider", "RPEDataEditorAuraInspectorEventsScrollBar", page)
    self.AuraInspectorEventsScrollBar:SetPoint("TOPRIGHT", page, "TOPRIGHT", -4, -2)
    self.AuraInspectorEventsScrollBar:SetPoint("BOTTOMRIGHT", page, "BOTTOMRIGHT", -4, 2)
    self.AuraInspectorEventsScrollBar:SetOrientation("VERTICAL")
    self.AuraInspectorEventsScrollBar:SetMinMaxValues(0, 0)
    self.AuraInspectorEventsScrollBar:SetValueStep(12)
    if self.AuraInspectorEventsScrollBar.SetObeyStepOnDrag then
        self.AuraInspectorEventsScrollBar:SetObeyStepOnDrag(true)
    end
    self.AuraInspectorEventsScrollBar:SetWidth(12)

    self.AuraInspectorEventsScrollBarTrack = self.AuraInspectorEventsScrollBarTrack or self.AuraInspectorEventsScrollBar:CreateTexture(nil, "BACKGROUND")
    self.AuraInspectorEventsScrollBarTrack:SetAllPoints(self.AuraInspectorEventsScrollBar)
    local trackColor = UI.ResolveColor(nil, "scrollbar.track")
    self.AuraInspectorEventsScrollBarTrack:SetColorTexture(trackColor.r or 0.08, trackColor.g or 0.09, trackColor.b or 0.11, trackColor.a or 0.95)

    self.AuraInspectorEventsScrollBar:SetThumbTexture("Interface\\Buttons\\WHITE8x8")
    local thumb = self.AuraInspectorEventsScrollBar.GetThumbTexture and self.AuraInspectorEventsScrollBar:GetThumbTexture() or nil
    if thumb and thumb.SetVertexColor then
        local thumbColor = UI.ResolveColor(nil, "scrollbar.thumb")
        thumb:SetVertexColor(thumbColor.r or 0.42, thumbColor.g or 0.46, thumbColor.b or 0.52, thumbColor.a or 1)
    end
    self.AuraInspectorEventsScrollBar:SetValue(0)

    local root = UI.CreateLayout(UI.VerticalLayoutGroup, self.AuraInspectorEventsScrollFrame, "RPEDataEditorAuraInspectorEventsLayout", {
        spacing = 6,
        fitChildrenWidth = true,
        fitChildrenHeight = false,
        autoSize = true,
    })
    root:GetFrame():SetPoint("TOPLEFT", self.AuraInspectorEventsScrollFrame, "TOPLEFT", 0, 0)
    root:GetFrame():SetPoint("TOPRIGHT", self.AuraInspectorEventsScrollFrame, "TOPRIGHT", 0, 0)
    self.AuraInspectorEventsScrollFrame:SetScrollChild(root:GetFrame())

    self.AuraInspectorEventsScrollBar:SetScript("OnValueChanged", function(_, value)
        self.AuraInspectorEventsScrollFrame:SetVerticalScroll(value or 0)
    end)
    self.AuraInspectorEventsScrollFrame:SetScript("OnMouseWheel", handleMouseWheel)
    self.AuraInspectorEventsScrollFrame:SetScript("OnSizeChanged", function(scrollFrame)
        local width = math.max(1, (scrollFrame:GetWidth() or self.AuraInspectorFieldWidth) - 4)
        root:GetFrame():SetWidth(width)
        if root.RefreshLayout then
            root:RefreshLayout()
        end
    end)
    attachMouseWheel(root)

    self.AuraInspectorEventsRoot = root

    local function createGroup(name, labelText, height)
        local groupHeight = 12 + 2 + (height or self.AuraInspectorControlHeight)
        local group = UI.CreateLayout(UI.VerticalLayoutGroup, root:GetFrame(), name, {
            width = self.AuraInspectorFieldWidth,
            height = groupHeight,
            spacing = 2,
            fitChildrenWidth = true,
            fitChildrenHeight = false,
        })
        group._visibleHeight = groupHeight
        root:AddChild(group)
        local label = self:BuildAuraInspectorLabel(group:GetFrame(), name .. "Label", labelText)
        group:AddChild(label)
        attachMouseWheel(group)
        return group, label
    end

    root:AddChild(self:BuildAuraInspectorLabel(root:GetFrame(), "RPEDataEditorAuraInspectorEventsLabel", "Events"))

    self.AuraInspectorEventListPanel = UI.CreatePanel(root:GetFrame(), "RPEDataEditorAuraInspectorEventListPanel", {
        width = self.AuraInspectorFieldWidth,
        height = 92,
        contentInset = 1,
        showBorder = true,
    })
    root:AddChild(self.AuraInspectorEventListPanel)
    attachMouseWheel(self.AuraInspectorEventListPanel)

    self.AuraInspectorEventsScroll = UI.ScrollLayout:New({
        name = "RPEDataEditorAuraInspectorEventsScroll",
        width = self.AuraInspectorFieldWidth,
        height = 90,
        visibleRows = 5,
        rowHeight = 18,
        rowSpacing = 0,
        border = false,
        rowElementClass = UI.ScrollListEntry,
        categoryWidth = 130,
        statusWidth = 26,
        categoryInsetLeft = 4,
        statusInsetRight = 4,
    })
    self.AuraInspectorEventsScroll:SetParent(self.AuraInspectorEventListPanel:GetContentFrame())
    self.AuraInspectorEventsScroll:SetRowRenderer(function(row, item, itemIndex)
        if row.SetCategory then
            row:SetCategory(item and item.title or "")
        end
        if row.SetTestName then
            row:SetTestName("")
        end
        if row.SetStatus then
            row:SetStatus(item and item.statusText or "")
        end
        if row.SetDetail then
            row:SetDetail(item and item.detail or "")
        end

        local frame = row.GetFrame and row:GetFrame() or nil
        if frame then
            frame:EnableMouse(true)
            frame:SetScript("OnMouseUp", function(_, button)
                if button == "LeftButton" then
                    self:SetSelectedAuraInspectorEventIndex(itemIndex)
                    self.SelectedAuraEventEffectIndex = nil
                    self.SelectedAuraEventScalingIndex = nil
                    self:RefreshAuraInspectorPage()
                end
            end)

            local isSelected = tonumber(self.SelectedAuraEventIndex) == tonumber(itemIndex)
            if row.entryBackground and row.entryBackground.SetColorTexture then
                local token = isSelected and "list.rowHover" or "list.rowBackground"
                local color = UI.ResolveColor(nil, token)
                row.entryBackground:SetColorTexture(color.r or 0.08, color.g or 0.09, color.b or 0.11, color.a or 0.85)
            end
        end
    end)
    self.AuraInspectorEventsScroll:Create()
    UI.Utils.AnchorFill(self.AuraInspectorEventsScroll, self.AuraInspectorEventListPanel:GetContentFrame(), 0, 0, 0, 0)
    attachMouseWheel(self.AuraInspectorEventsScroll)

    self.AuraInspectorEventButtons = UI.CreateLayout(UI.HorizontalLayoutGroup, root:GetFrame(), "RPEDataEditorAuraInspectorEventButtons", {
        width = self.AuraInspectorFieldWidth,
        height = 18,
        spacing = 4,
        fitChildrenWidth = false,
        fitChildrenHeight = false,
    })
    root:AddChild(self.AuraInspectorEventButtons)
    attachMouseWheel(self.AuraInspectorEventButtons)

    self.AuraInspectorAddEventButton = UI.CreateButton(self.AuraInspectorEventButtons:GetFrame(), "RPEDataEditorAuraInspectorAddEventButton", "Add Event", 72, function()
        self:AddAuraEvent()
    end, {
        height = 18,
        fontSize = 7,
    })
    self.AuraInspectorEventButtons:AddChild(self.AuraInspectorAddEventButton)
    attachMouseWheel(self.AuraInspectorAddEventButton)

    self.AuraInspectorDeleteEventButton = UI.CreateButton(self.AuraInspectorEventButtons:GetFrame(), "RPEDataEditorAuraInspectorDeleteEventButton", "Delete Event", 78, function()
        self:RemoveSelectedAuraEvent()
    end, {
        height = 18,
        fontSize = 7,
    })
    self.AuraInspectorEventButtons:AddChild(self.AuraInspectorDeleteEventButton)
    attachMouseWheel(self.AuraInspectorDeleteEventButton)

    self.AuraInspectorSelectedEventHeader = UI.CreateText(root:GetFrame(), "RPEDataEditorAuraInspectorSelectedEventHeader", "Select an event to edit it.", {
        width = self.AuraInspectorFieldWidth,
        height = 12,
        justifyH = "LEFT",
        textColor = UI.ResolveColor(nil, "text.secondary"),
    })
    root:AddChild(self.AuraInspectorSelectedEventHeader)

    self.AuraInspectorCombatEventGroup = createGroup("RPEDataEditorAuraInspectorCombatEventGroup", "Combat Trigger", 18)
    self.AuraInspectorCombatEventDropdown = UI.CreateDropdown(self.AuraInspectorCombatEventGroup:GetFrame(), "RPEDataEditorAuraInspectorCombatEventDropdown", {
        width = self.AuraInspectorFieldWidth,
        height = 18,
        items = self:GetAuraInspectorCombatEventItems(),
        onValueChanged = function(value)
            if self._refreshingAuraInspector then
                return
            end

            self:CommitSelectedAuraInspectorEvent(function(auraEvent)
                auraEvent.combatEventId = value ~= "" and value or nil
                if auraEvent.combatEventId == nil then
                    auraEvent.triggerTarget = nil
                end
                self:NormalizeAuraInspectorEvent(auraEvent)
            end)
        end,
    })
    self.AuraInspectorCombatEventGroup:AddChild(self.AuraInspectorCombatEventDropdown)
    attachMouseWheel(self.AuraInspectorCombatEventDropdown)

    self.AuraInspectorDefenceStatGroup = createGroup("RPEDataEditorAuraInspectorDefenceStatGroup", "Defence Type", 18)
    self.AuraInspectorDefenceStatDropdown = UI.CreateDropdown(self.AuraInspectorDefenceStatGroup:GetFrame(), "RPEDataEditorAuraInspectorDefenceStatDropdown", {
        width = self.AuraInspectorFieldWidth,
        height = 18,
        items = self:BuildSpellInspectorDefenceStatsAcrossDatasets(),
        onValueChanged = function(value)
            if self._refreshingAuraInspector then
                return
            end
            self:CommitSelectedAuraInspectorEvent(function(auraEvent)
                auraEvent.defenceStatRef = value ~= "" and value or nil
                self:NormalizeAuraInspectorEvent(auraEvent)
            end)
        end,
    })
    self.AuraInspectorDefenceStatGroup:AddChild(self.AuraInspectorDefenceStatDropdown)
    attachMouseWheel(self.AuraInspectorDefenceStatDropdown)

    self.AuraInspectorTriggerTargetGroup = createGroup("RPEDataEditorAuraInspectorTriggerTargetGroup", "Trigger Target", 18)
    self.AuraInspectorTriggerTargetDropdown = UI.CreateDropdown(self.AuraInspectorTriggerTargetGroup:GetFrame(), "RPEDataEditorAuraInspectorTriggerTargetDropdown", {
        width = self.AuraInspectorFieldWidth,
        height = 18,
        items = self:GetAuraInspectorTriggerTargetItems(),
        onValueChanged = function(value)
            if self._refreshingAuraInspector then
                return
            end

            self:CommitSelectedAuraInspectorEvent(function(auraEvent)
                auraEvent.triggerTarget = value ~= "" and value or nil
                self:NormalizeAuraInspectorEvent(auraEvent)
            end)
        end,
    })
    self.AuraInspectorTriggerTargetGroup:AddChild(self.AuraInspectorTriggerTargetDropdown)
    attachMouseWheel(self.AuraInspectorTriggerTargetDropdown)

    self.AuraInspectorEventChanceGroup = createGroup("RPEDataEditorAuraInspectorEventChanceGroup", "Trigger Chance %", 18)
    self.AuraInspectorEventChanceInput = UI.CreateTextInput(self.AuraInspectorEventChanceGroup:GetFrame(), "RPEDataEditorAuraInspectorEventChanceInput", {
        width = self.AuraInspectorFieldWidth,
        height = self.AuraInspectorControlHeight,
        text = "100",
        borderColor = UI.ResolveColor(nil, "panel.border"),
    })
    self.AuraInspectorEventChanceGroup:AddChild(self.AuraInspectorEventChanceInput)
    attachMouseWheel(self.AuraInspectorEventChanceInput)

    self.AuraInspectorSelectedEventEffectHeader = UI.CreateText(root:GetFrame(), "RPEDataEditorAuraInspectorSelectedEventEffectHeader", "Select an event effect to edit it.", {
        width = self.AuraInspectorFieldWidth,
        height = 12,
        justifyH = "LEFT",
        textColor = UI.ResolveColor(nil, "text.secondary"),
    })
    root:AddChild(self.AuraInspectorSelectedEventEffectHeader)

    self.AuraInspectorEventEffectsPanel = UI.CreatePanel(root:GetFrame(), "RPEDataEditorAuraInspectorEventEffectsPanel", {
        width = self.AuraInspectorFieldWidth,
        height = 92,
        contentInset = 1,
        showBorder = true,
    })
    root:AddChild(self.AuraInspectorEventEffectsPanel)
    attachMouseWheel(self.AuraInspectorEventEffectsPanel)

    self.AuraInspectorEventEffectsScroll = UI.ScrollLayout:New({
        name = "RPEDataEditorAuraInspectorEventEffectsScroll",
        width = self.AuraInspectorFieldWidth,
        height = 90,
        visibleRows = 5,
        rowHeight = 18,
        rowSpacing = 0,
        border = false,
        rowElementClass = UI.ScrollListEntry,
        categoryWidth = 110,
        statusWidth = 44,
        categoryInsetLeft = 4,
        statusInsetRight = 4,
    })
    self.AuraInspectorEventEffectsScroll:SetParent(self.AuraInspectorEventEffectsPanel:GetContentFrame())
    self.AuraInspectorEventEffectsScroll:SetRowRenderer(function(row, item, itemIndex)
        if row.SetCategory then
            row:SetCategory(item and item.title or "")
        end
        if row.SetTestName then
            row:SetTestName("")
        end
        if row.SetStatus then
            row:SetStatus(item and item.statusText or "")
        end
        if row.SetDetail then
            row:SetDetail(item and item.detail or "")
        end

        local frame = row.GetFrame and row:GetFrame() or nil
        if frame then
            frame:EnableMouse(true)
            frame:SetScript("OnMouseUp", function(_, button)
                if button == "LeftButton" then
                    self:SetSelectedAuraInspectorEventEffectIndex(itemIndex)
                    self.SelectedAuraEventScalingIndex = nil
                    self:RefreshAuraInspectorPage()
                end
            end)

            local isSelected = tonumber(self.SelectedAuraEventEffectIndex) == tonumber(itemIndex)
            if row.entryBackground and row.entryBackground.SetColorTexture then
                local token = isSelected and "list.rowHover" or "list.rowBackground"
                local color = UI.ResolveColor(nil, token)
                row.entryBackground:SetColorTexture(color.r or 0.08, color.g or 0.09, color.b or 0.11, color.a or 0.85)
            end
        end
    end)
    self.AuraInspectorEventEffectsScroll:Create()
    UI.Utils.AnchorFill(self.AuraInspectorEventEffectsScroll, self.AuraInspectorEventEffectsPanel:GetContentFrame(), 0, 0, 0, 0)
    attachMouseWheel(self.AuraInspectorEventEffectsScroll)

    self.AuraInspectorEventEffectButtons = UI.CreateLayout(UI.HorizontalLayoutGroup, root:GetFrame(), "RPEDataEditorAuraInspectorEventEffectButtons", {
        width = self.AuraInspectorFieldWidth,
        height = 18,
        spacing = 4,
        fitChildrenWidth = false,
        fitChildrenHeight = false,
    })
    root:AddChild(self.AuraInspectorEventEffectButtons)
    attachMouseWheel(self.AuraInspectorEventEffectButtons)

    self.AuraInspectorAddEventEffectButton = UI.CreateButton(self.AuraInspectorEventEffectButtons:GetFrame(), "RPEDataEditorAuraInspectorAddEventEffectButton", "Add Effect", 72, function()
        self:AddAuraEventEffect()
    end, {
        height = 18,
        fontSize = 7,
    })
    self.AuraInspectorEventEffectButtons:AddChild(self.AuraInspectorAddEventEffectButton)
    attachMouseWheel(self.AuraInspectorAddEventEffectButton)

    self.AuraInspectorDeleteEventEffectButton = UI.CreateButton(self.AuraInspectorEventEffectButtons:GetFrame(), "RPEDataEditorAuraInspectorDeleteEventEffectButton", "Delete Effect", 78, function()
        self:RemoveSelectedAuraEventEffect()
    end, {
        height = 18,
        fontSize = 7,
    })
    self.AuraInspectorEventEffectButtons:AddChild(self.AuraInspectorDeleteEventEffectButton)
    attachMouseWheel(self.AuraInspectorDeleteEventEffectButton)

    self.AuraInspectorEventEffectTypeGroup = createGroup("RPEDataEditorAuraInspectorEventEffectTypeGroup", "Effect Type", 18)
    self.AuraInspectorEventEffectTypeDropdown = UI.CreateDropdown(self.AuraInspectorEventEffectTypeGroup:GetFrame(), "RPEDataEditorAuraInspectorEventEffectTypeDropdown", {
        width = self.AuraInspectorFieldWidth,
        height = 18,
        items = self:GetAuraInspectorEventEffectTypeItems(),
        onValueChanged = function(value)
            if self._refreshingAuraInspector then
                return
            end

            self:CommitSelectedAuraInspectorEventEffect(function(effect)
                effect.type = value
                self:NormalizeAuraInspectorEventEffect(effect)
            end)
        end,
    })
    self.AuraInspectorEventEffectTypeGroup:AddChild(self.AuraInspectorEventEffectTypeDropdown)
    attachMouseWheel(self.AuraInspectorEventEffectTypeDropdown)

    self.AuraInspectorEventBaseAmountGroup, self.AuraInspectorEventBaseAmountLabel = createGroup("RPEDataEditorAuraInspectorEventBaseAmountGroup", "Base Damage")
    self.AuraInspectorEventBaseAmountInput = UI.CreateTextInput(self.AuraInspectorEventBaseAmountGroup:GetFrame(), "RPEDataEditorAuraInspectorEventBaseAmountInput", {
        width = self.AuraInspectorFieldWidth,
        height = self.AuraInspectorControlHeight,
        text = "0",
        borderColor = UI.ResolveColor(nil, "panel.border"),
    })
    self.AuraInspectorEventBaseAmountGroup:AddChild(self.AuraInspectorEventBaseAmountInput)
    attachMouseWheel(self.AuraInspectorEventBaseAmountInput)

    self.AuraInspectorEventAmountModeGroup = createGroup("RPEDataEditorAuraInspectorEventAmountModeGroup", "Amount Mode")
    self.AuraInspectorEventAmountModeDropdown = UI.CreateDropdown(self.AuraInspectorEventAmountModeGroup:GetFrame(), "RPEDataEditorAuraInspectorEventAmountModeDropdown", {
        width = self.AuraInspectorFieldWidth,
        height = 18,
        items = self:GetAuraInspectorAmountModeItems(),
        onValueChanged = function(value)
            if self._refreshingAuraInspector then
                return
            end

            self:CommitSelectedAuraInspectorEventEffect(function(effect)
                effect.amountMode = value
            end)
        end,
    })
    self.AuraInspectorEventAmountModeGroup:AddChild(self.AuraInspectorEventAmountModeDropdown)
    attachMouseWheel(self.AuraInspectorEventAmountModeDropdown)

    self.AuraInspectorEventDamageSchoolsGroup = createGroup("RPEDataEditorAuraInspectorEventDamageSchoolsGroup", "Damage Schools", 18)
    self.AuraInspectorEventDamageSchoolsDropdown = UI.CreateDropdown(self.AuraInspectorEventDamageSchoolsGroup:GetFrame(), "RPEDataEditorAuraInspectorEventDamageSchoolsDropdown", {
        width = self.AuraInspectorFieldWidth,
        height = 18,
        multiSelect = true,
        items = self:BuildSpellInspectorDamageSchoolsAcrossDatasets(),
        onValueChanged = function()
            if self._refreshingAuraInspector then
                return
            end

            self:CommitSelectedAuraInspectorEventEffect(function(effect)
                effect.damageSchoolRefs = self.AuraInspectorEventDamageSchoolsDropdown:GetSelectedValues()
            end)
        end,
    })
    self.AuraInspectorEventDamageSchoolsGroup:AddChild(self.AuraInspectorEventDamageSchoolsDropdown)
    attachMouseWheel(self.AuraInspectorEventDamageSchoolsDropdown)

    self.AuraInspectorEventAuraGroup = createGroup("RPEDataEditorAuraInspectorEventAuraGroup", "Aura", 18)
    self.AuraInspectorEventAuraDropdown = UI.CreateDropdown(self.AuraInspectorEventAuraGroup:GetFrame(), "RPEDataEditorAuraInspectorEventAuraDropdown", {
        width = self.AuraInspectorFieldWidth,
        height = 18,
        items = self:BuildSpellInspectorAurasAcrossDatasets(),
        onValueChanged = function(value)
            if self._refreshingAuraInspector then
                return
            end

            self:CommitSelectedAuraInspectorEventEffect(function(effect)
                effect.auraRef = value ~= "" and value or nil
            end)
        end,
    })
    self.AuraInspectorEventAuraGroup:AddChild(self.AuraInspectorEventAuraDropdown)
    attachMouseWheel(self.AuraInspectorEventAuraDropdown)

    self.AuraInspectorEventAuraStacksGroup = createGroup("RPEDataEditorAuraInspectorEventAuraStacksGroup", "Aura Stacks", 18)
    self.AuraInspectorEventAuraStacksInput = UI.CreateTextInput(self.AuraInspectorEventAuraStacksGroup:GetFrame(), "RPEDataEditorAuraInspectorEventAuraStacksInput", {
        width = self.AuraInspectorFieldWidth,
        height = self.AuraInspectorControlHeight,
        text = "1",
        borderColor = UI.ResolveColor(nil, "panel.border"),
    })
    self.AuraInspectorEventAuraStacksGroup:AddChild(self.AuraInspectorEventAuraStacksInput)
    attachMouseWheel(self.AuraInspectorEventAuraStacksInput)

    self.AuraInspectorEventAuraDurationGroup = createGroup("RPEDataEditorAuraInspectorEventAuraDurationGroup", "Aura Duration", 18)
    self.AuraInspectorEventAuraDurationInput = UI.CreateTextInput(self.AuraInspectorEventAuraDurationGroup:GetFrame(), "RPEDataEditorAuraInspectorEventAuraDurationInput", {
        width = self.AuraInspectorFieldWidth,
        height = self.AuraInspectorControlHeight,
        text = "12",
        borderColor = UI.ResolveColor(nil, "panel.border"),
    })
    self.AuraInspectorEventAuraDurationGroup:AddChild(self.AuraInspectorEventAuraDurationInput)
    attachMouseWheel(self.AuraInspectorEventAuraDurationInput)

    self.AuraInspectorEventBasePowerGroup = createGroup("RPEDataEditorAuraInspectorEventBasePowerGroup", "Base Power", 18)
    self.AuraInspectorEventBasePowerInput = UI.CreateTextInput(self.AuraInspectorEventBasePowerGroup:GetFrame(), "RPEDataEditorAuraInspectorEventBasePowerInput", {
        width = self.AuraInspectorFieldWidth,
        height = self.AuraInspectorControlHeight,
        text = "0",
        borderColor = UI.ResolveColor(nil, "panel.border"),
    })
    self.AuraInspectorEventBasePowerGroup:AddChild(self.AuraInspectorEventBasePowerInput)
    attachMouseWheel(self.AuraInspectorEventBasePowerInput)

    self.AuraInspectorEventResourceGroup = createGroup("RPEDataEditorAuraInspectorEventResourceGroup", "Resource", 18)
    self.AuraInspectorEventResourceDropdown = UI.CreateDropdown(self.AuraInspectorEventResourceGroup:GetFrame(), "RPEDataEditorAuraInspectorEventResourceDropdown", {
        width = self.AuraInspectorFieldWidth,
        height = 18,
        items = self:BuildSpellInspectorResourcesAcrossDatasets(),
        onValueChanged = function(value)
            if self._refreshingAuraInspector then
                return
            end

            self:CommitSelectedAuraInspectorEventEffect(function(effect)
                effect.resourceRef = value ~= "" and value or nil
            end)
        end,
    })
    self.AuraInspectorEventResourceGroup:AddChild(self.AuraInspectorEventResourceDropdown)
    attachMouseWheel(self.AuraInspectorEventResourceDropdown)

    self.AuraInspectorEventResourceAmountGroup = createGroup("RPEDataEditorAuraInspectorEventResourceAmountGroup", "Resource Amount", 18)
    self.AuraInspectorEventResourceAmountInput = UI.CreateTextInput(self.AuraInspectorEventResourceAmountGroup:GetFrame(), "RPEDataEditorAuraInspectorEventResourceAmountInput", {
        width = self.AuraInspectorFieldWidth,
        height = self.AuraInspectorControlHeight,
        text = "0",
        borderColor = UI.ResolveColor(nil, "panel.border"),
    })
    self.AuraInspectorEventResourceAmountGroup:AddChild(self.AuraInspectorEventResourceAmountInput)
    attachMouseWheel(self.AuraInspectorEventResourceAmountInput)

    self.AuraInspectorEventResourceAmountModeGroup = createGroup("RPEDataEditorAuraInspectorEventResourceAmountModeGroup", "Amount Mode")
    self.AuraInspectorEventResourceAmountModeDropdown = UI.CreateDropdown(self.AuraInspectorEventResourceAmountModeGroup:GetFrame(), "RPEDataEditorAuraInspectorEventResourceAmountModeDropdown", {
        width = self.AuraInspectorFieldWidth,
        height = 18,
        items = self:GetAuraInspectorAmountModeItems(),
        onValueChanged = function(value)
            if self._refreshingAuraInspector then
                return
            end

            self:CommitSelectedAuraInspectorEventEffect(function(effect)
                effect.amountMode = value
            end)
        end,
    })
    self.AuraInspectorEventResourceAmountModeGroup:AddChild(self.AuraInspectorEventResourceAmountModeDropdown)
    attachMouseWheel(self.AuraInspectorEventResourceAmountModeDropdown)

    self.AuraInspectorEventScalingGroup = createGroup("RPEDataEditorAuraInspectorEventScalingGroup", "Stat Scaling", 110)
    self.AuraInspectorEventScalingPanel = UI.CreatePanel(self.AuraInspectorEventScalingGroup:GetFrame(), "RPEDataEditorAuraInspectorEventScalingPanel", {
        width = self.AuraInspectorFieldWidth,
        height = 74,
        contentInset = 1,
        showBorder = true,
    })
    self.AuraInspectorEventScalingGroup:AddChild(self.AuraInspectorEventScalingPanel)
    attachMouseWheel(self.AuraInspectorEventScalingPanel)

    self.AuraInspectorEventScalingScroll = UI.ScrollLayout:New({
        name = "RPEDataEditorAuraInspectorEventScalingScroll",
        width = self.AuraInspectorFieldWidth,
        height = 72,
        visibleRows = 4,
        rowHeight = 18,
        rowSpacing = 0,
        border = false,
        rowElementClass = UI.ScrollListEntry,
        categoryWidth = 150,
        statusWidth = 40,
        categoryInsetLeft = 4,
        statusInsetRight = 4,
    })
    self.AuraInspectorEventScalingScroll:SetParent(self.AuraInspectorEventScalingPanel:GetContentFrame())
    self.AuraInspectorEventScalingScroll:SetRowRenderer(function(row, item, itemIndex)
        if row.SetCategory then
            row:SetCategory(item and item.title or "")
        end
        if row.SetTestName then
            row:SetTestName("")
        end
        if row.SetStatus then
            row:SetStatus(item and item.statusText or "")
        end
        if row.SetDetail then
            row:SetDetail(item and item.detail or "")
        end

        local frame = row.GetFrame and row:GetFrame() or nil
        if frame then
            frame:EnableMouse(true)
            frame:SetScript("OnMouseUp", function(_, button)
                if button == "LeftButton" then
                    self.SelectedAuraEventScalingIndex = itemIndex
                    self:RefreshAuraInspectorPage()
                end
            end)

            local isSelected = tonumber(self.SelectedAuraEventScalingIndex) == tonumber(itemIndex)
            if row.entryBackground and row.entryBackground.SetColorTexture then
                local token = isSelected and "list.rowHover" or "list.rowBackground"
                local color = UI.ResolveColor(nil, token)
                row.entryBackground:SetColorTexture(color.r or 0.08, color.g or 0.09, color.b or 0.11, color.a or 0.85)
            end
        end
    end)
    self.AuraInspectorEventScalingScroll:Create()
    UI.Utils.AnchorFill(self.AuraInspectorEventScalingScroll, self.AuraInspectorEventScalingPanel:GetContentFrame(), 0, 0, 0, 0)
    attachMouseWheel(self.AuraInspectorEventScalingScroll)

    self.AuraInspectorPendingEventScalingRow = UI.CreateLayout(UI.HorizontalLayoutGroup, self.AuraInspectorEventScalingGroup:GetFrame(), "RPEDataEditorAuraInspectorPendingEventScalingRow", {
        width = self.AuraInspectorFieldWidth,
        height = 18,
        spacing = 2,
        fitChildrenWidth = false,
        fitChildrenHeight = false,
    })
    self.AuraInspectorEventScalingGroup:AddChild(self.AuraInspectorPendingEventScalingRow)
    attachMouseWheel(self.AuraInspectorPendingEventScalingRow)

    self.AuraInspectorPendingEventScalingStatDropdown = UI.CreateDropdown(self.AuraInspectorPendingEventScalingRow:GetFrame(), "RPEDataEditorAuraInspectorPendingEventScalingStatDropdown", {
        width = 146,
        height = 18,
        items = self:BuildSpellInspectorStatsAcrossDatasets(),
    })
    self.AuraInspectorPendingEventScalingRow:AddChild(self.AuraInspectorPendingEventScalingStatDropdown)
    attachMouseWheel(self.AuraInspectorPendingEventScalingStatDropdown)

    self.AuraInspectorPendingEventScalingCoefficientInput = UI.CreateTextInput(self.AuraInspectorPendingEventScalingRow:GetFrame(), "RPEDataEditorAuraInspectorPendingEventScalingCoefficientInput", {
        width = 44,
        height = 18,
        text = "0",
        borderColor = UI.ResolveColor(nil, "panel.border"),
    })
    self.AuraInspectorPendingEventScalingRow:AddChild(self.AuraInspectorPendingEventScalingCoefficientInput)
    attachMouseWheel(self.AuraInspectorPendingEventScalingCoefficientInput)

    self.AuraInspectorAddEventScalingButton = UI.CreateButton(self.AuraInspectorPendingEventScalingRow:GetFrame(), "RPEDataEditorAuraInspectorAddEventScalingButton", "Add", 36, function()
        local effect = self:GetSelectedAuraInspectorEventEffect()
        if not effect then
            return
        end

        local statRef = self.AuraInspectorPendingEventScalingStatDropdown and self.AuraInspectorPendingEventScalingStatDropdown.GetSelectedValue and self.AuraInspectorPendingEventScalingStatDropdown:GetSelectedValue() or ""
        if statRef == "" then
            return
        end

        local coefficient = tonumber(self.AuraInspectorPendingEventScalingCoefficientInput and self.AuraInspectorPendingEventScalingCoefficientInput:GetText()) or 0
        self:CommitSelectedAuraInspectorEventEffect(function(selectedEffect)
            selectedEffect.statScaling = selectedEffect.statScaling or {}
            selectedEffect.statScaling[#selectedEffect.statScaling + 1] = {
                statRef = statRef,
                coefficient = coefficient,
            }
            self.SelectedAuraEventScalingIndex = #selectedEffect.statScaling
        end)
    end, {
        height = 18,
        fontSize = 7,
    })
    self.AuraInspectorPendingEventScalingRow:AddChild(self.AuraInspectorAddEventScalingButton)
    attachMouseWheel(self.AuraInspectorAddEventScalingButton)

    self.AuraInspectorDeleteEventScalingButton = UI.CreateButton(self.AuraInspectorPendingEventScalingRow:GetFrame(), "RPEDataEditorAuraInspectorDeleteEventScalingButton", "Delete", 44, function()
        local effect = self:GetSelectedAuraInspectorEventEffect()
        local scalingIndex = tonumber(self.SelectedAuraEventScalingIndex) or 0
        if not effect or scalingIndex <= 0 or type(effect.statScaling) ~= "table" or not effect.statScaling[scalingIndex] then
            return
        end

        self:CommitSelectedAuraInspectorEventEffect(function(selectedEffect)
            table.remove(selectedEffect.statScaling, scalingIndex)
            if #(selectedEffect.statScaling or {}) > 0 then
                self.SelectedAuraEventScalingIndex = math.min(scalingIndex, #selectedEffect.statScaling)
            else
                self.SelectedAuraEventScalingIndex = nil
            end
        end)
    end, {
        height = 18,
        fontSize = 7,
    })
    self.AuraInspectorPendingEventScalingRow:AddChild(self.AuraInspectorDeleteEventScalingButton)
    attachMouseWheel(self.AuraInspectorDeleteEventScalingButton)

    local function bindInput(fieldName, callback)
        self[fieldName]:SetScript("OnEnterPressed", callback)
        self[fieldName]:SetScript("OnEditFocusLost", callback)
    end

    bindInput("AuraInspectorEventBaseAmountInput", function()
        self:CommitSelectedAuraInspectorEventEffect(function(effect)
            local amount = tonumber(self.AuraInspectorEventBaseAmountInput:GetText()) or 0
            if tostring(effect.type or "damage") == "heal" then
                effect.baseHealing = amount
            else
                effect.baseDamage = amount
            end
        end)
    end)
    bindInput("AuraInspectorEventAuraStacksInput", function()
        self:CommitSelectedAuraInspectorEventEffect(function(effect)
            effect.stacks = math.max(1, math.floor(tonumber(self.AuraInspectorEventAuraStacksInput:GetText()) or 1))
        end)
    end)
    bindInput("AuraInspectorEventAuraDurationInput", function()
        self:CommitSelectedAuraInspectorEventEffect(function(effect)
            effect.duration = math.max(1, math.floor(tonumber(self.AuraInspectorEventAuraDurationInput:GetText()) or 12))
        end)
    end)
    bindInput("AuraInspectorEventBasePowerInput", function()
        self:CommitSelectedAuraInspectorEventEffect(function(effect)
            effect.basePower = tonumber(self.AuraInspectorEventBasePowerInput:GetText()) or 0
        end)
    end)
    bindInput("AuraInspectorEventResourceAmountInput", function()
        self:CommitSelectedAuraInspectorEventEffect(function(effect)
            effect.amount = tonumber(self.AuraInspectorEventResourceAmountInput:GetText()) or 0
        end)
    end)
    bindInput("AuraInspectorEventChanceInput", function()
        self:CommitSelectedAuraInspectorEvent(function(auraEvent)
            auraEvent.chance = tonumber(self.AuraInspectorEventChanceInput:GetText()) or 100
            self:NormalizeAuraInspectorEvent(auraEvent)
        end)
    end)

    local function refreshScrollBounds()
        local frame = root:GetFrame()
        local viewportHeight = self.AuraInspectorEventsScrollFrame and self.AuraInspectorEventsScrollFrame:GetHeight() or 0
        local contentHeight = frame and frame:GetHeight() or 0
        local maxScroll = math.max(0, math.floor(contentHeight - viewportHeight + 0.5))
        self.AuraInspectorEventsScrollBar:SetMinMaxValues(0, maxScroll)
        if self.AuraInspectorEventsScrollBar.SetShown then
            self.AuraInspectorEventsScrollBar:SetShown(maxScroll > 0)
        elseif maxScroll > 0 and self.AuraInspectorEventsScrollBar.Show then
            self.AuraInspectorEventsScrollBar:Show()
        elseif self.AuraInspectorEventsScrollBar.Hide then
            self.AuraInspectorEventsScrollBar:Hide()
        end
        if (self.AuraInspectorEventsScrollBar:GetValue() or 0) > maxScroll then
            self.AuraInspectorEventsScrollBar:SetValue(maxScroll)
        end
    end

    self.RefreshAuraInspectorEventsScrollBounds = refreshScrollBounds
    root:GetFrame():SetScript("OnSizeChanged", refreshScrollBounds)
    self.AuraInspectorEventsScrollFrame:SetScript("OnShow", refreshScrollBounds)
    refreshScrollBounds()
end
