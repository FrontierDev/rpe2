from pathlib import Path


def replace_once(text, old, new, label):
    count = text.count(old)
    if count != 1:
        raise SystemExit(f"{label}: expected 1 anchor, found {count}")
    return text.replace(old, new, 1)


def replace_between(text, start_marker, end_marker, replacement, label):
    start = text.find(start_marker)
    if start < 0:
        raise SystemExit(f"{label}: missing start marker")
    end = text.find(end_marker, start)
    if end < 0:
        raise SystemExit(f"{label}: missing end marker")
    return text[:start] + replacement + text[end:]


# ---------------------------------------------------------------------------
# Setup rules
# ---------------------------------------------------------------------------
rules_path = Path("core/internal/ruleset/Rules.lua")
rules = rules_path.read_text(encoding="utf-8")
anchor = '            { key = "required_starting_item_slot_refs", label = "Required Starting Item Slots", type = "dropdown", default = {}, multiSelect = true, description = "Require the setup wizard selection to include equipable items that satisfy these item slots.", optionsSource = "itemSlotReference" },\n'
addition = anchor + (
    '            { key = "enable_skills_page", label = "Enable Skills Page", type = "checkbox", default = true, description = "Show the Skills page in the setup wizard for allocating permanent bonuses to non-combat skills." },\n'
    '            { key = "permanent_skill_point_limit", label = "Permanent Skill Point Limit", type = "text", default = "50", description = "Maximum number of permanent non-combat skill points that can be allocated during character setup." },\n'
)
rules = replace_once(rules, anchor, addition, "setup rules")
rules_path.write_text(rules, encoding="utf-8")


# ---------------------------------------------------------------------------
# Persist the setup wizard's own skill allocation separately from the profile's
# combined permanent bonus value.
# ---------------------------------------------------------------------------
db_path = Path("core/internal/database/Database.lua")
db = db_path.read_text(encoding="utf-8")
anchor = '''        startingItemRefs = startingItemRefs,\n        actionBarSpellRefs = actionBarSpellRefs,\n    }\nend\n\nlocal function isValidProfileSpellRef'''
replacement = '''        startingItemRefs = startingItemRefs,\n        actionBarSpellRefs = actionBarSpellRefs,\n        skillPermanentBonuses = normalizeProfileSkillPermanentBonuses(data.skillPermanentBonuses),\n    }\nend\n\nlocal function isValidProfileSpellRef'''
db = replace_once(db, anchor, replacement, "setup wizard normalization")
db_path.write_text(db, encoding="utf-8")


# ---------------------------------------------------------------------------
# Clean setup-owned skill refs when datasets/skills are deleted.
# ---------------------------------------------------------------------------
deps_path = Path("core/internal/database/Dependecies.lua")
deps = deps_path.read_text(encoding="utf-8")
anchor = '''            if type(profile) == "table" and type(profile.skillPermanentBonuses) == "table" then\n                for skillRef in pairs(profile.skillPermanentBonuses) do\n                    local sourceDatasetId = Dependecies.ParseSourceStatRef(skillRef)\n                    if sourceDatasetId == datasetId then\n                        profile.skillPermanentBonuses[skillRef] = nil\n                    end\n                end\n            end\n            if type(profile) == "table" and type(profile.skillActionBar) == "table" then\n'''
replacement = '''            if type(profile) == "table" and type(profile.skillPermanentBonuses) == "table" then\n                for skillRef in pairs(profile.skillPermanentBonuses) do\n                    local sourceDatasetId = Dependecies.ParseSourceStatRef(skillRef)\n                    if sourceDatasetId == datasetId then\n                        profile.skillPermanentBonuses[skillRef] = nil\n                    end\n                end\n            end\n            if type(profile) == "table" and type(profile.setupWizard) == "table" and type(profile.setupWizard.skillPermanentBonuses) == "table" then\n                for skillRef in pairs(profile.setupWizard.skillPermanentBonuses) do\n                    local sourceDatasetId = Dependecies.ParseSourceStatRef(skillRef)\n                    if sourceDatasetId == datasetId then\n                        profile.setupWizard.skillPermanentBonuses[skillRef] = nil\n                    end\n                end\n            end\n            if type(profile) == "table" and type(profile.skillActionBar) == "table" then\n'''
deps = replace_once(deps, anchor, replacement, "dataset setup skill cleanup")

