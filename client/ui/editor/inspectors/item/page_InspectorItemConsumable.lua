local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Client.UI = Addon.Client.UI or {}
Addon.Client.UI.Editor = Addon.Client.UI.Editor or {}

local DataEditor = Addon.Client.UI.Editor
local UI = Addon.UI or {}
local Shared = DataEditor.ItemInspectorShared or {}
local FIELD_WIDTH = Shared.FIELD_WIDTH or 236
local CONSUMABLE_PHASE_ITEMS = Shared.CONSUMABLE_PHASE_ITEMS or {}
local AUTO_AURA_TARGET_ITEMS = Shared.AUTO_AURA_TARGET_ITEMS or {}
local TRIGGER_TARGET_ITEMS = Shared.TRIGGER_TARGET_ITEMS or {}
local EVENT_EFFECT_ITEMS = Shared.EVENT_EFFECT_ITEMS or {}
local createInspectorSection = Shared.createInspectorSection
local createEquipmentFieldGroup = Shared.createEquipmentFieldGroup
local createHorizontalFieldLabels = Shared.createHorizontalFieldLabels
local getEmbeddedItemTrait = Shared.getEmbeddedItemTrait
local setEmbeddedItemTrait = Shared.setEmbeddedItemTrait
local normalizeConsumableTraitStatBonuses = Shared.normalizeConsumableTraitStatBonuses
local normalizeConsumableTraitSkillBonuses = Shared.normalizeConsumableTraitSkillBonuses
local normalizeConsumableTraitAutomaticAuras = Shared.normalizeConsumableTraitAutomaticAuras
local normalizeConsumableTraitEvents = Shared.normalizeConsumableTraitEvents

