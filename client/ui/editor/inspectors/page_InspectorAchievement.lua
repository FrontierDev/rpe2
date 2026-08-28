local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Client.UI = Addon.Client.UI or {}
Addon.Client.UI.Editor = Addon.Client.UI.Editor or {}

local DataEditor = Addon.Client.UI.Editor
local UI = Addon.UI or {}
local Client = Addon.Client or {}
local Profile = Addon.Internal and Addon.Internal.Profile or {}
local AchievementClass = Addon.Internal
    and Addon.Internal.Database
    and Addon.Internal.Database.Classes
    and Addon.Internal.Database.Classes.Achievement

local INSPECTOR_SIDE_PADDING = 8
local CONTROL_HEIGHT = 20
local FIELD_WIDTH = 236
local DEFAULT_ICON = "Interface\\Icons\\INV_Misc_QuestionMark"

local INSPECTOR_PAGE_DEFINITIONS = {
    { key = "general", label = "General" },
    { key = "criteria", label = "Criteria" },
    { key = "rewards", label = "Rewards" },
}

local TRIGGER_ITEMS = {
    { label = "Manual", value = "manual" },
    { label = "Currency Gain", value = "currency_gain" },
    { label = "RPE Kill", value = "rpe_kill" },
    { label = "Achievement Earned", value = "achievement_earned" },
    { label = "RPE Event Complete", value = "rpe_event_complete" },
    { label = "Item Gain", value = "item_gain" },
    { label = "Skill Gain", value = "skill_gain" },
    { label = "RPE Boss Kill", value = "rpe_boss_kill" },
    { label = "RPE Damage", value = "rpe_damage" },
    { label = "RPE Healing", value = "rpe_healing" },
    { label = "RPE Event Started", value = "rpe_event_started" },
}

local REWARD_TYPE_ITEMS = {
    { label = "Item", value = "item" },
    { label = "Currency", value = "currency" },
}

local BUILTIN_CURRENCY_DEFINITIONS = {
    copper = { id = "copper", key = "copper", name = "Copper" },
    valor = { id = "valor", key = "valor", name = "Valor" },
    justice = { id = "justice", key = "justice", name = "Justice" },
    honor = { id = "honor", key = "honor", name = "Honor" },
    conquest = { id = "conquest", key = "conquest", name = "Conquest" },
}

local BUILTIN_CURRENCY_ORDER = {
    "copper",
    "valor",
    "justice",
    "honor",
    "conquest",
}

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

local function trim(value)
    return tostring(value or ""):match("^%s*(.-)%s*$")
end

local function parseDatasetQualifiedRef(value)
    local datasetId, entryId = trim(value):match("^([^:]+):(.+)$")
    return datasetId, entryId
end

local function dropdownItemsContainValue(items, value)
    local normalizedValue = trim(value)
    for index = 1, #(items or {}) do
        local item = items[index]
        if item and trim(item.value) == normalizedValue then
            return true
        end
        if item and dropdownItemsContainValue(item.children, value) then
            return true
        end
    end

    return false
end

local function appendMissingDropdownValue(items, value, label)
    local reference = trim(value)
    if reference ~= "" and not dropdownItemsContainValue(items, reference) then
        items[#items + 1] = {
            label = label or ("Missing: %s"):format(reference),
            value = value,
        }
    end

    return items
end

local function normalizeCurrencyReference(value)
    local reference = trim(value)
    if reference == "" then
        return ""
    end

    if type(Profile.NormalizeCurrencyKey) == "function" then
        return trim(Profile.NormalizeCurrencyKey(reference))
    end

    return string.lower(reference)
end

local function buildAchievementDatasetItems(self, datasetId)
    local items = self:BuildItemInspectorDatasetItems()
    return appendMissingDropdownValue(items, datasetId, ("Missing dataset: %s"):format(trim(datasetId)))
end

local function buildAchievementItemReferenceItems(self, datasetId, reference)
    local items = self:BuildItemInspectorDatasetCollectionItems("items", datasetId, {
        noneLabel = "None",
    })
    return appendMissingDropdownValue(items, reference, ("Missing item: %s"):format(trim(reference)))
end

local function buildAchievementCurrencyItems(self, reference)
    local items = {
        { label = "None", value = "" },
    }
    local knownValues = {}
    local builtinDefinitions = {}

    if type(Profile.GetBuiltinCurrencyDefinitions) == "function" then
        for _, definition in ipairs(Profile.GetBuiltinCurrencyDefinitions() or {}) do
            local key = normalizeCurrencyReference(definition and (definition.key or definition.id))
            if key ~= "" then
                builtinDefinitions[key] = definition
            end
        end
    end

    local builtinChildren = {}
    for index = 1, #BUILTIN_CURRENCY_ORDER do
        local key = BUILTIN_CURRENCY_ORDER[index]
        local definition = builtinDefinitions[key] or BUILTIN_CURRENCY_DEFINITIONS[key]
        local value = normalizeCurrencyReference(definition and (definition.key or definition.id) or key)
        if value ~= "" and not knownValues[value] then
            knownValues[value] = true
            builtinChildren[#builtinChildren + 1] = {
                label = trim(definition and definition.name) ~= "" and trim(definition.name) or value,
                value = value,
                icon = definition and definition.icon,
            }
        end
    end

    if #builtinChildren > 0 then
        items[#items + 1] = {
            label = "Built-in",
            value = "achievement-currency-group:builtin",
            enabled = true,
            keepShownOnClick = true,
            notCheckable = true,
            children = builtinChildren,
        }
    end

    local datasets = self:GetDatasets() or {}
    for datasetIndex = 1, #datasets do
        local dataset = datasets[datasetIndex]
        local datasetId = trim(dataset and dataset.id)
        local currencyChildren = {}
        for currencyIndex = 1, #(dataset and dataset.currencies or {}) do
            local currency = dataset.currencies[currencyIndex]
            local currencyId = trim(currency and currency.id)
            if datasetId ~= "" and currencyId ~= "" then
                local value = ("%s:%s"):format(datasetId, currencyId)
                if not knownValues[value] then
                    knownValues[value] = true
                    currencyChildren[#currencyChildren + 1] = {
                        label = self.GetEntryDisplayName and self:GetEntryDisplayName("currencies", currency) or currencyId,
                        value = value,
                        icon = currency.icon,
                    }
                end
            end
        end

        if #currencyChildren > 0 then
            items[#items + 1] = {
                label = self.GetDatasetDisplayName and self:GetDatasetDisplayName(dataset) or datasetId,
                value = ("achievement-currency-group:%s"):format(datasetId),
                enabled = true,
                keepShownOnClick = true,
                notCheckable = true,
                children = currencyChildren,
            }
        end
    end

    local currentReference = trim(reference)
    local normalizedReference = normalizeCurrencyReference(currentReference)
    if currentReference ~= ""
        and not dropdownItemsContainValue(items, currentReference)
        and not dropdownItemsContainValue(items, normalizedReference)
    then
        appendMissingDropdownValue(items, currentReference, ("Missing currency: %s"):format(currentReference))
    end

    return items
end

local function getAchievementCurrencySelectionValue(items, reference)
    local rawReference = trim(reference)
    if rawReference == "" or dropdownItemsContainValue(items, rawReference) then
        return rawReference
    end

    local normalizedReference = normalizeCurrencyReference(rawReference)
    if normalizedReference ~= "" and dropdownItemsContainValue(items, normalizedReference) then
        return normalizedReference
    end

    return rawReference
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

local function setGroupVisible(group, visible)
    if not group then
        return
    end

    local frame = group.GetFrame and group:GetFrame() or nil
    local targetHeight = visible and group._visibleHeight or 0
    if group.SetHeight then
        group:SetHeight(targetHeight or 0)
    elseif group.options then
        group.options.height = targetHeight or 0
    end

    if frame then
        if frame.SetHeight then
            frame:SetHeight(targetHeight or 0)
        end
        if visible then
            frame:Show()
        else
            frame:Hide()
        end
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

local function getCriterion(achievement, index)
    local criteria = achievement and achievement.criteria or nil
    index = tonumber(index)
    if type(criteria) ~= "table" or not index or not criteria[index] then
        return nil
    end

    return criteria[index], index
end

local function buildCriterionId(criteria, ignoredIndex)
    local used = {}
    for index = 1, #(criteria or {}) do
        if index ~= ignoredIndex then
            local criterion = criteria[index]
            local id = trim(criterion and criterion.id)
            if id ~= "" then
                used[id] = true
            end
        end
    end

    local index = 1
    while used["criterion_" .. index] do
        index = index + 1
    end
    return "criterion_" .. index
end

local function buildUniqueCriterionId(criteria, ignoredIndex, requestedId)
    local baseId = trim(requestedId)
    if baseId == "" then
        return buildCriterionId(criteria, ignoredIndex)
    end

    local used = {}
    for index = 1, #(criteria or {}) do
        if index ~= ignoredIndex then
            local criterion = criteria[index]
            local id = trim(criterion and criterion.id)
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

local function normalizeRewardType(value)
    local rewardType = string.lower(trim(value))
    if rewardType == "item" or rewardType == "currency" then
        return rewardType
    end

    return nil
end

local function normalizeRewardAmount(value)
    local numeric = tonumber(value)
    if not numeric
        or numeric ~= numeric
        or numeric == math.huge
        or numeric == -math.huge
    then
        numeric = 1
    end

    return math.max(1, math.floor(numeric))
end

local function isSupportedReward(reward)
    return type(reward) == "table" and normalizeRewardType(reward.type) ~= nil