anchor = '''                if type(profile) == "table" and type(profile.skillPermanentBonuses) == "table" then\n                    profile.skillPermanentBonuses[deletedRef] = nil\n                end\n                if type(profile) == "table" and type(profile.skillActionBar) == "table" then\n'''
replacement = '''                if type(profile) == "table" and type(profile.skillPermanentBonuses) == "table" then\n                    profile.skillPermanentBonuses[deletedRef] = nil\n                end\n                if type(profile) == "table" and type(profile.setupWizard) == "table" and type(profile.setupWizard.skillPermanentBonuses) == "table" then\n                    profile.setupWizard.skillPermanentBonuses[deletedRef] = nil\n                end\n                if type(profile) == "table" and type(profile.skillActionBar) == "table" then\n'''
deps = replace_once(deps, anchor, replacement, "single setup skill cleanup")
deps_path.write_text(deps, encoding="utf-8")


# ---------------------------------------------------------------------------
# Setup wizard UI and draft/apply logic
# ---------------------------------------------------------------------------
ui_path = Path("client/ui/windows/window_SetupWizard.lua")
ui = ui_path.read_text(encoding="utf-8")

ui = replace_once(
    ui,
    'local UI = Addon.UI or {}\nlocal Database =',
    'local UI = Addon.UI or {}\nlocal BaseElement = UI.BaseElement\nlocal Database =',
    "BaseElement import",
)

ui = replace_once(
    ui,
    'local SETUP_WIZARD_TIMING_THRESHOLD_MS = 16\n',
    'local SETUP_WIZARD_TIMING_THRESHOLD_MS = 16\nlocal SKILLS_TAB_INDEX = 3\nlocal SKILLS_TAB_WIDTH = 56\nlocal SETUP_SKILL_ROW_HEIGHT = 30\nlocal SETUP_SKILL_ROW_WIDTH = 440\n',
    "setup skill constants",
)

row_class = r'''local SetupSkillAllocationRow = {}
SetupSkillAllocationRow.__index = SetupSkillAllocationRow
setmetatable(SetupSkillAllocationRow, { __index = BaseElement })

function SetupSkillAllocationRow:New(options)
    local instance = BaseElement.New(self, options)
    instance.options.border = false
    instance.adjustButtons = {}
    instance.adjustHandler = nil
    return instance
end

function SetupSkillAllocationRow:Create()
    if self.frame then
        return self.frame
    end

    local frame = CreateFrame("Frame", self.name, self:GetParentFrame())
    self:SetFrame(frame)
    local width = math.max(1, tonumber(self.options.width) or SETUP_SKILL_ROW_WIDTH)
    local height = math.max(1, tonumber(self.options.height) or SETUP_SKILL_ROW_HEIGHT)
    frame:SetSize(width, height)

    local buttonWidth = 30
    local buttonSpacing = 3
    local controlsWidth = (buttonWidth * 4) + (buttonSpacing * 3)
    local skillWidth = math.max(220, width - controlsWidth - 8)

    self.skillEntry = UI.SkillEntry:New({
        name = (self.name or "SetupSkillAllocationRow") .. "SkillEntry",
        width = skillWidth,
        height = height,
        border = false,
    })
    self.skillEntry:SetParent(frame)
    self.skillEntry:Create()
    self.skillEntry:GetFrame():SetPoint("LEFT", frame, "LEFT", 0, 0)

    local specs = {
        { label = "-5", delta = -5 },
        { label = "-1", delta = -1 },
        { label = "+1", delta = 1 },
        { label = "+5", delta = 5 },
    }
    local previousFrame = nil
    for index = #specs, 1, -1 do
        local spec = specs[index]
        local delta = spec.delta
        local button = UI.CreateButton(
            frame,
            (self.name or "SetupSkillAllocationRow") .. "AdjustButton" .. index,
            spec.label,
            buttonWidth,
            function()
                if type(self.adjustHandler) == "function" then
                    self.adjustHandler(delta)
                end
            end,
            {
                height = 20,
                fontSize = 7,
            }
        )
        local buttonFrame = button and button.GetFrame and button:GetFrame() or nil
        if buttonFrame then
            if previousFrame then
                buttonFrame:SetPoint("RIGHT", previousFrame, "LEFT", -buttonSpacing, 0)
            else
                buttonFrame:SetPoint("RIGHT", frame, "RIGHT", 0, 0)
            end
            previousFrame = buttonFrame
        end
        self.adjustButtons[delta] = button
    end

    return frame
end

function SetupSkillAllocationRow:SetAdjustHandler(handler)
    self.adjustHandler = handler
end

function SetupSkillAllocationRow:SetAdjustmentEnabled(delta, enabled)
    local button = self.adjustButtons and self.adjustButtons[delta] or nil
    if button and button.SetEnabled then
        button:SetEnabled(enabled == true)
    end
end

'''
ui = replace_once(
    ui,
    'local ACTIONBAR_SELECTED_SLOT_BORDER = { r = 0.94, g = 0.74, b = 0.22, a = 1 }\n\n',
    'local ACTIONBAR_SELECTED_SLOT_BORDER = { r = 0.94, g = 0.74, b = 0.22, a = 1 }\n\n' + row_class,
    "setup skill row class",
)

