local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Client.UI = Addon.Client.UI or {}
Addon.Client.UI.Editor = Addon.Client.UI.Editor or {}

local DataEditor = Addon.Client.UI.Editor
local UI = Addon.UI or {}
local Client = Addon.Client or {}
local SkillClass = Addon.Internal and Addon.Internal.Database and Addon.Internal.Database.Classes and Addon.Internal.Database.Classes.Skill or nil

local SIDE_PADDING = 8
local FIELD_WIDTH = 236
local CONTROL_HEIGHT = 20

local SKILL_TYPE_ITEMS = {
    { label = "Weapon", value = "weapon" },
    { label = "Non-Combat", value = "noncombat" },
    { label = "Crafting", value = "crafting" },
    { label = "Language", value = "language" },
}

local SKILL_LEARN_MODE_ITEMS = {
    { label = "Always Available", value = "always_available" },
    { label = "Trainer", value = "trainer" },
    { label = "Book", value = "book" },
    { label = "Unavailable", value = "unavailable" },
}

local SKILL_INSPECTOR_PAGE_DEFINITIONS = {
    { key = "general", label = "General" },
    { key = "learning", label = "Learning" },
    { key = "configuration", label = "Configuration" },
}

local function ensureString(value)
    if value == nil then
        return ""
    end

    return tostring(value)
end

local function buildLabel(parent, name, text, width)
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

local function setCheckboxEnabled(checkbox, enabled)
    if not checkbox then
        return
    end

    if checkbox.SetEnabled then
        checkbox:SetEnabled(enabled == true)
    end

    local frame = checkbox.GetFrame and checkbox:GetFrame() or nil
    if frame and frame.EnableMouse then
        frame:EnableMouse(enabled == true)
    end
    if frame and frame.SetAlpha then
        frame:SetAlpha(enabled == true and 1 or 0.5)
    end
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

local function createSkillInspectorPageFrame(self, name)
    local page = CreateFrame("Frame", name, self.SkillInspectorPage)
    page:SetPoint("TOPLEFT", self.SkillInspectorPage, "TOPLEFT", SIDE_PADDING, -24)
    page:SetPoint("TOPRIGHT", self.SkillInspectorPage, "TOPRIGHT", -SIDE_PADDING, -24)
    page:SetPoint("BOTTOMLEFT", self.SkillInspectorPage, "BOTTOMLEFT", SIDE_PADDING, 24)
    page:SetPoint("BOTTOMRIGHT", self.SkillInspectorPage, "BOTTOMRIGHT", -SIDE_PADDING, 24)
    return page
end

local function createFieldGroup(parent, name, labelText, height)
    local groupHeight = 14 + 2 + (height or CONTROL_HEIGHT)
    local group = UI.CreateLayout(UI.VerticalLayoutGroup, parent:GetFrame(), name, {
        width = FIELD_WIDTH,
        height = groupHeight,
        spacing = 2,
        fitChildrenWidth = true,
        fitChildrenHeight = false,
    })
    group._visibleHeight = groupHeight
    parent:AddChild(group)
    group:AddChild(buildLabel(group:GetFrame(), name .. "Label", labelText))
    return group
end

local function buildWeaponTypeItems(self)
    local items = {
        { label = "None", value = "" },
    }

    local datasets = self.GetDatasets and self:GetDatasets() or {}
    for datasetIndex = 1, #datasets do
        local dataset = datasets[datasetIndex]
        local weaponTypes = dataset and dataset.weaponTypes or {}
        for weaponTypeIndex = 1, #weaponTypes do
            local weaponType = weaponTypes[weaponTypeIndex]
            if weaponType and weaponType.id then
                items[#items + 1] = {
                    label = ("%s / %s"):format(self:GetDatasetDisplayName(dataset), self:GetEntryDisplayName("weaponTypes", weaponType)),
                    value = ("%s:%s"):format(dataset.id, weaponType.id),
                }
            end
        end
    end

    return items
