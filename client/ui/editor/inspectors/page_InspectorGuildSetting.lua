local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Client.UI = Addon.Client.UI or {}
Addon.Client.UI.Editor = Addon.Client.UI.Editor or {}

local DataEditor = Addon.Client.UI.Editor
local UI = Addon.UI or {}
local Client = Addon.Client or {}
local GuildSettingClass = Addon.Internal
    and Addon.Internal.Database
    and Addon.Internal.Database.Classes
    and Addon.Internal.Database.Classes.GuildSetting

local INSPECTOR_SIDE_PADDING = 8
local CONTROL_HEIGHT = 20
local FIELD_WIDTH = 236
local DEFAULT_ICON = "Interface\\Icons\\INV_Misc_QuestionMark"

local INSPECTOR_PAGE_DEFINITIONS = {
    { key = "general", label = "General" },
    { key = "requisitions", label = "Requisitions" },
    { key = "dailyRewards", label = "Daily Rewards" },
    { key = "progression", label = "Progression" },
}

local DAILY_REWARD_TYPE_ITEMS = {
    { label = "Item", value = "item" },
    { label = "Currency", value = "currency" },
}

local function trim(value)
    return tostring(value or ""):match("^%s*(.-)%s*$")
end

local function applyTable(target, source)
    if type(target) ~= "table" or type(source) ~= "table" then
        return
    end

    for key in pairs(target) do
        if source[key] == nil then
            target[key] = nil
        end
    end

    for key, value in pairs(source) do
        target[key] = value
    end
end

local function createLabel(parent, name, text, width)
    return UI.CreateText(parent, name, text, {
        fontFile = (UI.Constants and UI.Constants.FontFiles and UI.Constants.FontFiles.Default) or "Fonts\\FRIZQT__.TTF",
        fontSize = (UI.Constants and UI.Constants.FontSizes and UI.Constants.FontSizes.Body) or 8,
        textColor = UI.ResolveColor(nil, "text.secondary"),
        width = width or FIELD_WIDTH,
        height = 12,
        justifyH = "LEFT",
    })
end

local function setTextElementEnabled(element, enabled)
    if not element then
        return
    end

    if element.SetEnabled then
        element:SetEnabled(enabled == true)
    end
    if element.SetReadOnly then
        element:SetReadOnly(enabled ~= true)
    end
end

local function setDropdownEnabled(dropdown, enabled)
    local frame = dropdown and dropdown.GetFrame and dropdown:GetFrame() or nil
    if not frame then
        return
    end

    if frame.EnableMouse then
        frame:EnableMouse(enabled == true)
    end
    if frame.SetAlpha then
        frame:SetAlpha(enabled == true and 1 or 0.5)
    end
end

local function setRowSelection(row, selected)
    if not row or not row.entryBackground or not row.entryBackground.SetColorTexture then
        return
    end

    local token = selected and "list.rowHover" or "list.rowBackground"
    local color = UI.ResolveColor(nil, token)
    row.entryBackground:SetColorTexture(color.r or 0.08, color.g or 0.09, color.b or 0.11, color.a or 0.85)
end

local function createCheckbox(parent, name, text, onValueChanged)
    local checkbox = UI.Checkbox:New({
        name = name,
        width = FIELD_WIDTH,
        height = 18,
        text = text,
        checked = false,
        border = false,
        fontFile = (UI.Constants and UI.Constants.FontFiles and UI.Constants.FontFiles.Default) or "Fonts\\FRIZQT__.TTF",
        fontSize = (UI.Constants and UI.Constants.FontSizes and UI.Constants.FontSizes.Checkbox) or 8,
        labelColor = UI.ResolveColor(nil, "text.primary"),
        onValueChanged = onValueChanged,
    })
    checkbox:SetParent(parent)
    checkbox:Create()
    return checkbox
end

local function normalizeInteger(value, fallback, minimum)
    local numeric = tonumber(value)
    if not numeric or numeric ~= numeric or numeric == math.huge or numeric == -math.huge then
        numeric = fallback
    end
    return math.max(minimum, math.floor(numeric))
end

local function buildUniqueStableId(entries, ignoredIndex, requestedId, prefix)
    local baseId = trim(requestedId)
    if baseId == "" then
        baseId = ("%s_1"):format(prefix)
    end

    local used = {}
    for index = 1, #(entries or {}) do
        if index ~= ignoredIndex then
            local entry = entries[index]
            local id = trim(entry and entry.id)
            if id ~= "" then
                used[id] = true
            end
        end
    end

    local candidate = baseId
    local suffix = 2
    while used[candidate] do
        candidate = ("%s_%d"):format(baseId, suffix)
        suffix = suffix + 1
    end
    return candidate
end

local function getSelectedRequisition(self)
    local guildSetting = self:GetSelectedGuildSetting()
    local requisitions = guildSetting and guildSetting.requisitions or {}
    local index = tonumber(self.SelectedGuildSettingRequisitionIndex)
    return guildSetting, requisitions, index, index and requisitions[index] or nil
end

local function getSelectedDailyReward(self)
    local guildSetting = self:GetSelectedGuildSetting()
    local rewards = guildSetting and guildSetting.dailyRewards or {}
    local index = tonumber(self.SelectedGuildSettingDailyRewardIndex)
    return guildSetting, rewards, index, index and rewards[index] or nil
end

local function getSelectedProgressionEntry(self)
    local guildSetting = self:GetSelectedGuildSetting()
    local progression = guildSetting and guildSetting.progression or {}
    local entries = progression and progression.entries or {}
    local index = tonumber(self.SelectedGuildSettingProgressionEntryIndex)
    return guildSetting, entries, index, index and entries[index] or nil
end

function DataEditor:NormalizeGuildSettingDefinition(guildSetting)
    if GuildSettingClass and GuildSettingClass.New and GuildSettingClass.ToTable then
        return GuildSettingClass:New(guildSetting):ToTable()
    end

    return guildSetting or {}
end

function DataEditor:CommitSelectedGuildSetting(mutate)
    local dataset = self:GetSelectedDataset()
    local guildSetting = self:GetSelectedGuildSetting()
    if not dataset or not guildSetting or type(mutate) ~= "function" then
        return guildSetting
    end

    local before = self:DeepCopyValue(guildSetting)
    mutate(guildSetting, dataset)
    applyTable(guildSetting, self:NormalizeGuildSettingDefinition(guildSetting))

    if self:DeepEqualValues(before, guildSetting) then
        return guildSetting
    end

    self:QueuePendingDatasetEntryChanged(dataset.id, "guildSettings")
    return guildSetting
end

function DataEditor:GetGuildSettingInspectorPageDefinitions()
    return INSPECTOR_PAGE_DEFINITIONS
end

function DataEditor:GetGuildSettingInspectorPageIndexByKey(key)
    for index = 1, #INSPECTOR_PAGE_DEFINITIONS do
        if INSPECTOR_PAGE_DEFINITIONS[index].key == key then
            return index
        end
    end
    return 1
end

function DataEditor:BuildGuildSettingInspectorPageSelectorItems()
    local items = {}
    for index = 1, #INSPECTOR_PAGE_DEFINITIONS do
        items[#items + 1] = {
            label = INSPECTOR_PAGE_DEFINITIONS[index].label,
            value = INSPECTOR_PAGE_DEFINITIONS[index].key,
        }
    end
    return items
end

function DataEditor:RefreshGuildSettingInspectorPageSelector()
    local pageCount = #INSPECTOR_PAGE_DEFINITIONS
    local activeIndex = math.max(1, math.min(self.ActiveGuildSettingInspectorPageIndex or 1, pageCount))
    self.ActiveGuildSettingInspectorPageIndex = activeIndex
    self.ActiveGuildSettingInspectorTabKey = INSPECTOR_PAGE_DEFINITIONS[activeIndex].key

    if self.GuildSettingInspectorPageDropdown then
        self._refreshingGuildSettingInspectorPageSelector = true
        self.GuildSettingInspectorPageDropdown:SetSelectedValue(self.ActiveGuildSettingInspectorTabKey, true)
        self._refreshingGuildSettingInspectorPageSelector = false
    end
    if self.GuildSettingInspectorPreviousButton and self.GuildSettingInspectorPreviousButton.SetEnabled then
        self.GuildSettingInspectorPreviousButton:SetEnabled(activeIndex > 1)
    end
    if self.GuildSettingInspectorNextButton and self.GuildSettingInspectorNextButton.SetEnabled then
        self.GuildSettingInspectorNextButton:SetEnabled(activeIndex < pageCount)
    end
end

function DataEditor:SetGuildSettingInspectorTab(tabKey)
    local activeIndex = self:GetGuildSettingInspectorPageIndexByKey(tabKey or "general")
    self.ActiveGuildSettingInspectorPageIndex = activeIndex
    self.ActiveGuildSettingInspectorTabKey = INSPECTOR_PAGE_DEFINITIONS[activeIndex].key

    local pages = {
        general = self.GuildSettingInspectorGeneralPage,
        requisitions = self.GuildSettingInspectorRequisitionsPage,
        dailyRewards = self.GuildSettingInspectorDailyRewardsPage,
        progression = self.GuildSettingInspectorProgressionPage,
    }
    for key, page in pairs(pages) do
        if page then
            if key == self.ActiveGuildSettingInspectorTabKey then
                page:Show()
            else
                page:Hide()
            end
        end
    end
    self:RefreshGuildSettingInspectorPageSelector()
end