end

local function buildUniqueRewardId(rewards, ignoredIndex, requestedId)
    local baseId = trim(requestedId)
    if baseId == "" then
        baseId = "reward_1"
    end

    local used = {}
    for index = 1, #(rewards or {}) do
        if index ~= ignoredIndex then
            local reward = rewards[index]
            local rewardId = trim(reward and reward.id)
            if rewardId ~= "" then
                used[rewardId] = true
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

local function getFilter(criterion)
    if type(criterion.filters) ~= "table" then
        criterion.filters = {}
    end
    return criterion.filters
end

local function getSelectedAchievementReward(self)
    local achievement = self:GetSelectedAchievement()
    local rewards = achievement and achievement.rewards or {}
    local index = tonumber(self.SelectedAchievementRewardIndex)
    return achievement, rewards, index, index and rewards[index] or nil
end

function DataEditor:NormalizeAchievementDefinition(achievement)
    if AchievementClass and AchievementClass.New and AchievementClass.ToTable then
        return AchievementClass:New(achievement):ToTable()
    end

    return achievement or {}
end

function DataEditor:CommitSelectedAchievement(mutate)
    local dataset = self:GetSelectedDataset()
    local achievement = self:GetSelectedAchievement()
    if not dataset or not achievement or type(mutate) ~= "function" then
        return achievement
    end

    local before = self:DeepCopyValue(achievement)
    mutate(achievement, dataset)
    applyTable(achievement, self:NormalizeAchievementDefinition(achievement))

    if self:DeepEqualValues(before, achievement) then
        return achievement
    end

    self:QueuePendingDatasetEntryChanged(dataset.id, "achievements")
    return achievement
end

function DataEditor:GetAchievementInspectorPageDefinitions()
    return INSPECTOR_PAGE_DEFINITIONS
end

function DataEditor:GetAchievementInspectorPageIndexByKey(key)
    for index = 1, #INSPECTOR_PAGE_DEFINITIONS do
        if INSPECTOR_PAGE_DEFINITIONS[index].key == key then
            return index
        end
    end
    return 1
end

function DataEditor:BuildAchievementInspectorPageSelectorItems()
    local items = {}
    for index = 1, #INSPECTOR_PAGE_DEFINITIONS do
        items[#items + 1] = {
            label = INSPECTOR_PAGE_DEFINITIONS[index].label,
            value = INSPECTOR_PAGE_DEFINITIONS[index].key,
        }
    end
    return items
end

function DataEditor:RefreshAchievementInspectorPageSelector()
    local pageCount = #INSPECTOR_PAGE_DEFINITIONS
    local activeIndex = math.max(1, math.min(self.ActiveAchievementInspectorPageIndex or 1, pageCount))
    self.ActiveAchievementInspectorPageIndex = activeIndex
    self.ActiveAchievementInspectorTabKey = INSPECTOR_PAGE_DEFINITIONS[activeIndex].key

    if self.AchievementInspectorPageDropdown then
        self._refreshingAchievementInspectorPageSelector = true
        self.AchievementInspectorPageDropdown:SetSelectedValue(self.ActiveAchievementInspectorTabKey, true)
        self._refreshingAchievementInspectorPageSelector = false
    end
    if self.AchievementInspectorPreviousButton and self.AchievementInspectorPreviousButton.SetEnabled then
        self.AchievementInspectorPreviousButton:SetEnabled(activeIndex > 1)
    end
    if self.AchievementInspectorNextButton and self.AchievementInspectorNextButton.SetEnabled then
        self.AchievementInspectorNextButton:SetEnabled(activeIndex < pageCount)
    end
end

function DataEditor:SetAchievementInspectorTab(tabKey)
    local activeIndex = self:GetAchievementInspectorPageIndexByKey(tabKey or "general")
    self.ActiveAchievementInspectorPageIndex = activeIndex
    self.ActiveAchievementInspectorTabKey = INSPECTOR_PAGE_DEFINITIONS[activeIndex].key

    local pages = {
        general = self.AchievementInspectorGeneralPage,
        criteria = self.AchievementInspectorCriteriaPage,
        rewards = self.AchievementInspectorRewardsPage,
    }
    for key, page in pairs(pages) do
        if page then
            if key == self.ActiveAchievementInspectorTabKey then
                page:Show()
            else
                page:Hide()
            end
        end
    end
    self:RefreshAchievementInspectorPageSelector()
end

function DataEditor:BuildAchievementInspectorPage(parent)
    if self.AchievementInspectorPage then
        self:RefreshAchievementInspectorPage()
        return self.AchievementInspectorPage
    end

    self.AchievementInspectorPage = CreateFrame("Frame", "RPEDataEditorAchievementInspectorPage", parent)
    self.AchievementInspectorSelectorBar = UI.CreateLayout(UI.HorizontalLayoutGroup, self.AchievementInspectorPage, "RPEDataEditorAchievementInspectorSelectorBar", {
        spacing = 4,
        fitChildrenWidth = true,
        fitChildrenHeight = false,
        height = 20,
    })
    self.AchievementInspectorSelectorBar:GetFrame():SetPoint("TOPLEFT", self.AchievementInspectorPage, "TOPLEFT", 0, 0)
    self.AchievementInspectorSelectorBar:GetFrame():SetPoint("TOPRIGHT", self.AchievementInspectorPage, "TOPRIGHT", 0, 0)

    self.AchievementInspectorPreviousButton = UI.CreateButton(self.AchievementInspectorSelectorBar:GetFrame(), "RPEDataEditorAchievementInspectorPreviousButton", "Prev", 40, function()
        local definition = INSPECTOR_PAGE_DEFINITIONS[(self.ActiveAchievementInspectorPageIndex or 1) - 1]
        self:SetAchievementInspectorTab(definition and definition.key or "general")
    end, { height = 20, fontSize = 7 })
    self.AchievementInspectorSelectorBar:AddChild(self.AchievementInspectorPreviousButton)

    self.AchievementInspectorPageDropdown = UI.CreateDropdown(self.AchievementInspectorSelectorBar:GetFrame(), "RPEDataEditorAchievementInspectorPageDropdown", {
        width = 118,
        height = 18,
        expandWidth = true,
        weight = 1,
        items = self:BuildAchievementInspectorPageSelectorItems(),
        onValueChanged = function(value)
            if not self._refreshingAchievementInspectorPageSelector then
                self:SetAchievementInspectorTab(value)
            end
        end,
    })
    self.AchievementInspectorSelectorBar:AddChild(self.AchievementInspectorPageDropdown)

    self.AchievementInspectorNextButton = UI.CreateButton(self.AchievementInspectorSelectorBar:GetFrame(), "RPEDataEditorAchievementInspectorNextButton", "Next", 40, function()
        local definition = INSPECTOR_PAGE_DEFINITIONS[(self.ActiveAchievementInspectorPageIndex or 1) + 1]
        self:SetAchievementInspectorTab(definition and definition.key or "rewards")
    end, { height = 20, fontSize = 7 })
    self.AchievementInspectorSelectorBar:AddChild(self.AchievementInspectorNextButton)

    local function createPage(name)
        local page = CreateFrame("Frame", name, self.AchievementInspectorPage)
        page:SetPoint("TOPLEFT", self.AchievementInspectorPage, "TOPLEFT", INSPECTOR_SIDE_PADDING, -24)
        page:SetPoint("TOPRIGHT", self.AchievementInspectorPage, "TOPRIGHT", -INSPECTOR_SIDE_PADDING, -24)
        page:SetPoint("BOTTOMLEFT", self.AchievementInspectorPage, "BOTTOMLEFT", INSPECTOR_SIDE_PADDING, 24)
        page:SetPoint("BOTTOMRIGHT", self.AchievementInspectorPage, "BOTTOMRIGHT", -INSPECTOR_SIDE_PADDING, 24)
        return page
    end

    self.AchievementInspectorGeneralPage = createPage("RPEDataEditorAchievementInspectorGeneralPage")
    self:BuildAchievementInspectorGeneralPage(self.AchievementInspectorGeneralPage)
    self.AchievementInspectorCriteriaPage = createPage("RPEDataEditorAchievementInspectorCriteriaPage")
    self:BuildAchievementInspectorCriteriaPage(self.AchievementInspectorCriteriaPage)
    self.AchievementInspectorRewardsPage = createPage("RPEDataEditorAchievementInspectorRewardsPage")
    self:BuildAchievementInspectorRewardsPage(self.AchievementInspectorRewardsPage)

    self.AchievementInspectorEmptyText = createLabel(self.AchievementInspectorPage, "RPEDataEditorAchievementInspectorEmptyText", "", FIELD_WIDTH)
    self.AchievementInspectorEmptyText:GetFrame():SetPoint("BOTTOMLEFT", self.AchievementInspectorPage, "BOTTOMLEFT", 0, 0)

    self:SetAchievementInspectorTab("general")
    self:RefreshAchievementInspectorPage()
    return self.AchievementInspectorPage
end

