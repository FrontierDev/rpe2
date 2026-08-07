local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Client.UI = Addon.Client.UI or {}
Addon.Client.UI.Profile = Addon.Client.UI.Profile or {}

local ProfileUI = Addon.Client.UI.Profile
local UI = Addon.UI or {}
local Profile = Addon.Internal and Addon.Internal.Profile or {}
local Registry = Addon.Internal and Addon.Internal.Registry or {}
local Client = Addon.Client or {}
local SkillsPage = ProfileUI.SkillsPage or {}
ProfileUI.SkillsPage = SkillsPage

local NAV_PANEL_WIDTH = 168
local ENTRY_HEIGHT = 28
local ENTRY_SPACING = 4
local ENTRY_ROWS = 8
local GRID_PADDING = 8

local CATEGORY_DEFINITIONS = {
    { key = "weapon", label = "Weapon Skills" },
    { key = "noncombat", label = "Non-Combat Skills" },
    { key = "crafting", label = "Crafting Skills" },
    { key = "language", label = "Language Skills" },
}

local function getSkillRuleValue(ruleKey, fallback)
    local ruleset = Addon.Internal and Addon.Internal.Ruleset and Addon.Internal.Ruleset.GetActiveRuleset and Addon.Internal.Ruleset.GetActiveRuleset() or nil
    local rulesetLogic = Addon.Internal and Addon.Internal.Ruleset or nil
    local value = nil
    if rulesetLogic and rulesetLogic.GetRulesetRuleDefinition and rulesetLogic.GetRulesetRuleValue then
        local ruleDefinition = rulesetLogic.GetRulesetRuleDefinition("skills", ruleKey)
        value = rulesetLogic.GetRulesetRuleValue(ruleset, "skills", ruleDefinition)
    end
    if value == nil then
        return fallback
    end

    return value
end

local function isCategoryEnabled(categoryKey)
    if categoryKey == "weapon" then
        return getSkillRuleValue("use_weapon_skills", true) ~= false
    end
    if categoryKey == "crafting" then
        return getSkillRuleValue("use_crafting_skills", true) ~= false
    end
    if categoryKey == "language" then
        return getSkillRuleValue("use_language_skills", true) ~= false
    end

    return getSkillRuleValue("use_noncombat_skills", true) ~= false
end

local function buildNavigationRows()
    local rows = {}
    local resolved = Profile.ListResolvedSkills and Profile.ListResolvedSkills() or {}
    local counts = { weapon = 0, noncombat = 0, crafting = 0, language = 0 }
    local authoredCount = 0

    local datasets = Registry.GetActivatedDatasets and Registry:GetActivatedDatasets() or {}
    for datasetIndex = 1, #datasets do
        local dataset = datasets[datasetIndex]
        authoredCount = authoredCount + #(dataset and dataset.skills or {})
    end

    for index = 1, #resolved do
        local row = resolved[index]
        local skillType = tostring(row and row.skillType or "")
        if counts[skillType] ~= nil then
            counts[skillType] = counts[skillType] + 1
        end
    end

    for index = 1, #CATEGORY_DEFINITIONS do
        local definition = CATEGORY_DEFINITIONS[index]
        if isCategoryEnabled(definition.key) then
            rows[#rows + 1] = {
                key = definition.key,
                name = definition.label,
                count = counts[definition.key] or 0,
            }
        end
    end

    return rows, resolved, authoredCount
end

local function refreshNavListVisualRows(page, navRows)
    local navList = page and page.NavList or nil
    local rows = navList and navList.rows or nil
    if not rows then
        return
    end

    for index = 1, #rows do
        local row = rows[index]
        local item = navRows and navRows[index] or nil
        local frame = row and row.GetFrame and row:GetFrame() or nil

        if item then
            if row.SetCategory then
                row:SetCategory(item.name or "")
            end
            if row.SetTestName then
                row:SetTestName("")
            end
            if row.SetStatus then
                row:SetStatus(tostring(item.count or 0))
            end
            if row.SetDetail then
                row:SetDetail("")
            end

            if frame then
                if frame.Show then
                    frame:Show()
                end
                frame:EnableMouse(true)
            end

            local isSelected = tostring(item.key or "") == tostring(page.SelectedCategoryKey or "")
            if row.entryBackground and row.entryBackground.SetColorTexture then
                local token = isSelected and "list.rowHover" or "list.rowBackground"
                local color = UI.ResolveColor(nil, token)
                row.entryBackground:SetColorTexture(color.r or 0.08, color.g or 0.09, color.b or 0.11, color.a or 0.85)
            end
        else
            if row.SetCategory then
                row:SetCategory("")
            end
            if row.SetTestName then
                row:SetTestName("")
            end
            if row.SetStatus then
                row:SetStatus("")
            end
            if row.SetDetail then
                row:SetDetail("")
            end
            if frame and frame.Hide then
                frame:Hide()
            end
        end
    end