skill_map_helpers = r'''local function normalizeSetupSkillBonusMap(record)
    local normalized = {}
    for skillRef, value in pairs(type(record) == "table" and record or {}) do
        local normalizedRef = trimString(skillRef)
        local normalizedValue = math.max(0, math.floor(tonumber(value) or 0))
        if normalizedRef ~= "" and normalizedValue > 0 then
            normalized[normalizedRef] = normalizedValue
        end
    end
    return normalized
end

local function copySetupSkillBonusMap(record)
    local copy = {}
    for skillRef, value in pairs(normalizeSetupSkillBonusMap(record)) do
        copy[skillRef] = value
    end
    return copy
end

'''
ui = replace_once(
    ui,
    'local function findEntryByValue(items, value)\n',
    skill_map_helpers + 'local function findEntryByValue(items, value)\n',
    "setup skill map helpers",
)

ui = replace_once(
    ui,
    '        selectedStartingItemLookup = {},\n        startingItemFilterQuery = "",\n',
    '        selectedStartingItemLookup = {},\n        selectedSkillPermanentBonuses = {},\n        initialSkillPermanentBonuses = {},\n        setupSkillRows = {},\n        skillPointFeedback = "",\n        startingItemFilterQuery = "",\n',
    "setup wizard instance skill state",
)

ui = replace_once(
    ui,
    '''function SetupWizard:GetRequiredStartingItemSlotRefs()\n    local values = self:GetRuleValue("required_starting_item_slot_refs", {})\n    return type(values) == "table" and values or {}\nend\n\n''',
    '''function SetupWizard:GetRequiredStartingItemSlotRefs()\n    local values = self:GetRuleValue("required_starting_item_slot_refs", {})\n    return type(values) == "table" and values or {}\nend\n\nfunction SetupWizard:ShouldShowSkillsPage()\n    return self:GetRuleValue("enable_skills_page", true) ~= false\nend\n\nfunction SetupWizard:GetPermanentSkillPointLimit()\n    return math.max(0, math.floor(tonumber(self:GetRuleValue("permanent_skill_point_limit", 50)) or 50))\nend\n\n''',
    "setup skill rules accessors",
)

ui = replace_once(
    ui,
    '''        startingItemRefs = type(setupState.startingItemRefs) == "table" and setupState.startingItemRefs or {},\n        actionBarSpellRefs = actionBarSpellRefs,\n    }\nend\n\nfunction SetupWizard:SyncSelectionState(state)\n    self.selectedRaceRef = trimString(state and state.raceRef)\n    self.selectedClassRef = trimString(state and state.classRef)\n    self.selectedStartingItemLookup = selectionLookupFromArray(state and state.startingItemRefs or {})\n    self.hasDraftSelectionState = true\nend\n''',
    '''        startingItemRefs = type(setupState.startingItemRefs) == "table" and setupState.startingItemRefs or {},\n        actionBarSpellRefs = actionBarSpellRefs,\n        skillPermanentBonuses = copySetupSkillBonusMap(setupState.skillPermanentBonuses),\n    }\nend\n\nfunction SetupWizard:SyncSelectionState(state)\n    self.selectedRaceRef = trimString(state and state.raceRef)\n    self.selectedClassRef = trimString(state and state.classRef)\n    self.selectedStartingItemLookup = selectionLookupFromArray(state and state.startingItemRefs or {})\n    self.selectedSkillPermanentBonuses = copySetupSkillBonusMap(state and state.skillPermanentBonuses)\n    self.initialSkillPermanentBonuses = copySetupSkillBonusMap(state and state.skillPermanentBonuses)\n    self.skillPointFeedback = ""\n    self.hasDraftSelectionState = true\nend\n''',
    "capture and sync skill allocations",
)