function DataEditor:BuildAchievementInspectorGeneralPage(parent)
    local root = UI.CreateLayout(UI.VerticalLayoutGroup, parent, "RPEDataEditorAchievementInspectorGeneralLayout", {
        spacing = 3,
        fitChildrenWidth = true,
        fitChildrenHeight = false,
    })
    UI.Utils.AnchorFill(root, parent, 0, 0, 0, 0)

    root:AddChild(createLabel(root:GetFrame(), "RPEDataEditorAchievementInspectorNameLabel", "Name"))
    self.AchievementInspectorNameInput = UI.CreateTextInput(root:GetFrame(), "RPEDataEditorAchievementInspectorNameInput", {
        width = FIELD_WIDTH, height = CONTROL_HEIGHT, text = "", borderColor = UI.ResolveColor(nil, "panel.border"),
    })
    local commitName = function()
        self:CommitSelectedAchievement(function(achievement)
            achievement.name = self.AchievementInspectorNameInput:GetText()
        end)
    end
    self.AchievementInspectorNameInput:SetScript("OnEnterPressed", commitName)
    self.AchievementInspectorNameInput:SetScript("OnEditFocusLost", commitName)
    root:AddChild(self.AchievementInspectorNameInput)

    self.AchievementInspectorIdText = createLabel(root:GetFrame(), "RPEDataEditorAchievementInspectorIdText", "ID: -")
    root:AddChild(self.AchievementInspectorIdText)

    root:AddChild(createLabel(root:GetFrame(), "RPEDataEditorAchievementInspectorIconLabel", "Icon"))
    self.AchievementInspectorIconField = UI.EditorIconField:New({
        name = "RPEDataEditorAchievementInspectorIconField",
        width = FIELD_WIDTH,
        height = CONTROL_HEIGHT,
        buttonText = "Select Icon",
        labelText = "-",
        iconTexture = DEFAULT_ICON,
        border = false,
    })
    self.AchievementInspectorIconField:SetParent(root:GetFrame())
    self.AchievementInspectorIconField:Create()
    local iconButton = self.AchievementInspectorIconField:GetButton()
    if iconButton and iconButton.SetScript then
        iconButton:SetScript("OnClick", function()
            local achievement = self:GetSelectedAchievement()
            if not achievement or not Client.OpenIconFinder then
                return
            end
            Client:OpenIconFinder(function(_, filePath)
                self:CommitSelectedAchievement(function(selectedAchievement)
                    selectedAchievement.icon = filePath or ""
                end)
            end, { filter = achievement.icon or "" })
        end)
    end
    root:AddChild(self.AchievementInspectorIconField)

    root:AddChild(createLabel(root:GetFrame(), "RPEDataEditorAchievementInspectorTagsLabel", "Tags"))
    self.AchievementInspectorTagsInput = UI.CreateTextInput(root:GetFrame(), "RPEDataEditorAchievementInspectorTagsInput", {
        width = FIELD_WIDTH, height = CONTROL_HEIGHT, text = "", borderColor = UI.ResolveColor(nil, "panel.border"),
    })
    local commitTags = function()
        self:CommitSelectedAchievement(function(achievement)
            achievement.tags = UI.Utils.ParseCommaSeparatedList(self.AchievementInspectorTagsInput:GetText())
        end)
    end
    self.AchievementInspectorTagsInput:SetScript("OnEnterPressed", commitTags)
    self.AchievementInspectorTagsInput:SetScript("OnEditFocusLost", commitTags)
    root:AddChild(self.AchievementInspectorTagsInput)

    root:AddChild(createLabel(root:GetFrame(), "RPEDataEditorAchievementInspectorDescriptionLabel", "Description"))
    self.AchievementInspectorDescriptionInput = UI.CreateTextArea(root:GetFrame(), "RPEDataEditorAchievementInspectorDescriptionInput", {
        width = FIELD_WIDTH, height = 92, text = "", readOnly = false, borderColor = UI.ResolveColor(nil, "panel.border"),
    })
    self.AchievementInspectorDescriptionInput:SetScript("OnEditFocusLost", function()
        self:CommitSelectedAchievement(function(achievement)
            achievement.description = self.AchievementInspectorDescriptionInput:GetText()
        end)
    end)
    root:AddChild(self.AchievementInspectorDescriptionInput)
end