end

local function getSkillTypeSummary(skillType)
    if skillType == "weapon" then
        return "Weapon skills use the profile level and ruleset multiplier for their cap, then add stored progression and bonuses. Each weapon skill targets one weapon type."
    end
    if skillType == "crafting" then
        return "Crafting skills use stored progression, bonus sources, and a ruleset-defined cap."
    end
    if skillType == "language" then
        return "Language skills use stored progression, bonus sources, and a ruleset-defined cap."
    end

    return "Non-combat skills can be rollable metadata and may add a derived stat contribution on top of stored progression."
end

local function getSkillRulesText(skillType, hasDerivedStat)
    if skillType == "weapon" then
        return "Weapon cap = floor(profile level x ruleset multiplier). Weapon skill gain chance is also driven by the ruleset."
    end
    if skillType == "crafting" then
        return "Crafting skills use stored profile progression and the ruleset crafting max. Crafting gain chance is handled outside the ruleset."
    end
    if skillType == "language" then
        return "Language skills use stored profile progression, the ruleset language max, and the ruleset language gain chance."
    end
    if hasDerivedStat then
        return "Derived non-combat skills add their stat-based contribution to any stored progression, then apply temporary bonuses."
    end

    return "Manual non-combat skills use stored profile progression, then apply temporary bonuses. Their cap and gain chance both come from the ruleset."
end

function DataEditor:GetSelectedSkillAndDataset()
    return self:GetSelectedDataset(), self:GetSelectedSkill()
end

function DataEditor:NormalizeSkillDefinition(skill)
    if SkillClass and SkillClass.New and SkillClass.ToTable then
        return SkillClass.ToTable(SkillClass:New(skill))
    end

    return skill or {}
end

function DataEditor:CommitSelectedSkill(mutate)
    local dataset, skill = self:GetSelectedSkillAndDataset()
    if not dataset or not skill or type(mutate) ~= "function" then
        return
    end

    local before = self:DeepCopyValue(skill)
    mutate(skill, dataset)
    local normalized = self:NormalizeSkillDefinition(skill)
    for key in pairs(skill) do
        if normalized[key] == nil then
            skill[key] = nil
        end
    end
    for key, value in pairs(normalized) do
        skill[key] = value
    end

    if self:DeepEqualValues(before, skill) then
        return
    end

    self:QueuePendingDatasetEntryChanged(dataset.id, "skills")
end

function DataEditor:GetSkillInspectorPageDefinitions()
    return SKILL_INSPECTOR_PAGE_DEFINITIONS
end

function DataEditor:GetSkillInspectorPageIndexByKey(key)
    local pages = self:GetSkillInspectorPageDefinitions()
    for index = 1, #pages do
        if pages[index].key == key then
            return index
        end
    end

    return 1
end

function DataEditor:BuildSkillInspectorPageSelectorItems()
    local items = {}
    local pages = self:GetSkillInspectorPageDefinitions()
    for index = 1, #pages do
        items[#items + 1] = {
            label = pages[index].label,
            value = pages[index].key,
        }
    end

    return items
end

function DataEditor:RefreshSkillInspectorPageSelector()
    local pages = self:GetSkillInspectorPageDefinitions()
    local pageCount = #pages
    local activeIndex = math.max(1, math.min(self.ActiveSkillInspectorPageIndex or 1, pageCount))
    self.ActiveSkillInspectorPageIndex = activeIndex
    self.ActiveSkillInspectorTabKey = pages[activeIndex] and pages[activeIndex].key or "general"

    local activeDefinition = pages[activeIndex]
    if self.SkillInspectorPageDropdown and activeDefinition then
        self._refreshingSkillInspectorPageSelector = true
        self.SkillInspectorPageDropdown:SetItems(self:BuildSkillInspectorPageSelectorItems())
        self.SkillInspectorPageDropdown:SetSelectedValue(activeDefinition.key, true)
        self._refreshingSkillInspectorPageSelector = false
    end

    if self.SkillInspectorPreviousButton and self.SkillInspectorPreviousButton.SetEnabled then
        self.SkillInspectorPreviousButton:SetEnabled(activeIndex > 1)
    end
    if self.SkillInspectorNextButton and self.SkillInspectorNextButton.SetEnabled then
        self.SkillInspectorNextButton:SetEnabled(activeIndex < pageCount)
    end
