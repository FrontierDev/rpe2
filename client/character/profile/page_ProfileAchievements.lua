local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Client.UI = Addon.Client.UI or {}
Addon.Client.UI.Profile = Addon.Client.UI.Profile or {}

local ProfileUI = Addon.Client.UI.Profile
local UI = Addon.UI or {}
local Profile = Addon.Internal and Addon.Internal.Profile or {}
local Registry = Addon.Internal and Addon.Internal.Registry or {}
local Runtime = Addon.Internal and Addon.Internal.Runtime or {}
local AchievementClass = Addon.Internal
    and Addon.Internal.Database
    and Addon.Internal.Database.Classes
    and Addon.Internal.Database.Classes.Achievement

local AchievementsPage = ProfileUI.AchievementsPage or {}
ProfileUI.AchievementsPage = AchievementsPage

local NAV_PANEL_WIDTH = 168
local CONTENT_PANEL_WIDTH = 340
local CONTENT_PADDING = 8
local ENTRY_HEIGHT = 64
local ENTRY_SPACING = 4
local ENTRY_ROWS = 4
local DEFAULT_ICON = "Interface\\Icons\\INV_Misc_QuestionMark"
local RETRY_BUTTON_WIDTH = 100
local RETRY_BUTTON_HEIGHT = 18

local function getConfigurationRevision()
    return math.max(0, math.floor(tonumber(Addon.Internal and Addon.Internal.ConfigurationRevision) or 0))
end

local function getRuntimeRevision(domain)
    if type(Runtime) == "table" and type(Runtime.GetRevision) == "function" then
        return math.max(0, math.floor(tonumber(Runtime:GetRevision(domain)) or 0))
    end

    return 0
end

local function revisionTuplesEqual(left, right)
    if type(left) ~= "table" or type(right) ~= "table" then
        return false
    end

    for key, value in pairs(left) do
        if right[key] ~= value then
            return false
        end
    end
    for key, value in pairs(right) do
        if left[key] ~= value then
            return false
        end
    end

    return true
end

local function ensureString(value)
    if value == nil then
        return ""
    end

    return tostring(value)
end

local function trimString(value)
    return ensureString(value):gsub("^%s+", ""):gsub("%s+$", "")
end

local function getAchievementCategoryDefinitions()
    if AchievementClass and type(AchievementClass.GetCategoryDefinitions) == "function" then
        return AchievementClass.GetCategoryDefinitions()
    end

    return {}
end

local function normalizeAchievementCategory(value)
    if AchievementClass and type(AchievementClass.NormalizeCategory) == "function" then
        return AchievementClass.NormalizeCategory(value)
    end

    return "general"
end

local function normalizeAchievementSubcategory(value)
    if AchievementClass and type(AchievementClass.NormalizeSubcategory) == "function" then
        return AchievementClass.NormalizeSubcategory(value)
    end

    return trimString(value)
end

local function composeAchievementRef(datasetId, achievementId)
    local normalizedDatasetId = trimString(datasetId)
    local normalizedAchievementId = trimString(achievementId)
    if normalizedDatasetId == "" or normalizedAchievementId == "" then
        return ""
    end

    return ("%s:%s"):format(normalizedDatasetId, normalizedAchievementId)
end

local function normalizeProgress(value)
    local numeric = tonumber(value)
    if not numeric or numeric ~= numeric or numeric == math.huge or numeric == -math.huge then
        return 0
    end

    return math.max(0, math.floor(numeric))
end

local function normalizeGoal(value)
    local numeric = tonumber(value)
    if not numeric or numeric ~= numeric or numeric == math.huge or numeric == -math.huge then
        return 1
    end

    return math.max(1, math.floor(numeric))
end

local function getAchievementName(achievement)
    local name = trimString(achievement and achievement.name)
    if name ~= "" then
        return name
    end

    local id = trimString(achievement and achievement.id)
    return id ~= "" and id or "Unnamed Achievement"
end

local function getAchievementIcon(achievement)
    local icon = trimString(achievement and achievement.icon)
    return icon ~= "" and icon or DEFAULT_ICON
end

local function getCompletionDate(completedAt)
    local timestamp = tonumber(completedAt)
    if not timestamp or timestamp < 0 then
        return nil
    end

    if type(date) == "function" then
        return date("%Y-%m-%d", timestamp)
    end

    return tostring(math.floor(timestamp))