skill_logic = r'''function SetupWizard:GetSetupSkillRows()
    local resolved = Profile.ListResolvedSkills and Profile.ListResolvedSkills() or {}
    local rows = {}
    for index = 1, #resolved do
        local row = resolved[index]
        if row and tostring(row.skillType or "") == "noncombat" and trimString(row.ref) ~= "" then
            rows[#rows + 1] = row
        end
    end
    table.sort(rows, function(left, right)
        local leftName = string.lower(trimString(left and left.name))
        local rightName = string.lower(trimString(right and right.name))
        if leftName == rightName then
            return trimString(left and left.ref) < trimString(right and right.ref)
        end
        return leftName < rightName
    end)
    return rows
end

function SetupWizard:GetAllocatedPermanentSkillPointTotal(bonuses)
    local total = 0
    for _, value in pairs(normalizeSetupSkillBonusMap(bonuses)) do
        total = total + math.max(0, math.floor(tonumber(value) or 0))
    end
    return total
end

function SetupWizard:ValidatePermanentSkillPointAllocation(bonuses)
    local limit = self:GetPermanentSkillPointLimit()
    local total = self:GetAllocatedPermanentSkillPointTotal(bonuses)
    return {
        limit = limit,
        total = total,
        remaining = math.max(0, limit - total),
        valid = total <= limit,
    }
end

function SetupWizard:GetSetupSkillPreviewValue(row)
    local skillRef = trimString(row and row.ref)
    local currentValue = math.max(0, tonumber(row and row.value) or 0)
    if skillRef == "" then
        return currentValue
    end

    local previousSetupBonus = math.max(0, math.floor(tonumber(self.initialSkillPermanentBonuses and self.initialSkillPermanentBonuses[skillRef]) or 0))
    local currentPermanentBonus = type(Profile.GetSkillPermanentBonus) == "function"
        and math.max(0, math.floor(tonumber(Profile.GetSkillPermanentBonus(skillRef)) or 0))
        or 0
    local currentSetupContribution = math.min(currentPermanentBonus, previousSetupBonus)
    local draftBonus = math.max(0, math.floor(tonumber(self.selectedSkillPermanentBonuses and self.selectedSkillPermanentBonuses[skillRef]) or 0))
    return math.max(0, currentValue - currentSetupContribution + draftBonus)
end

function SetupWizard:AdjustPermanentSkillPoint(skillRef, delta)
    local normalizedRef = trimString(skillRef)
    local normalizedDelta = math.floor(tonumber(delta) or 0)
    if normalizedRef == "" or normalizedDelta == 0 then
        return false
    end

    self.selectedSkillPermanentBonuses = self.selectedSkillPermanentBonuses or {}
    local current = math.max(0, math.floor(tonumber(self.selectedSkillPermanentBonuses[normalizedRef]) or 0))
    local nextValue = current + normalizedDelta
    if nextValue < 0 then
        return false
    end

    local validation = self:ValidatePermanentSkillPointAllocation(self.selectedSkillPermanentBonuses)
    if normalizedDelta > 0 and validation.total + normalizedDelta > validation.limit then
        self.skillPointFeedback = ("Permanent skill point limit reached: %d / %d."):format(validation.total, validation.limit)
        self:RefreshStatus()
        return false
    end

    if nextValue > 0 then
        self.selectedSkillPermanentBonuses[normalizedRef] = nextValue
    else
        self.selectedSkillPermanentBonuses[normalizedRef] = nil
    end
    self.skillPointFeedback = ""
    self:RefreshSkillsPage()
    if self.FinalizePageBuilt then
        self:RefreshFinalizePage()
    end
    self:RefreshStatus()
    return true
end

function SetupWizard:ApplySetupSkillPermanentBonuses(previousBonuses, nextBonuses)
    if type(Profile.GetSkillPermanentBonus) ~= "function" or type(Profile.SetSkillPermanentBonus) ~= "function" then
        return false
    end

    local previous = normalizeSetupSkillBonusMap(previousBonuses)
    local nextValues = normalizeSetupSkillBonusMap(nextBonuses)
    local refs = {}
    for skillRef in pairs(previous) do
        refs[skillRef] = true
    end
    for skillRef in pairs(nextValues) do
        refs[skillRef] = true
    end

    for skillRef in pairs(refs) do
        local currentPermanentBonus = math.max(0, math.floor(tonumber(Profile.GetSkillPermanentBonus(skillRef)) or 0))
        local previousSetupBonus = math.max(0, math.floor(tonumber(previous[skillRef]) or 0))
        local manualPermanentBonus = math.max(0, currentPermanentBonus - previousSetupBonus)
        local targetPermanentBonus = manualPermanentBonus + math.max(0, math.floor(tonumber(nextValues[skillRef]) or 0))
        if targetPermanentBonus > 0 then
            Profile.SetSkillPermanentBonus(skillRef, targetPermanentBonus)
        elseif type(Profile.ClearSkillPermanentBonus) == "function" then
            Profile.ClearSkillPermanentBonus(skillRef)
        else
            Profile.SetSkillPermanentBonus(skillRef, 0)
        end
    end
    return true
end

'''
ui = replace_once(
    ui,
    'local function createSectionPanel(parent, name, width)\n',
    skill_logic + 'local function createSectionPanel(parent, name, width)\n',
    "setup skill draft logic",
)