function DataEditor:BuildGuildSettingInspectorPage(parent)
    if self.GuildSettingInspectorPage then
        self:RefreshGuildSettingInspectorPage()
        return self.GuildSettingInspectorPage
    end

    self.GuildSettingInspectorPage = CreateFrame("Frame", "RPEDataEditorGuildSettingInspectorPage", parent)
    self.GuildSettingInspectorSelectorBar = UI.CreateLayout(UI.HorizontalLayoutGroup, self.GuildSettingInspectorPage, "RPEDataEditorGuildSettingInspectorSelectorBar", {
        spacing = 4,
        fitChildrenWidth = true,
        fitChildrenHeight = false,
        height = 20,
    })
    self.GuildSettingInspectorSelectorBar:GetFrame():SetPoint("TOPLEFT", self.GuildSettingInspectorPage, "TOPLEFT", 0, 0)
    self.GuildSettingInspectorSelectorBar:GetFrame():SetPoint("TOPRIGHT", self.GuildSettingInspectorPage, "TOPRIGHT", 0, 0)

    self.GuildSettingInspectorPreviousButton = UI.CreateButton(self.GuildSettingInspectorSelectorBar:GetFrame(), "RPEDataEditorGuildSettingInspectorPreviousButton", "Prev", 40, function()
        local definition = INSPECTOR_PAGE_DEFINITIONS[(self.ActiveGuildSettingInspectorPageIndex or 1) - 1]
        self:SetGuildSettingInspectorTab(definition and definition.key or "general")
    end, { height = 20, fontSize = 7 })
    self.GuildSettingInspectorSelectorBar:AddChild(self.GuildSettingInspectorPreviousButton)

    self.GuildSettingInspectorPageDropdown = UI.CreateDropdown(self.GuildSettingInspectorSelectorBar:GetFrame(), "RPEDataEditorGuildSettingInspectorPageDropdown", {
        width = 118,
        height = 18,
        expandWidth = true,
        weight = 1,
        items = self:BuildGuildSettingInspectorPageSelectorItems(),
        onValueChanged = function(value)
            if not self._refreshingGuildSettingInspectorPageSelector then
                self:SetGuildSettingInspectorTab(value)
            end
        end,
    })
    self.GuildSettingInspectorSelectorBar:AddChild(self.GuildSettingInspectorPageDropdown)

    self.GuildSettingInspectorNextButton = UI.CreateButton(self.GuildSettingInspectorSelectorBar:GetFrame(), "RPEDataEditorGuildSettingInspectorNextButton", "Next", 40, function()
        local definition = INSPECTOR_PAGE_DEFINITIONS[(self.ActiveGuildSettingInspectorPageIndex or 1) + 1]
        self:SetGuildSettingInspectorTab(definition and definition.key or "progression")
    end, { height = 20, fontSize = 7 })
    self.GuildSettingInspectorSelectorBar:AddChild(self.GuildSettingInspectorNextButton)

    local function createPage(name)
        local page = CreateFrame("Frame", name, self.GuildSettingInspectorPage)
        page:SetPoint("TOPLEFT", self.GuildSettingInspectorPage, "TOPLEFT", INSPECTOR_SIDE_PADDING, -24)
        page:SetPoint("TOPRIGHT", self.GuildSettingInspectorPage, "TOPRIGHT", -INSPECTOR_SIDE_PADDING, -24)
        page:SetPoint("BOTTOMLEFT", self.GuildSettingInspectorPage, "BOTTOMLEFT", INSPECTOR_SIDE_PADDING, 24)
        page:SetPoint("BOTTOMRIGHT", self.GuildSettingInspectorPage, "BOTTOMRIGHT", -INSPECTOR_SIDE_PADDING, 24)
        return page
    end

    self.GuildSettingInspectorGeneralPage = createPage("RPEDataEditorGuildSettingInspectorGeneralPage")
    self:BuildGuildSettingInspectorGeneralPage(self.GuildSettingInspectorGeneralPage)
    self.GuildSettingInspectorRequisitionsPage = createPage("RPEDataEditorGuildSettingInspectorRequisitionsPage")
    self:BuildGuildSettingInspectorRequisitionsPage(self.GuildSettingInspectorRequisitionsPage)
    self.GuildSettingInspectorDailyRewardsPage = createPage("RPEDataEditorGuildSettingInspectorDailyRewardsPage")
    self:BuildGuildSettingInspectorDailyRewardsPage(self.GuildSettingInspectorDailyRewardsPage)
    self.GuildSettingInspectorProgressionPage = createPage("RPEDataEditorGuildSettingInspectorProgressionPage")
    self:BuildGuildSettingInspectorProgressionPage(self.GuildSettingInspectorProgressionPage)

    self.GuildSettingInspectorEmptyText = createLabel(self.GuildSettingInspectorPage, "RPEDataEditorGuildSettingInspectorEmptyText", "")
    self.GuildSettingInspectorEmptyText:GetFrame():SetPoint("BOTTOMLEFT", self.GuildSettingInspectorPage, "BOTTOMLEFT", 0, 0)

    self:SetGuildSettingInspectorTab("general")
    self:RefreshGuildSettingInspectorPage()
    return self.GuildSettingInspectorPage
end

function DataEditor:BuildGuildSettingInspectorGeneralPage(parent)
    local root = UI.CreateLayout(UI.VerticalLayoutGroup, parent, "RPEDataEditorGuildSettingInspectorGeneralLayout", {
        spacing = 3,
        fitChildrenWidth = true,
        fitChildrenHeight = false,
    })
    UI.Utils.AnchorFill(root, parent, 0, 0, 0, 0)

    root:AddChild(createLabel(root:GetFrame(), "RPEDataEditorGuildSettingInspectorNameLabel", "Name"))
    self.GuildSettingInspectorNameInput = UI.CreateTextInput(root:GetFrame(), "RPEDataEditorGuildSettingInspectorNameInput", {
        width = FIELD_WIDTH, height = CONTROL_HEIGHT, text = "", borderColor = UI.ResolveColor(nil, "panel.border"),
    })
    local commitName = function()
        self:CommitSelectedGuildSetting(function(guildSetting)
            guildSetting.name = self.GuildSettingInspectorNameInput:GetText()
        end)
    end
    self.GuildSettingInspectorNameInput:SetScript("OnEnterPressed", commitName)
    self.GuildSettingInspectorNameInput:SetScript("OnEditFocusLost", commitName)
    root:AddChild(self.GuildSettingInspectorNameInput)

    self.GuildSettingInspectorIdText = createLabel(root:GetFrame(), "RPEDataEditorGuildSettingInspectorIdText", "ID: -")
    root:AddChild(self.GuildSettingInspectorIdText)

    root:AddChild(createLabel(root:GetFrame(), "RPEDataEditorGuildSettingInspectorDescriptionLabel", "Description"))
    self.GuildSettingInspectorDescriptionInput = UI.CreateTextArea(root:GetFrame(), "RPEDataEditorGuildSettingInspectorDescriptionInput", {
        width = FIELD_WIDTH, height = 68, text = "", readOnly = false, borderColor = UI.ResolveColor(nil, "panel.border"),
    })
    self.GuildSettingInspectorDescriptionInput:SetScript("OnEditFocusLost", function()
        self:CommitSelectedGuildSetting(function(guildSetting)
            guildSetting.description = self.GuildSettingInspectorDescriptionInput:GetText()
        end)
    end)
    root:AddChild(self.GuildSettingInspectorDescriptionInput)

    root:AddChild(createLabel(root:GetFrame(), "RPEDataEditorGuildSettingInspectorGuildNameLabel", "Guild Name"))
    self.GuildSettingInspectorGuildNameInput = UI.CreateTextInput(root:GetFrame(), "RPEDataEditorGuildSettingInspectorGuildNameInput", {
        width = FIELD_WIDTH, height = CONTROL_HEIGHT, text = "", borderColor = UI.ResolveColor(nil, "panel.border"),
    })
    local commitGuildName = function()
        self:CommitSelectedGuildSetting(function(guildSetting)
            guildSetting.guildName = self.GuildSettingInspectorGuildNameInput:GetText()
        end)
    end
    self.GuildSettingInspectorGuildNameInput:SetScript("OnEnterPressed", commitGuildName)
    self.GuildSettingInspectorGuildNameInput:SetScript("OnEditFocusLost", commitGuildName)
    root:AddChild(self.GuildSettingInspectorGuildNameInput)

    root:AddChild(createLabel(root:GetFrame(), "RPEDataEditorGuildSettingInspectorWowGuildRankIndicesLabel", "Eligible WoW Guild Ranks"))
    self.GuildSettingInspectorWowGuildRankIndicesHint = UI.CreateText(root:GetFrame(), "RPEDataEditorGuildSettingInspectorWowGuildRankIndicesHint", "Enter comma-separated non-negative indexes. 0 = highest WoW guild rank. Blank means any WoW guild rank.", {
        width = FIELD_WIDTH,
        height = 28,
        justifyH = "LEFT",
        wordWrap = true,
        textColor = UI.ResolveColor(nil, "text.secondary"),
    })
    root:AddChild(self.GuildSettingInspectorWowGuildRankIndicesHint)
    self.GuildSettingInspectorWowGuildRankIndicesInput = UI.CreateTextInput(root:GetFrame(), "RPEDataEditorGuildSettingInspectorWowGuildRankIndicesInput", {
        width = FIELD_WIDTH, height = CONTROL_HEIGHT, text = "", borderColor = UI.ResolveColor(nil, "panel.border"),
    })
    local commitWowGuildRankIndices = function()
        self:CommitSelectedGuildSetting(function(guildSetting)
            guildSetting.wowGuildRankIndices = UI.Utils.ParseCommaSeparatedList(self.GuildSettingInspectorWowGuildRankIndicesInput:GetText())
        end)
    end
    self.GuildSettingInspectorWowGuildRankIndicesInput:SetScript("OnEnterPressed", commitWowGuildRankIndices)
    self.GuildSettingInspectorWowGuildRankIndicesInput:SetScript("OnEditFocusLost", commitWowGuildRankIndices)
    root:AddChild(self.GuildSettingInspectorWowGuildRankIndicesInput)

    self.GuildSettingInspectorEnableRequisitionsCheckbox = createCheckbox(root:GetFrame(), "RPEDataEditorGuildSettingInspectorEnableRequisitionsCheckbox", "Enable Requisitions", function(value)
        if self._refreshingGuildSettingInspector then
            return
        end
        self:CommitSelectedGuildSetting(function(guildSetting)
            guildSetting.general = guildSetting.general or {}
            guildSetting.general.enableRequisitions = value == true
        end)
    end)
    root:AddChild(self.GuildSettingInspectorEnableRequisitionsCheckbox)

    self.GuildSettingInspectorEnableDailyRewardsCheckbox = createCheckbox(root:GetFrame(), "RPEDataEditorGuildSettingInspectorEnableDailyRewardsCheckbox", "Enable Daily Rewards", function(value)
        if self._refreshingGuildSettingInspector then
            return
        end
        self:CommitSelectedGuildSetting(function(guildSetting)
            guildSetting.general = guildSetting.general or {}
            guildSetting.general.enableDailyRewards = value == true
        end)
    end)
    root:AddChild(self.GuildSettingInspectorEnableDailyRewardsCheckbox)

    self.GuildSettingInspectorEnableProgressionCheckbox = createCheckbox(root:GetFrame(), "RPEDataEditorGuildSettingInspectorEnableProgressionCheckbox", "Enable Progression", function(value)
        if self._refreshingGuildSettingInspector then
            return
        end
        self:CommitSelectedGuildSetting(function(guildSetting)
            guildSetting.general = guildSetting.general or {}
            guildSetting.general.enableProgression = value == true
        end)
    end)
    root:AddChild(self.GuildSettingInspectorEnableProgressionCheckbox)

    root:AddChild(createLabel(root:GetFrame(), "RPEDataEditorGuildSettingInspectorTagsLabel", "Tags"))
    self.GuildSettingInspectorTagsInput = UI.CreateTextInput(root:GetFrame(), "RPEDataEditorGuildSettingInspectorTagsInput", {
        width = FIELD_WIDTH, height = CONTROL_HEIGHT, text = "", borderColor = UI.ResolveColor(nil, "panel.border"),
    })
    local commitTags = function()
        self:CommitSelectedGuildSetting(function(guildSetting)
            guildSetting.tags = UI.Utils.ParseCommaSeparatedList(self.GuildSettingInspectorTagsInput:GetText())
        end)
    end
    self.GuildSettingInspectorTagsInput:SetScript("OnEnterPressed", commitTags)
    self.GuildSettingInspectorTagsInput:SetScript("OnEditFocusLost", commitTags)
    root:AddChild(self.GuildSettingInspectorTagsInput)