end

local function getTimestampText(timestampValue)
    local timestamp = tonumber(timestampValue)
    if not timestamp or timestamp < 0 then
        return nil
    end

    if type(date) == "function" then
        return date("%Y-%m-%d %H:%M:%S", timestamp)
    end

    return tostring(math.floor(timestamp))
end

local function buildCriterionProgress(achievement, state)
    local criteria = achievement and achievement.criteria or {}
    if type(criteria) ~= "table" or #criteria == 0 then
        return ""
    end

    local stateCriteria = state and type(state.criteria) == "table" and state.criteria or {}
    local progress = {}
    for index = 1, #criteria do
        local criterion = criteria[index]
        if type(criterion) == "table" then
            local criterionId = trimString(criterion.id)
            local label = trimString(criterion.description)
            if label == "" then
                label = criterionId ~= "" and criterionId or ("Criterion %d"):format(index)
            end

            local current = normalizeProgress(stateCriteria and stateCriteria[criterionId] or 0)
            local goal = normalizeGoal(criterion.goal)
            progress[#progress + 1] = ("%s: %d / %d"):format(label, current, goal)
        end
    end

    return table.concat(progress, "  |  ")
end

local function buildAchievementRows()
    local datasets = Registry.GetActivatedDatasets and Registry:GetActivatedDatasets() or {}
    local states = Profile.ListAchievementStates and Profile.ListAchievementStates() or {}
    if type(states) ~= "table" then
        states = {}
    end

    local rows = {}
    for datasetIndex = 1, #datasets do
        local dataset = datasets[datasetIndex]
        local datasetId = trimString(dataset and dataset.id)
        if datasetId ~= "" then
            local achievements = dataset and dataset.achievements or {}
            for achievementIndex = 1, #achievements do
                local achievement = achievements[achievementIndex]
                local achievementId = trimString(achievement and achievement.id)
                local achievementRef = composeAchievementRef(datasetId, achievementId)
                if type(achievement) == "table" and achievementRef ~= "" then
                    rows[#rows + 1] = {
                        achievement = achievement,
                        achievementId = achievementId,
                        achievementRef = achievementRef,
                        dataset = dataset,
                        datasetId = datasetId,
                        state = states[achievementRef],
                        category = normalizeAchievementCategory(achievement.category),
                        subcategory = normalizeAchievementSubcategory(achievement.subcategory),
                    }
                end
            end
        end
    end

    return rows
end

local function buildCategoryRows(achievementRows)
    local rows = {
        {
            key = "all",
            label = "All",
            title = "All",
            count = #achievementRows,
        },
    }

    local definitions = getAchievementCategoryDefinitions()
    for definitionIndex = 1, #definitions do
        local definition = definitions[definitionIndex]
        local categoryKey = definition.key
        local categoryCount = 0
        local subcategoryCounts = {}

        for achievementIndex = 1, #achievementRows do
            local achievementRow = achievementRows[achievementIndex]
            if achievementRow.category == categoryKey then
                categoryCount = categoryCount + 1
                local subcategory = achievementRow.subcategory
                if subcategory ~= "" then
                    subcategoryCounts[subcategory] = (subcategoryCounts[subcategory] or 0) + 1
                end
            end
        end

        rows[#rows + 1] = {
            key = categoryKey,
            label = definition.label,
            title = definition.label,
            categoryKey = categoryKey,
            count = categoryCount,
        }

        local subcategories = {}
        for subcategory in pairs(subcategoryCounts) do
            subcategories[#subcategories + 1] = subcategory
        end
        table.sort(subcategories, function(left, right)
            local leftLower = string.lower(tostring(left))
            local rightLower = string.lower(tostring(right))
            if leftLower == rightLower then
                return tostring(left) < tostring(right)
            end
            return leftLower < rightLower
        end)

        for subcategoryIndex = 1, #subcategories do
            local subcategory = subcategories[subcategoryIndex]
            rows[#rows + 1] = {
                key = ("%s::%s"):format(categoryKey, subcategory),
                label = ("    %s"):format(subcategory),
                title = ("%s / %s"):format(definition.label, subcategory),
                categoryKey = categoryKey,
                subcategory = subcategory,
                count = subcategoryCounts[subcategory],
            }
        end
    end

    return rows
end

local function filterAchievementRows(rows, selectedCategory)
    if type(selectedCategory) ~= "table" or selectedCategory.key == "all" then
        return rows
    end

    local filtered = {}
    for index = 1, #rows do
        local row = rows[index]
        if row.category == selectedCategory.categoryKey
            and (selectedCategory.subcategory == nil or row.subcategory == selectedCategory.subcategory)
        then
            filtered[#filtered + 1] = row
        end
    end

    return filtered
end

local function findCategory(categories, selectedKey)
    for index = 1, #categories do
        if tostring(categories[index].key or "") == tostring(selectedKey or "") then
            return categories[index]
        end
    end

    return nil
end

local function getRewardDefinitions(row)
    local rewards = row and row.achievement and row.achievement.rewards
    return type(rewards) == "table" and rewards or {}
end

local function getRewardState(row)
    local state = row and row.state
    local rewardState = type(state) == "table" and state.rewardState or nil
    return type(rewardState) == "table" and rewardState or nil
end

local function getRewardEntryId(reward, index, usedIds)
    local baseId = type(reward) == "table" and trimString(reward.id) or ""
    if baseId == "" then
        baseId = ("reward_%d"):format(index)
    end

    local rewardId = baseId
    local suffix = 2
    while usedIds[rewardId] do
        rewardId = ("%s_%d"):format(baseId, suffix)
        suffix = suffix + 1
    end

    usedIds[rewardId] = true
    return rewardId
end

local function getRewardAmountText(amount)
    local numeric = tonumber(amount)
    if numeric and numeric == numeric and numeric ~= math.huge and numeric ~= -math.huge then
        return tostring(math.max(0, math.floor(numeric)))
    end

    local configured = trimString(amount)
    return configured ~= "" and configured or "unknown"
end

local function resolveItemRewardName(itemRef)
    local normalizedRef = trimString(itemRef)
    if normalizedRef == "" then
        return "Unknown item"
    end

    if type(Registry.ResolveItemReference) == "function" then
        local callOk, _, item = pcall(Registry.ResolveItemReference, Registry, normalizedRef)
        if callOk and type(item) == "table" then
            local name = trimString(item.name)
            if name ~= "" then
                return name
            end
        end
    end

    return normalizedRef .. " (unavailable)"
end

local function resolveCurrencyRewardName(currencyRef)
    local normalizedRef = trimString(currencyRef)
    if normalizedRef == "" then
        return "Unknown currency"
    end

    local currencyKey = normalizedRef
    if type(Profile.NormalizeCurrencyKey) == "function" then
        local normalizeOk, normalized = pcall(Profile.NormalizeCurrencyKey, normalizedRef)
        if normalizeOk and trimString(normalized) ~= "" then
            currencyKey = trimString(normalized)
        end
    end

    if type(Profile.ResolveCurrencyDefinition) == "function" then
        local resolveOk, definition = pcall(Profile.ResolveCurrencyDefinition, currencyKey)
        if resolveOk and type(definition) == "table" then
            local name = trimString(definition.name)
            if name ~= "" then
                return name
            end
        end
    end

    return currencyKey .. " (unavailable)"
end

local function getRewardEntry(state, rewardId)
    local entries = state and state.entries
    local entry = type(entries) == "table" and entries[rewardId] or nil
    return type(entry) == "table" and entry or nil
end

local function buildRewardLines(row)
    local rewards = getRewardDefinitions(row)
    local rewardState = getRewardState(row)
    local lines = {}
    local usedIds = {}

    for index = 1, #rewards do
        local reward = rewards[index]
        local rewardId = getRewardEntryId(reward, index, usedIds)
        local rewardType = type(reward) == "table" and string.lower(trimString(reward.type)) or ""
        local rewardRef = type(reward) == "table" and trimString(reward.ref) or ""
        local entry = getRewardEntry(rewardState, rewardId)

        if rewardType == "item" then
            local name = resolveItemRewardName(rewardRef)
            local line = ("Item: %s x%s"):format(name, getRewardAmountText(reward.amount))
            local appliedAmount = tonumber(entry and entry.appliedAmount)
            if appliedAmount and appliedAmount == appliedAmount and appliedAmount >= 0 then
                line = ("%s (applied %d)"):format(line, math.floor(appliedAmount))
            end
            local appliedAt = getTimestampText(entry and entry.appliedAt)
            if appliedAt then
                line = ("%s on %s"):format(line, appliedAt)
            end
            local entryReason = trimString(entry and entry.reason)
            if entryReason ~= "" then
                line = ("%s; reason: %s"):format(line, entryReason)
            end
            lines[#lines + 1] = line
        elseif rewardType == "currency" then
            local name = resolveCurrencyRewardName(rewardRef)
            local line = ("Currency: %s x%s"):format(name, getRewardAmountText(reward.amount))
            local appliedAmount = tonumber(entry and entry.appliedAmount)
            if appliedAmount and appliedAmount == appliedAmount and appliedAmount >= 0 then
                line = ("%s (applied %d)"):format(line, math.floor(appliedAmount))
            end
            local appliedAt = getTimestampText(entry and entry.appliedAt)
            if appliedAt then
                line = ("%s on %s"):format(line, appliedAt)
            end
            local entryReason = trimString(entry and entry.reason)
            if entryReason ~= "" then
                line = ("%s; reason: %s"):format(line, entryReason)
            end
            lines[#lines + 1] = line
        else
            local unsupported = "Unsupported reward data"
            if rewardType ~= "" then
                unsupported = ("Unsupported reward: %s"):format(rewardType)
            end
            if rewardRef ~= "" then
                unsupported = ("%s (%s)"):format(unsupported, rewardRef)
            end
            lines[#lines + 1] = unsupported
        end
    end

    return lines
end

local function hasUnsupportedRewardData(row)
    local rewards = getRewardDefinitions(row)
    for index = 1, #rewards do
        local reward = rewards[index]
        local rewardType = type(reward) == "table" and string.lower(trimString(reward.type)) or ""
        if rewardType ~= "item" and rewardType ~= "currency" then
            return true
        end
    end

    local rewardState = getRewardState(row)
    if rewardState and rewardState.reason == "unsupported-reward-record" then
        return true
    end

    local entries = rewardState and rewardState.entries
    if type(entries) == "table" then
        for _, entry in pairs(entries) do
            if type(entry) == "table" and entry.status == "unsupported" then
                return true
            end
        end
    end

    return false
end

local function getRewardStatusText(row)
    local rewards = getRewardDefinitions(row)
    local rewardState = getRewardState(row)
    local completedAt = row and row.state and row.state.completedAt
    local hasRewards = #rewards > 0

    if not rewardState then
        if completedAt ~= nil and hasRewards then
            return "Rewards: Not retroactively granted (legacy completion)"
        end
        if hasUnsupportedRewardData(row) and hasRewards then
            return "Rewards: Contains unsupported legacy reward data"
        end
        if hasRewards then
            return "Rewards: Pending"
        end
        return ""
    end

    local status = string.lower(trimString(rewardState.status))
    if status == "complete" then
        if hasUnsupportedRewardData(row) then
            return "Rewards: Contains unsupported legacy reward data"
        end
        return "Rewards: Received"
    elseif status == "failed" then
        return "Rewards: Delivery failed"
    elseif status == "recovery-required" then
        return "Rewards: Recovery required"
    elseif status == "in-progress" then
        return "Rewards: Delivery in progress"
    elseif status == "pending" then
        return "Rewards: Pending"
    elseif status == "legacy-skipped" then
        return "Rewards: Not retroactively granted (legacy completion)"
    end

    if status ~= "" then
        return ("Rewards: %s"):format(status)
    end

    return hasRewards and "Rewards: Pending" or ""
end

local function getRewardTimestampLines(row)
    local rewardState = getRewardState(row)
    if not rewardState then
        return {}
    end

    local lines = {}
    local startedAt = getTimestampText(rewardState.startedAt)
    local completedAt = getTimestampText(rewardState.completedAt)
    local failedAt = getTimestampText(rewardState.failedAt)
    if startedAt then
        lines[#lines + 1] = "Reward started: " .. startedAt
    end
    if completedAt then
        lines[#lines + 1] = "Rewards delivered: " .. completedAt
    end
    if failedAt then
        lines[#lines + 1] = "Reward delivery failed: " .. failedAt
    end

    local reason = trimString(rewardState.reason)
    if reason ~= "" then
        lines[#lines + 1] = "Reward reason: " .. reason
    end

    return lines
end

local function findAchievementRow(rows, achievementRef)
    local normalizedRef = trimString(achievementRef)
    if normalizedRef == "" then
        return nil
    end

    for index = 1, #rows do
        if rows[index].achievementRef == normalizedRef then
            return rows[index]
        end
    end

    return nil
end

local function canRetryRewards(row)
    local rewardState = getRewardState(row)
    return rewardState and string.lower(trimString(rewardState.status)) == "failed"
end

local function getStatusText(row)
    local completionDate = getCompletionDate(row and row.state and row.state.completedAt)
    local status = completionDate and ("Complete\n" .. completionDate) or "Incomplete"
    local rewardStatus = getRewardStatusText(row)
    if rewardStatus ~= "" then
        status = status .. "\n" .. rewardStatus
    end

    return status
end

local function getDisplayText(row)
    local achievement = row and row.achievement or {}
    local lines = { getAchievementName(achievement) }
    local description = trimString(achievement.description)
    local criterionProgress = buildCriterionProgress(achievement, row and row.state)

    if description ~= "" then
        lines[#lines + 1] = description
    end
    if criterionProgress ~= "" then
        lines[#lines + 1] = criterionProgress
    end
    local rewardStatus = getRewardStatusText(row)
    if rewardStatus ~= "" then
        lines[#lines + 1] = rewardStatus
    end
    for index, rewardLine in ipairs(buildRewardLines(row)) do
        lines[#lines + 1] = rewardLine
    end

    return table.concat(lines, "\n")
end

local function getTooltipLines(row)
    local achievement = row and row.achievement or {}
    local lines = {}
    local description = trimString(achievement.description)
    local criterionProgress = buildCriterionProgress(achievement, row and row.state)
    local completionDate = getCompletionDate(row and row.state and row.state.completedAt)

    if description ~= "" then
        lines[#lines + 1] = description
    end
    if criterionProgress ~= "" then
        lines[#lines + 1] = criterionProgress
    end
    if completionDate then
        lines[#lines + 1] = "Completed: " .. completionDate
    end
    local rewardStatus = getRewardStatusText(row)
    if rewardStatus ~= "" then
        lines[#lines + 1] = rewardStatus
    end
    for index, rewardLine in ipairs(buildRewardLines(row)) do
        lines[#lines + 1] = rewardLine
    end
    for index, rewardTimestampLine in ipairs(getRewardTimestampLines(row)) do
        lines[#lines + 1] = rewardTimestampLine
    end
    if #lines == 0 then
        lines[1] = "No additional achievement details."
    end

    return lines
end

local function applyAchievementRowVisuals(row, achievementRow)
    local isComplete = achievementRow and achievementRow.state and achievementRow.state.completedAt ~= nil
    local background = isComplete
        and UI.ResolveColor({ r = 0.08, g = 0.18, b = 0.11, a = 0.92 }, "list.rowBackground")
        or UI.ResolveColor(nil, "list.rowBackground")
    if row and row.entryBackground and row.entryBackground.SetColorTexture then
        row.entryBackground:SetColorTexture(background.r or 0, background.g or 0, background.b or 0, background.a or 1)
    end

    if row and row.SetStatusColor then
        local color = UI.ResolveColor(nil, isComplete and "success" or "text.muted")
        row:SetStatusColor(color.r or 1, color.g or 1, color.b or 1, color.a or 1)
    end
end

function AchievementsPage:EnsureCategorySelection(categories)
    if findCategory(categories, self.SelectedCategoryKey) then
        return
    end

    self.SelectedCategoryKey = categories[1] and categories[1].key or "all"
end

function AchievementsPage:GetSelectedAchievementRows()
    local selectedCategory = findCategory(self.CategoryRows or {}, self.SelectedCategoryKey)
    return filterAchievementRows(self.AllAchievementRows or {}, selectedCategory)
end

function AchievementsPage:UpdateRetryButton(selectedRows)
    if not self.RetryButton then
        return
    end

    local selectedRow = findAchievementRow(selectedRows or {}, self.SelectedAchievementRef)
    if canRetryRewards(selectedRow) then
        self.RetryButton:Show()
    else
        self.RetryButton:Hide()
    end
end

function AchievementsPage:MarkDirty()
    self.dirty = true
    return self
end

function AchievementsPage:IsVisible()
    if not self.frame or not self.frame.IsShown or not self.frame:IsShown() then
        return false
    end

    if self.owner and self.owner.IsVisible then
        return self.owner:IsVisible()
    end

    return true
end

function AchievementsPage:GetRevisionTuple()
    return {
        configurationRevision = getConfigurationRevision(),
        achievementRevision = getRuntimeRevision("AchievementRevision"),
        selectedCategoryKey = tostring(self.SelectedCategoryKey or ""),
        selectedAchievementRef = tostring(self.SelectedAchievementRef or ""),
    }
end

function AchievementsPage:RefreshIfDirty()
    if not self.frame then
        return nil, false
    end

    local revision = self:GetRevisionTuple()
    if not self.dirty and revisionTuplesEqual(self.lastRenderedRevision, revision) then
        return self.frame, false
    end

    if not self:IsVisible() then
        self:MarkDirty()
        return self.frame, false
    end

    return self:Refresh(), true
end

function AchievementsPage:Build(parent, owner)
    self.owner = owner
    if self.frame then
        return self.frame
    end

    self.frame = CreateFrame("Frame", "RPEProfileAchievementsPage", parent)
    self.frame:SetAllPoints(parent)

    self.RootLayout = UI.CreateLayout(UI.HorizontalLayoutGroup, self.frame, "RPEProfileAchievementsRootLayout", {
        spacing = 8,
        fitChildrenWidth = true,
        fitChildrenHeight = true,
    })
    UI.Utils.AnchorFill(self.RootLayout, self.frame, 0, 0, 0, 0)

    self.CategoryPanel = UI.CreatePanel(self.RootLayout:GetFrame(), "RPEProfileAchievementsCategoryPanel", {
        width = NAV_PANEL_WIDTH,
        height = 304,
        contentInset = 2,
        showBorder = false,
    })
    self.RootLayout:AddChild(self.CategoryPanel)

    self.ContentPanel = UI.CreatePanel(self.RootLayout:GetFrame(), "RPEProfileAchievementsContentPanel", {
        width = CONTENT_PANEL_WIDTH,
        height = 304,
        expandWidth = true,
        weight = 1,
        contentInset = 0,
        showBorder = false,
    })
    self.RootLayout:AddChild(self.ContentPanel)

    self.CategoryList = UI.ScrollLayout:New({
        name = "RPEProfileAchievementsCategoryList",
        width = NAV_PANEL_WIDTH - 4,
        height = 300,
        visibleRows = 14,
        rowHeight = 18,
        rowSpacing = 0,
        border = false,
        rowElementClass = UI.ScrollListEntry,
        categoryWidth = 112,
        statusWidth = 26,
        categoryInsetLeft = 4,
        statusInsetRight = 4,
    })
    self.CategoryList:SetParent(self.CategoryPanel:GetContentFrame())
    self.CategoryList:SetRowRenderer(function(row, item)
        row:SetCategory(item and item.label or "")
        row:SetTestName("")
        row:SetStatus(tostring(item and item.count or 0))
        row:SetDetail("")

        local frame = row.GetFrame and row:GetFrame() or nil
        if frame then
            frame:EnableMouse(true)
            frame:SetScript("OnMouseUp", function(_, button)
                if button == "LeftButton" and item and item.key then
                    self.SelectedCategoryKey = item.key
                    if self.EntryScroll and self.EntryScroll.SetScrollOffset then
                        self.EntryScroll:SetScrollOffset(0)
                    end
                    self:Refresh()
                end
            end)

            local isSelected = tostring(item and item.key or "") == tostring(self.SelectedCategoryKey or "")
            if row.entryBackground and row.entryBackground.SetColorTexture then
                local token = isSelected and "list.rowHover" or "list.rowBackground"
                local color = UI.ResolveColor(nil, token)
                row.entryBackground:SetColorTexture(color.r or 0, color.g or 0, color.b or 0, color.a or 1)
            end
        end
    end)
    self.CategoryList:Create()
    UI.Utils.AnchorFill(self.CategoryList, self.CategoryPanel:GetContentFrame(), 0, 0, 0, 0)

    self.CategoryEmptyText = UI.CreateText(self.CategoryPanel:GetContentFrame(), "RPEProfileAchievementsCategoryEmptyText", "", {
        width = 140,
        height = 40,
        justifyH = "CENTER",
        wordWrap = true,
        textColor = UI.ResolveColor(nil, "text.secondary"),
    })
    self.CategoryEmptyText:GetFrame():SetPoint("CENTER", self.CategoryPanel:GetContentFrame(), "CENTER", 0, 0)

    self.ContentLayout = UI.CreateLayout(UI.VerticalLayoutGroup, self.ContentPanel:GetContentFrame(), "RPEProfileAchievementsContentLayout", {
        spacing = 4,
        fitChildrenWidth = true,
        fitChildrenHeight = true,
    })
    UI.Utils.AnchorFill(self.ContentLayout, self.ContentPanel:GetContentFrame(), CONTENT_PADDING, 0, CONTENT_PADDING, 0)

    self.RetryButton = UI.TextButton:New({
        name = "RPEProfileAchievementsRetryRewardsButton",
        width = RETRY_BUTTON_WIDTH,
        height = RETRY_BUTTON_HEIGHT,
        text = "Retry Rewards",
        fontSize = 8,
        border = false,
    })
    self.RetryButton:SetParent(self.ContentPanel:GetContentFrame())
    self.RetryButton:Create()
    self.RetryButton:GetFrame():SetPoint("TOPRIGHT", self.ContentPanel:GetContentFrame(), "TOPRIGHT", -CONTENT_PADDING, -2)
    self.RetryButton:SetScript("OnClick", function()
        local selectedRow = findAchievementRow(self:GetSelectedAchievementRows(), self.SelectedAchievementRef)
        if not canRetryRewards(selectedRow) then
            self:Refresh()
            return
        end

        local achievements = Addon.Client and Addon.Client.Achievements or nil
        if achievements and type(achievements.RetryRewards) == "function" then
            pcall(achievements.RetryRewards, achievements, selectedRow.achievementRef)
        end
        self:Refresh()
    end)
    self.RetryButton:Hide()

    self.GridTitle = UI.CreateText(self.ContentLayout:GetFrame(), "RPEProfileAchievementsGridTitle", "Achievements", {
        width = CONTENT_PANEL_WIDTH - (CONTENT_PADDING * 2) - RETRY_BUTTON_WIDTH - 4,
        height = 18,
        justifyH = "LEFT",
    })
    self.ContentLayout:AddChild(self.GridTitle)

    self.GridHintText = UI.CreateText(self.ContentLayout:GetFrame(), "RPEProfileAchievementsGridHintText", "", {
        width = CONTENT_PANEL_WIDTH - (CONTENT_PADDING * 2),
        height = 18,
        justifyH = "LEFT",
        textColor = UI.ResolveColor(nil, "text.secondary"),
    })
    self.ContentLayout:AddChild(self.GridHintText)

    self.EntryPanel = UI.CreatePanel(self.ContentLayout:GetFrame(), "RPEProfileAchievementsEntryPanel", {
        width = CONTENT_PANEL_WIDTH - (CONTENT_PADDING * 2),
        height = (ENTRY_HEIGHT * ENTRY_ROWS) + (ENTRY_SPACING * (ENTRY_ROWS - 1)),
        contentInset = 0,
        showBorder = false,
        expandWidth = true,
        expandHeight = true,
        weight = 1,
    })
    self.ContentLayout:AddChild(self.EntryPanel)

    self.EntryScroll = UI.ScrollLayout:New({
        name = "RPEProfileAchievementsEntryScroll",
        width = CONTENT_PANEL_WIDTH - (CONTENT_PADDING * 2),
        height = (ENTRY_HEIGHT * ENTRY_ROWS) + (ENTRY_SPACING * (ENTRY_ROWS - 1)),
        visibleRows = ENTRY_ROWS,
        rowHeight = ENTRY_HEIGHT,
        rowSpacing = ENTRY_SPACING,
        border = false,
        rowElementClass = UI.ScrollListEntry,
        rowWidth = CONTENT_PANEL_WIDTH - (CONTENT_PADDING * 2),
        categoryWidth = 48,
        statusWidth = 118,
        categoryInsetLeft = 4,
        statusInsetRight = 4,
        rowWordWrap = true,
    })
    self.EntryScroll:SetParent(self.EntryPanel:GetContentFrame())
    self.EntryScroll:SetRowRenderer(function(row, achievementRow)
        local achievement = achievementRow and achievementRow.achievement or {}
        row._achievementRef = achievementRow and achievementRow.achievementRef or ""
        local rowFrame = row.GetFrame and row:GetFrame() or nil
        if rowFrame then
            rowFrame:EnableMouse(true)
            if not row._achievementSelectionBound then
                local selectAchievement = function(_, button)
                    if button == "LeftButton" and row._achievementRef ~= "" then
                        self.SelectedAchievementRef = row._achievementRef
                        self:Refresh()
                    end
                end
                if rowFrame.HookScript then
                    rowFrame:HookScript("OnMouseUp", selectAchievement)
                    row._achievementSelectionBound = true
                elseif rowFrame.SetScript then
                    rowFrame:SetScript("OnMouseUp", selectAchievement)
                    row._achievementSelectionBound = true
                end
            end
        end
        local iconMarkup = ("|T%s:24:24:0:0|t"):format(getAchievementIcon(achievement))
        row:SetCategory(iconMarkup)
        row:SetTestName(getDisplayText(achievementRow))
        row:SetStatus(getStatusText(achievementRow))
        row:SetDetail(table.concat(getTooltipLines(achievementRow), "\n"))
        applyAchievementRowVisuals(row, achievementRow)
    end)
    self.EntryScroll:Create()
    UI.Utils.AnchorFill(self.EntryScroll, self.EntryPanel:GetContentFrame(), 0, 0, 0, 0)

    self.GridEmptyText = UI.CreateText(self.EntryPanel:GetContentFrame(), "RPEProfileAchievementsGridEmptyText", "", {
        width = 220,
        height = 40,
        justifyH = "CENTER",
        wordWrap = true,
        textColor = UI.ResolveColor(nil, "text.secondary"),
    })
    self.GridEmptyText:GetFrame():SetPoint("CENTER", self.EntryPanel:GetContentFrame(), "CENTER", 0, 0)

    return self.frame
end

function AchievementsPage:Refresh()
    if not self.frame then
        return nil
    end

    if not self:IsVisible() then
        self:MarkDirty()
        return self.frame
    end

    if self.refreshInProgress then
        return self.frame
    end

    self.refreshInProgress = true

    self.AllAchievementRows = buildAchievementRows()
    self.CategoryRows = buildCategoryRows(self.AllAchievementRows)
    self:EnsureCategorySelection(self.CategoryRows)

    local selectedCategory = findCategory(self.CategoryRows, self.SelectedCategoryKey)
    local selectedRows = self:GetSelectedAchievementRows()
    self:UpdateRetryButton(selectedRows)

    if self.CategoryList and self.CategoryList.SetItems then
        self.CategoryList:SetItems(self.CategoryRows)
    end
    if self.CategoryEmptyText and self.CategoryEmptyText.SetText then
        self.CategoryEmptyText:SetText(#self.CategoryRows > 0 and "" or "No achievement categories available.")
    end

    if self.GridTitle and self.GridTitle.SetText then
        self.GridTitle:SetText(selectedCategory and (selectedCategory.title or selectedCategory.label) or "Achievements")
    end
    if self.GridHintText and self.GridHintText.SetText then
        self.GridHintText:SetText(("%d achievement%s"):format(#selectedRows, #selectedRows == 1 and "" or "s"))
    end

    if self.EntryScroll then
        self.EntryScroll:SetItems(selectedRows)
    end
    if self.GridEmptyText and self.GridEmptyText.SetText then
        if #self.AllAchievementRows == 0 then
            self.GridEmptyText:SetText("No Achievements are available in active datasets.")
        elseif #selectedRows == 0 then
            self.GridEmptyText:SetText("No Achievements match this category.")
        else
            self.GridEmptyText:SetText("")
        end
    end

    self.lastRenderedRevision = self:GetRevisionTuple()
    self.dirty = false
    self.refreshInProgress = false
    return self.frame
end

return AchievementsPage