end

local function resolveDerivedStatLabel(statRef)
    if type(Registry.ResolveStatName) == "function" then
        return Registry:ResolveStatName(statRef)
    end

    local text = tostring(statRef or "")
    local _, statId = text:match("^([^:]+):(.+)$")
    return statId or text
end

local function resolveSkillDescription(row)
    local text = tostring(row and row.description or "")
    if text ~= "" then
        return text
    end

    return "No description provided for this skill."
end

local function formatFooterLevelText(row)
    if not row then
        return "Level -- / --"
    end

    local text = ("Level %d / %d"):format(tonumber(row.value) or 0, tonumber(row.maxValue) or 0)
    local bonusValue = tonumber(row.bonusValue) or 0
    if bonusValue > 0 then
        text = text .. (" |cff55ff55(+%d)|r"):format(bonusValue)
    end

    return text
end

function SkillsPage:GetSelectedRows()
    local rows = self.AllSkillRows or {}
    local selectedType = tostring(self.SelectedCategoryKey or "")
    if selectedType == "" then
        return rows
    end

    local filtered = {}
    for index = 1, #rows do
        local row = rows[index]
        if row and tostring(row.skillType or "") == selectedType then
            filtered[#filtered + 1] = row
        end
    end

    return filtered
end

function SkillsPage:EnsureSelection(rows)
    local selectedKey = tostring(self.SelectedCategoryKey or "")
    for index = 1, #rows do
        if tostring(rows[index] and rows[index].key or "") == selectedKey then
            return
        end
    end

    self.SelectedCategoryKey = rows[1] and rows[1].key or nil
end

function SkillsPage:BuildSkillEntryRenderer()
    return function(entry, row)
        entry:SetIcon(row.icon ~= "" and row.icon or "Interface\\Icons\\INV_Misc_QuestionMark")
        entry:SetSkillName(row.name or "Unnamed Skill")
        entry:SetValueText(("%d / %d"):format(tonumber(row.value) or 0, tonumber(row.maxValue) or 0))
        entry:SetProgress(row.progressValue, row.maxValue, "")
        entry:SetSelected(tostring(row.ref or "") == tostring(self.SelectedSkillRef or ""))
        if tostring(row.ref or "") == tostring(self.SelectedSkillRef or "") then
            entry:SetBorderColor(0.94, 0.74, 0.22, 1)
        else
            entry:SetBorderColor(0.42, 0.46, 0.52, 1)
        end
        entry.skillRow = row

        local frame = entry.GetFrame and entry:GetFrame() or nil
        if frame then
            frame:EnableMouse(true)
            frame:SetScript("OnMouseUp", function(_, button)
                if button == "LeftButton" and row and row.ref then
                    self.SelectedSkillRef = row.ref
                    self:Refresh()
                end
            end)
        end
    end
end

function SkillsPage:RefreshEntries()
    local rows = self:GetSelectedRows()
    local hasSelection = false

    for index = 1, #rows do
        if tostring(rows[index] and rows[index].ref or "") == tostring(self.SelectedSkillRef or "") then
            hasSelection = true
            break
        end
    end

    if not hasSelection then
        self.SelectedSkillRef = rows[1] and rows[1].ref or nil
    end

    if self.EntryScroll and self.EntryScroll.SetItems then
        self.EntryScroll:SetItems(rows)
    end

    if self.GridEmptyText and self.GridEmptyText.SetText then
        if #rows > 0 then
            self.GridEmptyText:SetText("")
        elseif (tonumber(self.AuthoredSkillCount) or 0) <= 0 then
            self.GridEmptyText:SetText("No skills are authored in active datasets.")
        else
            self.GridEmptyText:SetText("No enabled skills in this category.")
        end
    end
end

function SkillsPage:RefreshFooter()
    local row = Profile.GetResolvedSkillRow and Profile.GetResolvedSkillRow(self.SelectedSkillRef) or nil
    local canBindToActionBar = row ~= nil
        and tostring(row.skillType or "") == "noncombat"
        and row.rollable == true
    local boundSlot = canBindToActionBar and Profile.FindActionBarSlotBySkill and Profile.FindActionBarSlotBySkill(row.ref) or nil

    if self.FooterIcon and self.FooterIcon.SetTexture then
        self.FooterIcon:SetTexture(row and row.icon ~= "" and row.icon or "Interface\\Icons\\INV_Misc_QuestionMark")
    end
    if self.FooterTitle and self.FooterTitle.SetText then
        self.FooterTitle:SetText(row and (row.name or "Skill") or "Skill Details")
    end
    if self.FooterHint and self.FooterHint.SetText then
        self.FooterHint:SetText(formatFooterLevelText(row))
    end
    if self.FooterDescriptionText and self.FooterDescriptionText.SetText then
        self.FooterDescriptionText:SetText(row and resolveSkillDescription(row) or "Select a skill to inspect it.")
    end

    if self.FooterValueText and self.FooterValueText.SetText then
        self.FooterValueText:SetText(row and ("Current Level: %d"):format(tonumber(row.value) or 0) or "Current Level: --")
    end
    if self.FooterProgressText and self.FooterProgressText.SetText then
        self.FooterProgressText:SetText(row and ("Progress: %d / %d"):format(tonumber(row.progressValue) or 0, tonumber(row.maxValue) or 0) or "Progress: --")
    end
    if self.FooterBaseText and self.FooterBaseText.SetText then
        if not row then
            self.FooterBaseText:SetText("Base Value: --")
        elseif row.isDerived == true then
            local statName = resolveDerivedStatLabel(row.derivedStatRef)
            local derivedAmount = tonumber(row.derivedValue) or 0
            local storedAmount = tonumber(row.storedValue) or 0
            local sourceText = ("%d from %s x %s"):format(
                derivedAmount,
                statName ~= "" and statName or "stat",
                tostring(tonumber(row.derivedMultiplier) or 0)
            )
            if storedAmount > 0 then
                sourceText = ("%s, stored +%d"):format(sourceText, storedAmount)
            end
            self.FooterBaseText:SetText(("Base Value: %d (%s)"):format(
                tonumber(row.baseValue) or 0,
                sourceText
            ))
        else
            self.FooterBaseText:SetText(("Base Value: %d"):format(tonumber(row.baseValue) or 0))
        end
    end
    if self.FooterBonusText and self.FooterBonusText.SetText then
        self.FooterBonusText:SetText(row and ("Total Bonuses: %+d"):format(tonumber(row.bonusValue) or 0) or "Total Bonuses: --")
    end
    if self.FooterCapText and self.FooterCapText.SetText then
        self.FooterCapText:SetText(row and ("Maximum Level: %d"):format(tonumber(row.maxValue) or 0) or "Maximum Level: --")
    end
    if self.FooterActionButton and self.FooterActionButton.SetText then
        self.FooterActionButton:SetText(boundSlot and ("Remove From Action Bar") or "Add to Action Bar")
    end
    if self.FooterActionButton and self.FooterActionButton.SetEnabled then
        self.FooterActionButton:SetEnabled(canBindToActionBar)
    end
end

function SkillsPage:RefreshActionBarWidget(reason)
    if Client.BuildActionBarWidget then
        Client:BuildActionBarWidget()
    end
    if Client.ShowActionBarWidget then
        Client:ShowActionBarWidget()
    end
    if Client.RefreshActionBarWidget then
        Client:RefreshActionBarWidget(reason or "skills-action-bar")
    end
end

function SkillsPage:HandleSkillActionBarToggle(skillRef)
    if not skillRef or not Profile.ToggleSkillActionBarBinding then
        return false
    end

    local action = Profile.ToggleSkillActionBarBinding(skillRef)
    if not action then
        return false
    end

    self:RefreshActionBarWidget("skills-footer-toggle")
    if self.owner and self.owner.Refresh then
        self.owner:Refresh()
    else
        self:Refresh()
    end
    return true
end

function SkillsPage:Build(parent, owner)
    self.owner = owner
    if self.frame then
        return self.frame
    end

    self.frame = CreateFrame("Frame", "RPEProfileSkillsPage", parent)
    self.frame:SetAllPoints(parent)

    self.RootLayout = UI.CreateLayout(UI.HorizontalLayoutGroup, self.frame, "RPEProfileSkillsRootLayout", {
        spacing = 8,
        fitChildrenWidth = true,
        fitChildrenHeight = true,
    })
    UI.Utils.AnchorFill(self.RootLayout, self.frame, 0, 0, 0, 0)

    self.NavPanel = UI.CreatePanel(self.RootLayout:GetFrame(), "RPEProfileSkillsNavPanel", {
        width = NAV_PANEL_WIDTH,
        height = 304,
        contentInset = 2,
        showBorder = false,
    })
    self.RootLayout:AddChild(self.NavPanel)

    self.ContentPanel = UI.CreatePanel(self.RootLayout:GetFrame(), "RPEProfileSkillsContentPanel", {
        width = 340,
        height = 304,
        expandWidth = true,
        weight = 1,
        contentInset = 0,
        showBorder = false,
    })
    self.RootLayout:AddChild(self.ContentPanel)

    self.NavList = UI.ScrollLayout:New({
        name = "RPEProfileSkillsNavList",
        width = NAV_PANEL_WIDTH - 4,
        height = 300,
        visibleRows = 8,
        rowHeight = 18,
        rowSpacing = 0,
        border = false,
        rowElementClass = UI.ScrollListEntry,
        categoryWidth = 108,
        statusWidth = 26,
        categoryInsetLeft = 4,
        statusInsetRight = 4,
    })
    self.NavList:SetParent(self.NavPanel:GetContentFrame())
    self.NavList:SetRowRenderer(function(row, item)
        if row.SetCategory then
            row:SetCategory(item and item.name or "")
        end
        if row.SetTestName then
            row:SetTestName("")
        end
        if row.SetStatus then
            row:SetStatus(tostring(item and item.count or 0))
        end
        if row.SetDetail then
            row:SetDetail("")
        end

        local frame = row.GetFrame and row:GetFrame() or nil
        if frame then
            frame:EnableMouse(true)
            frame:SetScript("OnMouseUp", function(_, button)
                if button == "LeftButton" and item and item.key then
                    self.SelectedCategoryKey = item.key
                    self.SelectedSkillRef = nil
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
                row.entryBackground:SetColorTexture(color.r or 0.08, color.g or 0.09, color.b or 0.11, color.a or 0.85)
            end
        end
    end)
    self.NavList:Create()
    UI.Utils.AnchorFill(self.NavList, self.NavPanel:GetContentFrame(), 0, 0, 0, 0)

    self.NavEmptyText = UI.CreateText(self.NavPanel:GetContentFrame(), "RPEProfileSkillsNavEmptyText", "", {
        width = 140,
        height = 40,
        justifyH = "CENTER",
        wordWrap = true,
        textColor = UI.ResolveColor(nil, "text.secondary"),
    })
    self.NavEmptyText:GetFrame():SetPoint("CENTER", self.NavPanel:GetContentFrame(), "CENTER", 0, 0)

    self.ContentLayout = UI.CreateLayout(UI.VerticalLayoutGroup, self.ContentPanel:GetContentFrame(), "RPEProfileSkillsContentLayout", {
        spacing = 6,
        fitChildrenWidth = true,
        fitChildrenHeight = true,
    })
    UI.Utils.AnchorFill(self.ContentLayout, self.ContentPanel:GetContentFrame(), GRID_PADDING, 0, GRID_PADDING, 0)

    self.GridTitle = UI.CreateText(self.ContentLayout:GetFrame(), "RPEProfileSkillsGridTitle", "Skills", {
        width = 320,
        height = 18,
        justifyH = "LEFT",
    })
    self.ContentLayout:AddChild(self.GridTitle)

    self.EntryScrollPanel = UI.CreatePanel(self.ContentLayout:GetFrame(), "RPEProfileSkillsEntryScrollPanel", {
        width = 320,
        height = (ENTRY_HEIGHT * ENTRY_ROWS) + (ENTRY_SPACING * (ENTRY_ROWS - 1)),
        contentInset = 0,
        showBorder = false,
        expandWidth = true,
    })
    self.ContentLayout:AddChild(self.EntryScrollPanel)

    self.EntryScroll = UI.ScrollLayout:New({
        name = "RPEProfileSkillsEntryScroll",
        width = 320,
        height = (ENTRY_HEIGHT * ENTRY_ROWS) + (ENTRY_SPACING * (ENTRY_ROWS - 1)),
        visibleRows = ENTRY_ROWS,
        rowHeight = ENTRY_HEIGHT,
        rowSpacing = ENTRY_SPACING,
        rowInsetLeft = 0,
        rowInsetRight = 2,
        rowInsetTop = 0,
        rowInsetBottom = 0,
        contentInsetLeft = 0,
        contentInsetRight = 0,
        contentInsetTop = 0,
        contentInsetBottom = 0,
        scrollBarInsetRight = 0,
        rowElementClass = UI.SkillEntry,
        rowWidth = 320,
    })
    self.EntryScroll:SetParent(self.EntryScrollPanel:GetContentFrame())
    self.EntryScroll:SetRowRenderer(self:BuildSkillEntryRenderer())
    self.EntryScroll:Create()
    UI.Utils.AnchorFill(self.EntryScroll, self.EntryScrollPanel:GetContentFrame(), 0, 0, 0, 0)

    self.GridEmptyText = UI.CreateText(self.EntryScrollPanel:GetContentFrame(), "RPEProfileSkillsGridEmptyText", "", {
        width = 200,
        height = 40,
        justifyH = "CENTER",
        wordWrap = true,
        textColor = UI.ResolveColor(nil, "text.secondary"),
    })
    self.GridEmptyText:GetFrame():SetPoint("CENTER", self.EntryScrollPanel:GetContentFrame(), "CENTER", 0, 0)

    self.FooterPanel = UI.CreatePanel(self.ContentLayout:GetFrame(), "RPEProfileSkillsFooterPanel", {
        width = 320,
        height = 120,
        contentInset = 8,
        showBorder = true,
        expandWidth = true,
        expandHeight = true,
        weight = 1,
    })
    self.ContentLayout:AddChild(self.FooterPanel)

    self.FooterLayout = UI.CreateLayout(UI.VerticalLayoutGroup, self.FooterPanel:GetContentFrame(), "RPEProfileSkillsFooterLayout", {
        spacing = 8,
        fitChildrenWidth = true,
        fitChildrenHeight = false,
    })
    UI.Utils.AnchorFill(self.FooterLayout, self.FooterPanel:GetContentFrame(), 0, 0, 0, 0)

    self.FooterHeaderRow = UI.CreateLayout(UI.HorizontalLayoutGroup, self.FooterLayout:GetFrame(), "RPEProfileSkillsFooterHeaderRow", {
        height = 32,
        spacing = 10,
        fitChildrenWidth = true,
        fitChildrenHeight = false,
    })
    self.FooterLayout:AddChild(self.FooterHeaderRow)

    self.FooterIconPanel = UI.CreatePanel(self.FooterHeaderRow:GetFrame(), "RPEProfileSkillsFooterIconPanel", {
        width = 32,
        height = 32,
        contentInset = 1,
        showBorder = true,
    })
    self.FooterHeaderRow:AddChild(self.FooterIconPanel)

    self.FooterIcon = UI.Image:New({
        name = "RPEProfileSkillsFooterIcon",
        width = 30,
        height = 30,
        texture = "Interface\\Icons\\INV_Misc_QuestionMark",
        border = false,
        textureInsetLeft = 0,
        textureInsetTop = 0,
        textureInsetRight = 0,
        textureInsetBottom = 0,
    })
    self.FooterIcon:SetParent(self.FooterIconPanel:GetContentFrame())
    self.FooterIcon:Create()
    self.FooterIcon:GetFrame():SetAllPoints(self.FooterIconPanel:GetContentFrame())

    self.FooterHeaderTextLayout = UI.CreateLayout(UI.VerticalLayoutGroup, self.FooterHeaderRow:GetFrame(), "RPEProfileSkillsFooterHeaderTextLayout", {
        width = 250,
        height = 32,
        spacing = 2,
        fitChildrenWidth = true,
        fitChildrenHeight = false,
        expandWidth = true,
        weight = 1,
    })
    self.FooterHeaderRow:AddChild(self.FooterHeaderTextLayout)

    self.FooterTitle = UI.CreateText(self.FooterHeaderTextLayout:GetFrame(), "RPEProfileSkillsFooterTitle", "Skill Details", {
        width = 300,
        height = 14,
        justifyH = "LEFT",
    })
    self.FooterHeaderTextLayout:AddChild(self.FooterTitle)

    self.FooterHint = UI.CreateText(self.FooterHeaderTextLayout:GetFrame(), "RPEProfileSkillsFooterHint", "Level -- / --", {
        width = 300,
        height = 14,
        justifyH = "LEFT",
        textColor = UI.ResolveColor(nil, "text.secondary"),
    })
    self.FooterHeaderTextLayout:AddChild(self.FooterHint)

    self.FooterActionButton = UI.TextButton:New({
        name = "RPEProfileSkillsFooterActionButton",
        width = 84,
        height = 18,
        text = "Add",
        fontSize = 8,
        border = false,
    })
    self.FooterActionButton:SetParent(self.FooterHeaderRow:GetFrame())
    self.FooterActionButton:Create()
    self.FooterActionButton:SetScript("OnClick", function()
        self:HandleSkillActionBarToggle(self.SelectedSkillRef)
    end)
    self.FooterHeaderRow:AddChild(self.FooterActionButton)

    self.FooterDescriptionText = UI.CreateText(self.FooterLayout:GetFrame(), "RPEProfileSkillsFooterDescriptionText", "", {
        width = 300,
        height = 28,
        justifyH = "LEFT",
        wordWrap = true,
        textColor = UI.ResolveColor(nil, "text.primary"),
    })
    self.FooterLayout:AddChild(self.FooterDescriptionText)

    self.FooterStatsLayout = UI.CreateLayout(UI.VerticalLayoutGroup, self.FooterLayout:GetFrame(), "RPEProfileSkillsFooterStatsLayout", {
        spacing = 3,
        fitChildrenWidth = true,
        fitChildrenHeight = false,
    })
    self.FooterLayout:AddChild(self.FooterStatsLayout)

    self.FooterValueText = UI.CreateText(self.FooterStatsLayout:GetFrame(), "RPEProfileSkillsFooterValueText", "Current Level: --", {
        width = 300,
        height = 14,
        justifyH = "LEFT",
    })
    self.FooterStatsLayout:AddChild(self.FooterValueText)

    self.FooterProgressText = UI.CreateText(self.FooterStatsLayout:GetFrame(), "RPEProfileSkillsFooterProgressText", "Progress: --", {
        width = 300,
        height = 14,
        justifyH = "LEFT",
    })
    self.FooterStatsLayout:AddChild(self.FooterProgressText)

    self.FooterBaseText = UI.CreateText(self.FooterStatsLayout:GetFrame(), "RPEProfileSkillsFooterBaseText", "Base Value: --", {
        width = 300,
        height = 14,
        justifyH = "LEFT",
        textColor = UI.ResolveColor(nil, "text.secondary"),
    })
    self.FooterStatsLayout:AddChild(self.FooterBaseText)

    self.FooterBonusText = UI.CreateText(self.FooterStatsLayout:GetFrame(), "RPEProfileSkillsFooterBonusText", "Total Bonuses: --", {
        width = 300,
        height = 14,
        justifyH = "LEFT",
        textColor = UI.ResolveColor(nil, "text.secondary"),
    })
    self.FooterStatsLayout:AddChild(self.FooterBonusText)

    self.FooterCapText = UI.CreateText(self.FooterStatsLayout:GetFrame(), "RPEProfileSkillsFooterCapText", "Maximum Level: --", {
        width = 300,
        height = 14,
        justifyH = "LEFT",
        textColor = UI.ResolveColor(nil, "text.secondary"),
    })
    self.FooterStatsLayout:AddChild(self.FooterCapText)

    self:Refresh()
    return self.frame
end

function SkillsPage:Refresh()
    if not self.frame then
        return nil
    end

    local navRows, resolvedRows, authoredCount = buildNavigationRows()
    self.NavRows = navRows
    self.AllSkillRows = resolvedRows
    self.AuthoredSkillCount = authoredCount or 0
    self:EnsureSelection(navRows)

    if self.NavList and self.NavList.SetItems then
        if self.NavList.SetScrollOffset then
            self.NavList:SetScrollOffset(0)
        end
        self.NavList:SetItems(navRows)
        refreshNavListVisualRows(self, navRows)
    end
    if self.NavEmptyText and self.NavEmptyText.SetText then
        self.NavEmptyText:SetText(#navRows == 0 and "No enabled skill groups available." or "")
    end

    local title = "Skills"
    for index = 1, #navRows do
        local row = navRows[index]
        if tostring(row.key or "") == tostring(self.SelectedCategoryKey or "") then
            title = row.name or title
            break
        end
    end

    if self.GridTitle and self.GridTitle.SetText then
        self.GridTitle:SetText(title)
    end

    self:RefreshEntries()
    self:RefreshFooter()
    return self.frame
end

return SkillsPage