end

function DataEditor:SetSkillInspectorTab(tabKey)
    local pageDefinitions = self:GetSkillInspectorPageDefinitions()
    self.ActiveSkillInspectorPageIndex = self:GetSkillInspectorPageIndexByKey(tabKey or "general")
    self.ActiveSkillInspectorTabKey = pageDefinitions[self.ActiveSkillInspectorPageIndex] and pageDefinitions[self.ActiveSkillInspectorPageIndex].key or "general"

    local pageFrames = {
        general = self.SkillInspectorGeneralPage,
        learning = self.SkillInspectorLearningPage,
        configuration = self.SkillInspectorConfigurationPage,
    }

    for key, page in pairs(pageFrames) do
        if page then
            if key == self.ActiveSkillInspectorTabKey then
                page:Show()
            else
                page:Hide()
            end
        end
    end

    self:RefreshSkillInspectorPageSelector()
end

local function buildSkillInspectorGeneralPage(self, page)
    local root = UI.CreateLayout(UI.VerticalLayoutGroup, page, "RPEDataEditorSkillInspectorGeneralLayout", {
        spacing = 6,
        fitChildrenWidth = true,
        fitChildrenHeight = false,
    })
    UI.Utils.AnchorFill(root, page, 0, 0, 0, 0)
    self.SkillInspectorGeneralRoot = root

    root:AddChild(buildLabel(root:GetFrame(), "RPEDataEditorSkillInspectorNameLabel", "Name"))
    self.SkillInspectorNameInput = UI.CreateTextInput(root:GetFrame(), "RPEDataEditorSkillInspectorNameInput", {
        width = FIELD_WIDTH,
        height = CONTROL_HEIGHT,
        text = "",
        borderColor = UI.ResolveColor(nil, "panel.border"),
    })
    self.SkillInspectorNameInput:SetScript("OnEnterPressed", function()
        self:CommitSelectedSkill(function(skill)
            skill.name = self.SkillInspectorNameInput:GetText()
        end)
    end)
    self.SkillInspectorNameInput:SetScript("OnEditFocusLost", function()
        self:CommitSelectedSkill(function(skill)
            skill.name = self.SkillInspectorNameInput:GetText()
        end)
    end)
    root:AddChild(self.SkillInspectorNameInput)

    self.SkillInspectorIdText = UI.CreateText(root:GetFrame(), "RPEDataEditorSkillInspectorIdText", "ID: -", {
        width = FIELD_WIDTH,
        height = 12,
        justifyH = "LEFT",
        textColor = UI.ResolveColor(nil, "text.secondary"),
    })
    root:AddChild(self.SkillInspectorIdText)

    root:AddChild(buildLabel(root:GetFrame(), "RPEDataEditorSkillInspectorIconLabel", "Icon"))
    self.SkillInspectorIconField = UI.EditorIconField:New({
        name = "RPEDataEditorSkillInspectorIconField",
        width = FIELD_WIDTH,
        height = CONTROL_HEIGHT,
        buttonText = "Select Icon",
        labelText = "-",
        iconTexture = "Interface\\Icons\\INV_Misc_QuestionMark",
        border = false,
    })
    self.SkillInspectorIconField:SetParent(root:GetFrame())
    self.SkillInspectorIconField:Create()
    local iconButton = self.SkillInspectorIconField:GetButton()
    if iconButton and iconButton.SetScript then
        iconButton:SetScript("OnClick", function()
            local _, skill = self:GetSelectedSkillAndDataset()
            if not skill or not Client.OpenIconFinder then
                return
            end

            Client:OpenIconFinder(function(_, filePath)
                self:CommitSelectedSkill(function(selectedSkill)
                    selectedSkill.icon = filePath or ""
                end)
            end, {
                filter = skill.icon or "",
            })
        end)
    end
    root:AddChild(self.SkillInspectorIconField)

    self.SkillInspectorIconInput = {
        SetText = function(_, value)
            local iconPath = ensureString(value)
            self.SkillInspectorIconField:SetIcon(iconPath ~= "" and iconPath or "Interface\\Icons\\INV_Misc_QuestionMark")
            self.SkillInspectorIconField:SetLabelText(iconPath ~= "" and iconPath or "-")
        end,
        SetEnabled = function(_, enabled)
            self.SkillInspectorIconField:SetEnabled(enabled)
        end,
        SetReadOnly = function(_, readOnly)
            self.SkillInspectorIconField:SetEnabled(readOnly ~= true)
        end,
    }

    root:AddChild(buildLabel(root:GetFrame(), "RPEDataEditorSkillInspectorDescriptionLabel", "Description"))
    self.SkillInspectorDescriptionInput = UI.CreateTextArea(root:GetFrame(), "RPEDataEditorSkillInspectorDescriptionInput", {
        width = FIELD_WIDTH,
        height = 72,
        text = "",
        readOnly = false,
        borderColor = UI.ResolveColor(nil, "panel.border"),
    })
    self.SkillInspectorDescriptionInput:SetScript("OnEditFocusLost", function()
        self:CommitSelectedSkill(function(skill)
            skill.description = self.SkillInspectorDescriptionInput:GetText()
        end)
    end)
    root:AddChild(self.SkillInspectorDescriptionInput)

    root:AddChild(buildLabel(root:GetFrame(), "RPEDataEditorSkillInspectorTypeLabel", "Skill Type"))
    self.SkillInspectorTypeDropdown = UI.CreateDropdown(root:GetFrame(), "RPEDataEditorSkillInspectorTypeDropdown", {
        width = FIELD_WIDTH,
        height = 18,
        items = SKILL_TYPE_ITEMS,
        onValueChanged = function(value)
            if self._refreshingSkillInspector then
                return
            end

            self:CommitSelectedSkill(function(skill)
                skill.skillType = value
            end)
        end,
    })
    root:AddChild(self.SkillInspectorTypeDropdown)

    self.SkillInspectorTypeSummaryText = UI.CreateText(root:GetFrame(), "RPEDataEditorSkillInspectorTypeSummaryText", "", {
        width = FIELD_WIDTH,
        height = 30,
        justifyH = "LEFT",
        wordWrap = true,
        textColor = UI.ResolveColor(nil, "text.secondary"),
    })
    root:AddChild(self.SkillInspectorTypeSummaryText)

    self.SkillInspectorWeaponTypeGroup = createFieldGroup(root, "RPEDataEditorSkillInspectorWeaponTypeGroup", "Weapon Type", 18)
    self.SkillInspectorWeaponTypeDropdown = UI.CreateDropdown(self.SkillInspectorWeaponTypeGroup:GetFrame(), "RPEDataEditorSkillInspectorWeaponTypeDropdown", {
        width = FIELD_WIDTH,
        height = 18,
        items = buildWeaponTypeItems(self),
        onValueChanged = function(value)
            if self._refreshingSkillInspector then
                return
            end

            self:CommitSelectedSkill(function(skill)
                skill.weaponTypeRef = value ~= "" and value or nil
            end)
        end,
    })
    self.SkillInspectorWeaponTypeGroup:AddChild(self.SkillInspectorWeaponTypeDropdown)