skills_page = r'''function SetupWizard:BuildSkillsPage(page)
    if self.SkillsPageBuilt then
        return
    end

    self.SkillsPageBuilt = true
    self.SkillsPage = page

    self.SkillsHintText = UI.CreateText(page, "RPESetupWizardSkillsHintText",
        "Allocate permanent bonus points to non-combat skills. Changes are applied only when setup is finalized.", {
            width = CONTENT_WIDTH,
            height = 14,
            justifyH = "LEFT",
            textColor = UI.ResolveColor(nil, "text.secondary"),
        }
    )
    self.SkillsHintText:GetFrame():SetPoint("TOPLEFT", page, "TOPLEFT", 0, 0)
    self.SkillsHintText:GetFrame():SetPoint("TOPRIGHT", page, "TOPRIGHT", 0, 0)

    self.SkillsSummaryText = UI.CreateText(page, "RPESetupWizardSkillsSummaryText", "", {
        width = CONTENT_WIDTH,
        height = 14,
        justifyH = "LEFT",
        textColor = UI.ResolveColor(nil, "text.secondary"),
    })
    self.SkillsSummaryText:GetFrame():SetPoint("TOPLEFT", self.SkillsHintText:GetFrame(), "BOTTOMLEFT", 0, -6)
    self.SkillsSummaryText:GetFrame():SetPoint("TOPRIGHT", page, "TOPRIGHT", 0, -20)

    self.SkillsPanel = UI.CreatePanel(page, "RPESetupWizardSkillsPanel", {
        width = CONTENT_WIDTH,
        height = 238,
        contentInset = 6,
    })
    self.SkillsPanel:GetFrame():SetPoint("TOPLEFT", self.SkillsSummaryText:GetFrame(), "BOTTOMLEFT", 0, -4)
    self.SkillsPanel:GetFrame():SetPoint("TOPRIGHT", page, "TOPRIGHT", 0, -38)

    self.SkillsScroll = UI.ScrollLayout:New({
        name = "RPESetupWizardSkillsScroll",
        width = CONTENT_WIDTH - 12,
        height = 226,
        visibleRows = 7,
        autoFitRows = true,
        minVisibleRows = 4,
        rowHeight = SETUP_SKILL_ROW_HEIGHT,
        rowSpacing = 2,
        border = false,
        rowElementClass = SetupSkillAllocationRow,
        rowWidth = SETUP_SKILL_ROW_WIDTH,
        rowInsetLeft = 0,
        rowInsetRight = 0,
        contentInsetLeft = 0,
        contentInsetRight = 0,
        contentInsetTop = 0,
        contentInsetBottom = 0,
        scrollBarInsetRight = 0,
    })
    self.SkillsScroll:SetParent(self.SkillsPanel:GetContentFrame())
    self.SkillsScroll:SetRowRenderer(function(row, item)
        local resolved = item and item.row or nil
        local skillRef = trimString(item and item.skillRef)
        if not resolved or skillRef == "" then
            return
        end

        local allocated = math.max(0, math.floor(tonumber(self.selectedSkillPermanentBonuses and self.selectedSkillPermanentBonuses[skillRef]) or 0))
        local validation = self:ValidatePermanentSkillPointAllocation(self.selectedSkillPermanentBonuses)
        local previewValue = self:GetSetupSkillPreviewValue(resolved)
        local maxValue = math.max(0, math.floor(tonumber(resolved.maxValue) or 0))
        local entry = row.skillEntry
        if entry then
            entry:SetIcon(trimString(resolved.icon) ~= "" and resolved.icon or DEFAULT_ICON)
            entry:SetSkillName(resolved.name or "Unnamed Skill")
            entry:SetValueText(("%d / %d"):format(math.floor(previewValue), maxValue))
            entry:SetProgress(math.min(previewValue, maxValue), maxValue, "")
            entry:SetSelected(false)
            entry:SetBorderColor(DEFAULT_SLOT_BORDER.r, DEFAULT_SLOT_BORDER.g, DEFAULT_SLOT_BORDER.b, DEFAULT_SLOT_BORDER.a)
            entry:SetEnabled(true)
        end

        row:SetAdjustHandler(function(delta)
            self:AdjustPermanentSkillPoint(skillRef, delta)
        end)
        row:SetAdjustmentEnabled(-5, allocated >= 5)
        row:SetAdjustmentEnabled(-1, allocated >= 1)
        row:SetAdjustmentEnabled(1, validation.remaining >= 1)
        row:SetAdjustmentEnabled(5, validation.remaining >= 5)
    end)
    self.SkillsScroll:Create()
    self.SkillsScroll:SetPoint("TOPLEFT", self.SkillsPanel:GetContentFrame(), "TOPLEFT", 0, 0)
    self.SkillsScroll:SetPoint("BOTTOMRIGHT", self.SkillsPanel:GetContentFrame(), "BOTTOMRIGHT", 0, 0)

    self.SkillsEmptyText = UI.CreateText(self.SkillsPanel:GetContentFrame(), "RPESetupWizardSkillsEmptyText", "", {
        width = CONTENT_WIDTH - 24,
        height = 24,
        justifyH = "CENTER",
        textColor = UI.ResolveColor(nil, "text.secondary"),
    })
    self.SkillsEmptyText:GetFrame():SetPoint("CENTER", self.SkillsPanel:GetContentFrame(), "CENTER", 0, 0)
end

function SetupWizard:RefreshSkillsPage()
    if not self.SkillsPageBuilt then
        local page = self.window and self.window.tabContainer and self.window.tabContainer.pageFrames and self.window.tabContainer.pageFrames[SKILLS_TAB_INDEX] or nil
        if page then
            self:BuildSkillsPage(page)
        end
    end
    if not self.SkillsPageBuilt then
        return
    end

    local rows = self:GetSetupSkillRows()
    self.setupSkillRows = rows
    local validation = self:ValidatePermanentSkillPointAllocation(self.selectedSkillPermanentBonuses)
    if validation.valid then
        self.skillPointFeedback = ""
    else
        self.skillPointFeedback = ("Permanent skill points exceed the ruleset limit: %d / %d."):format(validation.total, validation.limit)
    end

    if self.SkillsSummaryText and self.SkillsSummaryText.SetText then
        self.SkillsSummaryText:SetText(("Permanent points allocated: %d / %d"):format(validation.total, validation.limit))
    end

    local items = {}
    for index = 1, #rows do
        local row = rows[index]
        items[#items + 1] = {
            row = row,
            skillRef = row.ref,
        }
    end
    if self.SkillsScroll and self.SkillsScroll.SetItems then
        self.SkillsScroll:SetItems(items)
    end

    setFrameShown(self.SkillsEmptyText, #rows == 0)
    if self.SkillsEmptyText and self.SkillsEmptyText.SetText then
        self.SkillsEmptyText:SetText(#rows == 0 and "No enabled non-combat skills are available." or "")
    end
end

'''
ui = replace_once(
    ui,
    'function SetupWizard:BuildFinalizePage(page)\n',
    skills_page + 'function SetupWizard:BuildFinalizePage(page)\n',
    "skills page UI",
)