local function buildConsumablePage(self, page)
    local function handleMouseWheel(_, delta)
        local _, maxValue = self.ItemInspectorConsumableScrollBar:GetMinMaxValues()
        local current = self.ItemInspectorConsumableScrollBar:GetValue() or 0
        local nextValue = math.max(0, math.min(maxValue or 0, current - ((delta or 0) * 24)))
        self.ItemInspectorConsumableScrollBar:SetValue(nextValue)
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

    local function attachMouseWheelRecursive(frame, visited)
        frame = frame and (frame.GetFrame and frame:GetFrame() or frame) or nil
        if not frame then
            return
        end

        visited = visited or {}
        if visited[frame] then
            return
        end
        visited[frame] = true

        attachMouseWheel(frame)
        local children = { frame:GetChildren() }
        for index = 1, #children do
            attachMouseWheelRecursive(children[index], visited)
        end
    end

    self.ItemInspectorConsumableScrollFrame = CreateFrame("ScrollFrame", "RPEDataEditorItemInspectorConsumableScrollFrame", page)
    self.ItemInspectorConsumableScrollFrame:SetPoint("TOPLEFT", page, "TOPLEFT", 0, 0)
    self.ItemInspectorConsumableScrollFrame:SetPoint("BOTTOMRIGHT", page, "BOTTOMRIGHT", -20, 0)
    self.ItemInspectorConsumableScrollFrame:EnableMouseWheel(true)
    self.ItemInspectorConsumableScrollFrame:SetClipsChildren(true)
    attachMouseWheel(page)
    attachMouseWheel(self.ItemInspectorConsumableScrollFrame)

    self.ItemInspectorConsumableScrollBar = CreateFrame("Slider", "RPEDataEditorItemInspectorConsumableScrollBar", page)
    self.ItemInspectorConsumableScrollBar:SetPoint("TOPRIGHT", page, "TOPRIGHT", -4, -2)
    self.ItemInspectorConsumableScrollBar:SetPoint("BOTTOMRIGHT", page, "BOTTOMRIGHT", -4, 2)
    self.ItemInspectorConsumableScrollBar:SetOrientation("VERTICAL")
    self.ItemInspectorConsumableScrollBar:SetMinMaxValues(0, 0)
    self.ItemInspectorConsumableScrollBar:SetValueStep(12)
    if self.ItemInspectorConsumableScrollBar.SetObeyStepOnDrag then
        self.ItemInspectorConsumableScrollBar:SetObeyStepOnDrag(true)
    end
    self.ItemInspectorConsumableScrollBar:SetWidth(12)

    self.ItemInspectorConsumableScrollBarTrack = self.ItemInspectorConsumableScrollBarTrack or self.ItemInspectorConsumableScrollBar:CreateTexture(nil, "BACKGROUND")
    self.ItemInspectorConsumableScrollBarTrack:SetAllPoints(self.ItemInspectorConsumableScrollBar)
    do
        local trackColor = UI.ResolveColor(nil, "scrollbar.track")
        self.ItemInspectorConsumableScrollBarTrack:SetColorTexture(trackColor.r or 0.08, trackColor.g or 0.09, trackColor.b or 0.11, trackColor.a or 0.95)
    end

    self.ItemInspectorConsumableScrollBar:SetThumbTexture("Interface\\Buttons\\WHITE8x8")
    do
        local thumb = self.ItemInspectorConsumableScrollBar.GetThumbTexture and self.ItemInspectorConsumableScrollBar:GetThumbTexture() or nil
        if thumb and thumb.SetVertexColor then
            local thumbColor = UI.ResolveColor(nil, "scrollbar.thumb")
            thumb:SetVertexColor(thumbColor.r or 0.42, thumbColor.g or 0.46, thumbColor.b or 0.52, thumbColor.a or 1)
        end
    end
    self.ItemInspectorConsumableScrollBar:SetValue(0)

    local root = UI.CreateLayout(UI.VerticalLayoutGroup, self.ItemInspectorConsumableScrollFrame, "RPEDataEditorItemInspectorConsumableLayout", {
        spacing = 6,
        fitChildrenWidth = true,
        fitChildrenHeight = false,
        autoSize = true,
    })
    root:GetFrame():SetPoint("TOPLEFT", self.ItemInspectorConsumableScrollFrame, "TOPLEFT", 0, 0)
    root:GetFrame():SetPoint("TOPRIGHT", self.ItemInspectorConsumableScrollFrame, "TOPRIGHT", 0, 0)
    self.ItemInspectorConsumableScrollFrame:SetScrollChild(root:GetFrame())
    self.ItemInspectorConsumableScrollBar:SetScript("OnValueChanged", function(_, value)
        self.ItemInspectorConsumableScrollFrame:SetVerticalScroll(value or 0)
    end)
    self.ItemInspectorConsumableScrollFrame:SetScript("OnMouseWheel", handleMouseWheel)
    self.ItemInspectorConsumableScrollFrame:SetScript("OnSizeChanged", function(scrollFrame)
        local width = math.max(1, (scrollFrame:GetWidth() or FIELD_WIDTH) - 4)
        root:GetFrame():SetWidth(width)
        if root.RefreshLayout then
            root:RefreshLayout()
        end
    end)

    self.ItemInspectorConsumableRoot = root

    local activationSection, activationLayout, activationHintText = createInspectorSection(
        root,
        "RPEDataEditorItemInspectorConsumableActivationSection",
        "Activation",
        62
    )
    self.ItemInspectorConsumableActivationSection = activationSection
    self.ItemInspectorConsumableHintText = activationHintText

    self.ItemInspectorConsumablePhaseGroup = createEquipmentFieldGroup(activationLayout, "RPEDataEditorItemInspectorConsumablePhaseGroup", "Activation Phase", 18)
    self.ItemInspectorConsumablePhaseDropdown = UI.CreateDropdown(self.ItemInspectorConsumablePhaseGroup:GetFrame(), "RPEDataEditorItemInspectorConsumablePhaseDropdown", {
        width = FIELD_WIDTH,
        height = 18,
        items = CONSUMABLE_PHASE_ITEMS,
        onValueChanged = function(value)
            if self._refreshingItemInspector then
                return
            end

            self:CommitSelectedItem(function(item)
                local trait = getEmbeddedItemTrait(item) or {}
                trait.phase = value or "event_start"
                setEmbeddedItemTrait(item, trait)
            end)
        end,
    })
    self.ItemInspectorConsumablePhaseGroup:AddChild(self.ItemInspectorConsumablePhaseDropdown)

    local identitySection, identityLayout = createInspectorSection(
        root,
        "RPEDataEditorItemInspectorConsumableIdentitySection",
        "Trait Description",
        82
    )
    self.ItemInspectorConsumableIdentitySection = identitySection

    self.ItemInspectorConsumableDescriptionGroup = createEquipmentFieldGroup(identityLayout, "RPEDataEditorItemInspectorConsumableDescriptionGroup", "Description", 48)
    self.ItemInspectorConsumableDescriptionInput = UI.CreateTextArea(self.ItemInspectorConsumableDescriptionGroup:GetFrame(), "RPEDataEditorItemInspectorConsumableDescriptionInput", {
        width = FIELD_WIDTH,
        height = 48,
        text = "",
        readOnly = false,
        borderColor = UI.ResolveColor(nil, "panel.border"),
    })
    self.ItemInspectorConsumableDescriptionInput:SetScript("OnEditFocusLost", function()
        self:CommitSelectedItem(function(item)
            local trait = getEmbeddedItemTrait(item) or {}
            trait.description = self.ItemInspectorConsumableDescriptionInput:GetText()
            setEmbeddedItemTrait(item, trait)
        end)
    end)
    self.ItemInspectorConsumableDescriptionGroup:AddChild(self.ItemInspectorConsumableDescriptionInput)

    local statsSection, statsLayout = createInspectorSection(
        root,
        "RPEDataEditorItemInspectorConsumableStatsSection",
        "Stat Bonuses",
        168
    )
    self.ItemInspectorConsumableStatsSection = statsSection
    self.ItemInspectorConsumableStatsPanel = UI.CreatePanel(statsLayout:GetFrame(), "RPEDataEditorItemInspectorConsumableStatsPanel", {
        width = FIELD_WIDTH,
        height = 56,
        contentInset = 1,
        showBorder = true,
    })
    statsLayout:AddChild(self.ItemInspectorConsumableStatsPanel)

    self.ItemInspectorConsumableStatsScroll = UI.ScrollLayout:New({
        name = "RPEDataEditorItemInspectorConsumableStatsScroll",
        width = FIELD_WIDTH,
        height = 54,
        visibleRows = 3,
        rowHeight = 18,
        rowSpacing = 0,
        border = false,
        rowElementClass = UI.TableRow,
    })
    self.ItemInspectorConsumableStatsScroll:SetParent(self.ItemInspectorConsumableStatsPanel:GetContentFrame())
    self.ItemInspectorConsumableStatsScroll:SetRowRenderer(function(row, item, itemIndex)
        if row.SetColumns then
            row:SetColumns({
                { key = "datasetName", width = 82, justifyH = "LEFT" },
                { key = "statName", width = 90, justifyH = "LEFT" },
                { key = "valueText", width = 46, justifyH = "RIGHT" },
            })
        end
        if row.SetRowData then
            row:SetRowData(item, itemIndex or 0)
        end
        if row.SetRowMouseUpHandler then
            row:SetRowMouseUpHandler(function(_, button, rowData)
                if button == "LeftButton" then
                    self.SelectedItemConsumableTraitStatIndex = rowData and rowData.rowIndex or nil
                    self:RefreshItemInspectorPage()
                end
            end)
        end
    end)
    self.ItemInspectorConsumableStatsScroll:Create()
    UI.Utils.AnchorFill(self.ItemInspectorConsumableStatsScroll, self.ItemInspectorConsumableStatsPanel:GetContentFrame(), 0, 0, 0, 0)

    self.ItemInspectorConsumablePendingStatHeaderRow = createHorizontalFieldLabels(statsLayout, "RPEDataEditorItemInspectorConsumablePendingStatHeaderRow", {
        { text = "Source Dataset", width = 90, expandWidth = true },
        { text = "Stat", width = 90, expandWidth = true },
    })

    self.ItemInspectorConsumablePendingStatRow = UI.CreateLayout(UI.HorizontalLayoutGroup, statsLayout:GetFrame(), "RPEDataEditorItemInspectorConsumablePendingStatRow", {
        width = FIELD_WIDTH,
        height = 18,
        spacing = 2,
        fitChildrenWidth = true,
        fitChildrenHeight = false,
    })
    self.ItemInspectorConsumablePendingStatRow._visibleHeight = 18
    statsLayout:AddChild(self.ItemInspectorConsumablePendingStatRow)

    self.ItemInspectorConsumablePendingStatDatasetDropdown = UI.CreateDropdown(self.ItemInspectorConsumablePendingStatRow:GetFrame(), "RPEDataEditorItemInspectorConsumablePendingStatDatasetDropdown", {
        width = 90,
        height = 18,
        expandWidth = true,
        items = self:BuildItemInspectorDatasetItems(),
        onValueChanged = function()
            if self._refreshingItemInspector then
                return
            end

            self:RefreshItemInspectorConsumablePendingStatDropdown()
            if self.ItemInspectorConsumablePendingStatDropdown and self.ItemInspectorConsumablePendingStatDropdown.SetSelectedValue then
                self.ItemInspectorConsumablePendingStatDropdown:SetSelectedValue("", true)
            end
        end,
    })
    self.ItemInspectorConsumablePendingStatRow:AddChild(self.ItemInspectorConsumablePendingStatDatasetDropdown)

    self.ItemInspectorConsumablePendingStatDropdown = UI.CreateDropdown(self.ItemInspectorConsumablePendingStatRow:GetFrame(), "RPEDataEditorItemInspectorConsumablePendingStatDropdown", {
        width = 90,
        height = 18,
        expandWidth = true,
        items = { { label = "None", value = "" } },
    })
    self.ItemInspectorConsumablePendingStatRow:AddChild(self.ItemInspectorConsumablePendingStatDropdown)

    self.ItemInspectorConsumablePendingStatActionLabels = createHorizontalFieldLabels(statsLayout, "RPEDataEditorItemInspectorConsumablePendingStatActionLabels", {
        { text = "Mode", width = 58 },
        { text = "Bonus Value", width = 90, expandWidth = true },
        { text = "", width = 36 },
        { text = "", width = 28 },
    })

    self.ItemInspectorConsumablePendingStatActionsRow = UI.CreateLayout(UI.HorizontalLayoutGroup, statsLayout:GetFrame(), "RPEDataEditorItemInspectorConsumablePendingStatActionsRow", {
        width = FIELD_WIDTH,
        height = 18,
        spacing = 2,
        fitChildrenWidth = true,
        fitChildrenHeight = false,
    })
    self.ItemInspectorConsumablePendingStatActionsRow._visibleHeight = 18
    statsLayout:AddChild(self.ItemInspectorConsumablePendingStatActionsRow)

    self.ItemInspectorConsumablePendingStatOperationDropdown = UI.CreateDropdown(self.ItemInspectorConsumablePendingStatActionsRow:GetFrame(), "RPEDataEditorItemInspectorConsumablePendingStatOperationDropdown", {
        width = 58,
        height = 18,
        items = self:GetAuraInspectorOperationItems(),
    })
    self.ItemInspectorConsumablePendingStatActionsRow:AddChild(self.ItemInspectorConsumablePendingStatOperationDropdown)

    self.ItemInspectorConsumablePendingStatValueInput = UI.CreateTextInput(self.ItemInspectorConsumablePendingStatActionsRow:GetFrame(), "RPEDataEditorItemInspectorConsumablePendingStatValueInput", {
        width = 90,
        height = 18,
        text = "0",
        expandWidth = true,
        borderColor = UI.ResolveColor(nil, "panel.border"),
    })
    self.ItemInspectorConsumablePendingStatActionsRow:AddChild(self.ItemInspectorConsumablePendingStatValueInput)

    self.ItemInspectorConsumableAddStatButton = UI.CreateButton(self.ItemInspectorConsumablePendingStatActionsRow:GetFrame(), "RPEDataEditorItemInspectorConsumableAddStatButton", "Save", 36, function()
        if self._refreshingItemInspector then
            return
        end

        local statRef = self.ItemInspectorConsumablePendingStatDropdown and self.ItemInspectorConsumablePendingStatDropdown.GetSelectedValue and self.ItemInspectorConsumablePendingStatDropdown:GetSelectedValue() or ""
        if statRef == "" then
            return
        end

        local value = tonumber(self.ItemInspectorConsumablePendingStatValueInput and self.ItemInspectorConsumablePendingStatValueInput:GetText()) or 0
        local operation = self.ItemInspectorConsumablePendingStatOperationDropdown and self.ItemInspectorConsumablePendingStatOperationDropdown.GetSelectedValue and self.ItemInspectorConsumablePendingStatOperationDropdown:GetSelectedValue() or "flat"
        local editIndex = tonumber(self.SelectedItemConsumableTraitStatIndex)
        self:CommitSelectedItem(function(item)
            local trait = getEmbeddedItemTrait(item) or {}
            local bonuses = normalizeConsumableTraitStatBonuses(trait.statBonuses)
            local entry = {
                statRef = statRef,
                operation = operation,
                value = value,
            }
            if editIndex and bonuses[editIndex] then
                bonuses[editIndex] = entry
            else
                bonuses[#bonuses + 1] = entry
            end
            trait.statBonuses = bonuses
            setEmbeddedItemTrait(item, trait)
        end)
    end, {
        height = 18,
        fontSize = 7,
    })
    self.ItemInspectorConsumablePendingStatActionsRow:AddChild(self.ItemInspectorConsumableAddStatButton)

    self.ItemInspectorConsumableRemoveStatButton = UI.CreateButton(self.ItemInspectorConsumablePendingStatActionsRow:GetFrame(), "RPEDataEditorItemInspectorConsumableRemoveStatButton", "Del", 28, function()
        local removeIndex = tonumber(self.SelectedItemConsumableTraitStatIndex)
        if not removeIndex then
            return
        end

        self:CommitSelectedItem(function(item)
            local trait = getEmbeddedItemTrait(item) or {}
            local bonuses = normalizeConsumableTraitStatBonuses(trait.statBonuses)
            table.remove(bonuses, removeIndex)
            trait.statBonuses = bonuses
            setEmbeddedItemTrait(item, trait)
        end)
    end, {
        height = 18,
        fontSize = 7,
    })
    self.ItemInspectorConsumablePendingStatActionsRow:AddChild(self.ItemInspectorConsumableRemoveStatButton)

    local skillSection, skillLayout = createInspectorSection(
        root,
        "RPEDataEditorItemInspectorConsumableSkillsSection",
        "Skill Bonuses",
        168
    )
    self.ItemInspectorConsumableSkillsSection = skillSection
    self.ItemInspectorConsumableSkillsPanel = UI.CreatePanel(skillLayout:GetFrame(), "RPEDataEditorItemInspectorConsumableSkillsPanel", {
        width = FIELD_WIDTH,
        height = 56,
        contentInset = 1,
        showBorder = true,
    })
    skillLayout:AddChild(self.ItemInspectorConsumableSkillsPanel)

    self.ItemInspectorConsumableSkillsScroll = UI.ScrollLayout:New({
        name = "RPEDataEditorItemInspectorConsumableSkillsScroll",
        width = FIELD_WIDTH,
        height = 54,
        visibleRows = 3,
        rowHeight = 18,
        rowSpacing = 0,
        border = false,
        rowElementClass = UI.TableRow,
    })
    self.ItemInspectorConsumableSkillsScroll:SetParent(self.ItemInspectorConsumableSkillsPanel:GetContentFrame())
    self.ItemInspectorConsumableSkillsScroll:SetRowRenderer(function(row, item, itemIndex)
        if row.SetColumns then
            row:SetColumns({
                { key = "datasetName", width = 82, justifyH = "LEFT" },
                { key = "skillName", width = 90, justifyH = "LEFT" },
                { key = "valueText", width = 46, justifyH = "RIGHT" },
            })
        end
        if row.SetRowData then
            row:SetRowData(item, itemIndex or 0)
        end
        if row.SetRowMouseUpHandler then
            row:SetRowMouseUpHandler(function(_, button, rowData)
                if button == "LeftButton" then
                    self.SelectedItemConsumableTraitSkillIndex = rowData and rowData.rowIndex or nil
                    self:RefreshItemInspectorPage()
                end
            end)
        end
    end)
    self.ItemInspectorConsumableSkillsScroll:Create()
    UI.Utils.AnchorFill(self.ItemInspectorConsumableSkillsScroll, self.ItemInspectorConsumableSkillsPanel:GetContentFrame(), 0, 0, 0, 0)

    self.ItemInspectorConsumablePendingSkillHeaderRow = createHorizontalFieldLabels(skillLayout, "RPEDataEditorItemInspectorConsumablePendingSkillHeaderRow", {
        { text = "Source Dataset", width = 90, expandWidth = true },
        { text = "Skill", width = 90, expandWidth = true },
    })

    self.ItemInspectorConsumablePendingSkillRow = UI.CreateLayout(UI.HorizontalLayoutGroup, skillLayout:GetFrame(), "RPEDataEditorItemInspectorConsumablePendingSkillRow", {
        width = FIELD_WIDTH,
        height = 18,
        spacing = 2,
        fitChildrenWidth = true,
        fitChildrenHeight = false,
    })
    self.ItemInspectorConsumablePendingSkillRow._visibleHeight = 18
    skillLayout:AddChild(self.ItemInspectorConsumablePendingSkillRow)

    self.ItemInspectorConsumablePendingSkillDatasetDropdown = UI.CreateDropdown(self.ItemInspectorConsumablePendingSkillRow:GetFrame(), "RPEDataEditorItemInspectorConsumablePendingSkillDatasetDropdown", {
        width = 90,
        height = 18,
        expandWidth = true,
        items = self:BuildItemInspectorDatasetItems(),
        onValueChanged = function()
            if self._refreshingItemInspector then
                return
            end

            self:RefreshItemInspectorConsumablePendingSkillDropdown()
            if self.ItemInspectorConsumablePendingSkillDropdown and self.ItemInspectorConsumablePendingSkillDropdown.SetSelectedValue then
                self.ItemInspectorConsumablePendingSkillDropdown:SetSelectedValue("", true)
            end
        end,
    })
    self.ItemInspectorConsumablePendingSkillRow:AddChild(self.ItemInspectorConsumablePendingSkillDatasetDropdown)

    self.ItemInspectorConsumablePendingSkillDropdown = UI.CreateDropdown(self.ItemInspectorConsumablePendingSkillRow:GetFrame(), "RPEDataEditorItemInspectorConsumablePendingSkillDropdown", {
        width = 90,
        height = 18,
        expandWidth = true,
        items = { { label = "None", value = "" } },
    })
    self.ItemInspectorConsumablePendingSkillRow:AddChild(self.ItemInspectorConsumablePendingSkillDropdown)

    self.ItemInspectorConsumablePendingSkillActionLabels = createHorizontalFieldLabels(skillLayout, "RPEDataEditorItemInspectorConsumablePendingSkillActionLabels", {
        { text = "Bonus Value", width = 90, expandWidth = true },
        { text = "", width = 36 },
        { text = "", width = 28 },
    })

    self.ItemInspectorConsumablePendingSkillActionsRow = UI.CreateLayout(UI.HorizontalLayoutGroup, skillLayout:GetFrame(), "RPEDataEditorItemInspectorConsumablePendingSkillActionsRow", {
        width = FIELD_WIDTH,
        height = 18,
        spacing = 2,
        fitChildrenWidth = true,
        fitChildrenHeight = false,
    })
    self.ItemInspectorConsumablePendingSkillActionsRow._visibleHeight = 18
    skillLayout:AddChild(self.ItemInspectorConsumablePendingSkillActionsRow)

    self.ItemInspectorConsumablePendingSkillValueInput = UI.CreateTextInput(self.ItemInspectorConsumablePendingSkillActionsRow:GetFrame(), "RPEDataEditorItemInspectorConsumablePendingSkillValueInput", {
        width = 90,
        height = 18,
        text = "0",
        expandWidth = true,
        borderColor = UI.ResolveColor(nil, "panel.border"),
    })
    self.ItemInspectorConsumablePendingSkillActionsRow:AddChild(self.ItemInspectorConsumablePendingSkillValueInput)

    self.ItemInspectorConsumableAddSkillButton = UI.CreateButton(self.ItemInspectorConsumablePendingSkillActionsRow:GetFrame(), "RPEDataEditorItemInspectorConsumableAddSkillButton", "Save", 36, function()
        if self._refreshingItemInspector then
            return
        end

        local skillRef = self.ItemInspectorConsumablePendingSkillDropdown and self.ItemInspectorConsumablePendingSkillDropdown.GetSelectedValue and self.ItemInspectorConsumablePendingSkillDropdown:GetSelectedValue() or ""
        if skillRef == "" then
            return
        end

        local value = tonumber(self.ItemInspectorConsumablePendingSkillValueInput and self.ItemInspectorConsumablePendingSkillValueInput:GetText()) or 0
        local editIndex = tonumber(self.SelectedItemConsumableTraitSkillIndex)
        self:CommitSelectedItem(function(item)
            local trait = getEmbeddedItemTrait(item) or {}
            local bonuses = normalizeConsumableTraitSkillBonuses(trait.skillBonuses)
            local entry = {
                skillRef = skillRef,
                value = value,
            }
            if editIndex and bonuses[editIndex] then
                bonuses[editIndex] = entry
            else
                bonuses[#bonuses + 1] = entry
            end
            trait.skillBonuses = bonuses
            setEmbeddedItemTrait(item, trait)
        end)
    end, {
        height = 18,
        fontSize = 7,
    })
    self.ItemInspectorConsumablePendingSkillActionsRow:AddChild(self.ItemInspectorConsumableAddSkillButton)

    self.ItemInspectorConsumableRemoveSkillButton = UI.CreateButton(self.ItemInspectorConsumablePendingSkillActionsRow:GetFrame(), "RPEDataEditorItemInspectorConsumableRemoveSkillButton", "Del", 28, function()
        local removeIndex = tonumber(self.SelectedItemConsumableTraitSkillIndex)
        if not removeIndex then
            return
        end

        self:CommitSelectedItem(function(item)
            local trait = getEmbeddedItemTrait(item) or {}
            local bonuses = normalizeConsumableTraitSkillBonuses(trait.skillBonuses)
            table.remove(bonuses, removeIndex)
            trait.skillBonuses = bonuses
            setEmbeddedItemTrait(item, trait)
        end)
    end, {
        height = 18,
        fontSize = 7,
    })
    self.ItemInspectorConsumablePendingSkillActionsRow:AddChild(self.ItemInspectorConsumableRemoveSkillButton)

    local auraSection, auraLayout = createInspectorSection(
        root,
        "RPEDataEditorItemInspectorConsumableAuraSection",
        "Automatic Aura",
        194
    )
    self.ItemInspectorConsumableAuraSection = auraSection

    self.ItemInspectorConsumableAutoAuraDatasetGroup = createEquipmentFieldGroup(auraLayout, "RPEDataEditorItemInspectorConsumableAutoAuraDatasetGroup", "Aura Dataset", 18)
    self.ItemInspectorConsumableAutoAuraDatasetDropdown = UI.CreateDropdown(self.ItemInspectorConsumableAutoAuraDatasetGroup:GetFrame(), "RPEDataEditorItemInspectorConsumableAutoAuraDatasetDropdown", {
        width = FIELD_WIDTH,
        height = 18,
        items = self:BuildItemInspectorDatasetItems(),
        onValueChanged = function()
            if self._refreshingItemInspector then
                return
            end

            self:RefreshItemInspectorConsumablePendingAuraDropdown()
            if self.ItemInspectorConsumableAutoAuraDropdown and self.ItemInspectorConsumableAutoAuraDropdown.SetSelectedValue then
                self.ItemInspectorConsumableAutoAuraDropdown:SetSelectedValue("", true)
            end
        end,
    })
    self.ItemInspectorConsumableAutoAuraDatasetGroup:AddChild(self.ItemInspectorConsumableAutoAuraDatasetDropdown)

    self.ItemInspectorConsumableAutoAuraGroup = createEquipmentFieldGroup(auraLayout, "RPEDataEditorItemInspectorConsumableAutoAuraGroup", "Aura", 18)
    self.ItemInspectorConsumableAutoAuraDropdown = UI.CreateDropdown(self.ItemInspectorConsumableAutoAuraGroup:GetFrame(), "RPEDataEditorItemInspectorConsumableAutoAuraDropdown", {
        width = FIELD_WIDTH,
        height = 18,
        items = { { label = "None", value = "" } },
        onValueChanged = function(value)
            if self._refreshingItemInspector then
                return
            end

            self:CommitSelectedItem(function(item)
                local trait = getEmbeddedItemTrait(item) or {}
                local automaticAuras = normalizeConsumableTraitAutomaticAuras(trait.automaticAuras)
                if value == "" then
                    trait.automaticAuras = {}
                    setEmbeddedItemTrait(item, trait)
                    return
                end

                local current = automaticAuras[1] or {
                    targetScope = "self",
                    stacks = 1,
                    turns = 1,
                    powerLevel = 0,
                }
                current.auraRef = value
                automaticAuras[1] = current
                trait.automaticAuras = automaticAuras
                setEmbeddedItemTrait(item, trait)
            end)
        end,
    })
    self.ItemInspectorConsumableAutoAuraGroup:AddChild(self.ItemInspectorConsumableAutoAuraDropdown)

    self.ItemInspectorConsumableAutoAuraTargetGroup = createEquipmentFieldGroup(auraLayout, "RPEDataEditorItemInspectorConsumableAutoAuraTargetGroup", "Target Scope", 18)
    self.ItemInspectorConsumableAutoAuraTargetDropdown = UI.CreateDropdown(self.ItemInspectorConsumableAutoAuraTargetGroup:GetFrame(), "RPEDataEditorItemInspectorConsumableAutoAuraTargetDropdown", {
        width = FIELD_WIDTH,
        height = 18,
        items = AUTO_AURA_TARGET_ITEMS,
        onValueChanged = function(value)
            if self._refreshingItemInspector then
                return
            end

            self:CommitSelectedItem(function(item)
                local trait = getEmbeddedItemTrait(item) or {}
                local automaticAuras = normalizeConsumableTraitAutomaticAuras(trait.automaticAuras)
                local current = automaticAuras[1]
                if not current then
                    return
                end

                current.targetScope = value or "self"
                automaticAuras[1] = current
                trait.automaticAuras = automaticAuras
                setEmbeddedItemTrait(item, trait)
            end)
        end,
    })
    self.ItemInspectorConsumableAutoAuraTargetGroup:AddChild(self.ItemInspectorConsumableAutoAuraTargetDropdown)

    self.ItemInspectorConsumableAutoAuraNumberLabels = createHorizontalFieldLabels(auraLayout, "RPEDataEditorItemInspectorConsumableAutoAuraNumberLabels", {
        { text = "Stacks", width = 56, expandWidth = true },
        { text = "Turns", width = 56, expandWidth = true },
        { text = "Power", width = 56, expandWidth = true },
    })

    self.ItemInspectorConsumableAutoAuraNumbers = UI.CreateLayout(UI.HorizontalLayoutGroup, auraLayout:GetFrame(), "RPEDataEditorItemInspectorConsumableAutoAuraNumbers", {
        width = FIELD_WIDTH,
        height = 18,
        spacing = 2,
        fitChildrenWidth = true,
        fitChildrenHeight = false,
    })
    self.ItemInspectorConsumableAutoAuraNumbers._visibleHeight = 18
    auraLayout:AddChild(self.ItemInspectorConsumableAutoAuraNumbers)

    self.ItemInspectorConsumableAutoAuraStacksInput = UI.CreateTextInput(self.ItemInspectorConsumableAutoAuraNumbers:GetFrame(), "RPEDataEditorItemInspectorConsumableAutoAuraStacksInput", {
        width = 56,
        height = 18,
        text = "1",
        expandWidth = true,
        borderColor = UI.ResolveColor(nil, "panel.border"),
    })
    self.ItemInspectorConsumableAutoAuraNumbers:AddChild(self.ItemInspectorConsumableAutoAuraStacksInput)

    self.ItemInspectorConsumableAutoAuraTurnsInput = UI.CreateTextInput(self.ItemInspectorConsumableAutoAuraNumbers:GetFrame(), "RPEDataEditorItemInspectorConsumableAutoAuraTurnsInput", {
        width = 56,
        height = 18,
        text = "1",
        expandWidth = true,
        borderColor = UI.ResolveColor(nil, "panel.border"),
    })
    self.ItemInspectorConsumableAutoAuraNumbers:AddChild(self.ItemInspectorConsumableAutoAuraTurnsInput)

    self.ItemInspectorConsumableAutoAuraPowerInput = UI.CreateTextInput(self.ItemInspectorConsumableAutoAuraNumbers:GetFrame(), "RPEDataEditorItemInspectorConsumableAutoAuraPowerInput", {
        width = 56,
        height = 18,
        text = "0",
        expandWidth = true,
        borderColor = UI.ResolveColor(nil, "panel.border"),
    })
    self.ItemInspectorConsumableAutoAuraNumbers:AddChild(self.ItemInspectorConsumableAutoAuraPowerInput)

    self.ItemInspectorConsumableAutoAuraActions = UI.CreateLayout(UI.HorizontalLayoutGroup, auraLayout:GetFrame(), "RPEDataEditorItemInspectorConsumableAutoAuraActions", {
        width = FIELD_WIDTH,
        height = 18,
        spacing = 2,
        fitChildrenWidth = true,
        fitChildrenHeight = false,
    })
    self.ItemInspectorConsumableAutoAuraActions._visibleHeight = 18
    auraLayout:AddChild(self.ItemInspectorConsumableAutoAuraActions)

    self.ItemInspectorConsumableAutoAuraSaveButton = UI.CreateButton(self.ItemInspectorConsumableAutoAuraActions:GetFrame(), "RPEDataEditorItemInspectorConsumableAutoAuraSaveButton", "Save", 72, function()
        if self._refreshingItemInspector then
            return
        end

        local auraRef = self.ItemInspectorConsumableAutoAuraDropdown and self.ItemInspectorConsumableAutoAuraDropdown.GetSelectedValue and self.ItemInspectorConsumableAutoAuraDropdown:GetSelectedValue() or ""
        if auraRef == "" then
            return
        end

        self:CommitSelectedItem(function(item)
            local trait = getEmbeddedItemTrait(item) or {}
            trait.automaticAuras = {
                {
                    auraRef = auraRef,
                    targetScope = self.ItemInspectorConsumableAutoAuraTargetDropdown:GetSelectedValue() or "self",
                    stacks = tonumber(self.ItemInspectorConsumableAutoAuraStacksInput:GetText()) or 1,
                    turns = tonumber(self.ItemInspectorConsumableAutoAuraTurnsInput:GetText()) or 1,
                    powerLevel = tonumber(self.ItemInspectorConsumableAutoAuraPowerInput:GetText()) or 0,
                },
            }
            setEmbeddedItemTrait(item, trait)
        end)
    end, {
        height = 18,
        fontSize = 7,
        expandWidth = true,
    })
    self.ItemInspectorConsumableAutoAuraActions:AddChild(self.ItemInspectorConsumableAutoAuraSaveButton)

    self.ItemInspectorConsumableAutoAuraClearButton = UI.CreateButton(self.ItemInspectorConsumableAutoAuraActions:GetFrame(), "RPEDataEditorItemInspectorConsumableAutoAuraClearButton", "Clear", 72, function()
        self:CommitSelectedItem(function(item)
            local trait = getEmbeddedItemTrait(item) or {}
            trait.automaticAuras = {}
            setEmbeddedItemTrait(item, trait)
        end)
    end, {
        height = 18,
        fontSize = 7,
        expandWidth = true,
    })
    self.ItemInspectorConsumableAutoAuraActions:AddChild(self.ItemInspectorConsumableAutoAuraClearButton)

    local eventsSection, eventsLayout = createInspectorSection(
        root,
        "RPEDataEditorItemInspectorConsumableEventsSection",
        "Permanent Events",
        286,
        "Configure automatic event triggers for this embedded trait."
    )
    self.ItemInspectorConsumableEventsSection = eventsSection
    self.ItemInspectorConsumableEventsPanel = UI.CreatePanel(eventsLayout:GetFrame(), "RPEDataEditorItemInspectorConsumableEventsPanel", {
        width = FIELD_WIDTH,
        height = 56,
        contentInset = 1,
        showBorder = true,
    })
    eventsLayout:AddChild(self.ItemInspectorConsumableEventsPanel)

    self.ItemInspectorConsumableEventsScroll = UI.ScrollLayout:New({
        name = "RPEDataEditorItemInspectorConsumableEventsScroll",
        width = FIELD_WIDTH,
        height = 54,
        visibleRows = 3,
        rowHeight = 18,
        rowSpacing = 0,
        border = false,
        rowElementClass = UI.TableRow,
    })
    self.ItemInspectorConsumableEventsScroll:SetParent(self.ItemInspectorConsumableEventsPanel:GetContentFrame())
    self.ItemInspectorConsumableEventsScroll:SetRowRenderer(function(row, item, itemIndex)
        if row.SetColumns then
            row:SetColumns({
                { key = "combatEventText", width = 78, justifyH = "LEFT" },
                { key = "targetText", width = 44, justifyH = "LEFT" },
                { key = "effectSummary", width = 80, justifyH = "LEFT" },
                { key = "amountText", width = 28, justifyH = "RIGHT" },
            })
        end
        if row.SetRowData then
            row:SetRowData(item, itemIndex or 0)
        end
        if row.SetRowMouseUpHandler then
            row:SetRowMouseUpHandler(function(_, button, rowData)
                if button == "LeftButton" then
                    self.SelectedItemConsumableTraitEventIndex = rowData and rowData.rowIndex or nil
                    self:RefreshItemInspectorPage()
                end
            end)
        end
    end)
    self.ItemInspectorConsumableEventsScroll:Create()
    UI.Utils.AnchorFill(self.ItemInspectorConsumableEventsScroll, self.ItemInspectorConsumableEventsPanel:GetContentFrame(), 0, 0, 0, 0)

    self.ItemInspectorConsumablePendingCombatEventGroup = createEquipmentFieldGroup(eventsLayout, "RPEDataEditorItemInspectorConsumablePendingCombatEventGroup", "Trigger Event", 18)
    self.ItemInspectorConsumablePendingCombatEventDropdown = UI.CreateDropdown(self.ItemInspectorConsumablePendingCombatEventGroup:GetFrame(), "RPEDataEditorItemInspectorConsumablePendingCombatEventDropdown", {
        width = FIELD_WIDTH,
        height = 18,
        items = self:GetSpellInspectorEventItems(),
    })
    self.ItemInspectorConsumablePendingCombatEventGroup:AddChild(self.ItemInspectorConsumablePendingCombatEventDropdown)

    self.ItemInspectorConsumablePendingEventHeaderRow = createHorizontalFieldLabels(eventsLayout, "RPEDataEditorItemInspectorConsumablePendingEventHeaderRow", {
        { text = "Trigger Target", width = 72, expandWidth = true },
        { text = "Effect Type", width = 72, expandWidth = true },
    })

    self.ItemInspectorConsumablePendingEventRow = UI.CreateLayout(UI.HorizontalLayoutGroup, eventsLayout:GetFrame(), "RPEDataEditorItemInspectorConsumablePendingEventRow", {
        width = FIELD_WIDTH,
        height = 18,
        spacing = 2,
        fitChildrenWidth = true,
        fitChildrenHeight = false,
    })
    self.ItemInspectorConsumablePendingEventRow._visibleHeight = 18
    eventsLayout:AddChild(self.ItemInspectorConsumablePendingEventRow)

    self.ItemInspectorConsumablePendingTriggerTargetDropdown = UI.CreateDropdown(self.ItemInspectorConsumablePendingEventRow:GetFrame(), "RPEDataEditorItemInspectorConsumablePendingTriggerTargetDropdown", {
        width = 72,
        height = 18,
        expandWidth = true,
        items = TRIGGER_TARGET_ITEMS,
    })
    self.ItemInspectorConsumablePendingEventRow:AddChild(self.ItemInspectorConsumablePendingTriggerTargetDropdown)

    self.ItemInspectorConsumablePendingEffectDropdown = UI.CreateDropdown(self.ItemInspectorConsumablePendingEventRow:GetFrame(), "RPEDataEditorItemInspectorConsumablePendingEffectDropdown", {
        width = 72,
        height = 18,
        expandWidth = true,
        items = EVENT_EFFECT_ITEMS,
        onValueChanged = function()
            if self._refreshingItemInspector then
                return
            end
            self:RefreshItemInspectorPage()
        end,
    })
    self.ItemInspectorConsumablePendingEventRow:AddChild(self.ItemInspectorConsumablePendingEffectDropdown)

    local _, eventActionLabels = createHorizontalFieldLabels(eventsLayout, "RPEDataEditorItemInspectorConsumablePendingEventActionLabels", {
        { text = "Magnitude", width = 52, expandWidth = true },
        { text = "Mode", width = 48 },
        { text = "Chance %", width = 40 },
        { text = "", width = 28 },
        { text = "", width = 28 },
        { text = "", width = 28 },
    })
    self.ItemInspectorConsumablePendingEffectAmountLabel = eventActionLabels[1]

    self.ItemInspectorConsumablePendingEventActionRow = UI.CreateLayout(UI.HorizontalLayoutGroup, eventsLayout:GetFrame(), "RPEDataEditorItemInspectorConsumablePendingEventActionRow", {
        width = FIELD_WIDTH,
        height = 18,
        spacing = 2,
        fitChildrenWidth = true,
        fitChildrenHeight = false,
    })
    self.ItemInspectorConsumablePendingEventActionRow._visibleHeight = 18
    eventsLayout:AddChild(self.ItemInspectorConsumablePendingEventActionRow)

    self.ItemInspectorConsumablePendingEffectAmountInput = UI.CreateTextInput(self.ItemInspectorConsumablePendingEventActionRow:GetFrame(), "RPEDataEditorItemInspectorConsumablePendingEffectAmountInput", {
        width = 52,
        height = 18,
        text = "0",
        expandWidth = true,
        borderColor = UI.ResolveColor(nil, "panel.border"),
    })
    self.ItemInspectorConsumablePendingEventActionRow:AddChild(self.ItemInspectorConsumablePendingEffectAmountInput)

    self.ItemInspectorConsumablePendingEffectAmountModeDropdown = UI.CreateDropdown(self.ItemInspectorConsumablePendingEventActionRow:GetFrame(), "RPEDataEditorItemInspectorConsumablePendingEffectAmountModeDropdown", {
        width = 48,
        height = 18,
        items = self:GetAuraInspectorAmountModeItems(),
    })
    self.ItemInspectorConsumablePendingEventActionRow:AddChild(self.ItemInspectorConsumablePendingEffectAmountModeDropdown)

    self.ItemInspectorConsumablePendingEventChanceInput = UI.CreateTextInput(self.ItemInspectorConsumablePendingEventActionRow:GetFrame(), "RPEDataEditorItemInspectorConsumablePendingEventChanceInput", {
        width = 40,
        height = 18,
        text = "100",
        borderColor = UI.ResolveColor(nil, "panel.border"),
    })
    self.ItemInspectorConsumablePendingEventActionRow:AddChild(self.ItemInspectorConsumablePendingEventChanceInput)

    self.ItemInspectorConsumableNewEventButton = UI.CreateButton(self.ItemInspectorConsumablePendingEventActionRow:GetFrame(), "RPEDataEditorItemInspectorConsumableNewEventButton", "New", 28, function()
        self.SelectedItemConsumableTraitEventIndex = nil
        self:RefreshItemInspectorPage()
    end, {
        height = 18,
        fontSize = 7,
        expandWidth = false,
    })
    self.ItemInspectorConsumablePendingEventActionRow:AddChild(self.ItemInspectorConsumableNewEventButton)

    local detailHeaderRow, detailLabels = createHorizontalFieldLabels(eventsLayout, "RPEDataEditorItemInspectorConsumablePendingEventDetailLabels", {
        { text = "Reference Dataset", width = 72, expandWidth = true },
        { text = "Reference", width = 96, expandWidth = true },
    })
    self.ItemInspectorConsumablePendingEventDetailLabels = detailLabels
    self.ItemInspectorConsumablePendingEventDetailHeaderRow = detailHeaderRow

    self.ItemInspectorConsumablePendingEventDetailRow = UI.CreateLayout(UI.HorizontalLayoutGroup, eventsLayout:GetFrame(), "RPEDataEditorItemInspectorConsumablePendingEventDetailRow", {
        width = FIELD_WIDTH,
        height = 18,
        spacing = 2,
        fitChildrenWidth = true,
        fitChildrenHeight = false,
    })
    self.ItemInspectorConsumablePendingEventDetailRow._visibleHeight = 18
    eventsLayout:AddChild(self.ItemInspectorConsumablePendingEventDetailRow)

    self.ItemInspectorConsumablePendingEffectDatasetDropdown = UI.CreateDropdown(self.ItemInspectorConsumablePendingEventDetailRow:GetFrame(), "RPEDataEditorItemInspectorConsumablePendingEffectDatasetDropdown", {
        width = 72,
        height = 18,
        expandWidth = true,
        items = self:BuildItemInspectorDatasetItems(),
        onValueChanged = function()
            if self._refreshingItemInspector then
                return
            end
            self:RefreshItemInspectorConsumablePendingEffectReferenceDropdown()
        end,
    })
    self.ItemInspectorConsumablePendingEventDetailRow:AddChild(self.ItemInspectorConsumablePendingEffectDatasetDropdown)

    self.ItemInspectorConsumablePendingEffectReferenceDropdown = UI.CreateDropdown(self.ItemInspectorConsumablePendingEventDetailRow:GetFrame(), "RPEDataEditorItemInspectorConsumablePendingEffectReferenceDropdown", {
        width = 96,
        height = 18,
        expandWidth = true,
        items = {
            { label = "None", value = "" },
        },
    })
    self.ItemInspectorConsumablePendingEventDetailRow:AddChild(self.ItemInspectorConsumablePendingEffectReferenceDropdown)

    self.ItemInspectorConsumablePendingEventSchoolGroup = createEquipmentFieldGroup(eventsLayout, "RPEDataEditorItemInspectorConsumablePendingEventSchoolGroup", "Damage Schools", 18)
    self.ItemInspectorConsumablePendingEventSchoolDropdown = UI.CreateDropdown(self.ItemInspectorConsumablePendingEventSchoolGroup:GetFrame(), "RPEDataEditorItemInspectorConsumablePendingEventSchoolDropdown", {
        width = FIELD_WIDTH,
        height = 18,
        multiSelect = true,
        items = self:BuildSpellInspectorDamageSchoolsAcrossDatasets(),
    })
    self.ItemInspectorConsumablePendingEventSchoolGroup:AddChild(self.ItemInspectorConsumablePendingEventSchoolDropdown)

    local extraHeaderRow, extraLabels = createHorizontalFieldLabels(eventsLayout, "RPEDataEditorItemInspectorConsumablePendingEventExtraLabels", {
        { text = "Aura Duration", width = 26, expandWidth = true },
        { text = "Base Power", width = 26, expandWidth = true },
    })
    self.ItemInspectorConsumablePendingEventExtraLabels = extraLabels
    self.ItemInspectorConsumablePendingEventExtraHeaderRow = extraHeaderRow

    self.ItemInspectorConsumablePendingEventExtraRow = UI.CreateLayout(UI.HorizontalLayoutGroup, eventsLayout:GetFrame(), "RPEDataEditorItemInspectorConsumablePendingEventExtraRow", {
        width = FIELD_WIDTH,
        height = 18,
        spacing = 2,
        fitChildrenWidth = true,
        fitChildrenHeight = false,
    })
    self.ItemInspectorConsumablePendingEventExtraRow._visibleHeight = 18
    eventsLayout:AddChild(self.ItemInspectorConsumablePendingEventExtraRow)

    self.ItemInspectorConsumablePendingEffectAuxInput = UI.CreateTextInput(self.ItemInspectorConsumablePendingEventExtraRow:GetFrame(), "RPEDataEditorItemInspectorConsumablePendingEffectAuxInput", {
        width = 26,
        height = 18,
        text = "0",
        expandWidth = true,
        borderColor = UI.ResolveColor(nil, "panel.border"),
    })
    self.ItemInspectorConsumablePendingEventExtraRow:AddChild(self.ItemInspectorConsumablePendingEffectAuxInput)

    self.ItemInspectorConsumablePendingEffectExtraInput = UI.CreateTextInput(self.ItemInspectorConsumablePendingEventExtraRow:GetFrame(), "RPEDataEditorItemInspectorConsumablePendingEffectExtraInput", {
        width = 26,
        height = 18,
        text = "0",
        expandWidth = true,
        borderColor = UI.ResolveColor(nil, "panel.border"),
    })
    self.ItemInspectorConsumablePendingEventExtraRow:AddChild(self.ItemInspectorConsumablePendingEffectExtraInput)

    self.ItemInspectorConsumableAddEventButton = UI.CreateButton(self.ItemInspectorConsumablePendingEventActionRow:GetFrame(), "RPEDataEditorItemInspectorConsumableAddEventButton", "Save", 28, function()
        if self._refreshingItemInspector then
            return
        end

        local combatEventId = self.ItemInspectorConsumablePendingCombatEventDropdown and self.ItemInspectorConsumablePendingCombatEventDropdown.GetSelectedValue and self.ItemInspectorConsumablePendingCombatEventDropdown:GetSelectedValue() or ""
        if combatEventId == "" then
            return
        end

        local triggerTarget = self.ItemInspectorConsumablePendingTriggerTargetDropdown:GetSelectedValue() or "event_other"
        local effectType = self.ItemInspectorConsumablePendingEffectDropdown:GetSelectedValue() or "damage"
        local amount = tonumber(self.ItemInspectorConsumablePendingEffectAmountInput:GetText()) or 0
        local amountMode = self.ItemInspectorConsumablePendingEffectAmountModeDropdown and self.ItemInspectorConsumablePendingEffectAmountModeDropdown.GetSelectedValue and self.ItemInspectorConsumablePendingEffectAmountModeDropdown:GetSelectedValue() or "flat"
        local chance = tonumber(self.ItemInspectorConsumablePendingEventChanceInput:GetText()) or 100
        local effectRef = self.ItemInspectorConsumablePendingEffectReferenceDropdown and self.ItemInspectorConsumablePendingEffectReferenceDropdown.GetSelectedValue and self.ItemInspectorConsumablePendingEffectReferenceDropdown:GetSelectedValue() or ""
        local damageSchoolRefs = self.ItemInspectorConsumablePendingEventSchoolDropdown and self.ItemInspectorConsumablePendingEventSchoolDropdown.GetSelectedValues and self.ItemInspectorConsumablePendingEventSchoolDropdown:GetSelectedValues() or {}
        local auxValue = tonumber(self.ItemInspectorConsumablePendingEffectAuxInput:GetText()) or 0
        local extraValue = tonumber(self.ItemInspectorConsumablePendingEffectExtraInput:GetText()) or 0
        local editIndex = tonumber(self.SelectedItemConsumableTraitEventIndex)

        if (effectType == "apply_aura" or effectType == "remove_aura" or effectType == "resource") and effectRef == "" then
            return
        end

        local effectEntry = nil
        if effectType == "heal" then
            effectEntry = {
                type = "heal",
                baseHealing = amount,
                amountMode = amountMode,
            }
        elseif effectType == "apply_aura" then
            effectEntry = {
                type = "apply_aura",
                auraRef = effectRef,
                stacks = math.max(1, math.floor(amount)),
                duration = math.max(1, math.floor(auxValue)),
                basePower = extraValue,
            }
        elseif effectType == "remove_aura" then
            effectEntry = {
                type = "remove_aura",
                auraRef = effectRef,
                stacks = math.max(1, math.floor(amount)),
            }
        elseif effectType == "resource" then
            effectEntry = {
                type = "resource",
                resourceRef = effectRef,
                amount = amount,
                amountMode = amountMode,
            }
        else
            effectEntry = {
                type = "damage",
                baseDamage = amount,
                amountMode = amountMode,
                damageSchoolRefs = damageSchoolRefs,
            }
        end

        self:CommitSelectedItem(function(item)
            local trait = getEmbeddedItemTrait(item) or {}
            local events = normalizeConsumableTraitEvents(trait.events)
            local entry = {
                combatEventId = combatEventId,
                triggerTarget = triggerTarget,
                chance = chance,
                effects = {
                    effectEntry,
                },
            }
            if editIndex and events[editIndex] then
                events[editIndex] = entry
            else
                events[#events + 1] = entry
            end
            trait.events = events
            setEmbeddedItemTrait(item, trait)
        end)
    end, {
        height = 18,
        fontSize = 7,
        expandWidth = false,
    })
    self.ItemInspectorConsumablePendingEventActionRow:AddChild(self.ItemInspectorConsumableAddEventButton)

    self.ItemInspectorConsumableRemoveEventButton = UI.CreateButton(self.ItemInspectorConsumablePendingEventActionRow:GetFrame(), "RPEDataEditorItemInspectorConsumableRemoveEventButton", "Del", 28, function()
        local removeIndex = tonumber(self.SelectedItemConsumableTraitEventIndex)
        if not removeIndex then
            return
        end

        self:CommitSelectedItem(function(item)
            local trait = getEmbeddedItemTrait(item) or {}
            local events = normalizeConsumableTraitEvents(trait.events)
            table.remove(events, removeIndex)
            trait.events = events
            setEmbeddedItemTrait(item, trait)
        end)
    end, {
        height = 18,
        fontSize = 7,
    })
    self.ItemInspectorConsumablePendingEventActionRow:AddChild(self.ItemInspectorConsumableRemoveEventButton)

    self.ItemInspectorConsumableEmptyText = UI.CreateText(root:GetFrame(), "RPEDataEditorItemInspectorConsumableEmptyText", "", {
        width = FIELD_WIDTH,
        height = 20,
        justifyH = "LEFT",
        textColor = UI.ResolveColor(nil, "text.secondary"),
    })
    root:AddChild(self.ItemInspectorConsumableEmptyText)

    self.ItemInspectorConsumableSections = {
        self.ItemInspectorConsumableActivationSection,
        self.ItemInspectorConsumableIdentitySection,
        self.ItemInspectorConsumableStatsSection,
        self.ItemInspectorConsumableAuraSection,
        self.ItemInspectorConsumableEventsSection,
    }

    for index = 1, #(self.ItemInspectorConsumableSections or {}) do
        local section = self.ItemInspectorConsumableSections[index]
        if section and section.UpdateHeight then
            section:UpdateHeight()
        end
    end
    if root.RefreshLayout then
        root:RefreshLayout()
    end

    local function refreshScrollBounds()
        local frame = root:GetFrame()
        local viewportHeight = self.ItemInspectorConsumableScrollFrame and self.ItemInspectorConsumableScrollFrame:GetHeight() or 0
        local contentHeight = frame and frame:GetHeight() or 0
        local maxScroll = math.max(0, math.floor(contentHeight - viewportHeight + 0.5))
        self.ItemInspectorConsumableScrollBar:SetMinMaxValues(0, maxScroll)
        if self.ItemInspectorConsumableScrollBar.SetShown then
            self.ItemInspectorConsumableScrollBar:SetShown(maxScroll > 0)
        elseif maxScroll > 0 and self.ItemInspectorConsumableScrollBar.Show then
            self.ItemInspectorConsumableScrollBar:Show()
        elseif self.ItemInspectorConsumableScrollBar.Hide then
            self.ItemInspectorConsumableScrollBar:Hide()
        end
        if (self.ItemInspectorConsumableScrollBar:GetValue() or 0) > maxScroll then
            self.ItemInspectorConsumableScrollBar:SetValue(maxScroll)
        end
    end

    self.RefreshItemInspectorConsumableScrollBounds = refreshScrollBounds
    root:GetFrame():SetScript("OnSizeChanged", refreshScrollBounds)
    self.ItemInspectorConsumableScrollFrame:SetScript("OnShow", refreshScrollBounds)
    attachMouseWheelRecursive(root:GetFrame())
    refreshScrollBounds()
end

function DataEditor:BuildItemInspectorConsumablePage(page)
    return buildConsumablePage(self, page)
end