end

local function buildSkillInspectorLearningPage(self, page)
    local root = UI.CreateLayout(UI.VerticalLayoutGroup, page, "RPEDataEditorSkillInspectorLearningLayout", {
        spacing = 6,
        fitChildrenWidth = true,
        fitChildrenHeight = false,
    })
    UI.Utils.AnchorFill(root, page, 0, 0, 0, 0)
    self.SkillInspectorLearningRoot = root

    root:AddChild(buildLabel(root:GetFrame(), "RPEDataEditorSkillInspectorLearnModeLabel", "Learn Mode"))
    self.SkillInspectorLearnModeDropdown = UI.CreateDropdown(root:GetFrame(), "RPEDataEditorSkillInspectorLearnModeDropdown", {
        width = FIELD_WIDTH,
        height = CONTROL_HEIGHT,
        items = SKILL_LEARN_MODE_ITEMS,
        onValueChanged = function(value)
            if self._refreshingSkillInspector then
                return
            end

            self:CommitSelectedSkill(function(skill)
                skill.learnMode = value or "always_available"
            end)
        end,
    })
    root:AddChild(self.SkillInspectorLearnModeDropdown)

    self.SkillInspectorLearningHintText = UI.CreateText(root:GetFrame(), "RPEDataEditorSkillInspectorLearningHintText", "", {
        width = FIELD_WIDTH,
        height = 30,
        justifyH = "LEFT",
        wordWrap = true,
        textColor = UI.ResolveColor(nil, "text.secondary"),
    })
    root:AddChild(self.SkillInspectorLearningHintText)
