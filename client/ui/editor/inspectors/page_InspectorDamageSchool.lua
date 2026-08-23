local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Client.UI = Addon.Client.UI or {}
Addon.Client.UI.Editor = Addon.Client.UI.Editor or {}

local DataEditor = Addon.Client.UI.Editor
local UI = Addon.UI or {}
local Client = Addon.Client or {}
local INSPECTOR_SIDE_PADDING = 8
local CONTROL_HEIGHT = 20

local function getDependenciesApi()
    local database = Addon.Internal and Addon.Internal.Database or nil
    return database and database.Dependecies or {}
end

local function commitSelectedDamageSchool(self, mutate)
    local damageSchool = self:GetSelectedDamageSchool()
    local dataset = self:GetSelectedDataset()
    if not dataset or not damageSchool or type(mutate) ~= "function" then
        return
    end

    local before = self:DeepCopyValue(damageSchool)
    mutate(damageSchool, dataset)
    if self:DeepEqualValues(before, damageSchool) then
        return
    end
    self:QueuePendingDatasetEntryChanged(dataset.id, "damageSchools")
end

local function normalizeDamageSchoolColor(color)
    local colorPicker = UI.ColorPicker or {}
    if colorPicker.NormalizeColor then
        return colorPicker.NormalizeColor(color, {
            r = 1,
            g = 1,
            b = 1,
            a = 1,
        })
    end

    return {
        r = math.max(0, math.min(1, tonumber(color and color.r) or 1)),
        g = math.max(0, math.min(1, tonumber(color and color.g) or 1)),
        b = math.max(0, math.min(1, tonumber(color and color.b) or 1)),
        a = math.max(0, math.min(1, tonumber(color and color.a) or 1)),
    }
end

local function commitSelectedDamageSchoolColor(self, color)
    commitSelectedDamageSchool(self, function(damageSchool)
        damageSchool.color = normalizeDamageSchoolColor(color)
    end)
end

local function ensureDamageSchoolColorPicker(self)
    if self.DamageSchoolInspectorColorPicker then
        return self.DamageSchoolInspectorColorPicker
    end

    local picker = UI.ColorPicker:New({
        name = "RPEDataEditorDamageSchoolInspectorColorPicker",
        width = 280,
        height = 228,
        hidden = true,
        title = "Damage School Color",
        paletteSettingKey = "damageSchoolColorPalette",
    })
    picker:SetParent(UIParent)
    picker:Create()
    self.DamageSchoolInspectorColorPicker = picker
    return self.DamageSchoolInspectorColorPicker
end

local function openDamageSchoolColorPicker(self)
    local damageSchool = self:GetSelectedDamageSchool()
    if not damageSchool then
        return
    end

    local picker = ensureDamageSchoolColorPicker(self)
    picker:Open({
        color = normalizeDamageSchoolColor(damageSchool.color),
        onApply = function(color)
            commitSelectedDamageSchoolColor(self, color)
        end,
    })
end