function DataEditor:BuildAchievementInspectorCriteriaPage(parent)
    local root = UI.CreateLayout(UI.VerticalLayoutGroup, parent, "RPEDataEditorAchievementInspectorCriteriaLayout", {
        spacing = 2,
        fitChildrenWidth = true,
        fitChildrenHeight = false,
    })
    UI.Utils.AnchorFill(root, parent, 0, 0, 0, 0)
    self.AchievementInspectorCriteriaRoot = root

    root:AddChild(createLabel(root:GetFrame(), "RPEDataEditorAchievementInspectorCriteriaLabel", "Criteria"))
    local criteriaPanel = UI.CreatePanel(root:GetFrame(), "RPEDataEditorAchievementInspectorCriteriaPanel", {
        width = FIELD_WIDTH,
        height = 70,
        contentInset = 2,
        showBorder = false,
    })
    root:AddChild(criteriaPanel)
    self.AchievementInspectorCriteriaScroll = UI.ScrollLayout:New({
        name = "RPEDataEditorAchievementInspectorCriteriaScroll",
        width = FIELD_WIDTH - 4,
        height = 66,
        visibleRows = 4,
        autoFitRows = true,
        rowHeight = 16,
        rowSpacing = 0,
        border = false,
        rowElementClass = UI.ScrollListEntry,
        categoryWidth = 118,
        statusWidth = 72,
        categoryInsetLeft = 4,
        statusInsetRight = 4,
    })
    self.AchievementInspectorCriteriaScroll:SetParent(criteriaPanel:GetContentFrame())
    self.AchievementInspectorCriteriaScroll:SetRowRenderer(function(row, criterion, index)
        row:SetCategory(tostring(criterion and criterion.id or "-"))
        row:SetTestName("")
        row:SetStatus(tostring(criterion and criterion.trigger or "manual"))
        row:SetDetail(tostring(criterion and criterion.description or ""))

        local frame = row.GetFrame and row:GetFrame() or nil
        if frame then
            frame:EnableMouse(true)
            frame:SetScript("OnMouseUp", function(_, button)
                if button == "LeftButton" then
                    self.SelectedAchievementCriterionIndex = index
                    self:RefreshAchievementCriteriaInspector()
                end
            end)
            local selected = tonumber(self.SelectedAchievementCriterionIndex) == tonumber(index)
            if row.entryBackground and row.entryBackground.SetColorTexture then
                local token = selected and "list.rowHover" or "list.rowBackground"
                local color = UI.ResolveColor(nil, token)
                row.entryBackground:SetColorTexture(color.r or 0.08, color.g or 0.09, color.b or 0.11, color.a or 0.85)
            end
        end
    end)
    self.AchievementInspectorCriteriaScroll:Create()
    self.AchievementInspectorCriteriaScroll:SetPoint("TOPLEFT", criteriaPanel:GetContentFrame(), "TOPLEFT", 0, 0)
    self.AchievementInspectorCriteriaScroll:SetPoint("BOTTOMRIGHT", criteriaPanel:GetContentFrame(), "BOTTOMRIGHT", 0, 0)

    local actions = UI.CreateLayout(UI.HorizontalLayoutGroup, root:GetFrame(), "RPEDataEditorAchievementInspectorCriteriaActions", {
        spacing = 2, height = 20, fitChildrenWidth = true, fitChildrenHeight = false,
    })
    self.AchievementInspectorAddCriterionButton = UI.CreateButton(actions:GetFrame(), "RPEDataEditorAchievementInspectorAddCriterionButton", "Add Criterion", 86, function()
        local achievement = self:CommitSelectedAchievement(function(selectedAchievement)
            selectedAchievement.criteria = selectedAchievement.criteria or {}
            selectedAchievement.criteria[#selectedAchievement.criteria + 1] = {
                id = buildCriterionId(selectedAchievement.criteria),
                description = "",
                trigger = "manual",
                goal = 1,
                filters = {},
            }
        end)
        self.SelectedAchievementCriterionIndex = achievement and #(achievement.criteria or {}) or nil
        self:RefreshAchievementCriteriaInspector()
    end, { height = 20, fontSize = 7 })
    actions:AddChild(self.AchievementInspectorAddCriterionButton)
    self.AchievementInspectorDeleteCriterionButton = UI.CreateButton(actions:GetFrame(), "RPEDataEditorAchievementInspectorDeleteCriterionButton", "Delete", 48, function()
        local selectedIndex = tonumber(self.SelectedAchievementCriterionIndex)
        local achievement = self:CommitSelectedAchievement(function(selectedAchievement)
            if selectedIndex and selectedAchievement.criteria and selectedAchievement.criteria[selectedIndex] then
                table.remove(selectedAchievement.criteria, selectedIndex)
            end
        end)
        local criteria = achievement and achievement.criteria or {}
        self.SelectedAchievementCriterionIndex = #criteria > 0 and math.min(selectedIndex or 1, #criteria) or nil
        self:RefreshAchievementCriteriaInspector()
    end, { height = 20, fontSize = 7 })
    actions:AddChild(self.AchievementInspectorDeleteCriterionButton)
    root:AddChild(actions)

    root:AddChild(createLabel(root:GetFrame(), "RPEDataEditorAchievementInspectorCriterionIdLabel", "Criterion ID"))
    self.AchievementInspectorCriterionIdInput = UI.CreateTextInput(root:GetFrame(), "RPEDataEditorAchievementInspectorCriterionIdInput", {
        width = FIELD_WIDTH, height = CONTROL_HEIGHT, text = "", borderColor = UI.ResolveColor(nil, "panel.border"),
    })
    local commitCriterionId = function()
        local selectedIndex = tonumber(self.SelectedAchievementCriterionIndex)
        self:CommitSelectedAchievement(function(achievement)
            local criterion = getCriterion(achievement, selectedIndex)
            if criterion then
                criterion.id = buildUniqueCriterionId(
                    achievement.criteria,
                    selectedIndex,
                    self.AchievementInspectorCriterionIdInput:GetText()
                )
            end
        end)
        self:RefreshAchievementCriteriaInspector()
    end
    self.AchievementInspectorCriterionIdInput:SetScript("OnEnterPressed", commitCriterionId)
    self.AchievementInspectorCriterionIdInput:SetScript("OnEditFocusLost", commitCriterionId)
    root:AddChild(self.AchievementInspectorCriterionIdInput)

    root:AddChild(createLabel(root:GetFrame(), "RPEDataEditorAchievementInspectorCriterionDescriptionLabel", "Criterion Description"))
    self.AchievementInspectorCriterionDescriptionInput = UI.CreateTextArea(root:GetFrame(), "RPEDataEditorAchievementInspectorCriterionDescriptionInput", {
        width = FIELD_WIDTH, height = 38, text = "", readOnly = false, borderColor = UI.ResolveColor(nil, "panel.border"),
    })
    self.AchievementInspectorCriterionDescriptionInput:SetScript("OnEditFocusLost", function()
        local selectedIndex = tonumber(self.SelectedAchievementCriterionIndex)
        self:CommitSelectedAchievement(function(achievement)
            local criterion = getCriterion(achievement, selectedIndex)
            if criterion then
                criterion.description = self.AchievementInspectorCriterionDescriptionInput:GetText()
            end
        end)
    end)
    root:AddChild(self.AchievementInspectorCriterionDescriptionInput)

    root:AddChild(createLabel(root:GetFrame(), "RPEDataEditorAchievementInspectorCriterionTriggerLabel", "Trigger"))
    self.AchievementInspectorCriterionTriggerDropdown = UI.CreateDropdown(root:GetFrame(), "RPEDataEditorAchievementInspectorCriterionTriggerDropdown", {
        width = FIELD_WIDTH,
        height = CONTROL_HEIGHT,
        items = TRIGGER_ITEMS,
        onValueChanged = function(value)
            if self._refreshingAchievementCriteria then
                return
            end
            local selectedIndex = tonumber(self.SelectedAchievementCriterionIndex)
            self:CommitSelectedAchievement(function(achievement)
                local criterion = getCriterion(achievement, selectedIndex)
                if criterion then
                    criterion.trigger = value
                end
            end)
            self:RefreshAchievementCriteriaInspector()
        end,
    })
    root:AddChild(self.AchievementInspectorCriterionTriggerDropdown)

    root:AddChild(createLabel(root:GetFrame(), "RPEDataEditorAchievementInspectorCriterionGoalLabel", "Goal"))
    self.AchievementInspectorCriterionGoalInput = UI.CreateTextInput(root:GetFrame(), "RPEDataEditorAchievementInspectorCriterionGoalInput", {
        width = FIELD_WIDTH, height = CONTROL_HEIGHT, text = "1", borderColor = UI.ResolveColor(nil, "panel.border"),
    })
    local commitCriterionGoal = function()
        local selectedIndex = tonumber(self.SelectedAchievementCriterionIndex)
        self:CommitSelectedAchievement(function(achievement)
            local criterion = getCriterion(achievement, selectedIndex)
            if criterion then
                criterion.goal = math.max(1, math.floor(tonumber(self.AchievementInspectorCriterionGoalInput:GetText()) or 1))
            end
        end)
    end
    self.AchievementInspectorCriterionGoalInput:SetScript("OnEnterPressed", commitCriterionGoal)
    self.AchievementInspectorCriterionGoalInput:SetScript("OnEditFocusLost", commitCriterionGoal)
    root:AddChild(self.AchievementInspectorCriterionGoalInput)

    self.AchievementInspectorCurrencyFilterGroup = UI.CreateLayout(UI.VerticalLayoutGroup, root:GetFrame(), "RPEDataEditorAchievementInspectorCurrencyFilterGroup", {
        spacing = 2, height = 34, fitChildrenWidth = true, fitChildrenHeight = false,
    })
    self.AchievementInspectorCurrencyFilterGroup._visibleHeight = 34
    self.AchievementInspectorCurrencyFilterGroup:AddChild(createLabel(self.AchievementInspectorCurrencyFilterGroup:GetFrame(), "RPEDataEditorAchievementInspectorCurrencyRefLabel", "Currency"))
    self.AchievementInspectorCurrencyRefDropdown = UI.CreateDropdown(self.AchievementInspectorCurrencyFilterGroup:GetFrame(), "RPEDataEditorAchievementInspectorCurrencyRefDropdown", {
        width = FIELD_WIDTH,
        height = CONTROL_HEIGHT,
        items = buildAchievementCurrencyItems(self, ""),
        onValueChanged = function(value)
            if self._refreshingAchievementCriteria then
                return
            end

            local selectedIndex = tonumber(self.SelectedAchievementCriterionIndex)
            self:CommitSelectedAchievement(function(achievement)
                local criterion = getCriterion(achievement, selectedIndex)
                if criterion then
                    getFilter(criterion).currencyRef = normalizeCurrencyReference(value)
                end
            end)
            self:RefreshAchievementCriteriaInspector()
        end,
    })
    self.AchievementInspectorCurrencyFilterGroup:AddChild(self.AchievementInspectorCurrencyRefDropdown)
    root:AddChild(self.AchievementInspectorCurrencyFilterGroup)

    self.AchievementInspectorItemFilterGroup = UI.CreateLayout(UI.VerticalLayoutGroup, root:GetFrame(), "RPEDataEditorAchievementInspectorItemFilterGroup", {
        spacing = 2, height = 70, fitChildrenWidth = true, fitChildrenHeight = false,
    })
    self.AchievementInspectorItemFilterGroup._visibleHeight = 70
    self.AchievementInspectorItemFilterGroup:AddChild(createLabel(self.AchievementInspectorItemFilterGroup:GetFrame(), "RPEDataEditorAchievementInspectorItemDatasetLabel", "Item Dataset"))
    self.AchievementInspectorItemDatasetDropdown = UI.CreateDropdown(self.AchievementInspectorItemFilterGroup:GetFrame(), "RPEDataEditorAchievementInspectorItemDatasetDropdown", {
        width = FIELD_WIDTH,
        height = CONTROL_HEIGHT,
        items = buildAchievementDatasetItems(self, ""),
        onValueChanged = function(value)
            if self._refreshingAchievementCriteria then
                return
            end

            local selectedIndex = tonumber(self.SelectedAchievementCriterionIndex)
            local selectedCriterion = getCriterion(self:GetSelectedAchievement(), selectedIndex)
            local currentDatasetId = select(1, parseDatasetQualifiedRef(selectedCriterion and getFilter(selectedCriterion).itemRef or "")) or ""
            if currentDatasetId == trim(value) then
                return
            end

            self:CommitSelectedAchievement(function(achievement)
                local criterion = getCriterion(achievement, selectedIndex)
                if criterion then
                    getFilter(criterion).itemRef = ""
                end
            end)
            if self.AchievementInspectorItemRefDropdown then
                self.AchievementInspectorItemRefDropdown:SetItems(buildAchievementItemReferenceItems(self, trim(value), ""))
                self.AchievementInspectorItemRefDropdown:SetSelectedValue("", true)
                setDropdownEnabled(self.AchievementInspectorItemRefDropdown, trim(value) ~= "")
            end
        end,
    })
    self.AchievementInspectorItemFilterGroup:AddChild(self.AchievementInspectorItemDatasetDropdown)
    self.AchievementInspectorItemFilterGroup:AddChild(createLabel(self.AchievementInspectorItemFilterGroup:GetFrame(), "RPEDataEditorAchievementInspectorItemRefLabel", "Item"))
    self.AchievementInspectorItemRefDropdown = UI.CreateDropdown(self.AchievementInspectorItemFilterGroup:GetFrame(), "RPEDataEditorAchievementInspectorItemRefDropdown", {
        width = FIELD_WIDTH,
        height = CONTROL_HEIGHT,
        items = { { label = "None", value = "" } },
        onValueChanged = function(value)
            if self._refreshingAchievementCriteria then
                return
            end

            local selectedIndex = tonumber(self.SelectedAchievementCriterionIndex)
            self:CommitSelectedAchievement(function(achievement)
                local criterion = getCriterion(achievement, selectedIndex)
                if criterion then
                    getFilter(criterion).itemRef = trim(value)
                end
            end)
            self:RefreshAchievementCriteriaInspector()
        end,
    })
    self.AchievementInspectorItemFilterGroup:AddChild(self.AchievementInspectorItemRefDropdown)
    root:AddChild(self.AchievementInspectorItemFilterGroup)

    self.AchievementInspectorSkillFilterGroup = UI.CreateLayout(UI.VerticalLayoutGroup, root:GetFrame(), "RPEDataEditorAchievementInspectorSkillFilterGroup", {
        spacing = 2, height = 42, fitChildrenWidth = true, fitChildrenHeight = false,
    })
    self.AchievementInspectorSkillFilterGroup._visibleHeight = 42
    self.AchievementInspectorSkillFilterGroup:AddChild(createLabel(self.AchievementInspectorSkillFilterGroup:GetFrame(), "RPEDataEditorAchievementInspectorSkillRefLabel", "Skill Ref"))
    self.AchievementInspectorSkillRefInput = UI.CreateTextInput(self.AchievementInspectorSkillFilterGroup:GetFrame(), "RPEDataEditorAchievementInspectorSkillRefInput", {
        width = FIELD_WIDTH, height = CONTROL_HEIGHT, text = "", borderColor = UI.ResolveColor(nil, "panel.border"),
    })
    local commitSkillRef = function()
        local selectedIndex = tonumber(self.SelectedAchievementCriterionIndex)
        self:CommitSelectedAchievement(function(achievement)
            local criterion = getCriterion(achievement, selectedIndex)
            if criterion then
                getFilter(criterion).skillRef = self.AchievementInspectorSkillRefInput:GetText()
            end
        end)
    end
    self.AchievementInspectorSkillRefInput:SetScript("OnEnterPressed", commitSkillRef)
    self.AchievementInspectorSkillRefInput:SetScript("OnEditFocusLost", commitSkillRef)
    self.AchievementInspectorSkillFilterGroup:AddChild(self.AchievementInspectorSkillRefInput)
    root:AddChild(self.AchievementInspectorSkillFilterGroup)

    self.AchievementInspectorKillFilterGroup = UI.CreateLayout(UI.VerticalLayoutGroup, root:GetFrame(), "RPEDataEditorAchievementInspectorKillFilterGroup", {
        spacing = 2, height = 62, fitChildrenWidth = true, fitChildrenHeight = false,
    })
    self.AchievementInspectorKillFilterGroup._visibleHeight = 62
    self.AchievementInspectorKillFilterGroup:AddChild(createLabel(self.AchievementInspectorKillFilterGroup:GetFrame(), "RPEDataEditorAchievementInspectorUnitRefLabel", "Unit Reference"))
    self.AchievementInspectorUnitRefInput = UI.CreateTextInput(self.AchievementInspectorKillFilterGroup:GetFrame(), "RPEDataEditorAchievementInspectorUnitRefInput", {
        width = FIELD_WIDTH, height = CONTROL_HEIGHT, text = "", borderColor = UI.ResolveColor(nil, "panel.border"),
    })
    local commitUnitRef = function()
        local selectedIndex = tonumber(self.SelectedAchievementCriterionIndex)
        self:CommitSelectedAchievement(function(achievement)
            local criterion = getCriterion(achievement, selectedIndex)
            if criterion then
                getFilter(criterion).unitRef = self.AchievementInspectorUnitRefInput:GetText()
            end
        end)
    end
    self.AchievementInspectorUnitRefInput:SetScript("OnEnterPressed", commitUnitRef)
    self.AchievementInspectorUnitRefInput:SetScript("OnEditFocusLost", commitUnitRef)
    self.AchievementInspectorKillFilterGroup:AddChild(self.AchievementInspectorUnitRefInput)
    self.AchievementInspectorEnemyOnlyCheckbox = createCheckbox(self.AchievementInspectorKillFilterGroup:GetFrame(), "RPEDataEditorAchievementInspectorEnemyOnlyCheckbox", "Enemy only", function(value)
        if self._refreshingAchievementCriteria then
            return
        end
        local selectedIndex = tonumber(self.SelectedAchievementCriterionIndex)
        self:CommitSelectedAchievement(function(achievement)
            local criterion = getCriterion(achievement, selectedIndex)
            if criterion then
                getFilter(criterion).enemyOnly = value == true
            end
        end)
    end)
    self.AchievementInspectorKillFilterGroup:AddChild(self.AchievementInspectorEnemyOnlyCheckbox)
    root:AddChild(self.AchievementInspectorKillFilterGroup)

    self.AchievementInspectorEventStartedFilterGroup = UI.CreateLayout(UI.VerticalLayoutGroup, root:GetFrame(), "RPEDataEditorAchievementInspectorEventStartedFilterGroup", {
        spacing = 2, height = 42, fitChildrenWidth = true, fitChildrenHeight = false,
    })
    self.AchievementInspectorEventStartedFilterGroup._visibleHeight = 42
    self.AchievementInspectorEventStartedFilterGroup:AddChild(createLabel(self.AchievementInspectorEventStartedFilterGroup:GetFrame(), "RPEDataEditorAchievementInspectorEventIdLabel", "Event ID"))
    self.AchievementInspectorEventIdInput = UI.CreateTextInput(self.AchievementInspectorEventStartedFilterGroup:GetFrame(), "RPEDataEditorAchievementInspectorEventIdInput", {
        width = FIELD_WIDTH, height = CONTROL_HEIGHT, text = "", borderColor = UI.ResolveColor(nil, "panel.border"),
    })
    local commitEventId = function()
        local selectedIndex = tonumber(self.SelectedAchievementCriterionIndex)
        self:CommitSelectedAchievement(function(achievement)
            local criterion = getCriterion(achievement, selectedIndex)
            if criterion then
                getFilter(criterion).eventId = self.AchievementInspectorEventIdInput:GetText()
            end
        end)
    end
    self.AchievementInspectorEventIdInput:SetScript("OnEnterPressed", commitEventId)
    self.AchievementInspectorEventIdInput:SetScript("OnEditFocusLost", commitEventId)
    self.AchievementInspectorEventStartedFilterGroup:AddChild(self.AchievementInspectorEventIdInput)
    root:AddChild(self.AchievementInspectorEventStartedFilterGroup)

    self.AchievementInspectorEarnedFilterGroup = UI.CreateLayout(UI.VerticalLayoutGroup, root:GetFrame(), "RPEDataEditorAchievementInspectorEarnedFilterGroup", {
        spacing = 2, height = 42, fitChildrenWidth = true, fitChildrenHeight = false,
    })
    self.AchievementInspectorEarnedFilterGroup._visibleHeight = 42
    self.AchievementInspectorEarnedFilterGroup:AddChild(createLabel(self.AchievementInspectorEarnedFilterGroup:GetFrame(), "RPEDataEditorAchievementInspectorAchievementRefLabel", "Achievement Reference"))
    self.AchievementInspectorAchievementRefInput = UI.CreateTextInput(self.AchievementInspectorEarnedFilterGroup:GetFrame(), "RPEDataEditorAchievementInspectorAchievementRefInput", {
        width = FIELD_WIDTH, height = CONTROL_HEIGHT, text = "", borderColor = UI.ResolveColor(nil, "panel.border"),
    })
    local commitAchievementRef = function()
        local selectedIndex = tonumber(self.SelectedAchievementCriterionIndex)
        self:CommitSelectedAchievement(function(achievement)
            local criterion = getCriterion(achievement, selectedIndex)
            if criterion then
                getFilter(criterion).achievementRef = self.AchievementInspectorAchievementRefInput:GetText()
            end
        end)
    end
    self.AchievementInspectorAchievementRefInput:SetScript("OnEnterPressed", commitAchievementRef)
    self.AchievementInspectorAchievementRefInput:SetScript("OnEditFocusLost", commitAchievementRef)
    self.AchievementInspectorEarnedFilterGroup:AddChild(self.AchievementInspectorAchievementRefInput)
    root:AddChild(self.AchievementInspectorEarnedFilterGroup)

    self.AchievementInspectorFilterHint = createLabel(root:GetFrame(), "RPEDataEditorAchievementInspectorFilterHint", "", FIELD_WIDTH)
    self.AchievementInspectorFilterHint:SetTextColor(UI.ResolveColor(nil, "text.secondary").r, UI.ResolveColor(nil, "text.secondary").g, UI.ResolveColor(nil, "text.secondary").b, UI.ResolveColor(nil, "text.secondary").a)
    root:AddChild(self.AchievementInspectorFilterHint)