end

local function buildSkillInspectorConfigurationPage(self, page)
    local root = UI.CreateLayout(UI.VerticalLayoutGroup, page, "RPEDataEditorSkillInspectorConfigurationRoot", {
        spacing = 6,
        fitChildrenWidth = true,
        fitChildrenHeight = false,
    })
    UI.Utils.AnchorFill(root, page, 0, 0, 0, 0)
    self.SkillInspectorConfigurationRoot = root

    self.SkillInspectorNotesPanel = UI.CreatePanel(root:GetFrame(), "RPEDataEditorSkillInspectorNotesPanel", {
        width = FIELD_WIDTH,
        height = 62,
        contentInset = 6,
        showBorder = true,
    })
    root:AddChild(self.SkillInspectorNotesPanel)

    self.SkillInspectorNotesTitle = UI.CreateText(self.SkillInspectorNotesPanel:GetContentFrame(), "RPEDataEditorSkillInspectorNotesTitle", "Skill Rules", {
        width = FIELD_WIDTH - 12,
        height = 14,
        justifyH = "LEFT",
    })
    self.SkillInspectorNotesTitle:GetFrame():SetPoint("TOPLEFT", self.SkillInspectorNotesPanel:GetContentFrame(), "TOPLEFT", 0, 0)

    self.SkillInspectorNotesText = UI.CreateText(self.SkillInspectorNotesPanel:GetContentFrame(), "RPEDataEditorSkillInspectorNotesText", "", {
        width = FIELD_WIDTH - 12,
        height = 36,
        justifyH = "LEFT",
        wordWrap = true,
        textColor = UI.ResolveColor(nil, "text.secondary"),
    })
    self.SkillInspectorNotesText:GetFrame():SetPoint("TOPLEFT", self.SkillInspectorNotesTitle:GetFrame(), "BOTTOMLEFT", 0, -4)

    self.SkillInspectorRollableGroup = createFieldGroup(root, "RPEDataEditorSkillInspectorRollableGroup", "Rollable", 18)
    self.SkillInspectorRollableCheckbox = UI.Checkbox:New({
        name = "RPEDataEditorSkillInspectorRollableCheckbox",
        width = FIELD_WIDTH,
        height = 18,
        text = "Allow this skill to be rolled later",
        checked = false,
        border = false,
        onValueChanged = function(value)
            if self._refreshingSkillInspector then
                return
            end

            self:CommitSelectedSkill(function(skill)
                skill.rollable = value == true
            end)
        end,
    })
    self.SkillInspectorRollableCheckbox:SetParent(self.SkillInspectorRollableGroup:GetFrame())
    self.SkillInspectorRollableCheckbox:Create()
    self.SkillInspectorRollableGroup:AddChild(self.SkillInspectorRollableCheckbox)

    self.SkillInspectorDerivedStatGroup = createFieldGroup(root, "RPEDataEditorSkillInspectorDerivedStatGroup", "Derived Stat", 18)
    self.SkillInspectorDerivedStatDropdown = UI.CreateDropdown(self.SkillInspectorDerivedStatGroup:GetFrame(), "RPEDataEditorSkillInspectorDerivedStatDropdown", {
        width = FIELD_WIDTH,
        height = 18,
        items = self:BuildSpellInspectorStatsAcrossDatasets(),
        onValueChanged = function(value)
            if self._refreshingSkillInspector then
                return
            end

            self:CommitSelectedSkill(function(skill)
                skill.derivedStatRef = value ~= "" and value or nil
            end)
        end,
    })
    self.SkillInspectorDerivedStatGroup:AddChild(self.SkillInspectorDerivedStatDropdown)

    self.SkillInspectorDerivedMultiplierGroup = createFieldGroup(root, "RPEDataEditorSkillInspectorDerivedMultiplierGroup", "Derived Multiplier")
    self.SkillInspectorDerivedMultiplierInput = UI.CreateTextInput(self.SkillInspectorDerivedMultiplierGroup:GetFrame(), "RPEDataEditorSkillInspectorDerivedMultiplierInput", {
        width = FIELD_WIDTH,
        height = CONTROL_HEIGHT,
        text = "1",
        borderColor = UI.ResolveColor(nil, "panel.border"),
    })
    self.SkillInspectorDerivedMultiplierInput:SetScript("OnEnterPressed", function()
        self:CommitSelectedSkill(function(skill)
            skill.derivedMultiplier = tonumber(self.SkillInspectorDerivedMultiplierInput:GetText()) or 0
        end)
    end)
    self.SkillInspectorDerivedMultiplierInput:SetScript("OnEditFocusLost", function()
        self:CommitSelectedSkill(function(skill)
            skill.derivedMultiplier = tonumber(self.SkillInspectorDerivedMultiplierInput:GetText()) or 0
        end)
    end)
    self.SkillInspectorDerivedMultiplierGroup:AddChild(self.SkillInspectorDerivedMultiplierInput)