function DataEditor:BuildDamageSchoolStatItems(sourceDatasetId)
    local items = { { label = "None", value = "" } }
    if not sourceDatasetId or sourceDatasetId == "" or not self.Database or not self.Database.GetDatasetByID then
        return items
    end
    local dataset = self.Database.GetDatasetByID(sourceDatasetId)
    local stats = dataset and dataset.stats or {}
    for index = 1, #stats do
        local stat = stats[index]
        if stat and stat.id then
            items[#items + 1] = { label = self:GetEntryDisplayName("stats", stat), value = stat.id }
        end
    end
    return items
end

function DataEditor:SetDamageSchoolInspectorTab(tabKey)
    self.ActiveDamageSchoolInspectorTabKey = tabKey or "general"

    local pages = {
        general = self.DamageSchoolInspectorGeneralPage,
        mitigation = self.DamageSchoolInspectorMitigationPage,
    }

    for key, page in pairs(pages) do
        if page then
            if key == self.ActiveDamageSchoolInspectorTabKey then
                page:Show()
            else
                page:Hide()
            end
        end
    end

    local activeColor = UI.ResolveColor(nil, "tab.active")
    local inactiveColor = UI.ResolveColor(nil, "tab.inactive")
    local tabButtons = {
        general = self.DamageSchoolInspectorGeneralTabButton,
        mitigation = self.DamageSchoolInspectorMitigationTabButton,
    }

    for key, button in pairs(tabButtons) do
        if button and button.SetLabelColor then
            local color = key == self.ActiveDamageSchoolInspectorTabKey and activeColor or inactiveColor
            button:SetLabelColor(color.r or 1, color.g or 1, color.b or 1, color.a or 1)
        end
    end
end

function DataEditor:BuildDamageSchoolInspectorPage(parent)
    if self.DamageSchoolInspectorPage then
        return self.DamageSchoolInspectorPage
    end

    self.DamageSchoolInspectorPage = CreateFrame("Frame", "RPEDataEditorDamageSchoolInspectorPage", parent)
    self.DamageSchoolInspectorTabBar = UI.CreateLayout(UI.HorizontalLayoutGroup, self.DamageSchoolInspectorPage, "RPEDataEditorDamageSchoolInspectorTabBar", {
        spacing = 2,
        autoSize = true,
        fitChildrenWidth = false,
        fitChildrenHeight = false,
    })
    self.DamageSchoolInspectorTabBar:GetFrame():SetPoint("TOPLEFT", self.DamageSchoolInspectorPage, "TOPLEFT", 0, 0)

    self.DamageSchoolInspectorGeneralTabButton = UI.CreateButton(self.DamageSchoolInspectorTabBar:GetFrame(), "RPEDataEditorDamageSchoolInspectorGeneralTabButton", "General", 64, function()
        self:SetDamageSchoolInspectorTab("general")
    end, {
        height = 18,
        fontSize = 8,
    })
    self.DamageSchoolInspectorTabBar:AddChild(self.DamageSchoolInspectorGeneralTabButton)

    self.DamageSchoolInspectorMitigationTabButton = UI.CreateButton(self.DamageSchoolInspectorTabBar:GetFrame(), "RPEDataEditorDamageSchoolInspectorMitigationTabButton", "Mitigation", 72, function()
        self:SetDamageSchoolInspectorTab("mitigation")
    end, {
        height = 18,
        fontSize = 8,
    })
    self.DamageSchoolInspectorTabBar:AddChild(self.DamageSchoolInspectorMitigationTabButton)

    self.DamageSchoolInspectorGeneralPage = CreateFrame("Frame", "RPEDataEditorDamageSchoolInspectorGeneralPage", self.DamageSchoolInspectorPage)
    self.DamageSchoolInspectorGeneralPage:SetPoint("TOPLEFT", self.DamageSchoolInspectorPage, "TOPLEFT", INSPECTOR_SIDE_PADDING, -24)
    self.DamageSchoolInspectorGeneralPage:SetPoint("TOPRIGHT", self.DamageSchoolInspectorPage, "TOPRIGHT", -INSPECTOR_SIDE_PADDING, -24)
    self.DamageSchoolInspectorGeneralPage:SetPoint("BOTTOMLEFT", self.DamageSchoolInspectorPage, "BOTTOMLEFT", INSPECTOR_SIDE_PADDING, 24)
    self.DamageSchoolInspectorGeneralPage:SetPoint("BOTTOMRIGHT", self.DamageSchoolInspectorPage, "BOTTOMRIGHT", -INSPECTOR_SIDE_PADDING, 24)

    self.DamageSchoolInspectorMitigationPage = CreateFrame("Frame", "RPEDataEditorDamageSchoolInspectorMitigationPage", self.DamageSchoolInspectorPage)
    self.DamageSchoolInspectorMitigationPage:SetPoint("TOPLEFT", self.DamageSchoolInspectorPage, "TOPLEFT", INSPECTOR_SIDE_PADDING, -24)
    self.DamageSchoolInspectorMitigationPage:SetPoint("TOPRIGHT", self.DamageSchoolInspectorPage, "TOPRIGHT", -INSPECTOR_SIDE_PADDING, -24)
    self.DamageSchoolInspectorMitigationPage:SetPoint("BOTTOMLEFT", self.DamageSchoolInspectorPage, "BOTTOMLEFT", INSPECTOR_SIDE_PADDING, 24)
    self.DamageSchoolInspectorMitigationPage:SetPoint("BOTTOMRIGHT", self.DamageSchoolInspectorPage, "BOTTOMRIGHT", -INSPECTOR_SIDE_PADDING, 24)

    local function buildPageLayout(frame, name)
        local layout = UI.CreateLayout(UI.VerticalLayoutGroup, frame, name, {
            spacing = 6,
            fitChildrenWidth = true,
            fitChildrenHeight = false,
        })
        UI.Utils.AnchorFill(layout, frame, 0, 0, 0, 0)
        return layout
    end

    local generalRoot = buildPageLayout(self.DamageSchoolInspectorGeneralPage, "RPEDataEditorDamageSchoolInspectorGeneralLayout")
    local mitigationRoot = buildPageLayout(self.DamageSchoolInspectorMitigationPage, "RPEDataEditorDamageSchoolInspectorMitigationLayout")

    local function addLabel(root, name, text)
        local label = UI.CreateText(root:GetFrame(), name, text, {
            width = 236, height = 12, justifyH = "LEFT", textColor = UI.ResolveColor(nil, "text.secondary"),
        })
        root:AddChild(label)
        label._preferredHeight = 12
        return label
    end

    addLabel(generalRoot, "RPEDataEditorDamageSchoolInspectorNameLabel", "Name")
    self.DamageSchoolInspectorNameInput = UI.CreateTextInput(generalRoot:GetFrame(), "RPEDataEditorDamageSchoolInspectorNameInput", {
        width = 236, height = CONTROL_HEIGHT, text = "", borderColor = UI.ResolveColor(nil, "panel.border"),
    })
    self.DamageSchoolInspectorNameInput:SetScript("OnEnterPressed", function()
        commitSelectedDamageSchool(self, function(damageSchool) damageSchool.name = self.DamageSchoolInspectorNameInput:GetText() end)
    end)
    self.DamageSchoolInspectorNameInput:SetScript("OnEditFocusLost", function()
        commitSelectedDamageSchool(self, function(damageSchool) damageSchool.name = self.DamageSchoolInspectorNameInput:GetText() end)
    end)
    generalRoot:AddChild(self.DamageSchoolInspectorNameInput)

    self.DamageSchoolInspectorIdText = UI.CreateText(generalRoot:GetFrame(), "RPEDataEditorDamageSchoolInspectorIdText", "ID: -", {
        width = 236, height = 12, justifyH = "LEFT", textColor = UI.ResolveColor(nil, "text.secondary"),
    })
    generalRoot:AddChild(self.DamageSchoolInspectorIdText)

    addLabel(generalRoot, "RPEDataEditorDamageSchoolInspectorIconLabel", "Icon")
    self.DamageSchoolInspectorIconField = UI.EditorIconField:New({
        name = "RPEDataEditorDamageSchoolInspectorIconField", width = 236, height = CONTROL_HEIGHT, buttonText = "Select Icon", labelText = "-", iconTexture = "Interface\\Icons\\INV_Misc_QuestionMark", border = false,
    })
    self.DamageSchoolInspectorIconField:SetParent(generalRoot:GetFrame())
    self.DamageSchoolInspectorIconField:Create()
    local iconButton = self.DamageSchoolInspectorIconField:GetButton()
    if iconButton and iconButton.SetScript then
        iconButton:SetScript("OnClick", function()
            local damageSchool = self:GetSelectedDamageSchool()
            if not damageSchool or not Client.OpenIconFinder then
                return
            end
            Client:OpenIconFinder(function(_, filePath)
                commitSelectedDamageSchool(self, function(selectedDamageSchool)
                    selectedDamageSchool.icon = filePath or ""
                end)
            end, { filter = damageSchool.icon or "" })
        end)
    end
    generalRoot:AddChild(self.DamageSchoolInspectorIconField)

    self.DamageSchoolInspectorIconInput = {
        SetText = function(_, value)
            local iconPath = value ~= nil and tostring(value) or ""
            self.DamageSchoolInspectorIconField:SetIcon(iconPath ~= "" and iconPath or "Interface\\Icons\\INV_Misc_QuestionMark")
            self.DamageSchoolInspectorIconField:SetLabelText(iconPath ~= "" and iconPath or "-")
        end,
        SetEnabled = function(_, enabled) self.DamageSchoolInspectorIconField:SetEnabled(enabled) end,
        SetReadOnly = function(_, readOnly) self.DamageSchoolInspectorIconField:SetEnabled(readOnly ~= true) end,
    }

    addLabel(generalRoot, "RPEDataEditorDamageSchoolInspectorTagsLabel", "Tags")
    self.DamageSchoolInspectorTagsInput = UI.CreateTextInput(generalRoot:GetFrame(), "RPEDataEditorDamageSchoolInspectorTagsInput", {
        width = 236, height = CONTROL_HEIGHT, text = "", borderColor = UI.ResolveColor(nil, "panel.border"),
    })
    self.DamageSchoolInspectorTagsInput:SetScript("OnEnterPressed", function()
        commitSelectedDamageSchool(self, function(damageSchool) damageSchool.tags = UI.Utils.ParseCommaSeparatedList(self.DamageSchoolInspectorTagsInput:GetText()) end)
    end)
    self.DamageSchoolInspectorTagsInput:SetScript("OnEditFocusLost", function()
        commitSelectedDamageSchool(self, function(damageSchool) damageSchool.tags = UI.Utils.ParseCommaSeparatedList(self.DamageSchoolInspectorTagsInput:GetText()) end)
    end)
    generalRoot:AddChild(self.DamageSchoolInspectorTagsInput)

    addLabel(generalRoot, "RPEDataEditorDamageSchoolInspectorDescriptionLabel", "Description")
    self.DamageSchoolInspectorDescriptionInput = UI.CreateTextArea(generalRoot:GetFrame(), "RPEDataEditorDamageSchoolInspectorDescriptionInput", {
        width = 236, height = 64, text = "", readOnly = false, borderColor = UI.ResolveColor(nil, "panel.border"),
    })
    self.DamageSchoolInspectorDescriptionInput:SetScript("OnEditFocusLost", function()
        commitSelectedDamageSchool(self, function(damageSchool) damageSchool.description = self.DamageSchoolInspectorDescriptionInput:GetText() end)
    end)
    generalRoot:AddChild(self.DamageSchoolInspectorDescriptionInput)

    addLabel(generalRoot, "RPEDataEditorDamageSchoolInspectorColorLabel", "Color")
    self.DamageSchoolInspectorSelectedColor = UI.SelectedColor:New({
        name = "RPEDataEditorDamageSchoolInspectorSelectedColor",
        width = 236,
        height = CONTROL_HEIGHT,
        buttonWidth = 96,
        buttonText = "Select Color",
        border = false,
    })
    self.DamageSchoolInspectorSelectedColor:SetParent(generalRoot:GetFrame())
    self.DamageSchoolInspectorSelectedColor:Create()
    local colorButton = self.DamageSchoolInspectorSelectedColor:GetButton()
    if colorButton and colorButton.SetScript then
        colorButton:SetScript("OnClick", function()
            openDamageSchoolColorPicker(self)
        end)
    end
    generalRoot:AddChild(self.DamageSchoolInspectorSelectedColor)

    self.DamageSchoolInspectorMitigationLayout = mitigationRoot
    self.DamageSchoolInspectorMitigationDatasetLabel = addLabel(mitigationRoot, "RPEDataEditorDamageSchoolInspectorMitigationDatasetLabel", "Mitigation Stat Dataset")
    self.DamageSchoolInspectorMitigationDatasetDropdown = UI.CreateDropdown(mitigationRoot:GetFrame(), "RPEDataEditorDamageSchoolInspectorMitigationDatasetDropdown", {
        width = 236, height = 18, items = { { label = "None", value = "" } },
        onValueChanged = function(value)
            if self._refreshingDamageSchoolInspector then return end
            if self.DamageSchoolInspectorMitigationStatDropdown then
                self.DamageSchoolInspectorMitigationStatDropdown:SetItems(self:BuildDamageSchoolStatItems(value))
                self.DamageSchoolInspectorMitigationStatDropdown:SetSelectedValue("", true)
            end
        end,
    })
    mitigationRoot:AddChild(self.DamageSchoolInspectorMitigationDatasetDropdown)
    self.DamageSchoolInspectorMitigationDatasetDropdown._preferredHeight = 18

    self.DamageSchoolInspectorMitigationModeLabel = addLabel(mitigationRoot, "RPEDataEditorDamageSchoolInspectorMitigationModeLabel", "Mitigation Mode")
    self.DamageSchoolInspectorMitigationModeDropdown = UI.CreateDropdown(mitigationRoot:GetFrame(), "RPEDataEditorDamageSchoolInspectorMitigationModeDropdown", {
        width = 236,
        height = 18,
        items = {
            { label = "Direct", value = "direct" },
            { label = "Percent", value = "percent" },
        },
        onValueChanged = function(value)
            if self._refreshingDamageSchoolInspector then
                return
            end

            commitSelectedDamageSchool(self, function(damageSchool)
                damageSchool.mitigationMode = value == "percent" and "percent" or "direct"
            end)
        end,
    })
    mitigationRoot:AddChild(self.DamageSchoolInspectorMitigationModeDropdown)
    self.DamageSchoolInspectorMitigationModeDropdown._preferredHeight = 18

    self.DamageSchoolInspectorMitigationStatLabel = addLabel(mitigationRoot, "RPEDataEditorDamageSchoolInspectorMitigationStatLabel", "Mitigation Stat")
    self.DamageSchoolInspectorMitigationStatDropdown = UI.CreateDropdown(mitigationRoot:GetFrame(), "RPEDataEditorDamageSchoolInspectorMitigationStatDropdown", {
        width = 236, height = 18, items = { { label = "None", value = "" } },
        onValueChanged = function(value)
            if self._refreshingDamageSchoolInspector then return end
            local datasetId = self.DamageSchoolInspectorMitigationDatasetDropdown and self.DamageSchoolInspectorMitigationDatasetDropdown:GetSelectedValue() or ""
            local dependencies = getDependenciesApi()
            commitSelectedDamageSchool(self, function(damageSchool)
                damageSchool.mitigationStatRef = dependencies.ComposeSourceStatRef and dependencies.ComposeSourceStatRef(datasetId, value) or nil
            end)
        end,
    })
    mitigationRoot:AddChild(self.DamageSchoolInspectorMitigationStatDropdown)
    self.DamageSchoolInspectorMitigationStatDropdown._preferredHeight = 18

    self.DamageSchoolInspectorMitigationCoefficientLabel = addLabel(mitigationRoot, "RPEDataEditorDamageSchoolInspectorCoefficientLabel", "Mitigation Coefficient")
    self.DamageSchoolInspectorMitigationCoefficientInput = UI.CreateTextInput(mitigationRoot:GetFrame(), "RPEDataEditorDamageSchoolInspectorMitigationCoefficientInput", {
        width = 236, height = CONTROL_HEIGHT, text = "1", borderColor = UI.ResolveColor(nil, "panel.border"),
    })
    self.DamageSchoolInspectorMitigationCoefficientInput:SetScript("OnEnterPressed", function()
        commitSelectedDamageSchool(self, function(damageSchool)
            damageSchool.mitigationCoefficient = tonumber(self.DamageSchoolInspectorMitigationCoefficientInput:GetText()) or 1
        end)
    end)
    self.DamageSchoolInspectorMitigationCoefficientInput:SetScript("OnEditFocusLost", function()
        commitSelectedDamageSchool(self, function(damageSchool)
            damageSchool.mitigationCoefficient = tonumber(self.DamageSchoolInspectorMitigationCoefficientInput:GetText()) or 1
        end)
    end)
    mitigationRoot:AddChild(self.DamageSchoolInspectorMitigationCoefficientInput)
    self.DamageSchoolInspectorMitigationCoefficientInput._preferredHeight = CONTROL_HEIGHT

    self.DamageSchoolInspectorMitigationReferenceAmountLabel = addLabel(mitigationRoot, "RPEDataEditorDamageSchoolInspectorReferenceAmountLabel", "Mitigation Amount")
    self.DamageSchoolInspectorMitigationReferenceAmountInput = UI.CreateTextInput(mitigationRoot:GetFrame(), "RPEDataEditorDamageSchoolInspectorReferenceAmountInput", {
        width = 236, height = CONTROL_HEIGHT, text = "0", borderColor = UI.ResolveColor(nil, "panel.border"),
    })
    self.DamageSchoolInspectorMitigationReferenceAmountInput:SetScript("OnEnterPressed", function()
        commitSelectedDamageSchool(self, function(damageSchool)
            damageSchool.mitigationReferenceAmount = tonumber(self.DamageSchoolInspectorMitigationReferenceAmountInput:GetText()) or 0
        end)
    end)
    self.DamageSchoolInspectorMitigationReferenceAmountInput:SetScript("OnEditFocusLost", function()
        commitSelectedDamageSchool(self, function(damageSchool)
            damageSchool.mitigationReferenceAmount = tonumber(self.DamageSchoolInspectorMitigationReferenceAmountInput:GetText()) or 0
        end)
    end)
    mitigationRoot:AddChild(self.DamageSchoolInspectorMitigationReferenceAmountInput)
    self.DamageSchoolInspectorMitigationReferenceAmountInput._preferredHeight = CONTROL_HEIGHT

    self.DamageSchoolInspectorMitigationReferencePercentLabel = addLabel(mitigationRoot, "RPEDataEditorDamageSchoolInspectorReferencePercentLabel", "Mitigation Percent")
    self.DamageSchoolInspectorMitigationReferencePercentInput = UI.CreateTextInput(mitigationRoot:GetFrame(), "RPEDataEditorDamageSchoolInspectorReferencePercentInput", {
        width = 236, height = CONTROL_HEIGHT, text = "0", borderColor = UI.ResolveColor(nil, "panel.border"),
    })
    self.DamageSchoolInspectorMitigationReferencePercentInput:SetScript("OnEnterPressed", function()
        commitSelectedDamageSchool(self, function(damageSchool)
            damageSchool.mitigationReferencePercent = tonumber(self.DamageSchoolInspectorMitigationReferencePercentInput:GetText()) or 0
        end)
    end)
    self.DamageSchoolInspectorMitigationReferencePercentInput:SetScript("OnEditFocusLost", function()
        commitSelectedDamageSchool(self, function(damageSchool)
            damageSchool.mitigationReferencePercent = tonumber(self.DamageSchoolInspectorMitigationReferencePercentInput:GetText()) or 0
        end)
    end)
    mitigationRoot:AddChild(self.DamageSchoolInspectorMitigationReferencePercentInput)
    self.DamageSchoolInspectorMitigationReferencePercentInput._preferredHeight = CONTROL_HEIGHT

    self.DamageSchoolInspectorEmptyText = UI.CreateText(self.DamageSchoolInspectorPage, "RPEDataEditorDamageSchoolInspectorEmptyText", "", {
        width = 236, height = 20, justifyH = "LEFT", textColor = UI.ResolveColor(nil, "text.secondary"),
    })
    self.DamageSchoolInspectorEmptyText:GetFrame():SetPoint("BOTTOMLEFT", self.DamageSchoolInspectorPage, "BOTTOMLEFT", 0, 0)

    self:SetDamageSchoolInspectorTab("general")
    self:RefreshDamageSchoolInspectorPage()
    return self.DamageSchoolInspectorPage
end

function DataEditor:RefreshDamageSchoolInspectorPage()
    local damageSchool = self:GetSelectedDamageSchool()
    local hasDamageSchool = damageSchool ~= nil
    local dependencies = getDependenciesApi()
    local mitigationDatasetId, mitigationStatId = nil, nil
    local mitigationMode = damageSchool and tostring(damageSchool.mitigationMode or "direct") or "direct"
    if damageSchool and dependencies.ParseSourceStatRef and damageSchool.mitigationStatRef then
        mitigationDatasetId, mitigationStatId = dependencies.ParseSourceStatRef(damageSchool.mitigationStatRef)
    end

    self._refreshingDamageSchoolInspector = true
    if self.DamageSchoolInspectorNameInput then
        self.DamageSchoolInspectorNameInput:SetText(damageSchool and (damageSchool.name or "") or "")
        self.DamageSchoolInspectorNameInput:SetEnabled(hasDamageSchool)
        self.DamageSchoolInspectorNameInput:SetReadOnly(not hasDamageSchool)
    end
    if self.DamageSchoolInspectorIdText then
        self.DamageSchoolInspectorIdText:SetText(("ID: %s"):format(damageSchool and tostring(damageSchool.id or "") or "-"))
    end
    if self.DamageSchoolInspectorIconInput then
        self.DamageSchoolInspectorIconInput:SetText(damageSchool and (damageSchool.icon or "") or "")
        self.DamageSchoolInspectorIconInput:SetEnabled(hasDamageSchool)
    end
    if self.DamageSchoolInspectorMitigationDatasetDropdown then
        self.DamageSchoolInspectorMitigationDatasetDropdown:SetItems(self:BuildItemInspectorDatasetItems())
        self.DamageSchoolInspectorMitigationDatasetDropdown:SetSelectedValue(mitigationDatasetId or "", true)
        local frame = self.DamageSchoolInspectorMitigationDatasetDropdown:GetFrame()
        if frame then frame:EnableMouse(hasDamageSchool) frame:SetAlpha(hasDamageSchool and 1 or 0.5) end
    end
    if self.DamageSchoolInspectorMitigationModeDropdown then
        self.DamageSchoolInspectorMitigationModeDropdown:SetSelectedValue(mitigationMode, true)
        local frame = self.DamageSchoolInspectorMitigationModeDropdown:GetFrame()
        if frame then frame:EnableMouse(hasDamageSchool) frame:SetAlpha(hasDamageSchool and 1 or 0.5) end
    end
    if self.DamageSchoolInspectorMitigationStatDropdown then
        self.DamageSchoolInspectorMitigationStatDropdown:SetItems(self:BuildDamageSchoolStatItems(mitigationDatasetId or ""))
        self.DamageSchoolInspectorMitigationStatDropdown:SetSelectedValue(mitigationStatId or "", true)
        local frame = self.DamageSchoolInspectorMitigationStatDropdown:GetFrame()
        if frame then frame:EnableMouse(hasDamageSchool) frame:SetAlpha(hasDamageSchool and 1 or 0.5) end
    end
    if self.DamageSchoolInspectorMitigationCoefficientInput then
        self.DamageSchoolInspectorMitigationCoefficientInput:SetText(tostring(damageSchool and damageSchool.mitigationCoefficient or 1))
        self.DamageSchoolInspectorMitigationCoefficientInput:SetEnabled(hasDamageSchool)
        self.DamageSchoolInspectorMitigationCoefficientInput:SetReadOnly(not hasDamageSchool)
    end
    if self.DamageSchoolInspectorMitigationReferenceAmountInput then
        self.DamageSchoolInspectorMitigationReferenceAmountInput:SetText(tostring(damageSchool and damageSchool.mitigationReferenceAmount or 0))
        self.DamageSchoolInspectorMitigationReferenceAmountInput:SetEnabled(hasDamageSchool)
        self.DamageSchoolInspectorMitigationReferenceAmountInput:SetReadOnly(not hasDamageSchool)
    end
    if self.DamageSchoolInspectorMitigationReferencePercentInput then
        self.DamageSchoolInspectorMitigationReferencePercentInput:SetText(tostring(damageSchool and damageSchool.mitigationReferencePercent or 0))
        self.DamageSchoolInspectorMitigationReferencePercentInput:SetEnabled(hasDamageSchool)
        self.DamageSchoolInspectorMitigationReferencePercentInput:SetReadOnly(not hasDamageSchool)
    end
    if self.DamageSchoolInspectorTagsInput then
        self.DamageSchoolInspectorTagsInput:SetText(UI.Utils.JoinCommaSeparatedList(damageSchool and damageSchool.tags or nil))
        self.DamageSchoolInspectorTagsInput:SetEnabled(hasDamageSchool)
        self.DamageSchoolInspectorTagsInput:SetReadOnly(not hasDamageSchool)
    end
    if self.DamageSchoolInspectorDescriptionInput then
        self.DamageSchoolInspectorDescriptionInput:SetText(damageSchool and (damageSchool.description or "") or "")
        self.DamageSchoolInspectorDescriptionInput:SetEnabled(hasDamageSchool)
        self.DamageSchoolInspectorDescriptionInput:SetReadOnly(not hasDamageSchool)
    end
    if self.DamageSchoolInspectorSelectedColor then
        self.DamageSchoolInspectorSelectedColor:SetColor(normalizeDamageSchoolColor(damageSchool and damageSchool.color or nil))
        self.DamageSchoolInspectorSelectedColor:SetEnabled(hasDamageSchool)
    end
    self._refreshingDamageSchoolInspector = false

    if self.DamageSchoolInspectorEmptyText then
        self.DamageSchoolInspectorEmptyText:SetText(hasDamageSchool and "Adjust the selected damage school here." or "Select a damage school to inspect it.")
    end

    if hasDamageSchool and self.ActiveDamageSchoolInspectorTabKey == nil then
        self:SetDamageSchoolInspectorTab("general")
    end
end
