local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Client.UI = Addon.Client.UI or {}
Addon.Client.UI.Profile = Addon.Client.UI.Profile or {}

local ProfileUI = Addon.Client.UI.Profile
local UI = Addon.UI or {}
local Profile = Addon.Internal and Addon.Internal.Profile or {}
local Registry = Addon.Internal and Addon.Internal.Registry or {}

local AchievementsPage = ProfileUI.AchievementsPage or {}
ProfileUI.AchievementsPage = AchievementsPage

local NAV_PANEL_WIDTH = 168
local CONTENT_PANEL_WIDTH = 340
local CONTENT_PADDING = 8
local ENTRY_HEIGHT = 64
local ENTRY_SPACING = 4
local ENTRY_ROWS = 4
local DEFAULT_ICON = "Interface\\Icons\\INV_Misc_QuestionMark"

local function ensureString(value)
    if value == nil then
        return ""
    end

    return tostring(value)
end

local function trimString(value)
    return ensureString(value):gsub("^%s+", ""):gsub("%s+$", "")
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
                    local tags = {}
                    local tagSet = {}
                    local achievementTags = type(achievement.tags) == "table" and achievement.tags or {}
                    for tagIndex = 1, #achievementTags do
                        local tag = trimString(achievementTags[tagIndex])
                        if tag ~= "" and not tagSet[tag] then
                            tagSet[tag] = true
                            tags[#tags + 1] = tag
                        end
                    end

                    rows[#rows + 1] = {
                        achievement = achievement,
                        achievementId = achievementId,
                        achievementRef = achievementRef,
                        dataset = dataset,
                        datasetId = datasetId,
                        state = states[achievementRef],
                        tags = tags,
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
            count = #achievementRows,
        },
    }
    local counts = {}
    local labels = {}

    for index = 1, #achievementRows do
        local achievementRow = achievementRows[index]
        for tagIndex = 1, #(achievementRow.tags or {}) do
            local tag = achievementRow.tags[tagIndex]
            counts[tag] = (counts[tag] or 0) + 1
            labels[tag] = tag
        end
    end

    local tags = {}
    for tag in pairs(counts) do
        tags[#tags + 1] = tag
    end
    table.sort(tags, function(left, right)
        return string.lower(tostring(left)) < string.lower(tostring(right))
    end)

    for index = 1, #tags do
        local tag = tags[index]
        rows[#rows + 1] = {
            key = tag,
            label = labels[tag] or tag,
            count = counts[tag] or 0,
        }
    end

    return rows
end

local function filterAchievementRows(rows, selectedCategoryKey)
    if not selectedCategoryKey or selectedCategoryKey == "all" then
        return rows
    end

    local filtered = {}
    for index = 1, #rows do
        local row = rows[index]
        for tagIndex = 1, #(row.tags or {}) do
            if tostring(row.tags[tagIndex]) == tostring(selectedCategoryKey) then
                filtered[#filtered + 1] = row
                break
            end
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

local function getStatusText(row)
    local completionDate = getCompletionDate(row and row.state and row.state.completedAt)
    if completionDate then
        return "Complete\n" .. completionDate
    end

    return "Incomplete"
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
    return filterAchievementRows(self.AllAchievementRows or {}, self.SelectedCategoryKey)
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

    self.GridTitle = UI.CreateText(self.ContentLayout:GetFrame(), "RPEProfileAchievementsGridTitle", "Achievements", {
        width = CONTENT_PANEL_WIDTH - (CONTENT_PADDING * 2),
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
        statusWidth = 72,
        categoryInsetLeft = 4,
        statusInsetRight = 4,
        rowWordWrap = true,
    })
    self.EntryScroll:SetParent(self.EntryPanel:GetContentFrame())
    self.EntryScroll:SetRowRenderer(function(row, achievementRow)
        local achievement = achievementRow and achievementRow.achievement or {}
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

    self:Refresh()
    return self.frame
end

function AchievementsPage:Refresh()
    if not self.frame then
        return nil
    end

    self.AllAchievementRows = buildAchievementRows()
    self.CategoryRows = buildCategoryRows(self.AllAchievementRows)
    self:EnsureCategorySelection(self.CategoryRows)

    local selectedCategory = findCategory(self.CategoryRows, self.SelectedCategoryKey)
    local selectedRows = self:GetSelectedAchievementRows()

    if self.CategoryList and self.CategoryList.SetItems then
        self.CategoryList:SetItems(self.CategoryRows)
    end
    if self.CategoryEmptyText and self.CategoryEmptyText.SetText then
        self.CategoryEmptyText:SetText(#self.CategoryRows > 1 and "" or "No achievement tags available.")
    end

    if self.GridTitle and self.GridTitle.SetText then
        self.GridTitle:SetText(selectedCategory and selectedCategory.label or "Achievements")
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
            self.GridEmptyText:SetText("No Achievements match this tag.")
        else
            self.GridEmptyText:SetText("")
        end
    end

    return self.frame
end

return AchievementsPage