# Add the Skills tab between Items and Action Bar.
anchor = '''            {\n                name = "actionbar",\n                label = "Action Bar",\n'''
skills_tab = '''            {\n                name = "skills",\n                label = "Skills",\n                width = SKILLS_TAB_WIDTH,\n                builder = function(page)\n                    measureSetupTiming("SetupWizard.BuildPage", "skills", function()\n                        self:BuildSkillsPage(page)\n                    end)\n                end,\n            },\n'''
ui = replace_once(ui, anchor, skills_tab + anchor, "skills tab")

ui = replace_once(
    ui,
    '    self.window = window\n\n    local outerContent =',
    '    self.window = window\n    self:ApplySkillsPageVisibility()\n\n    local outerContent =',
    "skills tab initial visibility",
)

visibility_method = r'''function SetupWizard:ApplySkillsPageVisibility()
    local tabContainer = self.window and self.window.tabContainer or nil
    if type(tabContainer) ~= "table" then
        return self:ShouldShowSkillsPage()
    end

    local visible = self:ShouldShowSkillsPage()
    local tab = tabContainer.tabs and tabContainer.tabs[SKILLS_TAB_INDEX] or nil
    local button = tabContainer.tabButtons and tabContainer.tabButtons[SKILLS_TAB_INDEX] or nil
    local buttonFrame = button and button.GetFrame and button:GetFrame() or nil
    local page = tabContainer.pageFrames and tabContainer.pageFrames[SKILLS_TAB_INDEX] or nil

    if tab and tostring(tab.name or "") == "skills" then
        tab.width = visible and SKILLS_TAB_WIDTH or 0
    end
    if buttonFrame and buttonFrame.SetShown then
        buttonFrame:SetShown(visible)
    elseif buttonFrame then
        if visible and buttonFrame.Show then
            buttonFrame:Show()
        elseif not visible and buttonFrame.Hide then
            buttonFrame:Hide()
        end
    end

    if not visible and tonumber(tabContainer.activeTabIndex) == SKILLS_TAB_INDEX then
        tabContainer:SetActiveTab(1)
    elseif not visible and page and page.Hide then
        page:Hide()
    end
    if tabContainer.LayoutTabs then
        tabContainer:LayoutTabs()
    end
    return visible
end

'''
ui = replace_once(
    ui,
    'function SetupWizard:GetActiveTabIndex()\n',
    visibility_method + 'function SetupWizard:GetActiveTabIndex()\n',
    "skills tab visibility method",
)