end

function DataEditor:BuildGuildSettingInspectorRequisitionsPage(parent)
    local root = UI.CreateLayout(UI.VerticalLayoutGroup, parent, "RPEDataEditorGuildSettingInspectorRequisitionsLayout", {
        spacing = 2,
        fitChildrenWidth = true,
        fitChildrenHeight = false,
    })
    UI.Utils.AnchorFill(root, parent, 0, 0, 0, 0)

    root:AddChild(createLabel(root:GetFrame(), "RPEDataEditorGuildSettingInspectorRequisitionsLabel", "Requisitions"))
    local requisitionPanel = UI.CreatePanel(root:GetFrame(), "RPEDataEditorGuildSettingInspectorRequisitionPanel", {
        width = FIELD_WIDTH, height = 64, contentInset = 2, showBorder = false,
    })
    root:AddChild(requisitionPanel)
    self.GuildSettingInspectorRequisitionScroll = UI.ScrollLayout:New({
        name = "RPEDataEditorGuildSettingInspectorRequisitionScroll",
        width = FIELD_WIDTH - 4, height = 60, visibleRows = 3, autoFitRows = true,
        rowHeight = 18, rowSpacing = 0, border = false, rowElementClass = UI.ScrollListEntry,
        categoryWidth = 112, statusWidth = 54, categoryInsetLeft = 4, statusInsetRight = 4,
    })
    self.GuildSettingInspectorRequisitionScroll:SetParent(requisitionPanel:GetContentFrame())
    self.GuildSettingInspectorRequisitionScroll:SetRowRenderer(function(row, requisition, itemIndex)
        row:SetCategory(tostring(requisition and requisition.id or "-"))
        row:SetTestName("")
        row:SetStatus(("x%d"):format(normalizeInteger(requisition and requisition.quantity, 1, 1)))
        row:SetDetail(tostring(requisition and requisition.itemRef or ""))
        local frame = row.GetFrame and row:GetFrame() or nil
        if frame then
            frame:EnableMouse(true)
            frame:SetScript("OnMouseUp", function(_, button)
                if button == "LeftButton" then
                    self.SelectedGuildSettingRequisitionIndex = itemIndex
                    self.SelectedGuildSettingCostIndex = nil
                    self:RefreshGuildSettingRequisitionsPage()
                end
            end)
            setRowSelection(row, tonumber(self.SelectedGuildSettingRequisitionIndex) == tonumber(itemIndex))
        end
    end)
    self.GuildSettingInspectorRequisitionScroll:Create()
    UI.Utils.AnchorFill(self.GuildSettingInspectorRequisitionScroll, requisitionPanel:GetContentFrame(), 0, 0, 0, 0)

    local requisitionActions = UI.CreateLayout(UI.HorizontalLayoutGroup, root:GetFrame(), "RPEDataEditorGuildSettingInspectorRequisitionActions", {
        spacing = 2, height = 18, fitChildrenWidth = true, fitChildrenHeight = false,
    })
    self.GuildSettingInspectorAddRequisitionButton = UI.CreateButton(requisitionActions:GetFrame(), "RPEDataEditorGuildSettingInspectorAddRequisitionButton", "Add", 42, function()
        local guildSetting = self:CommitSelectedGuildSetting(function(selected)
            selected.requisitions = selected.requisitions or {}
            selected.requisitions[#selected.requisitions + 1] = {
                id = buildUniqueStableId(selected.requisitions, nil, "", "requisition"),
                itemRef = "",
                quantity = 1,
                characterLimit = 1,
                costs = {},
            }
        end)
        self.SelectedGuildSettingRequisitionIndex = guildSetting and #(guildSetting.requisitions or {}) or nil
        self.SelectedGuildSettingCostIndex = nil
        self:RefreshGuildSettingRequisitionsPage()
    end, { height = 18, fontSize = 7 })
    requisitionActions:AddChild(self.GuildSettingInspectorAddRequisitionButton)
    self.GuildSettingInspectorDeleteRequisitionButton = UI.CreateButton(requisitionActions:GetFrame(), "RPEDataEditorGuildSettingInspectorDeleteRequisitionButton", "Delete", 48, function()
        local selectedIndex = tonumber(self.SelectedGuildSettingRequisitionIndex)
        local guildSetting = self:CommitSelectedGuildSetting(function(selected)
            if selectedIndex and selected.requisitions and selected.requisitions[selectedIndex] then
                table.remove(selected.requisitions, selectedIndex)
            end
        end)
        local requisitions = guildSetting and guildSetting.requisitions or {}
        self.SelectedGuildSettingRequisitionIndex = #requisitions > 0 and math.min(selectedIndex or 1, #requisitions) or nil
        self.SelectedGuildSettingCostIndex = nil
        self:RefreshGuildSettingRequisitionsPage()
    end, { height = 18, fontSize = 7 })
    requisitionActions:AddChild(self.GuildSettingInspectorDeleteRequisitionButton)
    root:AddChild(requisitionActions)

    root:AddChild(createLabel(root:GetFrame(), "RPEDataEditorGuildSettingInspectorRequisitionIdLabel", "Requisition ID"))
    self.GuildSettingInspectorRequisitionIdInput = UI.CreateTextInput(root:GetFrame(), "RPEDataEditorGuildSettingInspectorRequisitionIdInput", {
        width = FIELD_WIDTH, height = 18, text = "", borderColor = UI.ResolveColor(nil, "panel.border"),
    })
    local commitRequisitionId = function()
        local selectedIndex = tonumber(self.SelectedGuildSettingRequisitionIndex)
        self:CommitSelectedGuildSetting(function(guildSetting)
            local requisitions = guildSetting.requisitions or {}
            local requisition = requisitions[selectedIndex]
            if requisition then
                requisition.id = buildUniqueStableId(requisitions, selectedIndex, self.GuildSettingInspectorRequisitionIdInput:GetText(), "requisition")
            end
        end)
        self:RefreshGuildSettingRequisitionsPage()
    end
    self.GuildSettingInspectorRequisitionIdInput:SetScript("OnEnterPressed", commitRequisitionId)
    self.GuildSettingInspectorRequisitionIdInput:SetScript("OnEditFocusLost", commitRequisitionId)
    root:AddChild(self.GuildSettingInspectorRequisitionIdInput)

    root:AddChild(createLabel(root:GetFrame(), "RPEDataEditorGuildSettingInspectorRequisitionItemRefLabel", "Item Ref"))
    self.GuildSettingInspectorRequisitionItemRefInput = UI.CreateTextInput(root:GetFrame(), "RPEDataEditorGuildSettingInspectorRequisitionItemRefInput", {
        width = FIELD_WIDTH, height = 18, text = "", borderColor = UI.ResolveColor(nil, "panel.border"),
    })
    local commitRequisitionItemRef = function()
        local _, _, selectedIndex = getSelectedRequisition(self)
        self:CommitSelectedGuildSetting(function(guildSetting)
            local requisition = guildSetting.requisitions and guildSetting.requisitions[selectedIndex]
            if requisition then
                requisition.itemRef = self.GuildSettingInspectorRequisitionItemRefInput:GetText()
            end
        end)
    end
    self.GuildSettingInspectorRequisitionItemRefInput:SetScript("OnEnterPressed", commitRequisitionItemRef)
    self.GuildSettingInspectorRequisitionItemRefInput:SetScript("OnEditFocusLost", commitRequisitionItemRef)
    root:AddChild(self.GuildSettingInspectorRequisitionItemRefInput)

    local numberLabels = UI.CreateLayout(UI.HorizontalLayoutGroup, root:GetFrame(), "RPEDataEditorGuildSettingInspectorRequisitionNumberLabels", {
        spacing = 2, height = 12, fitChildrenWidth = true, fitChildrenHeight = false,
    })
    numberLabels:AddChild(createLabel(numberLabels:GetFrame(), "RPEDataEditorGuildSettingInspectorQuantityLabel", "Quantity", 114))
    numberLabels:AddChild(createLabel(numberLabels:GetFrame(), "RPEDataEditorGuildSettingInspectorLimitLabel", "Character Limit", 114))
    root:AddChild(numberLabels)

    local numberInputs = UI.CreateLayout(UI.HorizontalLayoutGroup, root:GetFrame(), "RPEDataEditorGuildSettingInspectorRequisitionNumberInputs", {
        spacing = 2, height = 18, fitChildrenWidth = true, fitChildrenHeight = false,
    })
    self.GuildSettingInspectorRequisitionQuantityInput = UI.CreateTextInput(numberInputs:GetFrame(), "RPEDataEditorGuildSettingInspectorRequisitionQuantityInput", {
        width = 114, height = 18, text = "1", borderColor = UI.ResolveColor(nil, "panel.border"),
    })
    numberInputs:AddChild(self.GuildSettingInspectorRequisitionQuantityInput)
    self.GuildSettingInspectorRequisitionLimitInput = UI.CreateTextInput(numberInputs:GetFrame(), "RPEDataEditorGuildSettingInspectorRequisitionLimitInput", {
        width = 114, height = 18, text = "1", borderColor = UI.ResolveColor(nil, "panel.border"),
    })
    numberInputs:AddChild(self.GuildSettingInspectorRequisitionLimitInput)
    local commitRequisitionNumbers = function()
        local _, _, selectedIndex = getSelectedRequisition(self)
        self:CommitSelectedGuildSetting(function(guildSetting)
            local requisition = guildSetting.requisitions and guildSetting.requisitions[selectedIndex]
            if requisition then
                requisition.quantity = normalizeInteger(self.GuildSettingInspectorRequisitionQuantityInput:GetText(), 1, 1)
                requisition.characterLimit = normalizeInteger(self.GuildSettingInspectorRequisitionLimitInput:GetText(), 1, 0)
            end
        end)
    end
    for _, input in ipairs({ self.GuildSettingInspectorRequisitionQuantityInput, self.GuildSettingInspectorRequisitionLimitInput }) do
        input:SetScript("OnEnterPressed", commitRequisitionNumbers)
        input:SetScript("OnEditFocusLost", commitRequisitionNumbers)
    end
    root:AddChild(numberInputs)

    root:AddChild(createLabel(root:GetFrame(), "RPEDataEditorGuildSettingInspectorCostsLabel", "Costs (Currency Ref / Amount)"))
    local costPanel = UI.CreatePanel(root:GetFrame(), "RPEDataEditorGuildSettingInspectorCostPanel", {
        width = FIELD_WIDTH, height = 46, contentInset = 2, showBorder = false,
    })
    root:AddChild(costPanel)
    self.GuildSettingInspectorCostScroll = UI.ScrollLayout:New({
        name = "RPEDataEditorGuildSettingInspectorCostScroll",
        width = FIELD_WIDTH - 4, height = 42, visibleRows = 2, autoFitRows = true,
        rowHeight = 18, rowSpacing = 0, border = false, rowElementClass = UI.ScrollListEntry,
        categoryWidth = 172, statusWidth = 48, categoryInsetLeft = 4, statusInsetRight = 4,
    })
    self.GuildSettingInspectorCostScroll:SetParent(costPanel:GetContentFrame())
    self.GuildSettingInspectorCostScroll:SetRowRenderer(function(row, cost, itemIndex)
        row:SetCategory(tostring(cost and cost.currencyRef or ""))
        row:SetTestName("")
        row:SetStatus(tostring(normalizeInteger(cost and cost.amount, 0, 0)))
        row:SetDetail("")
        local frame = row.GetFrame and row:GetFrame() or nil
        if frame then
            frame:EnableMouse(true)
            frame:SetScript("OnMouseUp", function(_, button)
                if button == "LeftButton" then
                    self.SelectedGuildSettingCostIndex = itemIndex
                    self:RefreshGuildSettingRequisitionsPage()
                end
            end)
            setRowSelection(row, tonumber(self.SelectedGuildSettingCostIndex) == tonumber(itemIndex))
        end
    end)
    self.GuildSettingInspectorCostScroll:Create()
    UI.Utils.AnchorFill(self.GuildSettingInspectorCostScroll, costPanel:GetContentFrame(), 0, 0, 0, 0)

    local costActions = UI.CreateLayout(UI.HorizontalLayoutGroup, root:GetFrame(), "RPEDataEditorGuildSettingInspectorCostActions", {
        spacing = 2, height = 18, fitChildrenWidth = true, fitChildrenHeight = false,
    })
    self.GuildSettingInspectorAddCostButton = UI.CreateButton(costActions:GetFrame(), "RPEDataEditorGuildSettingInspectorAddCostButton", "Add Cost", 62, function()
        local guildSetting = self:CommitSelectedGuildSetting(function(selected)
            local requisition = selected.requisitions and selected.requisitions[self.SelectedGuildSettingRequisitionIndex]
            if requisition then
                requisition.costs = requisition.costs or {}
                requisition.costs[#requisition.costs + 1] = { currencyRef = "", amount = 0 }
            end
        end)
        local requisition = guildSetting and guildSetting.requisitions and guildSetting.requisitions[self.SelectedGuildSettingRequisitionIndex]
        self.SelectedGuildSettingCostIndex = requisition and #requisition.costs or nil
        self:RefreshGuildSettingRequisitionsPage()
    end, { height = 18, fontSize = 7 })
    costActions:AddChild(self.GuildSettingInspectorAddCostButton)
    self.GuildSettingInspectorDeleteCostButton = UI.CreateButton(costActions:GetFrame(), "RPEDataEditorGuildSettingInspectorDeleteCostButton", "Delete", 48, function()
        local selectedCostIndex = tonumber(self.SelectedGuildSettingCostIndex)
        local guildSetting = self:CommitSelectedGuildSetting(function(selected)
            local requisition = selected.requisitions and selected.requisitions[self.SelectedGuildSettingRequisitionIndex]
            if requisition and selectedCostIndex and requisition.costs and requisition.costs[selectedCostIndex] then
                table.remove(requisition.costs, selectedCostIndex)
            end
        end)
        local requisition = guildSetting and guildSetting.requisitions and guildSetting.requisitions[self.SelectedGuildSettingRequisitionIndex]
        self.SelectedGuildSettingCostIndex = requisition and #requisition.costs > 0 and math.min(selectedCostIndex or 1, #requisition.costs) or nil
        self:RefreshGuildSettingRequisitionsPage()
    end, { height = 18, fontSize = 7 })
    costActions:AddChild(self.GuildSettingInspectorDeleteCostButton)
    root:AddChild(costActions)

    local costInputs = UI.CreateLayout(UI.HorizontalLayoutGroup, root:GetFrame(), "RPEDataEditorGuildSettingInspectorCostInputs", {
        spacing = 2, height = 18, fitChildrenWidth = true, fitChildrenHeight = false,
    })
    self.GuildSettingInspectorCostCurrencyRefInput = UI.CreateTextInput(costInputs:GetFrame(), "RPEDataEditorGuildSettingInspectorCostCurrencyRefInput", {
        width = 174, height = 18, text = "", borderColor = UI.ResolveColor(nil, "panel.border"),
    })
    costInputs:AddChild(self.GuildSettingInspectorCostCurrencyRefInput)
    self.GuildSettingInspectorCostAmountInput = UI.CreateTextInput(costInputs:GetFrame(), "RPEDataEditorGuildSettingInspectorCostAmountInput", {
        width = 60, height = 18, text = "0", borderColor = UI.ResolveColor(nil, "panel.border"),
    })
    costInputs:AddChild(self.GuildSettingInspectorCostAmountInput)
    local commitCost = function()
        local _, _, requisitionIndex = getSelectedRequisition(self)
        local costIndex = tonumber(self.SelectedGuildSettingCostIndex)
        self:CommitSelectedGuildSetting(function(guildSetting)
            local requisition = guildSetting.requisitions and guildSetting.requisitions[requisitionIndex]
            local cost = requisition and requisition.costs and requisition.costs[costIndex]
            if cost then
                cost.currencyRef = self.GuildSettingInspectorCostCurrencyRefInput:GetText()
                cost.amount = normalizeInteger(self.GuildSettingInspectorCostAmountInput:GetText(), 0, 0)
            end
        end)
    end
    self.GuildSettingInspectorCostCurrencyRefInput:SetScript("OnEnterPressed", commitCost)
    self.GuildSettingInspectorCostCurrencyRefInput:SetScript("OnEditFocusLost", commitCost)
    self.GuildSettingInspectorCostAmountInput:SetScript("OnEnterPressed", commitCost)
    self.GuildSettingInspectorCostAmountInput:SetScript("OnEditFocusLost", commitCost)
    root:AddChild(costInputs)
end

function DataEditor:BuildGuildSettingInspectorDailyRewardsPage(parent)
    local root = UI.CreateLayout(UI.VerticalLayoutGroup, parent, "RPEDataEditorGuildSettingInspectorDailyRewardsLayout", {
        spacing = 2, fitChildrenWidth = true, fitChildrenHeight = false,
    })
    UI.Utils.AnchorFill(root, parent, 0, 0, 0, 0)

    root:AddChild(createLabel(root:GetFrame(), "RPEDataEditorGuildSettingInspectorDailyRewardsLabel", "Daily Rewards"))
    local panel = UI.CreatePanel(root:GetFrame(), "RPEDataEditorGuildSettingInspectorDailyRewardPanel", {
        width = FIELD_WIDTH, height = 72, contentInset = 2, showBorder = false,
    })
    root:AddChild(panel)
    self.GuildSettingInspectorDailyRewardScroll = UI.ScrollLayout:New({
        name = "RPEDataEditorGuildSettingInspectorDailyRewardScroll",
        width = FIELD_WIDTH - 4, height = 68, visibleRows = 4, autoFitRows = true,
        rowHeight = 18, rowSpacing = 0, border = false, rowElementClass = UI.ScrollListEntry,
        categoryWidth = 112, statusWidth = 54, categoryInsetLeft = 4, statusInsetRight = 4,
    })
    self.GuildSettingInspectorDailyRewardScroll:SetParent(panel:GetContentFrame())
    self.GuildSettingInspectorDailyRewardScroll:SetRowRenderer(function(row, reward, itemIndex)
        row:SetCategory(tostring(reward and reward.id or "-"))
        row:SetTestName("")
        row:SetStatus(tostring(reward and reward.type or "item"))
        row:SetDetail(("%s x%d"):format(tostring(reward and reward.ref or ""), normalizeInteger(reward and reward.amount, 1, 1)))
        local frame = row.GetFrame and row:GetFrame() or nil
        if frame then
            frame:EnableMouse(true)
            frame:SetScript("OnMouseUp", function(_, button)
                if button == "LeftButton" then
                    self.SelectedGuildSettingDailyRewardIndex = itemIndex
                    self:RefreshGuildSettingDailyRewardsPage()
                end
            end)
            setRowSelection(row, tonumber(self.SelectedGuildSettingDailyRewardIndex) == tonumber(itemIndex))
        end
    end)
    self.GuildSettingInspectorDailyRewardScroll:Create()
    UI.Utils.AnchorFill(self.GuildSettingInspectorDailyRewardScroll, panel:GetContentFrame(), 0, 0, 0, 0)

    local actions = UI.CreateLayout(UI.HorizontalLayoutGroup, root:GetFrame(), "RPEDataEditorGuildSettingInspectorDailyRewardActions", {
        spacing = 2, height = 18, fitChildrenWidth = true, fitChildrenHeight = false,
    })
    self.GuildSettingInspectorAddDailyRewardButton = UI.CreateButton(actions:GetFrame(), "RPEDataEditorGuildSettingInspectorAddDailyRewardButton", "Add", 42, function()
        local guildSetting = self:CommitSelectedGuildSetting(function(selected)
            selected.dailyRewards = selected.dailyRewards or {}
            selected.dailyRewards[#selected.dailyRewards + 1] = {
                id = buildUniqueStableId(selected.dailyRewards, nil, "", "daily_reward"),
                type = "item",
                ref = "",
                amount = 1,
            }
        end)
        self.SelectedGuildSettingDailyRewardIndex = guildSetting and #(guildSetting.dailyRewards or {}) or nil
        self:RefreshGuildSettingDailyRewardsPage()
    end, { height = 18, fontSize = 7 })
    actions:AddChild(self.GuildSettingInspectorAddDailyRewardButton)
    self.GuildSettingInspectorDeleteDailyRewardButton = UI.CreateButton(actions:GetFrame(), "RPEDataEditorGuildSettingInspectorDeleteDailyRewardButton", "Delete", 48, function()
        local selectedIndex = tonumber(self.SelectedGuildSettingDailyRewardIndex)
        local guildSetting = self:CommitSelectedGuildSetting(function(selected)
            if selectedIndex and selected.dailyRewards and selected.dailyRewards[selectedIndex] then
                table.remove(selected.dailyRewards, selectedIndex)
            end
        end)
        local rewards = guildSetting and guildSetting.dailyRewards or {}
        self.SelectedGuildSettingDailyRewardIndex = #rewards > 0 and math.min(selectedIndex or 1, #rewards) or nil
        self:RefreshGuildSettingDailyRewardsPage()
    end, { height = 18, fontSize = 7 })
    actions:AddChild(self.GuildSettingInspectorDeleteDailyRewardButton)
    root:AddChild(actions)

    root:AddChild(createLabel(root:GetFrame(), "RPEDataEditorGuildSettingInspectorDailyRewardIdLabel", "Reward ID"))
    self.GuildSettingInspectorDailyRewardIdInput = UI.CreateTextInput(root:GetFrame(), "RPEDataEditorGuildSettingInspectorDailyRewardIdInput", {
        width = FIELD_WIDTH, height = 18, text = "", borderColor = UI.ResolveColor(nil, "panel.border"),
    })
    local commitDailyRewardId = function()
        local selectedIndex = tonumber(self.SelectedGuildSettingDailyRewardIndex)
        self:CommitSelectedGuildSetting(function(guildSetting)
            local rewards = guildSetting.dailyRewards or {}
            local reward = rewards[selectedIndex]
            if reward then
                reward.id = buildUniqueStableId(rewards, selectedIndex, self.GuildSettingInspectorDailyRewardIdInput:GetText(), "daily_reward")
            end
        end)
        self:RefreshGuildSettingDailyRewardsPage()
    end
    self.GuildSettingInspectorDailyRewardIdInput:SetScript("OnEnterPressed", commitDailyRewardId)
    self.GuildSettingInspectorDailyRewardIdInput:SetScript("OnEditFocusLost", commitDailyRewardId)
    root:AddChild(self.GuildSettingInspectorDailyRewardIdInput)

    root:AddChild(createLabel(root:GetFrame(), "RPEDataEditorGuildSettingInspectorDailyRewardTypeLabel", "Type"))
    self.GuildSettingInspectorDailyRewardTypeDropdown = UI.CreateDropdown(root:GetFrame(), "RPEDataEditorGuildSettingInspectorDailyRewardTypeDropdown", {
        width = FIELD_WIDTH, height = 18, items = DAILY_REWARD_TYPE_ITEMS,
        onValueChanged = function(value)
            if self._refreshingGuildSettingInspector then
                return
            end
            local selectedIndex = tonumber(self.SelectedGuildSettingDailyRewardIndex)
            self:CommitSelectedGuildSetting(function(guildSetting)
                local reward = guildSetting.dailyRewards and guildSetting.dailyRewards[selectedIndex]
                if reward then
                    reward.type = value
                end
            end)
            self:RefreshGuildSettingDailyRewardsPage()
        end,
    })
    root:AddChild(self.GuildSettingInspectorDailyRewardTypeDropdown)

    root:AddChild(createLabel(root:GetFrame(), "RPEDataEditorGuildSettingInspectorDailyRewardRefLabel", "Ref"))
    self.GuildSettingInspectorDailyRewardRefInput = UI.CreateTextInput(root:GetFrame(), "RPEDataEditorGuildSettingInspectorDailyRewardRefInput", {
        width = FIELD_WIDTH, height = 18, text = "", borderColor = UI.ResolveColor(nil, "panel.border"),
    })
    local commitDailyRewardRef = function()
        local selectedIndex = tonumber(self.SelectedGuildSettingDailyRewardIndex)
        self:CommitSelectedGuildSetting(function(guildSetting)
            local reward = guildSetting.dailyRewards and guildSetting.dailyRewards[selectedIndex]
            if reward then
                reward.ref = self.GuildSettingInspectorDailyRewardRefInput:GetText()
            end
        end)
    end
    self.GuildSettingInspectorDailyRewardRefInput:SetScript("OnEnterPressed", commitDailyRewardRef)
    self.GuildSettingInspectorDailyRewardRefInput:SetScript("OnEditFocusLost", commitDailyRewardRef)
    root:AddChild(self.GuildSettingInspectorDailyRewardRefInput)

    root:AddChild(createLabel(root:GetFrame(), "RPEDataEditorGuildSettingInspectorDailyRewardAmountLabel", "Amount"))
    self.GuildSettingInspectorDailyRewardAmountInput = UI.CreateTextInput(root:GetFrame(), "RPEDataEditorGuildSettingInspectorDailyRewardAmountInput", {
        width = FIELD_WIDTH, height = 18, text = "1", borderColor = UI.ResolveColor(nil, "panel.border"),
    })
    local commitDailyRewardAmount = function()
        local selectedIndex = tonumber(self.SelectedGuildSettingDailyRewardIndex)
        self:CommitSelectedGuildSetting(function(guildSetting)
            local reward = guildSetting.dailyRewards and guildSetting.dailyRewards[selectedIndex]
            if reward then
                reward.amount = normalizeInteger(self.GuildSettingInspectorDailyRewardAmountInput:GetText(), 1, 1)
            end
        end)
    end
    self.GuildSettingInspectorDailyRewardAmountInput:SetScript("OnEnterPressed", commitDailyRewardAmount)
    self.GuildSettingInspectorDailyRewardAmountInput:SetScript("OnEditFocusLost", commitDailyRewardAmount)
    root:AddChild(self.GuildSettingInspectorDailyRewardAmountInput)
end

function DataEditor:BuildGuildSettingInspectorProgressionPage(parent)
    local root = UI.CreateLayout(UI.VerticalLayoutGroup, parent, "RPEDataEditorGuildSettingInspectorProgressionLayout", {
        spacing = 2, fitChildrenWidth = true, fitChildrenHeight = false,
    })
    UI.Utils.AnchorFill(root, parent, 0, 0, 0, 0)

    root:AddChild(createLabel(root:GetFrame(), "RPEDataEditorGuildSettingInspectorProgressionLabel", "Progression (structural configuration)"))
    local slotRow = UI.CreateLayout(UI.HorizontalLayoutGroup, root:GetFrame(), "RPEDataEditorGuildSettingInspectorSlotRow", {
        spacing = 2, height = 18, fitChildrenWidth = true, fitChildrenHeight = false,
    })
    slotRow:AddChild(createLabel(slotRow:GetFrame(), "RPEDataEditorGuildSettingInspectorSlotCountLabel", "Slot Count", 76))
    self.GuildSettingInspectorSlotCountInput = UI.CreateTextInput(slotRow:GetFrame(), "RPEDataEditorGuildSettingInspectorSlotCountInput", {
        width = 76, height = 18, text = "3", borderColor = UI.ResolveColor(nil, "panel.border"),
    })
    slotRow:AddChild(self.GuildSettingInspectorSlotCountInput)
    self.GuildSettingInspectorSlotCountInput:SetScript("OnEnterPressed", function()
        self:CommitSelectedGuildSetting(function(guildSetting)
            guildSetting.progression = guildSetting.progression or {}
            guildSetting.progression.slotCount = normalizeInteger(self.GuildSettingInspectorSlotCountInput:GetText(), 3, 1)
        end)
    end)
    self.GuildSettingInspectorSlotCountInput:SetScript("OnEditFocusLost", function()
        self:CommitSelectedGuildSetting(function(guildSetting)
            guildSetting.progression = guildSetting.progression or {}
            guildSetting.progression.slotCount = normalizeInteger(self.GuildSettingInspectorSlotCountInput:GetText(), 3, 1)
        end)
    end)
    root:AddChild(slotRow)

    root:AddChild(createLabel(root:GetFrame(), "RPEDataEditorGuildSettingInspectorProgressionEntriesLabel", "Progression Entries"))
    local entryPanel = UI.CreatePanel(root:GetFrame(), "RPEDataEditorGuildSettingInspectorProgressionEntryPanel", {
        width = FIELD_WIDTH, height = 58, contentInset = 2, showBorder = false,
    })
    root:AddChild(entryPanel)
    self.GuildSettingInspectorProgressionEntryScroll = UI.ScrollLayout:New({
        name = "RPEDataEditorGuildSettingInspectorProgressionEntryScroll",
        width = FIELD_WIDTH - 4, height = 54, visibleRows = 3, autoFitRows = true,
        rowHeight = 18, rowSpacing = 0, border = false, rowElementClass = UI.ScrollListEntry,
        categoryWidth = 112, statusWidth = 54, categoryInsetLeft = 4, statusInsetRight = 4,
    })
    self.GuildSettingInspectorProgressionEntryScroll:SetParent(entryPanel:GetContentFrame())
    self.GuildSettingInspectorProgressionEntryScroll:SetRowRenderer(function(row, entry, itemIndex)
        row:SetCategory(tostring(entry and entry.id or "-"))
        row:SetTestName("")
        row:SetStatus(tostring(entry and entry.name or ""))
        row:SetDetail(tostring(entry and entry.description or ""))
        local frame = row.GetFrame and row:GetFrame() or nil
        if frame then
            frame:EnableMouse(true)
            frame:SetScript("OnMouseUp", function(_, button)
                if button == "LeftButton" then
                    self.SelectedGuildSettingProgressionEntryIndex = itemIndex
                    self.SelectedGuildSettingSpellRefIndex = nil
                    self:RefreshGuildSettingProgressionPage()
                end
            end)
            setRowSelection(row, tonumber(self.SelectedGuildSettingProgressionEntryIndex) == tonumber(itemIndex))
        end
    end)
    self.GuildSettingInspectorProgressionEntryScroll:Create()
    UI.Utils.AnchorFill(self.GuildSettingInspectorProgressionEntryScroll, entryPanel:GetContentFrame(), 0, 0, 0, 0)

    local entryActions = UI.CreateLayout(UI.HorizontalLayoutGroup, root:GetFrame(), "RPEDataEditorGuildSettingInspectorProgressionEntryActions", {
        spacing = 2, height = 18, fitChildrenWidth = true, fitChildrenHeight = false,
    })
    self.GuildSettingInspectorAddProgressionEntryButton = UI.CreateButton(entryActions:GetFrame(), "RPEDataEditorGuildSettingInspectorAddProgressionEntryButton", "Add", 42, function()
        local guildSetting = self:CommitSelectedGuildSetting(function(selected)
            selected.progression = selected.progression or {}
            selected.progression.entries = selected.progression.entries or {}
            selected.progression.entries[#selected.progression.entries + 1] = {
                id = buildUniqueStableId(selected.progression.entries, nil, "", "progression_entry"),
                name = "",
                description = "",
                icon = "",
                lockedText = "",
                spellRefs = {},
            }
        end)
        local entries = guildSetting and guildSetting.progression and guildSetting.progression.entries or {}
        self.SelectedGuildSettingProgressionEntryIndex = #entries
        self.SelectedGuildSettingSpellRefIndex = nil
        self:RefreshGuildSettingProgressionPage()
    end, { height = 18, fontSize = 7 })
    entryActions:AddChild(self.GuildSettingInspectorAddProgressionEntryButton)
    self.GuildSettingInspectorDeleteProgressionEntryButton = UI.CreateButton(entryActions:GetFrame(), "RPEDataEditorGuildSettingInspectorDeleteProgressionEntryButton", "Delete", 48, function()
        local selectedIndex = tonumber(self.SelectedGuildSettingProgressionEntryIndex)
        local guildSetting = self:CommitSelectedGuildSetting(function(selected)
            local entries = selected.progression and selected.progression.entries or {}
            if selectedIndex and entries[selectedIndex] then
                table.remove(entries, selectedIndex)
            end
        end)
        local entries = guildSetting and guildSetting.progression and guildSetting.progression.entries or {}
        self.SelectedGuildSettingProgressionEntryIndex = #entries > 0 and math.min(selectedIndex or 1, #entries) or nil
        self.SelectedGuildSettingSpellRefIndex = nil
        self:RefreshGuildSettingProgressionPage()
    end, { height = 18, fontSize = 7 })
    entryActions:AddChild(self.GuildSettingInspectorDeleteProgressionEntryButton)
    root:AddChild(entryActions)

    root:AddChild(createLabel(root:GetFrame(), "RPEDataEditorGuildSettingInspectorProgressionEntryIdLabel", "Entry ID"))
    self.GuildSettingInspectorProgressionEntryIdInput = UI.CreateTextInput(root:GetFrame(), "RPEDataEditorGuildSettingInspectorProgressionEntryIdInput", {
        width = FIELD_WIDTH, height = 18, text = "", borderColor = UI.ResolveColor(nil, "panel.border"),
    })
    local commitProgressionEntryId = function()
        local selectedIndex = tonumber(self.SelectedGuildSettingProgressionEntryIndex)
        self:CommitSelectedGuildSetting(function(guildSetting)
            local entries = guildSetting.progression and guildSetting.progression.entries or {}
            local entry = entries[selectedIndex]
            if entry then
                entry.id = buildUniqueStableId(entries, selectedIndex, self.GuildSettingInspectorProgressionEntryIdInput:GetText(), "progression_entry")
            end
        end)
        self:RefreshGuildSettingProgressionPage()
    end
    self.GuildSettingInspectorProgressionEntryIdInput:SetScript("OnEnterPressed", commitProgressionEntryId)
    self.GuildSettingInspectorProgressionEntryIdInput:SetScript("OnEditFocusLost", commitProgressionEntryId)
    root:AddChild(self.GuildSettingInspectorProgressionEntryIdInput)

    root:AddChild(createLabel(root:GetFrame(), "RPEDataEditorGuildSettingInspectorProgressionEntryNameLabel", "Entry Name"))
    self.GuildSettingInspectorProgressionEntryNameInput = UI.CreateTextInput(root:GetFrame(), "RPEDataEditorGuildSettingInspectorProgressionEntryNameInput", {
        width = FIELD_WIDTH, height = 18, text = "", borderColor = UI.ResolveColor(nil, "panel.border"),
    })
    local commitProgressionEntryName = function()
        local selectedIndex = tonumber(self.SelectedGuildSettingProgressionEntryIndex)
        self:CommitSelectedGuildSetting(function(guildSetting)
            local entries = guildSetting.progression and guildSetting.progression.entries or {}
            if entries[selectedIndex] then
                entries[selectedIndex].name = self.GuildSettingInspectorProgressionEntryNameInput:GetText()
            end
        end)
    end
    self.GuildSettingInspectorProgressionEntryNameInput:SetScript("OnEnterPressed", commitProgressionEntryName)
    self.GuildSettingInspectorProgressionEntryNameInput:SetScript("OnEditFocusLost", commitProgressionEntryName)
    root:AddChild(self.GuildSettingInspectorProgressionEntryNameInput)

    root:AddChild(createLabel(root:GetFrame(), "RPEDataEditorGuildSettingInspectorProgressionEntryDescriptionLabel", "Description"))
    self.GuildSettingInspectorProgressionEntryDescriptionInput = UI.CreateTextInput(root:GetFrame(), "RPEDataEditorGuildSettingInspectorProgressionEntryDescriptionInput", {
        width = FIELD_WIDTH, height = 18, text = "", borderColor = UI.ResolveColor(nil, "panel.border"),
    })
    local commitProgressionEntryDescription = function()
        local selectedIndex = tonumber(self.SelectedGuildSettingProgressionEntryIndex)
        self:CommitSelectedGuildSetting(function(guildSetting)
            local entries = guildSetting.progression and guildSetting.progression.entries or {}
            if entries[selectedIndex] then
                entries[selectedIndex].description = self.GuildSettingInspectorProgressionEntryDescriptionInput:GetText()
            end
        end)
    end
    self.GuildSettingInspectorProgressionEntryDescriptionInput:SetScript("OnEnterPressed", commitProgressionEntryDescription)
    self.GuildSettingInspectorProgressionEntryDescriptionInput:SetScript("OnEditFocusLost", commitProgressionEntryDescription)
    root:AddChild(self.GuildSettingInspectorProgressionEntryDescriptionInput)

    root:AddChild(createLabel(root:GetFrame(), "RPEDataEditorGuildSettingInspectorProgressionEntryIconLabel", "Icon"))
    self.GuildSettingInspectorProgressionEntryIconField = UI.EditorIconField:New({
        name = "RPEDataEditorGuildSettingInspectorProgressionEntryIconField",
        width = FIELD_WIDTH, height = 18, buttonText = "Select Icon", labelText = "-", iconTexture = DEFAULT_ICON, border = false,
    })
    self.GuildSettingInspectorProgressionEntryIconField:SetParent(root:GetFrame())
    self.GuildSettingInspectorProgressionEntryIconField:Create()
    local iconButton = self.GuildSettingInspectorProgressionEntryIconField:GetButton()
    if iconButton and iconButton.SetScript then
        iconButton:SetScript("OnClick", function()
            local _, _, _, entry = getSelectedProgressionEntry(self)
            if not entry or not Client.OpenIconFinder then
                return
            end
            Client:OpenIconFinder(function(_, filePath)
                self:CommitSelectedGuildSetting(function(guildSetting)
                    local entries = guildSetting.progression and guildSetting.progression.entries or {}
                    local selected = entries[self.SelectedGuildSettingProgressionEntryIndex]
                    if selected then
                        selected.icon = filePath or ""
                    end
                end)
                self:RefreshGuildSettingProgressionPage()
            end, { filter = entry.icon or "" })
        end)
    end
    root:AddChild(self.GuildSettingInspectorProgressionEntryIconField)

    root:AddChild(createLabel(root:GetFrame(), "RPEDataEditorGuildSettingInspectorProgressionEntryLockedTextLabel", "Locked Text"))
    self.GuildSettingInspectorProgressionEntryLockedTextInput = UI.CreateTextInput(root:GetFrame(), "RPEDataEditorGuildSettingInspectorProgressionEntryLockedTextInput", {
        width = FIELD_WIDTH, height = 18, text = "", borderColor = UI.ResolveColor(nil, "panel.border"),
    })
    local commitProgressionEntryLockedText = function()
        local selectedIndex = tonumber(self.SelectedGuildSettingProgressionEntryIndex)
        self:CommitSelectedGuildSetting(function(guildSetting)
            local entries = guildSetting.progression and guildSetting.progression.entries or {}
            if entries[selectedIndex] then
                entries[selectedIndex].lockedText = self.GuildSettingInspectorProgressionEntryLockedTextInput:GetText()
            end
        end)
    end
    self.GuildSettingInspectorProgressionEntryLockedTextInput:SetScript("OnEnterPressed", commitProgressionEntryLockedText)
    self.GuildSettingInspectorProgressionEntryLockedTextInput:SetScript("OnEditFocusLost", commitProgressionEntryLockedText)
    root:AddChild(self.GuildSettingInspectorProgressionEntryLockedTextInput)

    root:AddChild(createLabel(root:GetFrame(), "RPEDataEditorGuildSettingInspectorSpellRefsLabel", "Spell Refs"))
    local spellPanel = UI.CreatePanel(root:GetFrame(), "RPEDataEditorGuildSettingInspectorSpellPanel", {
        width = FIELD_WIDTH, height = 40, contentInset = 2, showBorder = false,
    })
    root:AddChild(spellPanel)
    self.GuildSettingInspectorSpellRefScroll = UI.ScrollLayout:New({
        name = "RPEDataEditorGuildSettingInspectorSpellRefScroll",
        width = FIELD_WIDTH - 4, height = 36, visibleRows = 2, autoFitRows = true,
        rowHeight = 18, rowSpacing = 0, border = false, rowElementClass = UI.ScrollListEntry,
        categoryWidth = 228, statusWidth = 0, categoryInsetLeft = 4, statusInsetRight = 0,
    })
    self.GuildSettingInspectorSpellRefScroll:SetParent(spellPanel:GetContentFrame())
    self.GuildSettingInspectorSpellRefScroll:SetRowRenderer(function(row, spellRef, itemIndex)
        row:SetCategory(tostring(spellRef or ""))
        row:SetTestName("")
        row:SetStatus("")
        row:SetDetail("")
        local frame = row.GetFrame and row:GetFrame() or nil
        if frame then
            frame:EnableMouse(true)
            frame:SetScript("OnMouseUp", function(_, button)
                if button == "LeftButton" then
                    self.SelectedGuildSettingSpellRefIndex = itemIndex
                    self:RefreshGuildSettingProgressionPage()
                end
            end)
            setRowSelection(row, tonumber(self.SelectedGuildSettingSpellRefIndex) == tonumber(itemIndex))
        end
    end)
    self.GuildSettingInspectorSpellRefScroll:Create()
    UI.Utils.AnchorFill(self.GuildSettingInspectorSpellRefScroll, spellPanel:GetContentFrame(), 0, 0, 0, 0)

    local spellActions = UI.CreateLayout(UI.HorizontalLayoutGroup, root:GetFrame(), "RPEDataEditorGuildSettingInspectorSpellActions", {
        spacing = 2, height = 18, fitChildrenWidth = true, fitChildrenHeight = false,
    })
    self.GuildSettingInspectorSpellRefInput = UI.CreateTextInput(spellActions:GetFrame(), "RPEDataEditorGuildSettingInspectorSpellRefInput", {
        width = 168, height = 18, text = "", borderColor = UI.ResolveColor(nil, "panel.border"),
    })
    spellActions:AddChild(self.GuildSettingInspectorSpellRefInput)
    self.GuildSettingInspectorSaveSpellRefButton = UI.CreateButton(spellActions:GetFrame(), "RPEDataEditorGuildSettingInspectorSaveSpellRefButton", "Add/Update", 64, function()
        local value = trim(self.GuildSettingInspectorSpellRefInput:GetText())
        if value == "" then
            return
        end
        local selectedSpellIndex = tonumber(self.SelectedGuildSettingSpellRefIndex)
        local guildSetting = self:CommitSelectedGuildSetting(function(selected)
            local entry = selected.progression and selected.progression.entries and selected.progression.entries[self.SelectedGuildSettingProgressionEntryIndex]
            if entry then
                entry.spellRefs = entry.spellRefs or {}
                if selectedSpellIndex and entry.spellRefs[selectedSpellIndex] then
                    entry.spellRefs[selectedSpellIndex] = value
                else
                    entry.spellRefs[#entry.spellRefs + 1] = value
                    selectedSpellIndex = #entry.spellRefs
                end
            end
        end)
        self.SelectedGuildSettingSpellRefIndex = selectedSpellIndex
        self:RefreshGuildSettingProgressionPage()
    end, { height = 18, fontSize = 7 })
    spellActions:AddChild(self.GuildSettingInspectorSaveSpellRefButton)
    self.GuildSettingInspectorDeleteSpellRefButton = UI.CreateButton(spellActions:GetFrame(), "RPEDataEditorGuildSettingInspectorDeleteSpellRefButton", "Delete", 48, function()
        local selectedSpellIndex = tonumber(self.SelectedGuildSettingSpellRefIndex)
        self:CommitSelectedGuildSetting(function(selected)
            local entry = selected.progression and selected.progression.entries and selected.progression.entries[self.SelectedGuildSettingProgressionEntryIndex]
            if entry and selectedSpellIndex and entry.spellRefs and entry.spellRefs[selectedSpellIndex] then
                table.remove(entry.spellRefs, selectedSpellIndex)
            end
        end)
        self.SelectedGuildSettingSpellRefIndex = nil
        self:RefreshGuildSettingProgressionPage()
    end, { height = 18, fontSize = 7 })
    spellActions:AddChild(self.GuildSettingInspectorDeleteSpellRefButton)
    root:AddChild(spellActions)
end

function DataEditor:RefreshGuildSettingInspectorGeneralPage(guildSetting)
    local hasGuildSetting = guildSetting ~= nil
    local general = guildSetting and guildSetting.general or {}

    if self.GuildSettingInspectorNameInput then
        self.GuildSettingInspectorNameInput:SetText(guildSetting and (guildSetting.name or "") or "")
        setTextElementEnabled(self.GuildSettingInspectorNameInput, hasGuildSetting)
    end
    if self.GuildSettingInspectorIdText then
        self.GuildSettingInspectorIdText:SetText(("ID: %s"):format(guildSetting and tostring(guildSetting.id or "") or "-"))
    end
    if self.GuildSettingInspectorDescriptionInput then
        self.GuildSettingInspectorDescriptionInput:SetText(guildSetting and (guildSetting.description or "") or "")
        setTextElementEnabled(self.GuildSettingInspectorDescriptionInput, hasGuildSetting)
    end
    if self.GuildSettingInspectorGuildNameInput then
        self.GuildSettingInspectorGuildNameInput:SetText(guildSetting and (guildSetting.guildName or "") or "")
        setTextElementEnabled(self.GuildSettingInspectorGuildNameInput, hasGuildSetting)
    end
    if self.GuildSettingInspectorWowGuildRankIndicesInput then
        self.GuildSettingInspectorWowGuildRankIndicesInput:SetText(guildSetting and UI.Utils.JoinCommaSeparatedList(guildSetting.wowGuildRankIndices or {}) or "")
        setTextElementEnabled(self.GuildSettingInspectorWowGuildRankIndicesInput, hasGuildSetting)
    end
    if self.GuildSettingInspectorEnableRequisitionsCheckbox then
        self.GuildSettingInspectorEnableRequisitionsCheckbox:SetChecked(general.enableRequisitions == true, true)
        self.GuildSettingInspectorEnableRequisitionsCheckbox:SetEnabled(hasGuildSetting)
    end
    if self.GuildSettingInspectorEnableDailyRewardsCheckbox then
        self.GuildSettingInspectorEnableDailyRewardsCheckbox:SetChecked(general.enableDailyRewards == true, true)
        self.GuildSettingInspectorEnableDailyRewardsCheckbox:SetEnabled(hasGuildSetting)
    end
    if self.GuildSettingInspectorEnableProgressionCheckbox then
        self.GuildSettingInspectorEnableProgressionCheckbox:SetChecked(general.enableProgression == true, true)
        self.GuildSettingInspectorEnableProgressionCheckbox:SetEnabled(hasGuildSetting)
    end
    if self.GuildSettingInspectorTagsInput then
        self.GuildSettingInspectorTagsInput:SetText(guildSetting and UI.Utils.JoinCommaSeparatedList(guildSetting.tags or {}) or "")
        setTextElementEnabled(self.GuildSettingInspectorTagsInput, hasGuildSetting)
    end
end

function DataEditor:RefreshGuildSettingRequisitionsPage()
    local guildSetting, requisitions = self:GetSelectedGuildSetting(), nil
    requisitions = guildSetting and guildSetting.requisitions or {}
    local requisitionIndex = tonumber(self.SelectedGuildSettingRequisitionIndex)
    if requisitionIndex and not requisitions[requisitionIndex] then
        requisitionIndex = #requisitions > 0 and math.min(requisitionIndex, #requisitions) or nil
        self.SelectedGuildSettingRequisitionIndex = requisitionIndex
    end
    local requisition = requisitionIndex and requisitions[requisitionIndex] or nil
    local costs = requisition and requisition.costs or {}
    local costIndex = tonumber(self.SelectedGuildSettingCostIndex)
    if costIndex and not costs[costIndex] then
        costIndex = #costs > 0 and math.min(costIndex, #costs) or nil
        self.SelectedGuildSettingCostIndex = costIndex
    end
    local cost = costIndex and costs[costIndex] or nil

    if self.GuildSettingInspectorRequisitionScroll then
        self.GuildSettingInspectorRequisitionScroll:SetItems(requisitions)
    end
    if self.GuildSettingInspectorAddRequisitionButton then
        self.GuildSettingInspectorAddRequisitionButton:SetEnabled(guildSetting ~= nil)
    end
    if self.GuildSettingInspectorDeleteRequisitionButton then
        self.GuildSettingInspectorDeleteRequisitionButton:SetEnabled(requisition ~= nil)
    end
    if self.GuildSettingInspectorRequisitionIdInput then
        self.GuildSettingInspectorRequisitionIdInput:SetText(requisition and (requisition.id or "") or "")
        setTextElementEnabled(self.GuildSettingInspectorRequisitionIdInput, requisition ~= nil)
    end
    if self.GuildSettingInspectorRequisitionItemRefInput then
        self.GuildSettingInspectorRequisitionItemRefInput:SetText(requisition and (requisition.itemRef or "") or "")
        setTextElementEnabled(self.GuildSettingInspectorRequisitionItemRefInput, requisition ~= nil)
    end
    if self.GuildSettingInspectorRequisitionQuantityInput then
        self.GuildSettingInspectorRequisitionQuantityInput:SetText(tostring(normalizeInteger(requisition and requisition.quantity, 1, 1)))
        setTextElementEnabled(self.GuildSettingInspectorRequisitionQuantityInput, requisition ~= nil)
    end
    if self.GuildSettingInspectorRequisitionLimitInput then
        self.GuildSettingInspectorRequisitionLimitInput:SetText(tostring(normalizeInteger(requisition and requisition.characterLimit, 1, 0)))
        setTextElementEnabled(self.GuildSettingInspectorRequisitionLimitInput, requisition ~= nil)
    end
    if self.GuildSettingInspectorCostScroll then
        self.GuildSettingInspectorCostScroll:SetItems(costs)
    end
    if self.GuildSettingInspectorAddCostButton then
        self.GuildSettingInspectorAddCostButton:SetEnabled(requisition ~= nil)
    end
    if self.GuildSettingInspectorDeleteCostButton then
        self.GuildSettingInspectorDeleteCostButton:SetEnabled(cost ~= nil)
    end
    if self.GuildSettingInspectorCostCurrencyRefInput then
        self.GuildSettingInspectorCostCurrencyRefInput:SetText(cost and (cost.currencyRef or "") or "")
        setTextElementEnabled(self.GuildSettingInspectorCostCurrencyRefInput, cost ~= nil)
    end
    if self.GuildSettingInspectorCostAmountInput then
        self.GuildSettingInspectorCostAmountInput:SetText(tostring(normalizeInteger(cost and cost.amount, 0, 0)))
        setTextElementEnabled(self.GuildSettingInspectorCostAmountInput, cost ~= nil)
    end
end

function DataEditor:RefreshGuildSettingDailyRewardsPage()
    local guildSetting = self:GetSelectedGuildSetting()
    local rewards = guildSetting and guildSetting.dailyRewards or {}
    local rewardIndex = tonumber(self.SelectedGuildSettingDailyRewardIndex)
    if rewardIndex and not rewards[rewardIndex] then
        rewardIndex = #rewards > 0 and math.min(rewardIndex, #rewards) or nil
        self.SelectedGuildSettingDailyRewardIndex = rewardIndex
    end
    local reward = rewardIndex and rewards[rewardIndex] or nil

    if self.GuildSettingInspectorDailyRewardScroll then
        self.GuildSettingInspectorDailyRewardScroll:SetItems(rewards)
    end
    if self.GuildSettingInspectorAddDailyRewardButton then
        self.GuildSettingInspectorAddDailyRewardButton:SetEnabled(guildSetting ~= nil)
    end
    if self.GuildSettingInspectorDeleteDailyRewardButton then
        self.GuildSettingInspectorDeleteDailyRewardButton:SetEnabled(reward ~= nil)
    end
    if self.GuildSettingInspectorDailyRewardIdInput then
        self.GuildSettingInspectorDailyRewardIdInput:SetText(reward and (reward.id or "") or "")
        setTextElementEnabled(self.GuildSettingInspectorDailyRewardIdInput, reward ~= nil)
    end
    if self.GuildSettingInspectorDailyRewardTypeDropdown then
        self._refreshingGuildSettingInspector = true
        self.GuildSettingInspectorDailyRewardTypeDropdown:SetSelectedValue(reward and reward.type or "item", true)
        self._refreshingGuildSettingInspector = false
        setDropdownEnabled(self.GuildSettingInspectorDailyRewardTypeDropdown, reward ~= nil)
    end
    if self.GuildSettingInspectorDailyRewardRefInput then
        self.GuildSettingInspectorDailyRewardRefInput:SetText(reward and (reward.ref or "") or "")
        setTextElementEnabled(self.GuildSettingInspectorDailyRewardRefInput, reward ~= nil)
    end
    if self.GuildSettingInspectorDailyRewardAmountInput then
        self.GuildSettingInspectorDailyRewardAmountInput:SetText(tostring(normalizeInteger(reward and reward.amount, 1, 1)))
        setTextElementEnabled(self.GuildSettingInspectorDailyRewardAmountInput, reward ~= nil)
    end
end

function DataEditor:RefreshGuildSettingProgressionPage()
    local guildSetting = self:GetSelectedGuildSetting()
    local progression = guildSetting and guildSetting.progression or {}
    local entries = progression and progression.entries or {}
    local entryIndex = tonumber(self.SelectedGuildSettingProgressionEntryIndex)
    if entryIndex and not entries[entryIndex] then
        entryIndex = #entries > 0 and math.min(entryIndex, #entries) or nil
        self.SelectedGuildSettingProgressionEntryIndex = entryIndex
    end
    local entry = entryIndex and entries[entryIndex] or nil
    local spellRefs = entry and entry.spellRefs or {}
    local spellRefIndex = tonumber(self.SelectedGuildSettingSpellRefIndex)
    if spellRefIndex and not spellRefs[spellRefIndex] then
        spellRefIndex = #spellRefs > 0 and math.min(spellRefIndex, #spellRefs) or nil
        self.SelectedGuildSettingSpellRefIndex = spellRefIndex
    end

    if self.GuildSettingInspectorSlotCountInput then
        self.GuildSettingInspectorSlotCountInput:SetText(tostring(normalizeInteger(progression and progression.slotCount, 3, 1)))
        setTextElementEnabled(self.GuildSettingInspectorSlotCountInput, guildSetting ~= nil)
    end
    if self.GuildSettingInspectorProgressionEntryScroll then
        self.GuildSettingInspectorProgressionEntryScroll:SetItems(entries)
    end
    if self.GuildSettingInspectorAddProgressionEntryButton then
        self.GuildSettingInspectorAddProgressionEntryButton:SetEnabled(guildSetting ~= nil)
    end
    if self.GuildSettingInspectorDeleteProgressionEntryButton then
        self.GuildSettingInspectorDeleteProgressionEntryButton:SetEnabled(entry ~= nil)
    end
    if self.GuildSettingInspectorProgressionEntryIdInput then
        self.GuildSettingInspectorProgressionEntryIdInput:SetText(entry and (entry.id or "") or "")
        setTextElementEnabled(self.GuildSettingInspectorProgressionEntryIdInput, entry ~= nil)
    end
    if self.GuildSettingInspectorProgressionEntryNameInput then
        self.GuildSettingInspectorProgressionEntryNameInput:SetText(entry and (entry.name or "") or "")
        setTextElementEnabled(self.GuildSettingInspectorProgressionEntryNameInput, entry ~= nil)
    end
    if self.GuildSettingInspectorProgressionEntryDescriptionInput then
        self.GuildSettingInspectorProgressionEntryDescriptionInput:SetText(entry and (entry.description or "") or "")
        setTextElementEnabled(self.GuildSettingInspectorProgressionEntryDescriptionInput, entry ~= nil)
    end
    if self.GuildSettingInspectorProgressionEntryIconField then
        local icon = entry and entry.icon or ""
        self.GuildSettingInspectorProgressionEntryIconField:SetIcon(icon ~= "" and icon or DEFAULT_ICON)
        self.GuildSettingInspectorProgressionEntryIconField:SetLabelText(icon ~= "" and icon or "-")
        self.GuildSettingInspectorProgressionEntryIconField:SetEnabled(entry ~= nil)
    end
    if self.GuildSettingInspectorProgressionEntryLockedTextInput then
        self.GuildSettingInspectorProgressionEntryLockedTextInput:SetText(entry and (entry.lockedText or "") or "")
        setTextElementEnabled(self.GuildSettingInspectorProgressionEntryLockedTextInput, entry ~= nil)
    end
    if self.GuildSettingInspectorSpellRefScroll then
        self.GuildSettingInspectorSpellRefScroll:SetItems(spellRefs)
    end
    if self.GuildSettingInspectorSpellRefInput then
        self.GuildSettingInspectorSpellRefInput:SetText(spellRefIndex and (spellRefs[spellRefIndex] or "") or "")
        setTextElementEnabled(self.GuildSettingInspectorSpellRefInput, entry ~= nil)
    end
    if self.GuildSettingInspectorSaveSpellRefButton then
        self.GuildSettingInspectorSaveSpellRefButton:SetEnabled(entry ~= nil)
    end
    if self.GuildSettingInspectorDeleteSpellRefButton then
        self.GuildSettingInspectorDeleteSpellRefButton:SetEnabled(spellRefIndex ~= nil)
    end
end

function DataEditor:RefreshGuildSettingInspectorPage()
    local guildSetting = self:GetSelectedGuildSetting()
    local hasGuildSetting = guildSetting ~= nil

    self._refreshingGuildSettingInspector = true
    local selectedId = guildSetting and guildSetting.id or nil
    if selectedId ~= self._guildSettingInspectorSelectedId then
        self._guildSettingInspectorSelectedId = selectedId
        self.SelectedGuildSettingRequisitionIndex = guildSetting and #(guildSetting.requisitions or {}) > 0 and 1 or nil
        self.SelectedGuildSettingCostIndex = nil
        self.SelectedGuildSettingDailyRewardIndex = guildSetting and #(guildSetting.dailyRewards or {}) > 0 and 1 or nil
        self.SelectedGuildSettingProgressionEntryIndex = guildSetting and guildSetting.progression and #(guildSetting.progression.entries or {}) > 0 and 1 or nil
        self.SelectedGuildSettingSpellRefIndex = nil
    end

    self:RefreshGuildSettingInspectorGeneralPage(guildSetting)
    self:RefreshGuildSettingRequisitionsPage()
    self:RefreshGuildSettingDailyRewardsPage()
    self:RefreshGuildSettingProgressionPage()
    if self.GuildSettingInspectorEmptyText then
        self.GuildSettingInspectorEmptyText:SetText(hasGuildSetting and "" or "Select a Guild Rank to inspect it.")
    end
    self:RefreshGuildSettingInspectorPageSelector()
    self._refreshingGuildSettingInspector = false
end
