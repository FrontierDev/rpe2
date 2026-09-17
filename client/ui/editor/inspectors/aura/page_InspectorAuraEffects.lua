local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Client.UI = Addon.Client.UI or {}
Addon.Client.UI.Editor = Addon.Client.UI.Editor or {}

local DataEditor = Addon.Client.UI.Editor
local UI = Addon.UI or {}

function DataEditor:BuildAuraInspectorEffectsPage(page)
    local function handleMouseWheel(_, delta)
        local _, maxValue = self.AuraInspectorEffectsScrollBar:GetMinMaxValues()
        local current = self.AuraInspectorEffectsScrollBar:GetValue() or 0
        local nextValue = math.max(0, math.min(maxValue or 0, current - ((delta or 0) * 24)))
        self.AuraInspectorEffectsScrollBar:SetValue(nextValue)
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

    self.AuraInspectorEffectsScrollFrame = CreateFrame("ScrollFrame", "RPEDataEditorAuraInspectorEffectsScrollFrame", page)
    self.AuraInspectorEffectsScrollFrame:SetPoint("TOPLEFT", page, "TOPLEFT", 0, 0)
    self.AuraInspectorEffectsScrollFrame:SetPoint("BOTTOMRIGHT", page, "BOTTOMRIGHT", -20, 0)
    self.AuraInspectorEffectsScrollFrame:EnableMouseWheel(true)
    self.AuraInspectorEffectsScrollFrame:SetClipsChildren(true)
    attachMouseWheel(page)
    attachMouseWheel(self.AuraInspectorEffectsScrollFrame)

    self.AuraInspectorEffectsScrollBar = CreateFrame("Slider", "RPEDataEditorAuraInspectorEffectsScrollBar", page)
    self.AuraInspectorEffectsScrollBar:SetPoint("TOPRIGHT", page, "TOPRIGHT", -4, -2)
    self.AuraInspectorEffectsScrollBar:SetPoint("BOTTOMRIGHT", page, "BOTTOMRIGHT", -4, 2)
    self.AuraInspectorEffectsScrollBar:SetOrientation("VERTICAL")
    self.AuraInspectorEffectsScrollBar:SetMinMaxValues(0, 0)
    self.AuraInspectorEffectsScrollBar:SetValueStep(12)
    if self.AuraInspectorEffectsScrollBar.SetObeyStepOnDrag then
        self.AuraInspectorEffectsScrollBar:SetObeyStepOnDrag(true)
    end
    self.AuraInspectorEffectsScrollBar:SetWidth(12)

    self.AuraInspectorEffectsScrollBarTrack = self.AuraInspectorEffectsScrollBarTrack or self.AuraInspectorEffectsScrollBar:CreateTexture(nil, "BACKGROUND")
    self.AuraInspectorEffectsScrollBarTrack:SetAllPoints(self.AuraInspectorEffectsScrollBar)
    local trackColor = UI.ResolveColor(nil, "scrollbar.track")
    self.AuraInspectorEffectsScrollBarTrack:SetColorTexture(trackColor.r or 0.08, trackColor.g or 0.09, trackColor.b or 0.11, trackColor.a or 0.95)

    self.AuraInspectorEffectsScrollBar:SetThumbTexture("Interface\\Buttons\\WHITE8x8")
    local thumb = self.AuraInspectorEffectsScrollBar.GetThumbTexture and self.AuraInspectorEffectsScrollBar:GetThumbTexture() or nil
    if thumb and thumb.SetVertexColor then
        local thumbColor = UI.ResolveColor(nil, "scrollbar.thumb")
        thumb:SetVertexColor(thumbColor.r or 0.42, thumbColor.g or 0.46, thumbColor.b or 0.52, thumbColor.a or 1)
    end
    self.AuraInspectorEffectsScrollBar:SetValue(0)

    local root = UI.CreateLayout(UI.VerticalLayoutGroup, self.AuraInspectorEffectsScrollFrame, "RPEDataEditorAuraInspectorEffectsLayout", {
        spacing = 6,
        fitChildrenWidth = true,
        fitChildrenHeight = false,
        autoSize = true,
    })
    root:GetFrame():SetPoint("TOPLEFT", self.AuraInspectorEffectsScrollFrame, "TOPLEFT", 0, 0)
    root:GetFrame():SetPoint("TOPRIGHT", self.AuraInspectorEffectsScrollFrame, "TOPRIGHT", 0, 0)
    self.AuraInspectorEffectsScrollFrame:SetScrollChild(root:GetFrame())

    self.AuraInspectorEffectsScrollBar:SetScript("OnValueChanged", function(_, value)
        self.AuraInspectorEffectsScrollFrame:SetVerticalScroll(value or 0)
    end)
    self.AuraInspectorEffectsScrollFrame:SetScript("OnMouseWheel", handleMouseWheel)
    self.AuraInspectorEffectsScrollFrame:SetScript("OnSizeChanged", function(scrollFrame)
        local width = math.max(1, (scrollFrame:GetWidth() or self.AuraInspectorFieldWidth) - 4)
        root:GetFrame():SetWidth(width)
        if root.RefreshLayout then
            root:RefreshLayout()
        end
    end)
    attachMouseWheel(root)

    self.AuraInspectorEffectsRoot = root

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

    root:AddChild(self:BuildAuraInspectorLabel(root:GetFrame(), "RPEDataEditorAuraInspectorEffectsLabel", "Effects"))

    self.AuraInspectorEffectsPanel = UI.CreatePanel(root:GetFrame(), "RPEDataEditorAuraInspectorEffectsPanel", {
        width = self.AuraInspectorFieldWidth,
        height = 92,
        contentInset = 1,
        showBorder = true,
    })
    root:AddChild(self.AuraInspectorEffectsPanel)
    attachMouseWheel(self.AuraInspectorEffectsPanel)

    self.AuraInspectorEffectsScroll = UI.ScrollLayout:New({
        name = "RPEDataEditorAuraInspectorEffectsScroll",
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
    self.AuraInspectorEffectsScroll:SetParent(self.AuraInspectorEffectsPanel:GetContentFrame())
    self.AuraInspectorEffectsScroll:SetRowRenderer(function(row, item, itemIndex)
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
                    self:SetSelectedAuraInspectorEffectIndex(itemIndex)
                    self.SelectedAuraScalingIndex = nil
                    self:RefreshAuraInspectorPage()
                end
            end)

            local isSelected = tonumber(self.SelectedAuraEffectIndex) == tonumber(itemIndex)
            if row.entryBackground and row.entryBackground.SetColorTexture then
                local token = isSelected and "list.rowHover" or "list.rowBackground"
                local color = UI.ResolveColor(nil, token)
                row.entryBackground:SetColorTexture(color.r or 0.08, color.g or 0.09, color.b or 0.11, color.a or 0.85)
            end
        end
    end)
    self.AuraInspectorEffectsScroll:Create()
    UI.Utils.AnchorFill(self.AuraInspectorEffectsScroll, self.AuraInspectorEffectsPanel:GetContentFrame(), 0, 0, 0, 0)
    attachMouseWheel(self.AuraInspectorEffectsScroll)

    self.AuraInspectorEffectButtons = UI.CreateLayout(UI.HorizontalLayoutGroup, root:GetFrame(), "RPEDataEditorAuraInspectorEffectButtons", {
        width = self.AuraInspectorFieldWidth,
        height = 18,
        spacing = 4,
        fitChildrenWidth = false,
        fitChildrenHeight = false,
    })
    root:AddChild(self.AuraInspectorEffectButtons)
    attachMouseWheel(self.AuraInspectorEffectButtons)

    self.AuraInspectorAddEffectButton = UI.CreateButton(self.AuraInspectorEffectButtons:GetFrame(), "RPEDataEditorAuraInspectorAddEffectButton", "Add Effect", 72, function()
        self:AddAuraEffect()
    end, {
        height = 18,
        fontSize = 7,
    })
    self.AuraInspectorEffectButtons:AddChild(self.AuraInspectorAddEffectButton)
    attachMouseWheel(self.AuraInspectorAddEffectButton)

    self.AuraInspectorDeleteEffectButton = UI.CreateButton(self.AuraInspectorEffectButtons:GetFrame(), "RPEDataEditorAuraInspectorDeleteEffectButton", "Delete Effect", 78, function()
        self:RemoveSelectedAuraEffect()
    end, {
        height = 18,
        fontSize = 7,
    })
    self.AuraInspectorEffectButtons:AddChild(self.AuraInspectorDeleteEffectButton)
    attachMouseWheel(self.AuraInspectorDeleteEffectButton)

    self.AuraInspectorSelectedEffectHeader = UI.CreateText(root:GetFrame(), "RPEDataEditorAuraInspectorSelectedEffectHeader", "Select an effect to edit it.", {
        width = self.AuraInspectorFieldWidth,
        height = 12,
        justifyH = "LEFT",
        textColor = UI.ResolveColor(nil, "text.secondary"),
    })
    root:AddChild(self.AuraInspectorSelectedEffectHeader)

    self.AuraInspectorEffectTypeGroup = createGroup("RPEDataEditorAuraInspectorEffectTypeGroup", "Effect Type", 18)
    self.AuraInspectorEffectTypeDropdown = UI.CreateDropdown(self.AuraInspectorEffectTypeGroup:GetFrame(), "RPEDataEditorAuraInspectorEffectTypeDropdown", {
        width = self.AuraInspectorFieldWidth,
        height = 18,
        items = self:GetAuraInspectorEffectTypeItems(),
        onValueChanged = function(value)
            if self._refreshingAuraInspector then
                return
            end

            self:CommitSelectedAuraInspectorEffect(function(effect)
                effect.type = value
                self:NormalizeAuraInspectorEffect(effect)
            end)
        end,
    })
    self.AuraInspectorEffectTypeGroup:AddChild(self.AuraInspectorEffectTypeDropdown)
    attachMouseWheel(self.AuraInspectorEffectTypeDropdown)

    self.AuraInspectorBaseAmountGroup, self.AuraInspectorBaseAmountLabel = createGroup("RPEDataEditorAuraInspectorBaseAmountGroup", "Base Damage")
    self.AuraInspectorBaseAmountInput = UI.CreateTextInput(self.AuraInspectorBaseAmountGroup:GetFrame(), "RPEDataEditorAuraInspectorBaseAmountInput", {
        width = self.AuraInspectorFieldWidth,
        height = self.AuraInspectorControlHeight,
        text = "0",
        borderColor = UI.ResolveColor(nil, "panel.border"),
    })
    self.AuraInspectorBaseAmountGroup:AddChild(self.AuraInspectorBaseAmountInput)
    attachMouseWheel(self.AuraInspectorBaseAmountInput)

    self.AuraInspectorAmountModeGroup = createGroup("RPEDataEditorAuraInspectorAmountModeGroup", "Amount Mode")
    self.AuraInspectorAmountModeDropdown = UI.CreateDropdown(self.AuraInspectorAmountModeGroup:GetFrame(), "RPEDataEditorAuraInspectorAmountModeDropdown", {
        width = self.AuraInspectorFieldWidth,
        height = 18,
        items = self:GetAuraInspectorAmountModeItems(),
        onValueChanged = function(value)
            if self._refreshingAuraInspector then
                return
            end

            self:CommitSelectedAuraInspectorEffect(function(effect)
                effect.amountMode = value
            end)
        end,
    })
    self.AuraInspectorAmountModeGroup:AddChild(self.AuraInspectorAmountModeDropdown)
    attachMouseWheel(self.AuraInspectorAmountModeDropdown)

    self.AuraInspectorDamageSchoolsGroup = createGroup("RPEDataEditorAuraInspectorDamageSchoolsGroup", "Damage Schools", 18)
    self.AuraInspectorDamageSchoolsDropdown = UI.CreateDropdown(self.AuraInspectorDamageSchoolsGroup:GetFrame(), "RPEDataEditorAuraInspectorDamageSchoolsDropdown", {
        width = self.AuraInspectorFieldWidth,
        height = 18,
        multiSelect = true,
        items = self:BuildSpellInspectorDamageSchoolsAcrossDatasets(),
        onValueChanged = function()
            if self._refreshingAuraInspector then
                return
            end

            self:CommitSelectedAuraInspectorEffect(function(effect)
                effect.damageSchoolRefs = self.AuraInspectorDamageSchoolsDropdown:GetSelectedValues()
            end)
        end,
    })
    self.AuraInspectorDamageSchoolsGroup:AddChild(self.AuraInspectorDamageSchoolsDropdown)
    attachMouseWheel(self.AuraInspectorDamageSchoolsDropdown)

    self.AuraInspectorStatRefGroup = createGroup("RPEDataEditorAuraInspectorStatRefGroup", "Stat", 18)
    self.AuraInspectorStatRefDropdown = UI.CreateDropdown(self.AuraInspectorStatRefGroup:GetFrame(), "RPEDataEditorAuraInspectorStatRefDropdown", {
        width = self.AuraInspectorFieldWidth,
        height = 18,
        items = self:BuildSpellInspectorStatsAcrossDatasets(),
        onValueChanged = function(value)
            if self._refreshingAuraInspector then
                return
            end

            self:CommitSelectedAuraInspectorEffect(function(effect)
                effect.statRef = value ~= "" and value or nil
            end)
        end,
    })
    self.AuraInspectorStatRefGroup:AddChild(self.AuraInspectorStatRefDropdown)
    attachMouseWheel(self.AuraInspectorStatRefDropdown)

    self.AuraInspectorSkillRefGroup = createGroup("RPEDataEditorAuraInspectorSkillRefGroup", "Skill", 18)
    self.AuraInspectorSkillRefDropdown = UI.CreateDropdown(self.AuraInspectorSkillRefGroup:GetFrame(), "RPEDataEditorAuraInspectorSkillRefDropdown", {
        width = self.AuraInspectorFieldWidth,
        height = 18,
        items = self:BuildSpellInspectorSkillsAcrossDatasets(),
        onValueChanged = function(value)
            if self._refreshingAuraInspector then
                return
            end

            self:CommitSelectedAuraInspectorEffect(function(effect)
                effect.skillRef = value ~= "" and value or nil
            end)
        end,
    })
    self.AuraInspectorSkillRefGroup:AddChild(self.AuraInspectorSkillRefDropdown)
    attachMouseWheel(self.AuraInspectorSkillRefDropdown)

    self.AuraInspectorOperationGroup = createGroup("RPEDataEditorAuraInspectorOperationGroup", "Operation", 18)
    self.AuraInspectorOperationDropdown = UI.CreateDropdown(self.AuraInspectorOperationGroup:GetFrame(), "RPEDataEditorAuraInspectorOperationDropdown", {
        width = self.AuraInspectorFieldWidth,
        height = 18,
        items = self:GetAuraInspectorOperationItems(),
        onValueChanged = function(value)
            if self._refreshingAuraInspector then
                return
            end

            self:CommitSelectedAuraInspectorEffect(function(effect)
                effect.operation = value == "percent" and "percent" or "flat"
            end)
        end,
    })
    self.AuraInspectorOperationGroup:AddChild(self.AuraInspectorOperationDropdown)
    attachMouseWheel(self.AuraInspectorOperationDropdown)

    self.AuraInspectorControlGroup = createGroup("RPEDataEditorAuraInspectorControlGroup", "Control", 74)
    self.AuraInspectorControlCancelOnDamageCheckbox = self:CreateAuraInspectorCheckbox(self.AuraInspectorControlGroup:GetFrame(), "RPEDataEditorAuraInspectorControlCancelOnDamageCheckbox", "Cancel On Damage", false, function(checked)
        if self._refreshingAuraInspector then
            return
        end
        self:CommitSelectedAuraInspectorEffect(function(effect)
            effect.cancelOnDamage = checked == true
        end)
    end)
    self.AuraInspectorControlGroup:AddChild(self.AuraInspectorControlCancelOnDamageCheckbox)
    self.AuraInspectorControlPreventCastingCheckbox = self:CreateAuraInspectorCheckbox(self.AuraInspectorControlGroup:GetFrame(), "RPEDataEditorAuraInspectorControlPreventCastingCheckbox", "Prevent Casting", false, function(checked)
        if self._refreshingAuraInspector then
            return
        end
        self:CommitSelectedAuraInspectorEffect(function(effect)
            effect.preventCasting = checked == true
        end)
    end)
    self.AuraInspectorControlGroup:AddChild(self.AuraInspectorControlPreventCastingCheckbox)
    self.AuraInspectorControlMovementZeroCheckbox = self:CreateAuraInspectorCheckbox(self.AuraInspectorControlGroup:GetFrame(), "RPEDataEditorAuraInspectorControlMovementZeroCheckbox", "Set Movement Range To 0", false, function(checked)
        if self._refreshingAuraInspector then
            return
        end
        self:CommitSelectedAuraInspectorEffect(function(effect)
            effect.movementRangeOverride = checked == true and 0 or nil
        end)
    end)
    self.AuraInspectorControlGroup:AddChild(self.AuraInspectorControlMovementZeroCheckbox)
    self.AuraInspectorControlForceAutoHitCheckbox = self:CreateAuraInspectorCheckbox(self.AuraInspectorControlGroup:GetFrame(), "RPEDataEditorAuraInspectorControlForceAutoHitCheckbox", "Force Auto-Hit", false, function(checked)
        if self._refreshingAuraInspector then
            return
        end
        self:CommitSelectedAuraInspectorEffect(function(effect)
            effect.forceAutoHitAgainstTarget = checked == true
        end)
    end)
    self.AuraInspectorControlGroup:AddChild(self.AuraInspectorControlForceAutoHitCheckbox)

    self.AuraInspectorAuraGroup = createGroup("RPEDataEditorAuraInspectorAuraGroup", "Aura", 18)
    self.AuraInspectorAuraDropdown = UI.CreateDropdown(self.AuraInspectorAuraGroup:GetFrame(), "RPEDataEditorAuraInspectorAuraDropdown", {
        width = self.AuraInspectorFieldWidth,
        height = 18,
        items = self:BuildSpellInspectorAurasAcrossDatasets(),
        onValueChanged = function(value)
            if self._refreshingAuraInspector then
                return
            end

            self:CommitSelectedAuraInspectorEffect(function(effect)
                effect.auraRef = value ~= "" and value or nil
            end)
        end,
    })
    self.AuraInspectorAuraGroup:AddChild(self.AuraInspectorAuraDropdown)
    attachMouseWheel(self.AuraInspectorAuraDropdown)

    self.AuraInspectorAuraStacksGroup = createGroup("RPEDataEditorAuraInspectorAuraStacksGroup", "Stacks", 18)
    self.AuraInspectorAuraStacksInput = UI.CreateTextInput(self.AuraInspectorAuraStacksGroup:GetFrame(), "RPEDataEditorAuraInspectorAuraStacksInput", {
        width = self.AuraInspectorFieldWidth,
        height = self.AuraInspectorControlHeight,
        text = "1",
        borderColor = UI.ResolveColor(nil, "panel.border"),
    })
    self.AuraInspectorAuraStacksGroup:AddChild(self.AuraInspectorAuraStacksInput)
    attachMouseWheel(self.AuraInspectorAuraStacksInput)

    self.AuraInspectorApplyAuraDurationGroup = createGroup("RPEDataEditorAuraInspectorApplyAuraDurationGroup", "Duration", 18)
    self.AuraInspectorApplyAuraDurationInput = UI.CreateTextInput(self.AuraInspectorApplyAuraDurationGroup:GetFrame(), "RPEDataEditorAuraInspectorApplyAuraDurationInput", {
        width = self.AuraInspectorFieldWidth,
        height = self.AuraInspectorControlHeight,
        text = "12",
        borderColor = UI.ResolveColor(nil, "panel.border"),
    })
    self.AuraInspectorApplyAuraDurationGroup:AddChild(self.AuraInspectorApplyAuraDurationInput)
    attachMouseWheel(self.AuraInspectorApplyAuraDurationInput)

    self.AuraInspectorBasePowerGroup = createGroup("RPEDataEditorAuraInspectorBasePowerGroup", "Base Power", 18)
    self.AuraInspectorBasePowerInput = UI.CreateTextInput(self.AuraInspectorBasePowerGroup:GetFrame(), "RPEDataEditorAuraInspectorBasePowerInput", {
        width = self.AuraInspectorFieldWidth,
        height = self.AuraInspectorControlHeight,
        text = "0",
        borderColor = UI.ResolveColor(nil, "panel.border"),
    })
    self.AuraInspectorBasePowerGroup:AddChild(self.AuraInspectorBasePowerInput)
    attachMouseWheel(self.AuraInspectorBasePowerInput)

    self.AuraInspectorResourceGroup = createGroup("RPEDataEditorAuraInspectorResourceGroup", "Resource", 18)
    self.AuraInspectorResourceDropdown = UI.CreateDropdown(self.AuraInspectorResourceGroup:GetFrame(), "RPEDataEditorAuraInspectorResourceDropdown", {
        width = self.AuraInspectorFieldWidth,
        height = 18,
        items = self:BuildSpellInspectorResourcesAcrossDatasets(),
        onValueChanged = function(value)
            if self._refreshingAuraInspector then
                return
            end

            self:CommitSelectedAuraInspectorEffect(function(effect)
                effect.resourceRef = value ~= "" and value or nil
            end)
        end,
    })
    self.AuraInspectorResourceGroup:AddChild(self.AuraInspectorResourceDropdown)
    attachMouseWheel(self.AuraInspectorResourceDropdown)

    self.AuraInspectorResourceAmountGroup = createGroup("RPEDataEditorAuraInspectorResourceAmountGroup", "Resource Amount", 18)
    self.AuraInspectorResourceAmountInput = UI.CreateTextInput(self.AuraInspectorResourceAmountGroup:GetFrame(), "RPEDataEditorAuraInspectorResourceAmountInput", {
        width = self.AuraInspectorFieldWidth,
        height = self.AuraInspectorControlHeight,
        text = "0",
        borderColor = UI.ResolveColor(nil, "panel.border"),
    })
    self.AuraInspectorResourceAmountGroup:AddChild(self.AuraInspectorResourceAmountInput)
    attachMouseWheel(self.AuraInspectorResourceAmountInput)

    self.AuraInspectorResourceAmountModeGroup = createGroup("RPEDataEditorAuraInspectorResourceAmountModeGroup", "Amount Mode")
    self.AuraInspectorResourceAmountModeDropdown = UI.CreateDropdown(self.AuraInspectorResourceAmountModeGroup:GetFrame(), "RPEDataEditorAuraInspectorResourceAmountModeDropdown", {
        width = self.AuraInspectorFieldWidth,
        height = 18,
        items = self:GetAuraInspectorAmountModeItems(),
        onValueChanged = function(value)
            if self._refreshingAuraInspector then
                return
            end

            self:CommitSelectedAuraInspectorEffect(function(effect)
                effect.amountMode = value
            end)
        end,
    })
    self.AuraInspectorResourceAmountModeGroup:AddChild(self.AuraInspectorResourceAmountModeDropdown)
    attachMouseWheel(self.AuraInspectorResourceAmountModeDropdown)

    self.AuraInspectorScalingGroup = createGroup("RPEDataEditorAuraInspectorScalingGroup", "Stat Scaling", 110)
    self.AuraInspectorScalingPanel = UI.CreatePanel(self.AuraInspectorScalingGroup:GetFrame(), "RPEDataEditorAuraInspectorScalingPanel", {
        width = self.AuraInspectorFieldWidth,
        height = 74,
        contentInset = 1,
        showBorder = true,
    })
    self.AuraInspectorScalingGroup:AddChild(self.AuraInspectorScalingPanel)
    attachMouseWheel(self.AuraInspectorScalingPanel)

    self.AuraInspectorScalingScroll = UI.ScrollLayout:New({
        name = "RPEDataEditorAuraInspectorScalingScroll",
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
    self.AuraInspectorScalingScroll:SetParent(self.AuraInspectorScalingPanel:GetContentFrame())
    self.AuraInspectorScalingScroll:SetRowRenderer(function(row, item, itemIndex)
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
                    self.SelectedAuraScalingIndex = itemIndex
                    self:RefreshAuraInspectorPage()
                end
            end)

            local isSelected = tonumber(self.SelectedAuraScalingIndex) == tonumber(itemIndex)
            if row.entryBackground and row.entryBackground.SetColorTexture then
                local token = isSelected and "list.rowHover" or "list.rowBackground"
                local color = UI.ResolveColor(nil, token)
                row.entryBackground:SetColorTexture(color.r or 0.08, color.g or 0.09, color.b or 0.11, color.a or 0.85)
            end
        end
    end)
    self.AuraInspectorScalingScroll:Create()
    UI.Utils.AnchorFill(self.AuraInspectorScalingScroll, self.AuraInspectorScalingPanel:GetContentFrame(), 0, 0, 0, 0)
    attachMouseWheel(self.AuraInspectorScalingScroll)

    self.AuraInspectorPendingScalingRow = UI.CreateLayout(UI.HorizontalLayoutGroup, self.AuraInspectorScalingGroup:GetFrame(), "RPEDataEditorAuraInspectorPendingScalingRow", {
        width = self.AuraInspectorFieldWidth,
        height = 18,
        spacing = 2,
        fitChildrenWidth = false,
        fitChildrenHeight = false,
    })
    self.AuraInspectorScalingGroup:AddChild(self.AuraInspectorPendingScalingRow)
    attachMouseWheel(self.AuraInspectorPendingScalingRow)

    self.AuraInspectorPendingScalingStatDropdown = UI.CreateDropdown(self.AuraInspectorPendingScalingRow:GetFrame(), "RPEDataEditorAuraInspectorPendingScalingStatDropdown", {
        width = 146,
        height = 18,
        items = self:BuildSpellInspectorStatsAcrossDatasets(),
    })
    self.AuraInspectorPendingScalingRow:AddChild(self.AuraInspectorPendingScalingStatDropdown)
    attachMouseWheel(self.AuraInspectorPendingScalingStatDropdown)

    self.AuraInspectorPendingScalingCoefficientInput = UI.CreateTextInput(self.AuraInspectorPendingScalingRow:GetFrame(), "RPEDataEditorAuraInspectorPendingScalingCoefficientInput", {
        width = 44,
        height = 18,
        text = "0",
        borderColor = UI.ResolveColor(nil, "panel.border"),
    })
    self.AuraInspectorPendingScalingRow:AddChild(self.AuraInspectorPendingScalingCoefficientInput)
    attachMouseWheel(self.AuraInspectorPendingScalingCoefficientInput)

    self.AuraInspectorAddScalingButton = UI.CreateButton(self.AuraInspectorPendingScalingRow:GetFrame(), "RPEDataEditorAuraInspectorAddScalingButton", "Add", 36, function()
        local effect = self:GetSelectedAuraInspectorEffect()
        if not effect then
            return
        end

        local statRef = self.AuraInspectorPendingScalingStatDropdown and self.AuraInspectorPendingScalingStatDropdown.GetSelectedValue and self.AuraInspectorPendingScalingStatDropdown:GetSelectedValue() or ""
        if statRef == "" then
            return
        end

        local coefficient = tonumber(self.AuraInspectorPendingScalingCoefficientInput and self.AuraInspectorPendingScalingCoefficientInput:GetText()) or 0
        self:CommitSelectedAuraInspectorEffect(function(selectedEffect)
            selectedEffect.statScaling = selectedEffect.statScaling or {}
            selectedEffect.statScaling[#selectedEffect.statScaling + 1] = {
                statRef = statRef,
                coefficient = coefficient,
            }
            self.SelectedAuraScalingIndex = #selectedEffect.statScaling
        end)
    end, {
        height = 18,
        fontSize = 7,
    })
    self.AuraInspectorPendingScalingRow:AddChild(self.AuraInspectorAddScalingButton)
    attachMouseWheel(self.AuraInspectorAddScalingButton)

    self.AuraInspectorDeleteScalingButton = UI.CreateButton(self.AuraInspectorPendingScalingRow:GetFrame(), "RPEDataEditorAuraInspectorDeleteScalingButton", "Delete", 44, function()
        local effect = self:GetSelectedAuraInspectorEffect()
        local scalingIndex = tonumber(self.SelectedAuraScalingIndex) or 0
        if not effect or scalingIndex <= 0 or type(effect.statScaling) ~= "table" or not effect.statScaling[scalingIndex] then
            return
        end

        self:CommitSelectedAuraInspectorEffect(function(selectedEffect)
            table.remove(selectedEffect.statScaling, scalingIndex)
            if #(selectedEffect.statScaling or {}) > 0 then
                self.SelectedAuraScalingIndex = math.min(scalingIndex, #selectedEffect.statScaling)
            else
                self.SelectedAuraScalingIndex = nil
            end
        end)
    end, {
        height = 18,
        fontSize = 7,
    })
    self.AuraInspectorPendingScalingRow:AddChild(self.AuraInspectorDeleteScalingButton)
    attachMouseWheel(self.AuraInspectorDeleteScalingButton)

    local function bindInput(fieldName, callback)
        self[fieldName]:SetScript("OnEnterPressed", callback)
        self[fieldName]:SetScript("OnEditFocusLost", callback)
    end

    bindInput("AuraInspectorBaseAmountInput", function()
        self:CommitSelectedAuraInspectorEffect(function(effect)
            local amount = tonumber(self.AuraInspectorBaseAmountInput:GetText()) or 0
            local effectType = tostring(effect.type or "damage")
            if effectType == "heal" then
                effect.baseHealing = amount
            elseif effectType == "absorb" then
                effect.baseAbsorption = amount
            elseif effectType == "stat" or effectType == "skill" then
                effect.baseAmount = amount
            else
                effect.baseDamage = amount
            end
        end)
    end)
    bindInput("AuraInspectorAuraStacksInput", function()
        self:CommitSelectedAuraInspectorEffect(function(effect)
            effect.stacks = math.max(1, math.floor(tonumber(self.AuraInspectorAuraStacksInput:GetText()) or 1))
        end)
    end)
    bindInput("AuraInspectorApplyAuraDurationInput", function()
        self:CommitSelectedAuraInspectorEffect(function(effect)
            effect.duration = math.max(1, math.floor(tonumber(self.AuraInspectorApplyAuraDurationInput:GetText()) or 12))
        end)
    end)
    bindInput("AuraInspectorBasePowerInput", function()
        self:CommitSelectedAuraInspectorEffect(function(effect)
            effect.basePower = tonumber(self.AuraInspectorBasePowerInput:GetText()) or 0
        end)
    end)
    bindInput("AuraInspectorResourceAmountInput", function()
        self:CommitSelectedAuraInspectorEffect(function(effect)
            effect.amount = tonumber(self.AuraInspectorResourceAmountInput:GetText()) or 0
        end)
    end)

    local function refreshScrollBounds()
        local frame = root:GetFrame()
        local viewportHeight = self.AuraInspectorEffectsScrollFrame and self.AuraInspectorEffectsScrollFrame:GetHeight() or 0
        local contentHeight = frame and frame:GetHeight() or 0
        local maxScroll = math.max(0, math.floor(contentHeight - viewportHeight + 0.5))
        self.AuraInspectorEffectsScrollBar:SetMinMaxValues(0, maxScroll)
        if self.AuraInspectorEffectsScrollBar.SetShown then
            self.AuraInspectorEffectsScrollBar:SetShown(maxScroll > 0)
        elseif maxScroll > 0 and self.AuraInspectorEffectsScrollBar.Show then
            self.AuraInspectorEffectsScrollBar:Show()
        elseif self.AuraInspectorEffectsScrollBar.Hide then
            self.AuraInspectorEffectsScrollBar:Hide()
        end
        if (self.AuraInspectorEffectsScrollBar:GetValue() or 0) > maxScroll then
            self.AuraInspectorEffectsScrollBar:SetValue(maxScroll)
        end
    end

    self.RefreshAuraInspectorEffectsScrollBounds = refreshScrollBounds
    root:GetFrame():SetScript("OnSizeChanged", refreshScrollBounds)
    self.AuraInspectorEffectsScrollFrame:SetScript("OnShow", refreshScrollBounds)
    refreshScrollBounds()
end