new_refresh_page = r'''function SetupWizard:RefreshPage(tabIndex, state)
    local index = math.max(1, math.floor(tonumber(tabIndex) or 1))
    local context = ({ "identity", "items", "skills", "actionbar", "finalize" })[index] or tostring(index)
    return measureSetupTiming("SetupWizard.RefreshPage", context, function()
        if index == 1 then
            self:RefreshIdentityPage(state)
        elseif index == 2 then
            self:RefreshStartingItemsPage(state)
        elseif index == SKILLS_TAB_INDEX then
            if self:ShouldShowSkillsPage() then
                self:RefreshSkillsPage()
            end
        elseif index == 4 then
            if not self.ActionBarPageRoot then
                local page = self.window and self.window.tabContainer and self.window.tabContainer.pageFrames and self.window.tabContainer.pageFrames[4] or nil
                if page then
                    self:BuildActionBarPage(page)
                end
            end
            self:RefreshActionBarPage(state)
        elseif index == 5 then
            if not self.FinalizePageBuilt then
                local page = self.window and self.window.tabContainer and self.window.tabContainer.pageFrames and self.window.tabContainer.pageFrames[5] or nil
                if page then
                    self:BuildFinalizePage(page)
                end
            end
            self:RefreshFinalizePage()
        end
    end)
end

'''
ui = replace_between(
    ui,
    'function SetupWizard:RefreshPage(tabIndex, state)\n',
    'function SetupWizard:QueuePageRefresh(tabIndex)\n',
    new_refresh_page,
    "refresh page routing",
)

# Refresh full wizard now includes the optional skill page and applies tab visibility.
ui = replace_once(
    ui,
    '''function SetupWizard:Refresh()\n    local timing = startSetupTiming("SetupWizard.Refresh", "full")\n    self:ApplyDatasetPolicy()\n''',
    '''function SetupWizard:Refresh()\n    local timing = startSetupTiming("SetupWizard.Refresh", "full")\n    self:ApplyDatasetPolicy()\n    self:ApplySkillsPageVisibility()\n''',
    "refresh visibility",
)
ui = replace_once(
    ui,
    '''    if self.ActionBarPageRoot then\n        self:RefreshActionBarPage(state)\n    end\n    if self.FinalizePageBuilt then\n''',
    '''    if self.SkillsPageBuilt and self:ShouldShowSkillsPage() then\n        self:RefreshSkillsPage()\n    end\n    if self.ActionBarPageRoot then\n        self:RefreshActionBarPage(state)\n    end\n    if self.FinalizePageBuilt then\n''',
    "full refresh skills page",
)
ui = replace_once(
    ui,
    '''        identity = self.IdentityPageBuilt and 1 or 0,\n        items = self.StartingItemsPageBuilt and 1 or 0,\n        actionbar = self.ActionBarPageRoot and 1 or 0,\n''',
    '''        identity = self.IdentityPageBuilt and 1 or 0,\n        items = self.StartingItemsPageBuilt and 1 or 0,\n        skills = self.SkillsPageBuilt and self:ShouldShowSkillsPage() and 1 or 0,\n        actionbar = self.ActionBarPageRoot and 1 or 0,\n''',
    "full refresh timing skills",
)

# Carry draft allocations through collection without applying them yet.
ui = replace_once(
    ui,
    '''        startingItemRefs = selectionArrayFromLookup(self.availableStartingItems, self.selectedStartingItemLookup),\n        actionBarSpellRefs = state.actionBarSpellRefs or {},\n    }\n''',
    '''        startingItemRefs = selectionArrayFromLookup(self.availableStartingItems, self.selectedStartingItemLookup),\n        actionBarSpellRefs = state.actionBarSpellRefs or {},\n        skillPermanentBonuses = copySetupSkillBonusMap(self.selectedSkillPermanentBonuses or state.skillPermanentBonuses),\n    }\n''',
    "collect skill allocations",
)

# Validate the budget and capture the previous setup-owned contribution before applying.
ui = replace_once(
    ui,
    '''    local state = self:CollectCurrentSelection()\n    local validation = self:ValidateCurrentItemSelection()\n    local plan = validation.plan\n''',
    '''    local state = self:CollectCurrentSelection()\n    local validation = self:ValidateCurrentItemSelection()\n    local skillValidation = self:ValidatePermanentSkillPointAllocation(state.skillPermanentBonuses)\n    local previousSetupState = Profile.GetSetupWizardState and Profile.GetSetupWizardState() or {}\n    local plan = validation.plan\n    if self:ShouldShowSkillsPage() and skillValidation.valid ~= true then\n        self.skillPointFeedback = ("Permanent skill points exceed the ruleset limit: %d / %d."):format(skillValidation.total, skillValidation.limit)\n        self:RefreshStatus()\n        return false\n    end\n''',
    "apply skill allocation validation",
)