end

function DataEditor:BuildAchievementInspectorRewardsPage(parent)
    local root = UI.CreateLayout(UI.VerticalLayoutGroup, parent, "RPEDataEditorAchievementInspectorRewardsLayout", {
        spacing = 2,
        fitChildrenWidth = true,
        fitChildrenHeight = false,
    })
    UI.Utils.AnchorFill(root, parent, 0, 0, 0, 0)
    self.AchievementInspectorRewardsRoot = root

    root:AddChild(createLabel(root:GetFrame(), "RPEDataEditorAchievementInspectorRewardsTitle", "Rewards"))
    local rewardPanel = UI.CreatePanel(root:GetFrame(), "RPEDataEditorAchievementInspectorRewardPanel", {
        width = FIELD_WIDTH,
        height = 80,
        contentInset = 2,
        showBorder = false,
    })
    root:AddChild(rewardPanel)
    self.AchievementInspectorRewardScroll = UI.ScrollLayout:New({
        name = "RPEDataEditorAchievementInspectorRewardScroll",
        width = FIELD_WIDTH - 4,
        height = 76,
        visibleRows = 4,
        autoFitRows = true,
        rowHeight = 18,
        rowSpacing = 0,
        border = false,
        rowElementClass = UI.ScrollListEntry,
        categoryWidth = 112,
        statusWidth = 68,
        categoryInsetLeft = 4,
        statusInsetRight = 4,
    })
    self.AchievementInspectorRewardScroll:SetParent(rewardPanel:GetContentFrame())
    self.AchievementInspectorRewardScroll:SetRowRenderer(function(row, reward, itemIndex)
        local supported = isSupportedReward(reward)
        local rewardType = supported and normalizeRewardType(reward.type) or nil
        local rewardId = type(reward) == "table" and trim(reward.id) or ""
        local rewardRef = type(reward) == "table" and trim(reward.ref) or ""

        if supported then
            row:SetCategory(rewardId ~= "" and rewardId or "-")
            row:SetStatus(rewardType)
            row:SetDetail(("%s x%d"):format(rewardRef, normalizeRewardAmount(reward.amount)))
        else
            row:SetCategory(rewardId ~= "" and rewardId or "Legacy")
            row:SetStatus("Unsupported")
            row:SetDetail("Preserved legacy reward data")
        end
        row:SetTestName("")

        local frame = row.GetFrame and row:GetFrame() or nil
        if frame then
            frame:EnableMouse(true)
            frame:SetScript("OnMouseUp", function(_, button)
                if button == "LeftButton" then
                    self.SelectedAchievementRewardIndex = itemIndex
                    self:RefreshAchievementRewardsInspector()
                end
            end)
            setRowSelection(row, tonumber(self.SelectedAchievementRewardIndex) == tonumber(itemIndex))
        end
    end)
    self.AchievementInspectorRewardScroll:Create()
    UI.Utils.AnchorFill(self.AchievementInspectorRewardScroll, rewardPanel:GetContentFrame(), 0, 0, 0, 0)

    local actions = UI.CreateLayout(UI.HorizontalLayoutGroup, root:GetFrame(), "RPEDataEditorAchievementInspectorRewardActions", {
        spacing = 2,
        height = 18,
        fitChildrenWidth = true,
        fitChildrenHeight = false,
    })
    self.AchievementInspectorAddRewardButton = UI.CreateButton(actions:GetFrame(), "RPEDataEditorAchievementInspectorAddRewardButton", "Add Reward", 76, function()
        local achievement = self:CommitSelectedAchievement(function(selected)
            selected.rewards = selected.rewards or {}
            selected.rewards[#selected.rewards + 1] = {
                id = buildUniqueRewardId(selected.rewards, nil, ""),
                type = "item",
                ref = "",
                amount = 1,
            }
        end)
        self.SelectedAchievementRewardIndex = achievement and #(achievement.rewards or {}) or nil
        self:RefreshAchievementRewardsInspector()
    end, { height = 18, fontSize = 7 })
    actions:AddChild(self.AchievementInspectorAddRewardButton)
    self.AchievementInspectorDeleteRewardButton = UI.CreateButton(actions:GetFrame(), "RPEDataEditorAchievementInspectorDeleteRewardButton", "Delete Reward", 78, function()
        local _, rewards, selectedIndex, reward = getSelectedAchievementReward(self)
        if not isSupportedReward(reward) then
            return
        end

        local achievement = self:CommitSelectedAchievement(function(selected)
            if selectedIndex and selected.rewards and isSupportedReward(selected.rewards[selectedIndex]) then
                table.remove(selected.rewards, selectedIndex)
            end
        end)
        local updatedRewards = achievement and achievement.rewards or rewards
        self.SelectedAchievementRewardIndex = #updatedRewards > 0
            and math.min(selectedIndex or 1, #updatedRewards)
            or nil
        self:RefreshAchievementRewardsInspector()
    end, { height = 18, fontSize = 7 })
    actions:AddChild(self.AchievementInspectorDeleteRewardButton)
    root:AddChild(actions)

    root:AddChild(createLabel(root:GetFrame(), "RPEDataEditorAchievementInspectorRewardIdLabel", "Reward ID"))
    self.AchievementInspectorRewardIdInput = UI.CreateTextInput(root:GetFrame(), "RPEDataEditorAchievementInspectorRewardIdInput", {
        width = FIELD_WIDTH,
        height = 18,
        text = "",
        borderColor = UI.ResolveColor(nil, "panel.border"),
    })
    local commitRewardId = function()
        local _, _, selectedIndex, reward = getSelectedAchievementReward(self)
        if not isSupportedReward(reward) then
            return
        end

        self:CommitSelectedAchievement(function(achievement)
            local selectedReward = achievement.rewards and achievement.rewards[selectedIndex]
            if isSupportedReward(selectedReward) then
                selectedReward.id = buildUniqueRewardId(
                    achievement.rewards,
                    selectedIndex,
                    self.AchievementInspectorRewardIdInput:GetText()
                )
            end
        end)
        self:RefreshAchievementRewardsInspector()
    end
    self.AchievementInspectorRewardIdInput:SetScript("OnEnterPressed", commitRewardId)
    self.AchievementInspectorRewardIdInput:SetScript("OnEditFocusLost", commitRewardId)
    root:AddChild(self.AchievementInspectorRewardIdInput)

    root:AddChild(createLabel(root:GetFrame(), "RPEDataEditorAchievementInspectorRewardTypeLabel", "Reward Type"))
    self.AchievementInspectorRewardTypeDropdown = UI.CreateDropdown(root:GetFrame(), "RPEDataEditorAchievementInspectorRewardTypeDropdown", {
        width = FIELD_WIDTH,
        height = 18,
        items = REWARD_TYPE_ITEMS,
        onValueChanged = function(value)
            if self._refreshingAchievementRewards then
                return
            end

            local _, _, selectedIndex, reward = getSelectedAchievementReward(self)
            if not isSupportedReward(reward) then
                return
            end

            local nextType = normalizeRewardType(value) or "item"
            if normalizeRewardType(reward.type) == nextType then
                return
            end

            self:CommitSelectedAchievement(function(achievement)
                local selectedReward = achievement.rewards and achievement.rewards[selectedIndex]
                if isSupportedReward(selectedReward) then
                    selectedReward.type = nextType
                    selectedReward.ref = ""
                end
            end)
            self:RefreshAchievementRewardsInspector()
        end,
    })
    root:AddChild(self.AchievementInspectorRewardTypeDropdown)

    local itemDatasetGroup = UI.CreateLayout(UI.VerticalLayoutGroup, root:GetFrame(), "RPEDataEditorAchievementInspectorRewardItemDatasetGroup", {
        spacing = 2,
        height = 34,
        fitChildrenWidth = true,
        fitChildrenHeight = false,
    })
    itemDatasetGroup._visibleHeight = 34
    itemDatasetGroup:AddChild(createLabel(itemDatasetGroup:GetFrame(), "RPEDataEditorAchievementInspectorRewardItemDatasetLabel", "Item Dataset"))
    self.AchievementInspectorRewardItemDatasetDropdown = UI.CreateDropdown(itemDatasetGroup:GetFrame(), "RPEDataEditorAchievementInspectorRewardItemDatasetDropdown", {
        width = FIELD_WIDTH,
        height = CONTROL_HEIGHT,
        items = buildAchievementDatasetItems(self, ""),
        onValueChanged = function(value)
            if self._refreshingAchievementRewards then
                return
            end

            local _, _, selectedIndex, reward = getSelectedAchievementReward(self)
            if not isSupportedReward(reward) or normalizeRewardType(reward.type) ~= "item" then
                return
            end

            local currentDatasetId = select(1, parseDatasetQualifiedRef(reward.ref or "")) or ""
            if currentDatasetId == trim(value) then
                return
            end

            self:CommitSelectedAchievement(function(achievement)
                local selectedReward = achievement.rewards and achievement.rewards[selectedIndex]
                if isSupportedReward(selectedReward) and normalizeRewardType(selectedReward.type) == "item" then
                    selectedReward.ref = ""
                end
            end)
            if self.AchievementInspectorRewardItemDropdown then
                self.AchievementInspectorRewardItemDropdown:SetItems(buildAchievementItemReferenceItems(self, trim(value), ""))
                self.AchievementInspectorRewardItemDropdown:SetSelectedValue("", true)
                setDropdownEnabled(self.AchievementInspectorRewardItemDropdown, trim(value) ~= "")
            end
        end,
    })
    itemDatasetGroup:AddChild(self.AchievementInspectorRewardItemDatasetDropdown)
    root:AddChild(itemDatasetGroup)

    local itemGroup = UI.CreateLayout(UI.VerticalLayoutGroup, root:GetFrame(), "RPEDataEditorAchievementInspectorRewardItemGroup", {
        spacing = 2,
        height = 34,
        fitChildrenWidth = true,
        fitChildrenHeight = false,
    })
    itemGroup._visibleHeight = 34
    itemGroup:AddChild(createLabel(itemGroup:GetFrame(), "RPEDataEditorAchievementInspectorRewardItemLabel", "Item"))
    self.AchievementInspectorRewardItemDropdown = UI.CreateDropdown(itemGroup:GetFrame(), "RPEDataEditorAchievementInspectorRewardItemDropdown", {
        width = FIELD_WIDTH,
        height = CONTROL_HEIGHT,
        items = { { label = "None", value = "" } },
        onValueChanged = function(value)
            if self._refreshingAchievementRewards then
                return
            end

            local _, _, selectedIndex, reward = getSelectedAchievementReward(self)
            if not isSupportedReward(reward) or normalizeRewardType(reward.type) ~= "item" then
                return
            end

            self:CommitSelectedAchievement(function(achievement)
                local selectedReward = achievement.rewards and achievement.rewards[selectedIndex]
                if isSupportedReward(selectedReward) and normalizeRewardType(selectedReward.type) == "item" then
                    selectedReward.ref = trim(value)
                end
            end)
            self:RefreshAchievementRewardsInspector()
        end,
    })
    itemGroup:AddChild(self.AchievementInspectorRewardItemDropdown)
    root:AddChild(itemGroup)

    local currencyGroup = UI.CreateLayout(UI.VerticalLayoutGroup, root:GetFrame(), "RPEDataEditorAchievementInspectorRewardCurrencyGroup", {
        spacing = 2,
        height = 34,
        fitChildrenWidth = true,
        fitChildrenHeight = false,
    })
    currencyGroup._visibleHeight = 34
    currencyGroup:AddChild(createLabel(currencyGroup:GetFrame(), "RPEDataEditorAchievementInspectorRewardCurrencyLabel", "Currency"))
    self.AchievementInspectorRewardCurrencyDropdown = UI.CreateDropdown(currencyGroup:GetFrame(), "RPEDataEditorAchievementInspectorRewardCurrencyDropdown", {
        width = FIELD_WIDTH,
        height = CONTROL_HEIGHT,
        items = buildAchievementCurrencyItems(self, ""),
        onValueChanged = function(value)
            if self._refreshingAchievementRewards then
                return
            end

            local _, _, selectedIndex, reward = getSelectedAchievementReward(self)
            if not isSupportedReward(reward) or normalizeRewardType(reward.type) ~= "currency" then
                return
            end

            self:CommitSelectedAchievement(function(achievement)
                local selectedReward = achievement.rewards and achievement.rewards[selectedIndex]
                if isSupportedReward(selectedReward) and normalizeRewardType(selectedReward.type) == "currency" then
                    selectedReward.ref = normalizeCurrencyReference(value)
                end
            end)
            self:RefreshAchievementRewardsInspector()
        end,
    })
    currencyGroup:AddChild(self.AchievementInspectorRewardCurrencyDropdown)
    root:AddChild(currencyGroup)

    self.AchievementInspectorRewardItemDatasetGroup = itemDatasetGroup
    self.AchievementInspectorRewardItemGroup = itemGroup
    self.AchievementInspectorRewardCurrencyGroup = currencyGroup

    root:AddChild(createLabel(root:GetFrame(), "RPEDataEditorAchievementInspectorRewardAmountLabel", "Amount"))
    self.AchievementInspectorRewardAmountInput = UI.CreateTextInput(root:GetFrame(), "RPEDataEditorAchievementInspectorRewardAmountInput", {
        width = FIELD_WIDTH,
        height = 18,
        text = "1",
        borderColor = UI.ResolveColor(nil, "panel.border"),
    })
    local commitRewardAmount = function()
        local _, _, selectedIndex, reward = getSelectedAchievementReward(self)
        if not isSupportedReward(reward) then
            return
        end

        self:CommitSelectedAchievement(function(achievement)
            local selectedReward = achievement.rewards and achievement.rewards[selectedIndex]
            if isSupportedReward(selectedReward) then
                selectedReward.amount = normalizeRewardAmount(self.AchievementInspectorRewardAmountInput:GetText())
            end
        end)
    end
    self.AchievementInspectorRewardAmountInput:SetScript("OnEnterPressed", commitRewardAmount)
    self.AchievementInspectorRewardAmountInput:SetScript("OnEditFocusLost", commitRewardAmount)
    root:AddChild(self.AchievementInspectorRewardAmountInput)

    self.AchievementInspectorRewardHint = createLabel(root:GetFrame(), "RPEDataEditorAchievementInspectorRewardHint", "", FIELD_WIDTH)
    self.AchievementInspectorRewardHint:SetTextColor(UI.ResolveColor(nil, "text.secondary").r, UI.ResolveColor(nil, "text.secondary").g, UI.ResolveColor(nil, "text.secondary").b, UI.ResolveColor(nil, "text.secondary").a)
    root:AddChild(self.AchievementInspectorRewardHint)
end

function DataEditor:RefreshAchievementCriteriaInspector()
    local achievement = self:GetSelectedAchievement()
    local criteria = achievement and achievement.criteria or {}
    local selectedIndex = tonumber(self.SelectedAchievementCriterionIndex)
    if selectedIndex and not criteria[selectedIndex] then
        selectedIndex = #criteria > 0 and math.min(selectedIndex, #criteria) or nil
        self.SelectedAchievementCriterionIndex = selectedIndex
    end
    local criterion = selectedIndex and criteria[selectedIndex] or nil
    local hasCriterion = criterion ~= nil
    local trigger = criterion and criterion.trigger or "manual"
    local filters = criterion and getFilter(criterion) or {}
    local combatTrigger = trigger == "rpe_kill"
        or trigger == "rpe_boss_kill"
        or trigger == "rpe_damage"
        or trigger == "rpe_healing"

    self._refreshingAchievementCriteria = true
    if self.AchievementInspectorCriteriaScroll then
        self.AchievementInspectorCriteriaScroll:SetItems(criteria)
    end
    if self.AchievementInspectorCriterionIdInput then
        self.AchievementInspectorCriterionIdInput:SetText(criterion and (criterion.id or "") or "")
        setTextElementEnabled(self.AchievementInspectorCriterionIdInput, hasCriterion)
    end
    if self.AchievementInspectorCriterionDescriptionInput then
        self.AchievementInspectorCriterionDescriptionInput:SetText(criterion and (criterion.description or "") or "")
        setTextElementEnabled(self.AchievementInspectorCriterionDescriptionInput, hasCriterion)
    end
    if self.AchievementInspectorCriterionTriggerDropdown then
        self.AchievementInspectorCriterionTriggerDropdown:SetSelectedValue(trigger, true)
        setDropdownEnabled(self.AchievementInspectorCriterionTriggerDropdown, hasCriterion)
    end
    if self.AchievementInspectorCriterionGoalInput then
        self.AchievementInspectorCriterionGoalInput:SetText(tostring(math.max(1, math.floor(tonumber(criterion and criterion.goal) or 1))))
        setTextElementEnabled(self.AchievementInspectorCriterionGoalInput, hasCriterion)
    end
    local currencyRef = trim(filters.currencyRef)
    local itemRef = trim(filters.itemRef)
    local itemDatasetId = select(1, parseDatasetQualifiedRef(itemRef)) or ""
    if self.AchievementInspectorCurrencyRefDropdown then
        local currencyItems = buildAchievementCurrencyItems(self, currencyRef)
        self.AchievementInspectorCurrencyRefDropdown:SetItems(currencyItems)
        self.AchievementInspectorCurrencyRefDropdown:SetSelectedValue(getAchievementCurrencySelectionValue(currencyItems, currencyRef), true)
        setDropdownEnabled(self.AchievementInspectorCurrencyRefDropdown, hasCriterion and trigger == "currency_gain")
    end
    if self.AchievementInspectorItemDatasetDropdown then
        self.AchievementInspectorItemDatasetDropdown:SetItems(buildAchievementDatasetItems(self, itemDatasetId))
        self.AchievementInspectorItemDatasetDropdown:SetSelectedValue(itemDatasetId, true)
        setDropdownEnabled(self.AchievementInspectorItemDatasetDropdown, hasCriterion and trigger == "item_gain")
    end
    if self.AchievementInspectorItemRefDropdown then
        local itemItems = buildAchievementItemReferenceItems(self, itemDatasetId, itemRef)
        self.AchievementInspectorItemRefDropdown:SetItems(itemItems)
        self.AchievementInspectorItemRefDropdown:SetSelectedValue(itemRef, true)
        setDropdownEnabled(self.AchievementInspectorItemRefDropdown, hasCriterion and trigger == "item_gain" and itemDatasetId ~= "")
    end
    if self.AchievementInspectorSkillRefInput then
        self.AchievementInspectorSkillRefInput:SetText(tostring(filters.skillRef or ""))
        setTextElementEnabled(self.AchievementInspectorSkillRefInput, hasCriterion and trigger == "skill_gain")
    end
    if self.AchievementInspectorUnitRefInput then
        self.AchievementInspectorUnitRefInput:SetText(tostring(filters.unitRef or ""))
        setTextElementEnabled(self.AchievementInspectorUnitRefInput, hasCriterion and combatTrigger)
    end
    if self.AchievementInspectorEnemyOnlyCheckbox then
        self.AchievementInspectorEnemyOnlyCheckbox:SetChecked(filters.enemyOnly == true, true)
        self.AchievementInspectorEnemyOnlyCheckbox:SetEnabled(hasCriterion and combatTrigger)
    end
    if self.AchievementInspectorEventIdInput then
        self.AchievementInspectorEventIdInput:SetText(tostring(filters.eventId or ""))
        setTextElementEnabled(self.AchievementInspectorEventIdInput, hasCriterion and trigger == "rpe_event_started")
    end
    if self.AchievementInspectorAchievementRefInput then
        self.AchievementInspectorAchievementRefInput:SetText(tostring(filters.achievementRef or ""))
        setTextElementEnabled(self.AchievementInspectorAchievementRefInput, hasCriterion and trigger == "achievement_earned")
    end
    if self.AchievementInspectorAddCriterionButton then
        self.AchievementInspectorAddCriterionButton:SetEnabled(achievement ~= nil)
    end
    if self.AchievementInspectorDeleteCriterionButton then
        self.AchievementInspectorDeleteCriterionButton:SetEnabled(hasCriterion)
    end

    setGroupVisible(self.AchievementInspectorCurrencyFilterGroup, hasCriterion and trigger == "currency_gain")
    setGroupVisible(self.AchievementInspectorItemFilterGroup, hasCriterion and trigger == "item_gain")
    setGroupVisible(self.AchievementInspectorSkillFilterGroup, hasCriterion and trigger == "skill_gain")
    setGroupVisible(self.AchievementInspectorKillFilterGroup, hasCriterion and combatTrigger)
    setGroupVisible(self.AchievementInspectorEventStartedFilterGroup, hasCriterion and trigger == "rpe_event_started")
    setGroupVisible(self.AchievementInspectorEarnedFilterGroup, hasCriterion and trigger == "achievement_earned")
    if self.AchievementInspectorFilterHint then
        local hint = "Select a criterion to edit its trigger and filters."
        if hasCriterion and trigger == "manual" then
            hint = "Manual criteria have no required filters."
        elseif hasCriterion and trigger == "rpe_event_complete" then
            hint = "RPE event complete criteria have no required filters in Phase 1."
        elseif hasCriterion and trigger == "currency_gain" then
            local currencyItems = buildAchievementCurrencyItems(self, "")
            if currencyRef ~= ""
                and not dropdownItemsContainValue(currencyItems, currencyRef)
                and not dropdownItemsContainValue(currencyItems, normalizeCurrencyReference(currencyRef))
            then
                hint = ("Unresolved currency reference: %s. Choose a replacement to update it."):format(currencyRef)
            else
                hint = "Select the currency used by this criterion."
            end
        elseif hasCriterion and trigger == "item_gain" then
            local itemItems = buildAchievementItemReferenceItems(self, itemDatasetId, "")
            if itemRef ~= "" and not dropdownItemsContainValue(itemItems, itemRef) then
                hint = ("Unresolved item reference: %s. Choose a replacement to update it."):format(itemRef)
            else
                hint = "Select an item from an Item Dataset."
            end
        elseif hasCriterion and trigger == "skill_gain" then
            hint = "Set the skill reference used by this criterion."
        elseif hasCriterion and combatTrigger then
            hint = "Unit reference and Enemy only are optional filters."
        elseif hasCriterion and trigger == "rpe_event_started" then
            hint = "Set the event ID used by this criterion."
        elseif hasCriterion and trigger == "achievement_earned" then
            hint = "Set the achievement reference used by this criterion."
        end
        self.AchievementInspectorFilterHint:SetText(hint)
    end
    if self.AchievementInspectorCriteriaRoot and self.AchievementInspectorCriteriaRoot.RefreshLayout then
        self.AchievementInspectorCriteriaRoot:RefreshLayout()
    end
    self._refreshingAchievementCriteria = false
end

function DataEditor:RefreshAchievementRewardsInspector()
    local achievement, rewards = self:GetSelectedAchievement(), nil
    rewards = achievement and achievement.rewards or {}
    local rewardIndex = tonumber(self.SelectedAchievementRewardIndex)
    if rewardIndex and not rewards[rewardIndex] then
        rewardIndex = #rewards > 0 and math.min(rewardIndex, #rewards) or nil
        self.SelectedAchievementRewardIndex = rewardIndex
    end
    local reward = rewardIndex and rewards[rewardIndex] or nil
    local supported = isSupportedReward(reward)
    local rewardType = supported and normalizeRewardType(reward.type) or "item"

    self._refreshingAchievementRewards = true
    if self.AchievementInspectorRewardScroll then
        self.AchievementInspectorRewardScroll:SetItems(rewards)
    end
    if self.AchievementInspectorAddRewardButton then
        self.AchievementInspectorAddRewardButton:SetEnabled(achievement ~= nil)
    end
    if self.AchievementInspectorDeleteRewardButton then
        self.AchievementInspectorDeleteRewardButton:SetEnabled(supported)
    end
    if self.AchievementInspectorRewardIdInput then
        self.AchievementInspectorRewardIdInput:SetText(reward and tostring(reward.id or "") or "")
        setTextElementEnabled(self.AchievementInspectorRewardIdInput, supported)
    end
    if self.AchievementInspectorRewardTypeDropdown then
        self.AchievementInspectorRewardTypeDropdown:SetSelectedValue(rewardType, true)
        setDropdownEnabled(self.AchievementInspectorRewardTypeDropdown, supported)
    end
    local rewardRef = trim(reward and reward.ref or "")
    local rewardDatasetId = select(1, parseDatasetQualifiedRef(rewardRef)) or ""
    local itemRef = rewardType == "item" and rewardRef or ""
    local itemDatasetId = rewardType == "item" and rewardDatasetId or ""
    local currencyRef = rewardType == "currency" and rewardRef or ""
    if self.AchievementInspectorRewardItemDatasetDropdown then
        self.AchievementInspectorRewardItemDatasetDropdown:SetItems(buildAchievementDatasetItems(self, itemDatasetId))
        self.AchievementInspectorRewardItemDatasetDropdown:SetSelectedValue(itemDatasetId, true)
        setDropdownEnabled(self.AchievementInspectorRewardItemDatasetDropdown, supported and rewardType == "item")
    end
    if self.AchievementInspectorRewardItemDropdown then
        local itemItems = buildAchievementItemReferenceItems(self, itemDatasetId, itemRef)
        self.AchievementInspectorRewardItemDropdown:SetItems(itemItems)
        self.AchievementInspectorRewardItemDropdown:SetSelectedValue(itemRef, true)
        setDropdownEnabled(self.AchievementInspectorRewardItemDropdown, supported and rewardType == "item" and itemDatasetId ~= "")
    end
    if self.AchievementInspectorRewardCurrencyDropdown then
        local currencyItems = buildAchievementCurrencyItems(self, currencyRef)
        self.AchievementInspectorRewardCurrencyDropdown:SetItems(currencyItems)
        self.AchievementInspectorRewardCurrencyDropdown:SetSelectedValue(getAchievementCurrencySelectionValue(currencyItems, currencyRef), true)
        setDropdownEnabled(self.AchievementInspectorRewardCurrencyDropdown, supported and rewardType == "currency")
    end
    setGroupVisible(self.AchievementInspectorRewardItemDatasetGroup, supported and rewardType == "item")
    setGroupVisible(self.AchievementInspectorRewardItemGroup, supported and rewardType == "item")
    setGroupVisible(self.AchievementInspectorRewardCurrencyGroup, supported and rewardType == "currency")
    if self.AchievementInspectorRewardAmountInput then
        self.AchievementInspectorRewardAmountInput:SetText(tostring(normalizeRewardAmount(reward and reward.amount)))
        setTextElementEnabled(self.AchievementInspectorRewardAmountInput, supported)
    end
    if self.AchievementInspectorRewardHint then
        local hint = "Select a reward to edit it. Item refs use datasetId:itemId; currency refs use a built-in or dataset currency ref."
        if supported and rewardType == "item" then
            local itemItems = buildAchievementItemReferenceItems(self, itemDatasetId, "")
            if itemRef ~= "" and not dropdownItemsContainValue(itemItems, itemRef) then
                hint = ("Unresolved item reference: %s. Choose a replacement to update it."):format(itemRef)
            else
                hint = "Select an item from an Item Dataset. Editing only changes saved Achievement data; it never grants the item."
            end
        elseif supported and rewardType == "currency" then
            local currencyItems = buildAchievementCurrencyItems(self, "")
            if currencyRef ~= ""
                and not dropdownItemsContainValue(currencyItems, currencyRef)
                and not dropdownItemsContainValue(currencyItems, normalizeCurrencyReference(currencyRef))
            then
                hint = ("Unresolved currency reference: %s. Choose a replacement to update it."):format(currencyRef)
            else
                hint = "Select a currency: copper, valor, justice, honor, conquest, or a dataset currency."
            end
        elseif reward ~= nil then
            hint = "Unsupported legacy reward data is preserved and cannot be edited here."
        end
        self.AchievementInspectorRewardHint:SetText(hint)
    end
    if self.AchievementInspectorRewardsRoot and self.AchievementInspectorRewardsRoot.RefreshLayout then
        self.AchievementInspectorRewardsRoot:RefreshLayout()
    end
    self._refreshingAchievementRewards = false
end

function DataEditor:RefreshAchievementInspectorPage()
    local achievement = self:GetSelectedAchievement()
    local hasAchievement = achievement ~= nil

    self._refreshingAchievementInspectorPage = true
    if self.AchievementInspectorNameInput then
        self.AchievementInspectorNameInput:SetText(achievement and (achievement.name or "") or "")
        setTextElementEnabled(self.AchievementInspectorNameInput, hasAchievement)
    end
    if self.AchievementInspectorIdText then
        self.AchievementInspectorIdText:SetText(("ID: %s"):format(achievement and tostring(achievement.id or "") or "-"))
    end
    if self.AchievementInspectorIconField then
        local icon = achievement and achievement.icon or ""
        self.AchievementInspectorIconField:SetIcon(icon ~= "" and icon or DEFAULT_ICON)
        self.AchievementInspectorIconField:SetLabelText(icon ~= "" and icon or "-")
        self.AchievementInspectorIconField:SetEnabled(hasAchievement)
    end
    if self.AchievementInspectorTagsInput then
        self.AchievementInspectorTagsInput:SetText(achievement and UI.Utils.JoinCommaSeparatedList(achievement.tags or {}) or "")
        setTextElementEnabled(self.AchievementInspectorTagsInput, hasAchievement)
    end
    if self.AchievementInspectorDescriptionInput then
        self.AchievementInspectorDescriptionInput:SetText(achievement and (achievement.description or "") or "")
        setTextElementEnabled(self.AchievementInspectorDescriptionInput, hasAchievement)
    end

    local selectedId = achievement and achievement.id or nil
    if selectedId ~= self._achievementInspectorSelectedId then
        self._achievementInspectorSelectedId = selectedId
        self.SelectedAchievementCriterionIndex = achievement and #(achievement.criteria or {}) > 0 and 1 or nil
        self.SelectedAchievementRewardIndex = achievement and #(achievement.rewards or {}) > 0 and 1 or nil
    end

    self:RefreshAchievementCriteriaInspector()
    self:RefreshAchievementRewardsInspector()
    if self.AchievementInspectorEmptyText then
        self.AchievementInspectorEmptyText:SetText(hasAchievement and "" or "Select an Achievement to inspect it.")
    end
    self:RefreshAchievementInspectorPageSelector()
    self._refreshingAchievementInspectorPage = false
end