end

function DataEditor:BuildSkillInspectorPage(parent)
    if self.SkillInspectorPage then
        self:RefreshSkillInspectorPage()
        return self.SkillInspectorPage
    end

    self.SkillInspectorPage = CreateFrame("Frame", "RPEDataEditorSkillInspectorPage", parent)

    self.SkillInspectorSelectorBar = UI.CreateLayout(UI.HorizontalLayoutGroup, self.SkillInspectorPage, "RPEDataEditorSkillInspectorSelectorBar", {
        spacing = 4,
        fitChildrenWidth = true,
        fitChildrenHeight = false,
        height = 20,
    })
    self.SkillInspectorSelectorBar:GetFrame():SetPoint("TOPLEFT", self.SkillInspectorPage, "TOPLEFT", 0, 0)
    self.SkillInspectorSelectorBar:GetFrame():SetPoint("TOPRIGHT", self.SkillInspectorPage, "TOPRIGHT", 0, 0)

    self.SkillInspectorPreviousButton = UI.CreateButton(self.SkillInspectorSelectorBar:GetFrame(), "RPEDataEditorSkillInspectorPreviousButton", "Prev", 40, function()
        self:SetSkillInspectorTab((self:GetSkillInspectorPageDefinitions()[(self.ActiveSkillInspectorPageIndex or 1) - 1] or {}).key or "general")
    end, {
        height = 20,
        fontSize = 7,
    })
    self.SkillInspectorSelectorBar:AddChild(self.SkillInspectorPreviousButton)

    self.SkillInspectorPageDropdown = UI.CreateDropdown(self.SkillInspectorSelectorBar:GetFrame(), "RPEDataEditorSkillInspectorPageDropdown", {
        width = 118,
        height = 18,
        expandWidth = true,
        weight = 1,
        items = self:BuildSkillInspectorPageSelectorItems(),
        onValueChanged = function(value)
            if self._refreshingSkillInspectorPageSelector then
                return
            end

            self:SetSkillInspectorTab(value)
        end,
    })
    self.SkillInspectorSelectorBar:AddChild(self.SkillInspectorPageDropdown)

    self.SkillInspectorNextButton = UI.CreateButton(self.SkillInspectorSelectorBar:GetFrame(), "RPEDataEditorSkillInspectorNextButton", "Next", 40, function()
        self:SetSkillInspectorTab((self:GetSkillInspectorPageDefinitions()[(self.ActiveSkillInspectorPageIndex or 1) + 1] or {}).key or "configuration")
    end, {
        height = 20,
        fontSize = 7,
    })
    self.SkillInspectorSelectorBar:AddChild(self.SkillInspectorNextButton)

    self.SkillInspectorGeneralPage = createSkillInspectorPageFrame(self, "RPEDataEditorSkillInspectorGeneralPage")
    buildSkillInspectorGeneralPage(self, self.SkillInspectorGeneralPage)

    self.SkillInspectorLearningPage = createSkillInspectorPageFrame(self, "RPEDataEditorSkillInspectorLearningPage")
    buildSkillInspectorLearningPage(self, self.SkillInspectorLearningPage)

    self.SkillInspectorConfigurationPage = createSkillInspectorPageFrame(self, "RPEDataEditorSkillInspectorConfigurationPage")
    buildSkillInspectorConfigurationPage(self, self.SkillInspectorConfigurationPage)

    self.SkillInspectorEmptyText = UI.CreateText(self.SkillInspectorPage, "RPEDataEditorSkillInspectorEmptyText", "", {
        width = FIELD_WIDTH,
        height = 20,
        justifyH = "LEFT",
        textColor = UI.ResolveColor(nil, "text.secondary"),
    })
    self.SkillInspectorEmptyText:GetFrame():SetPoint("BOTTOMLEFT", self.SkillInspectorPage, "BOTTOMLEFT", 0, 0)

    self.ActiveSkillInspectorPageIndex = self.ActiveSkillInspectorPageIndex or self:GetSkillInspectorPageIndexByKey(self.ActiveSkillInspectorTabKey or "general")
    self:SetSkillInspectorTab("general")
    self:RefreshSkillInspectorPage()
    return self.SkillInspectorPage