# Apply setup-owned bonuses only during final application, and only when the page is enabled.
ui = replace_once(
    ui,
    '''    for index = 1, #(plan.inventory or {}) do\n''',
    '''    if self:ShouldShowSkillsPage() then\n        self:ApplySetupSkillPermanentBonuses(previousSetupState.skillPermanentBonuses, state.skillPermanentBonuses)\n    end\n\n    for index = 1, #(plan.inventory or {}) do\n''',
    "apply setup skill bonuses on finalize",
)
ui = replace_once(
    ui,
    '''    self.startingItemFeedback = ""\n    if Client.RefreshActionBarWidget then\n''',
    '''    self.startingItemFeedback = ""\n    self.skillPointFeedback = ""\n    if Client.RefreshActionBarWidget then\n''',
    "clear setup skill feedback after apply",
)

# Finalize summary includes skill allocations and blocks Apply if the point cap is exceeded.
finalize_anchor = '''    if actionBarSize <= 0 then\n        lines[#lines + 1] = "- No action bar slots are available."\n    else\n        lines[#lines + 1] = ("Bound Spells: %d / %d"):format(boundSpellCount, actionBarSize)\n    end\n\n    if self.FinalizeSummaryScroll and self.FinalizeSummaryScroll.SetItems then\n'''
finalize_replacement = '''    if actionBarSize <= 0 then\n        lines[#lines + 1] = "- No action bar slots are available."\n    else\n        lines[#lines + 1] = ("Bound Spells: %d / %d"):format(boundSpellCount, actionBarSize)\n    end\n\n    local skillValidation = self:ValidatePermanentSkillPointAllocation(selection.skillPermanentBonuses)\n    if self:ShouldShowSkillsPage() then\n        lines[#lines + 1] = ""\n        lines[#lines + 1] = ("Permanent Skill Points: %d / %d"):format(skillValidation.total, skillValidation.limit)\n        local allocatedCount = 0\n        for index = 1, #(self:GetSetupSkillRows() or {}) do\n            local row = self:GetSetupSkillRows()[index]\n            local amount = math.max(0, math.floor(tonumber(selection.skillPermanentBonuses and selection.skillPermanentBonuses[row.ref]) or 0))\n            if amount > 0 then\n                allocatedCount = allocatedCount + 1\n                lines[#lines + 1] = ("- %s: +%d"):format(tostring(row.name or "Skill"), amount)\n            end\n        end\n        if allocatedCount == 0 then\n            lines[#lines + 1] = "- None"\n        end\n    end\n\n    if self.FinalizeSummaryScroll and self.FinalizeSummaryScroll.SetItems then\n'''
ui = replace_once(ui, finalize_anchor, finalize_replacement, "finalize skill summary")

ui = replace_once(
    ui,
    '''            self:IsEnabled()\n            and validation.withinBudget == true\n            and validation.passesRequiredSlots == true\n        )\n''',
    '''            self:IsEnabled()\n            and validation.withinBudget == true\n            and validation.passesRequiredSlots == true\n            and (not self:ShouldShowSkillsPage() or skillValidation.valid == true)\n        )\n''',
    "finalize apply skill validation",
)

# Status feedback prioritizes a skill allocation error over the item picker feedback.
ui = replace_once(
    ui,
    '''    if self:IsEnabled() and trimString(self.startingItemFeedback) ~= "" then\n        self.StatusText:SetText(self.startingItemFeedback)\n    elseif self:IsEnabled() then\n''',
    '''    if self:IsEnabled() and trimString(self.skillPointFeedback) ~= "" then\n        self.StatusText:SetText(self.skillPointFeedback)\n    elseif self:IsEnabled() and trimString(self.startingItemFeedback) ~= "" then\n        self.StatusText:SetText(self.startingItemFeedback)\n    elseif self:IsEnabled() then\n''',
    "skill point status feedback",
)

# Re-evaluate optional-page visibility whenever the wizard is shown.
ui = replace_once(
    ui,
    '''function SetupWizard:Show()\n    local window = self:BuildWindow()\n    local state = self:CaptureSelectionState()\n''',
    '''function SetupWizard:Show()\n    local window = self:BuildWindow()\n    self:ApplySkillsPageVisibility()\n    local state = self:CaptureSelectionState()\n''',
    "show skills page visibility",
)
ui = replace_once(
    ui,
    '''function SetupWizard:Hide()\n    self.hasDraftSelectionState = false\n    self.needsDatasetPolicyRefresh = false\n''',
    '''function SetupWizard:Hide()\n    self.hasDraftSelectionState = false\n    self.needsDatasetPolicyRefresh = false\n    self.skillPointFeedback = ""\n''',
    "hide skill feedback reset",
)

ui_path.write_text(ui, encoding="utf-8")