end

function DataEditor:RefreshSkillInspectorPage()
    local _, skill = self:GetSelectedSkillAndDataset()
    local hasSkill = skill ~= nil
    local skillType = hasSkill and ensureString(skill.skillType) or "noncombat"
    local learnMode = hasSkill and ensureString(skill.learnMode) or "always_available"
    local hasDerivedStat = ensureString(hasSkill and skill.derivedStatRef or "") ~= ""
    local isWeapon = skillType == "weapon"
    local isNonCombat = skillType == "noncombat"

    self._refreshingSkillInspector = true

    if self.SkillInspectorNameInput then
        self.SkillInspectorNameInput:SetText(hasSkill and ensureString(skill.name) or "")
        setTextElementEnabled(self.SkillInspectorNameInput, hasSkill)
    end
    if self.SkillInspectorIdText then
        self.SkillInspectorIdText:SetText(("ID: %s"):format(hasSkill and ensureString(skill.id) or "-"))
    end
    if self.SkillInspectorIconInput then
        self.SkillInspectorIconInput:SetText(hasSkill and ensureString(skill.icon) or "")
        setTextElementEnabled(self.SkillInspectorIconInput, hasSkill)
    end
    if self.SkillInspectorDescriptionInput then
        self.SkillInspectorDescriptionInput:SetText(hasSkill and ensureString(skill.description) or "")
        setTextElementEnabled(self.SkillInspectorDescriptionInput, hasSkill)
    end
    if self.SkillInspectorTypeDropdown then
        self.SkillInspectorTypeDropdown:SetSelectedValue(skillType, true)
        setDropdownEnabled(self.SkillInspectorTypeDropdown, hasSkill)
    end
    if self.SkillInspectorTypeSummaryText then
        self.SkillInspectorTypeSummaryText:SetText(getSkillTypeSummary(skillType))
    end
    if self.SkillInspectorWeaponTypeDropdown then
        self.SkillInspectorWeaponTypeDropdown:SetItems(buildWeaponTypeItems(self))
        self.SkillInspectorWeaponTypeDropdown:SetSelectedValue(hasSkill and ensureString(skill.weaponTypeRef) or "", true)
        setDropdownEnabled(self.SkillInspectorWeaponTypeDropdown, hasSkill and isWeapon)
    end

    if self.SkillInspectorLearnModeDropdown then
        self.SkillInspectorLearnModeDropdown:SetSelectedValue(learnMode ~= "" and learnMode or "always_available", true)
        setDropdownEnabled(self.SkillInspectorLearnModeDropdown, hasSkill)
    end
    if self.SkillInspectorLearningHintText then
        self.SkillInspectorLearningHintText:SetText("Always Available skills are exposed by default. Trainer and Book are authored acquisition sources. Unavailable marks a disabled learning path.")
    end

    if self.SkillInspectorNotesText then
        self.SkillInspectorNotesText:SetText(getSkillRulesText(skillType, hasDerivedStat))
    end
    if self.SkillInspectorRollableCheckbox then
        self.SkillInspectorRollableCheckbox:SetChecked(hasSkill and skill.rollable == true or false, true)
        setCheckboxEnabled(self.SkillInspectorRollableCheckbox, hasSkill and isNonCombat)
    end
    if self.SkillInspectorDerivedStatDropdown then
        self.SkillInspectorDerivedStatDropdown:SetItems(self:BuildSpellInspectorStatsAcrossDatasets())
        self.SkillInspectorDerivedStatDropdown:SetSelectedValue(hasSkill and ensureString(skill.derivedStatRef) or "", true)
        setDropdownEnabled(self.SkillInspectorDerivedStatDropdown, hasSkill and isNonCombat)
    end
    if self.SkillInspectorDerivedMultiplierInput then
        self.SkillInspectorDerivedMultiplierInput:SetText(tostring(hasSkill and (tonumber(skill.derivedMultiplier) or 1) or 1))
        setTextElementEnabled(self.SkillInspectorDerivedMultiplierInput, hasSkill and isNonCombat)
    end

    setGroupVisible(self.SkillInspectorWeaponTypeGroup, hasSkill and isWeapon)
    setGroupVisible(self.SkillInspectorRollableGroup, hasSkill and isNonCombat)
    setGroupVisible(self.SkillInspectorDerivedStatGroup, hasSkill and isNonCombat)
    setGroupVisible(self.SkillInspectorDerivedMultiplierGroup, hasSkill and isNonCombat)

    if self.SkillInspectorConfigurationRoot and self.SkillInspectorConfigurationRoot.RefreshLayout then
        self.SkillInspectorConfigurationRoot:RefreshLayout()
    end
    if self.SkillInspectorGeneralRoot and self.SkillInspectorGeneralRoot.RefreshLayout then
        self.SkillInspectorGeneralRoot:RefreshLayout()
    end
    if self.SkillInspectorLearningRoot and self.SkillInspectorLearningRoot.RefreshLayout then
        self.SkillInspectorLearningRoot:RefreshLayout()
    end

    self._refreshingSkillInspector = false
    self:RefreshSkillInspectorPageSelector()

    if self.SkillInspectorEmptyText then
        self.SkillInspectorEmptyText:SetText(hasSkill and "Edit the selected skill here." or "Select a skill to inspect it.")
    end
end
