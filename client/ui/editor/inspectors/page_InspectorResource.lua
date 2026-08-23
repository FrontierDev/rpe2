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

local function getSelectedResourceAndDataset(self)
    return self:GetSelectedDataset(), self:GetSelectedResource()
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

local function buildLabel(parent, name, text, width)
    return UI.CreateText(parent, name, text, {
        fontFile = (UI.Constants and UI.Constants.FontFiles and UI.Constants.FontFiles.Default) or "Fonts\\FRIZQT__.TTF",
        fontSize = (UI.Constants and UI.Constants.FontSizes and UI.Constants.FontSizes.Body) or 8,
        textColor = UI.ResolveColor(nil, "text.secondary"),
        width = width or 236,
        height = 12,
        justifyH = "LEFT",
    })
end

local function buildDatasetItems(self)
    local items = {
        { label = "None", value = "" },
    }

    local datasets = self:GetDatasets()
    for index = 1, #datasets do
        local dataset = datasets[index]
        items[#items + 1] = {
            label = self:GetDatasetDisplayName(dataset),
            value = dataset.id,
        }
    end

    return items
end

local function buildStatItems(self, sourceDatasetId, currentDatasetId, currentResourceId)
    local items = {
        { label = "None", value = "" },
    }

    if not sourceDatasetId or sourceDatasetId == "" or not self.Database or not self.Database.GetDatasetByID then
        return items
    end

    local dataset = self.Database.GetDatasetByID(sourceDatasetId)
    local stats = dataset and dataset.stats or {}

    for index = 1, #stats do
        local stat = stats[index]
        if stat and stat.id then
            items[#items + 1] = {
                label = self:GetEntryDisplayName("stats", stat),
                value = stat.id,
            }
        end
    end

    return items
end

local function commitSelectedResource(self, mutate)
    local dataset, resource = getSelectedResourceAndDataset(self)
    if not dataset or not resource or type(mutate) ~= "function" then
        return
    end

    local before = self:DeepCopyValue(resource)
    mutate(resource, dataset)

    if resource.valueMode ~= "derived" then
        resource.sourceStatRef = nil
    end
    if resource.regenMode ~= "derived" then
        resource.regenSourceStatRef = nil
    end

    if self:DeepEqualValues(before, resource) then
        return
    end

    self:QueuePendingDatasetEntryChanged(dataset.id, "resources")
end

local function setInspectorTab(self, tabKey)
    self.ActiveResourceInspectorTabKey = tabKey or "general"

    if self.ResourceInspectorGeneralPage then
        if self.ActiveResourceInspectorTabKey == "general" then
            self.ResourceInspectorGeneralPage:Show()
        else
            self.ResourceInspectorGeneralPage:Hide()
        end
    end

    if self.ResourceInspectorMechanicsPage then
        if self.ActiveResourceInspectorTabKey == "mechanics" then
            self.ResourceInspectorMechanicsPage:Show()
        else
            self.ResourceInspectorMechanicsPage:Hide()
        end
    end

    if self.ResourceInspectorRegenerationPage then
        if self.ActiveResourceInspectorTabKey == "regeneration" then
            self.ResourceInspectorRegenerationPage:Show()
        else
            self.ResourceInspectorRegenerationPage:Hide()
        end
    end

    local activeColor = UI.ResolveColor(nil, "tab.active")
    local inactiveColor = UI.ResolveColor(nil, "tab.inactive")

    local function styleButton(button, isActive)
        if not button then
            return
        end

        if button.SetLabelColor then
            local color = isActive and activeColor or inactiveColor
            button:SetLabelColor(color.r or 1, color.g or 1, color.b or 1, color.a or 1)
        end

        local frame = button.GetFrame and button:GetFrame() or nil
        if frame and frame.SetAlpha then
            frame:SetAlpha(isActive and 1 or 0.8)
        end
    end

    styleButton(self.ResourceInspectorGeneralTabButton, self.ActiveResourceInspectorTabKey == "general")
    styleButton(self.ResourceInspectorMechanicsTabButton, self.ActiveResourceInspectorTabKey == "mechanics")
    styleButton(self.ResourceInspectorRegenerationTabButton, self.ActiveResourceInspectorTabKey == "regeneration")
end

local function resolveSourceSelection(sourceStatRef, dropdowns)
    local dependencies = getDependenciesApi()
    local datasetId, statId = nil, nil
    if dependencies.ParseSourceStatRef and type(sourceStatRef) == "string" and sourceStatRef ~= "" then
        datasetId, statId = dependencies.ParseSourceStatRef(sourceStatRef)
    end

    local datasetDropdown = dropdowns.dataset
    local statDropdown = dropdowns.stat

    if datasetDropdown then
        datasetDropdown:SetItems(buildDatasetItems(dropdowns.owner))
        datasetDropdown:SetSelectedValue(datasetId or "", true)
    end
    if statDropdown then
        statDropdown:SetItems(buildStatItems(dropdowns.owner, datasetId or "", dropdowns.currentDatasetId, dropdowns.currentResourceId))
        statDropdown:SetSelectedValue(statId or "", true)
    end
end

local function createCheckbox(parent, name, text, checked, onValueChanged)
    local checkbox = UI.Checkbox:New({
        name = name,
        width = 236,
        height = 18,
        text = text,
        checked = checked == true,
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

local function normalizeResourceColor(color)
    local colorPicker = UI.ColorPicker or {}
    if colorPicker.NormalizeColor then
        return colorPicker.NormalizeColor(color, {
            r = 0.18,
            g = 0.68,
            b = 0.2,
            a = 1,
        })
    end

    return {
        r = math.max(0, math.min(1, tonumber(color and color.r) or 0.18)),
        g = math.max(0, math.min(1, tonumber(color and color.g) or 0.68)),
        b = math.max(0, math.min(1, tonumber(color and color.b) or 0.2)),
        a = math.max(0, math.min(1, tonumber(color and color.a) or 1)),
    }
end

local function ensureResourceColorPicker(self)
    if self.ResourceInspectorColorPicker then
        return self.ResourceInspectorColorPicker
    end

    local picker = UI.ColorPicker:New({
        name = "RPEDataEditorResourceInspectorColorPicker",
        width = 280,
        height = 228,
        hidden = true,
        title = "Resource Bar Color",
        paletteSettingKey = "resourceColorPalette",
    })
    picker:SetParent(UIParent)
    picker:Create()
    self.ResourceInspectorColorPicker = picker
    return self.ResourceInspectorColorPicker
end

local function openResourceColorPicker(self)
    local _, resource = getSelectedResourceAndDataset(self)
    if not resource then
        return
    end

    local picker = ensureResourceColorPicker(self)
    picker:Open({
        color = normalizeResourceColor(resource.color),
        onApply = function(color)
            commitSelectedResource(self, function(selectedResource)
                selectedResource.color = normalizeResourceColor(color)
            end)
        end,
    })
end

local function buildGeneralPage(self, page)
    local root = UI.CreateLayout(UI.VerticalLayoutGroup, page, "RPEDataEditorResourceInspectorGeneralLayout", {
        spacing = 6,
        fitChildrenWidth = true,
        fitChildrenHeight = false,
    })
    UI.Utils.AnchorFill(root, page, 0, 0, 0, 0)

    root:AddChild(buildLabel(root:GetFrame(), "RPEDataEditorResourceInspectorNameLabel", "Name"))
    self.ResourceInspectorNameInput = UI.CreateTextInput(root:GetFrame(), "RPEDataEditorResourceInspectorNameInput", {
        width = 236,
        height = CONTROL_HEIGHT,
        text = "",
        borderColor = UI.ResolveColor(nil, "panel.border"),
    })
    self.ResourceInspectorNameInput:SetScript("OnEnterPressed", function()
        commitSelectedResource(self, function(resource)
            resource.name = self.ResourceInspectorNameInput:GetText()
        end)
    end)
    self.ResourceInspectorNameInput:SetScript("OnEditFocusLost", function()
        commitSelectedResource(self, function(resource)
            resource.name = self.ResourceInspectorNameInput:GetText()
        end)
    end)
    root:AddChild(self.ResourceInspectorNameInput)

    self.ResourceInspectorIdText = UI.CreateText(root:GetFrame(), "RPEDataEditorResourceInspectorIdText", "ID: -", {
        fontFile = (UI.Constants and UI.Constants.FontFiles and UI.Constants.FontFiles.Default) or "Fonts\\FRIZQT__.TTF",
        fontSize = (UI.Constants and UI.Constants.FontSizes and UI.Constants.FontSizes.Body) or 8,
        textColor = UI.ResolveColor(nil, "text.secondary"),
        width = 236,
        height = 12,
        justifyH = "LEFT",
    })
    root:AddChild(self.ResourceInspectorIdText)

    root:AddChild(buildLabel(root:GetFrame(), "RPEDataEditorResourceInspectorIconLabel", "Icon"))
    self.ResourceInspectorIconField = UI.EditorIconField:New({
        name = "RPEDataEditorResourceInspectorIconField",
        width = 236,
        height = CONTROL_HEIGHT,
        buttonText = "Select Icon",
        labelText = "-",
        iconTexture = "Interface\\Icons\\INV_Misc_QuestionMark",
        border = false,
    })
    self.ResourceInspectorIconField:SetParent(root:GetFrame())
    self.ResourceInspectorIconField:Create()
    local iconButton = self.ResourceInspectorIconField:GetButton()
    if iconButton and iconButton.SetScript then
        iconButton:SetScript("OnClick", function()
            local dataset, resource = getSelectedResourceAndDataset(self)
            if not dataset or not resource or not Client.OpenIconFinder then
                return
            end

            Client:OpenIconFinder(function(_, filePath)
                commitSelectedResource(self, function(selectedResource)
                    selectedResource.icon = filePath or ""
                end)
            end, {
                filter = resource.icon or "",
            })
        end)
    end
    root:AddChild(self.ResourceInspectorIconField)

    self.ResourceInspectorIconInput = {
        SetText = function(_, value)
            local iconPath = value ~= nil and tostring(value) or ""
            self.ResourceInspectorIconField:SetIcon(iconPath ~= "" and iconPath or "Interface\\Icons\\INV_Misc_QuestionMark")
            self.ResourceInspectorIconField:SetLabelText(iconPath ~= "" and iconPath or "-")
        end,
        SetEnabled = function(_, enabled)
            self.ResourceInspectorIconField:SetEnabled(enabled)
        end,
        SetReadOnly = function(_, readOnly)
            self.ResourceInspectorIconField:SetEnabled(readOnly ~= true)
        end,
    }

    root:AddChild(buildLabel(root:GetFrame(), "RPEDataEditorResourceInspectorColorLabel", "Bar Color"))
    self.ResourceInspectorSelectedColor = UI.SelectedColor:New({
        name = "RPEDataEditorResourceInspectorSelectedColor",
        width = 236,
        height = CONTROL_HEIGHT,
        buttonWidth = 96,
        buttonText = "Select Color",
        border = false,
    })
    self.ResourceInspectorSelectedColor:SetParent(root:GetFrame())
    self.ResourceInspectorSelectedColor:Create()
    local colorButton = self.ResourceInspectorSelectedColor:GetButton()
    if colorButton and colorButton.SetScript then
        colorButton:SetScript("OnClick", function()
            openResourceColorPicker(self)
        end)
    end
    root:AddChild(self.ResourceInspectorSelectedColor)

    root:AddChild(buildLabel(root:GetFrame(), "RPEDataEditorResourceInspectorTagsLabel", "Tags"))
    self.ResourceInspectorTagsInput = UI.CreateTextInput(root:GetFrame(), "RPEDataEditorResourceInspectorTagsInput", {
        width = 236,
        height = CONTROL_HEIGHT,
        text = "",
        borderColor = UI.ResolveColor(nil, "panel.border"),
    })
    self.ResourceInspectorTagsInput:SetScript("OnEnterPressed", function()
        commitSelectedResource(self, function(resource)
            resource.tags = UI.Utils.ParseCommaSeparatedList(self.ResourceInspectorTagsInput:GetText())
        end)
    end)
    self.ResourceInspectorTagsInput:SetScript("OnEditFocusLost", function()
        commitSelectedResource(self, function(resource)
            resource.tags = UI.Utils.ParseCommaSeparatedList(self.ResourceInspectorTagsInput:GetText())
        end)
    end)
    root:AddChild(self.ResourceInspectorTagsInput)

    self.ResourceInspectorSeedNPCResourceCheckbox = createCheckbox(root:GetFrame(), "RPEDataEditorResourceInspectorSeedNPCResourceCheckbox", "Seed NPC Resource", false, function(checked)
        commitSelectedResource(self, function(resource)
            resource.seedNPCResource = checked == true
        end)
    end)
    root:AddChild(self.ResourceInspectorSeedNPCResourceCheckbox)

    self.ResourceInspectorSpecialResourceCheckbox = createCheckbox(root:GetFrame(), "RPEDataEditorResourceInspectorSpecialResourceCheckbox", "Special Resource", false, function(checked)
        commitSelectedResource(self, function(resource)
            resource.special = checked == true
        end)
    end)
    root:AddChild(self.ResourceInspectorSpecialResourceCheckbox)

    root:AddChild(buildLabel(root:GetFrame(), "RPEDataEditorResourceInspectorDescriptionLabel", "Description"))
    self.ResourceInspectorDescriptionInput = UI.CreateTextArea(root:GetFrame(), "RPEDataEditorResourceInspectorDescriptionInput", {
        width = 236,
        height = 64,
        text = "",
        readOnly = false,
        borderColor = UI.ResolveColor(nil, "panel.border"),
    })
    self.ResourceInspectorDescriptionInput:SetScript("OnEditFocusLost", function()
        commitSelectedResource(self, function(resource)
            resource.description = self.ResourceInspectorDescriptionInput:GetText()
        end)
    end)
    root:AddChild(self.ResourceInspectorDescriptionInput)
end

local function buildMechanicsPage(self, page)
    local root = UI.CreateLayout(UI.VerticalLayoutGroup, page, "RPEDataEditorResourceInspectorMechanicsLayout", {
        spacing = 6,
        fitChildrenWidth = true,
        fitChildrenHeight = false,
    })
    UI.Utils.AnchorFill(root, page, 0, 0, 0, 0)

    root:AddChild(buildLabel(root:GetFrame(), "RPEDataEditorResourceInspectorValueModeLabel", "Max Value Mode"))
    self.ResourceInspectorValueModeDropdown = UI.CreateDropdown(root:GetFrame(), "RPEDataEditorResourceInspectorValueModeDropdown", {
        width = 236,
        height = 18,
        items = {
            { label = "Manual", value = "manual" },
            { label = "Derived", value = "derived" },
        },
        onValueChanged = function(value)
            if self._refreshingResourceInspector then
                return
            end

            commitSelectedResource(self, function(resource)
                resource.valueMode = value == "derived" and "derived" or "manual"
            end)
        end,
    })
    root:AddChild(self.ResourceInspectorValueModeDropdown)

    root:AddChild(buildLabel(root:GetFrame(), "RPEDataEditorResourceInspectorBaseValueLabel", "Fixed Max Value"))
    self.ResourceInspectorBaseValueInput = UI.CreateTextInput(root:GetFrame(), "RPEDataEditorResourceInspectorBaseValueInput", {
        width = 236,
        height = CONTROL_HEIGHT,
        text = "0",
        borderColor = UI.ResolveColor(nil, "panel.border"),
    })
    self.ResourceInspectorBaseValueInput:SetScript("OnEnterPressed", function()
        commitSelectedResource(self, function(resource)
            resource.baseValue = tonumber(self.ResourceInspectorBaseValueInput:GetText()) or 0
        end)
    end)
    self.ResourceInspectorBaseValueInput:SetScript("OnEditFocusLost", function()
        commitSelectedResource(self, function(resource)
            resource.baseValue = tonumber(self.ResourceInspectorBaseValueInput:GetText()) or 0
        end)
    end)
    root:AddChild(self.ResourceInspectorBaseValueInput)

    root:AddChild(buildLabel(root:GetFrame(), "RPEDataEditorResourceInspectorSourceDatasetLabel", "Max Source Dataset"))
    self.ResourceInspectorSourceDatasetDropdown = UI.CreateDropdown(root:GetFrame(), "RPEDataEditorResourceInspectorSourceDatasetDropdown", {
        width = 236,
        height = 18,
        items = {
            { label = "None", value = "" },
        },
        onValueChanged = function(value)
            if self._refreshingResourceInspector then
                return
            end

            local dataset, resource = getSelectedResourceAndDataset(self)
            if self.ResourceInspectorSourceStatDropdown then
                self.ResourceInspectorSourceStatDropdown:SetItems(buildStatItems(self, value, dataset and dataset.id or nil, resource and resource.id or nil))
                self.ResourceInspectorSourceStatDropdown:SetSelectedValue("", true)
            end
        end,
    })
    root:AddChild(self.ResourceInspectorSourceDatasetDropdown)

    root:AddChild(buildLabel(root:GetFrame(), "RPEDataEditorResourceInspectorSourceStatLabel", "Max Source Stat"))
    self.ResourceInspectorSourceStatDropdown = UI.CreateDropdown(root:GetFrame(), "RPEDataEditorResourceInspectorSourceStatDropdown", {
        width = 236,
        height = 18,
        items = {
            { label = "None", value = "" },
        },
        onValueChanged = function(value)
            if self._refreshingResourceInspector then
                return
            end

            local datasetId = self.ResourceInspectorSourceDatasetDropdown and self.ResourceInspectorSourceDatasetDropdown:GetSelectedValue() or ""
            local dependencies = getDependenciesApi()
            commitSelectedResource(self, function(resource)
                resource.sourceStatRef = dependencies.ComposeSourceStatRef and dependencies.ComposeSourceStatRef(datasetId, value) or nil
            end)
        end,
    })
    root:AddChild(self.ResourceInspectorSourceStatDropdown)

    root:AddChild(buildLabel(root:GetFrame(), "RPEDataEditorResourceInspectorMultiplierLabel", "Max Multiplier"))
    self.ResourceInspectorMultiplierInput = UI.CreateTextInput(root:GetFrame(), "RPEDataEditorResourceInspectorMultiplierInput", {
        width = 236,
        height = CONTROL_HEIGHT,
        text = "0",
        borderColor = UI.ResolveColor(nil, "panel.border"),
    })
    self.ResourceInspectorMultiplierInput:SetScript("OnEnterPressed", function()
        commitSelectedResource(self, function(resource)
            resource.multiplier = tonumber(self.ResourceInspectorMultiplierInput:GetText()) or 0
        end)
    end)
    self.ResourceInspectorMultiplierInput:SetScript("OnEditFocusLost", function()
        commitSelectedResource(self, function(resource)
            resource.multiplier = tonumber(self.ResourceInspectorMultiplierInput:GetText()) or 0
        end)
    end)
    root:AddChild(self.ResourceInspectorMultiplierInput)

    self.ResourceInspectorStartsAtZeroCheckbox = createCheckbox(root:GetFrame(), "RPEDataEditorResourceInspectorStartsAtZeroCheckbox", "Starts at 0", false, function(checked)
        if self._refreshingResourceInspector then
            return
        end

        commitSelectedResource(self, function(resource)
            resource.startsAtZero = checked == true
        end)
    end)
    root:AddChild(self.ResourceInspectorStartsAtZeroCheckbox)
end

local function buildRegenerationPage(self, page)
    local root = UI.CreateLayout(UI.VerticalLayoutGroup, page, "RPEDataEditorResourceInspectorRegenerationLayout", {
        spacing = 6,
        fitChildrenWidth = true,
        fitChildrenHeight = false,
    })
    UI.Utils.AnchorFill(root, page, 0, 0, 0, 0)

    root:AddChild(buildLabel(root:GetFrame(), "RPEDataEditorResourceInspectorRegenModeLabel", "Regen Mode"))
    self.ResourceInspectorRegenModeDropdown = UI.CreateDropdown(root:GetFrame(), "RPEDataEditorResourceInspectorRegenModeDropdown", {
        width = 236,
        height = 18,
        items = {
            { label = "Manual", value = "manual" },
            { label = "Derived", value = "derived" },
        },
        onValueChanged = function(value)
            if self._refreshingResourceInspector then
                return
            end

            commitSelectedResource(self, function(resource)
                resource.regenMode = value == "derived" and "derived" or "manual"
            end)
        end,
    })
    root:AddChild(self.ResourceInspectorRegenModeDropdown)

    root:AddChild(buildLabel(root:GetFrame(), "RPEDataEditorResourceInspectorRegenValueLabel", "Fixed Regen Per Turn"))
    self.ResourceInspectorRegenPerSecondInput = UI.CreateTextInput(root:GetFrame(), "RPEDataEditorResourceInspectorRegenPerSecondInput", {
        width = 236,
        height = CONTROL_HEIGHT,
        text = "0",
        borderColor = UI.ResolveColor(nil, "panel.border"),
    })
    self.ResourceInspectorRegenPerSecondInput:SetScript("OnEnterPressed", function()
        commitSelectedResource(self, function(resource)
            resource.regenPerSecond = tonumber(self.ResourceInspectorRegenPerSecondInput:GetText()) or 0
        end)
    end)
    self.ResourceInspectorRegenPerSecondInput:SetScript("OnEditFocusLost", function()
        commitSelectedResource(self, function(resource)
            resource.regenPerSecond = tonumber(self.ResourceInspectorRegenPerSecondInput:GetText()) or 0
        end)
    end)
    root:AddChild(self.ResourceInspectorRegenPerSecondInput)

    root:AddChild(buildLabel(root:GetFrame(), "RPEDataEditorResourceInspectorRegenSourceDatasetLabel", "Regen Source Dataset"))
    self.ResourceInspectorRegenSourceDatasetDropdown = UI.CreateDropdown(root:GetFrame(), "RPEDataEditorResourceInspectorRegenSourceDatasetDropdown", {
        width = 236,
        height = 18,
        items = {
            { label = "None", value = "" },
        },
        onValueChanged = function(value)
            if self._refreshingResourceInspector then
                return
            end

            local dataset, resource = getSelectedResourceAndDataset(self)
            if self.ResourceInspectorRegenSourceStatDropdown then
                self.ResourceInspectorRegenSourceStatDropdown:SetItems(buildStatItems(self, value, dataset and dataset.id or nil, resource and resource.id or nil))
                self.ResourceInspectorRegenSourceStatDropdown:SetSelectedValue("", true)
            end
        end,
    })
    root:AddChild(self.ResourceInspectorRegenSourceDatasetDropdown)

    root:AddChild(buildLabel(root:GetFrame(), "RPEDataEditorResourceInspectorRegenSourceStatLabel", "Regen Source Stat"))
    self.ResourceInspectorRegenSourceStatDropdown = UI.CreateDropdown(root:GetFrame(), "RPEDataEditorResourceInspectorRegenSourceStatDropdown", {
        width = 236,
        height = 18,
        items = {
            { label = "None", value = "" },
        },
        onValueChanged = function(value)
            if self._refreshingResourceInspector then
                return
            end

            local datasetId = self.ResourceInspectorRegenSourceDatasetDropdown and self.ResourceInspectorRegenSourceDatasetDropdown:GetSelectedValue() or ""
            local dependencies = getDependenciesApi()
            commitSelectedResource(self, function(resource)
                resource.regenSourceStatRef = dependencies.ComposeSourceStatRef and dependencies.ComposeSourceStatRef(datasetId, value) or nil
            end)
        end,
    })
    root:AddChild(self.ResourceInspectorRegenSourceStatDropdown)

    root:AddChild(buildLabel(root:GetFrame(), "RPEDataEditorResourceInspectorRegenMultiplierLabel", "Regen Multiplier"))
    self.ResourceInspectorRegenMultiplierInput = UI.CreateTextInput(root:GetFrame(), "RPEDataEditorResourceInspectorRegenMultiplierInput", {
        width = 236,
        height = CONTROL_HEIGHT,
        text = "0",
        borderColor = UI.ResolveColor(nil, "panel.border"),
    })
    self.ResourceInspectorRegenMultiplierInput:SetScript("OnEnterPressed", function()
        commitSelectedResource(self, function(resource)
            resource.regenMultiplier = tonumber(self.ResourceInspectorRegenMultiplierInput:GetText()) or 0
        end)
    end)
    self.ResourceInspectorRegenMultiplierInput:SetScript("OnEditFocusLost", function()
        commitSelectedResource(self, function(resource)
            resource.regenMultiplier = tonumber(self.ResourceInspectorRegenMultiplierInput:GetText()) or 0
        end)
    end)
    root:AddChild(self.ResourceInspectorRegenMultiplierInput)
end

function DataEditor:BuildResourceInspectorPage(parent)
    if self.ResourceInspectorPage then
        self:RefreshResourceInspectorPage()
        return self.ResourceInspectorPage
    end

    self.ResourceInspectorPage = CreateFrame("Frame", "RPEDataEditorResourceInspectorPage", parent)

    self.ResourceInspectorTabBar = UI.CreateLayout(UI.HorizontalLayoutGroup, self.ResourceInspectorPage, "RPEDataEditorResourceInspectorTabBar", {
        spacing = 2,
        autoSize = true,
        fitChildrenWidth = false,
        fitChildrenHeight = false,
    })
    self.ResourceInspectorTabBar:GetFrame():SetPoint("TOPLEFT", self.ResourceInspectorPage, "TOPLEFT", 0, 0)

    self.ResourceInspectorGeneralTabButton = UI.CreateButton(self.ResourceInspectorTabBar:GetFrame(), "RPEDataEditorResourceInspectorGeneralTabButton", "General", 64, function()
        setInspectorTab(self, "general")
    end, {
        height = 18,
        fontSize = 8,
    })
    self.ResourceInspectorTabBar:AddChild(self.ResourceInspectorGeneralTabButton)

    self.ResourceInspectorMechanicsTabButton = UI.CreateButton(self.ResourceInspectorTabBar:GetFrame(), "RPEDataEditorResourceInspectorMechanicsTabButton", "Mechanics", 64, function()
        setInspectorTab(self, "mechanics")
    end, {
        height = 18,
        fontSize = 8,
    })
    self.ResourceInspectorTabBar:AddChild(self.ResourceInspectorMechanicsTabButton)

    self.ResourceInspectorRegenerationTabButton = UI.CreateButton(self.ResourceInspectorTabBar:GetFrame(), "RPEDataEditorResourceInspectorRegenerationTabButton", "Regen", 64, function()
        setInspectorTab(self, "regeneration")
    end, {
        height = 18,
        fontSize = 8,
    })
    self.ResourceInspectorTabBar:AddChild(self.ResourceInspectorRegenerationTabButton)

    self.ResourceInspectorGeneralPage = CreateFrame("Frame", "RPEDataEditorResourceInspectorGeneralPage", self.ResourceInspectorPage)
    self.ResourceInspectorGeneralPage:SetPoint("TOPLEFT", self.ResourceInspectorPage, "TOPLEFT", INSPECTOR_SIDE_PADDING, -24)
    self.ResourceInspectorGeneralPage:SetPoint("TOPRIGHT", self.ResourceInspectorPage, "TOPRIGHT", -INSPECTOR_SIDE_PADDING, -24)
    self.ResourceInspectorGeneralPage:SetPoint("BOTTOMLEFT", self.ResourceInspectorPage, "BOTTOMLEFT", INSPECTOR_SIDE_PADDING, 24)
    self.ResourceInspectorGeneralPage:SetPoint("BOTTOMRIGHT", self.ResourceInspectorPage, "BOTTOMRIGHT", -INSPECTOR_SIDE_PADDING, 24)
    buildGeneralPage(self, self.ResourceInspectorGeneralPage)

    self.ResourceInspectorMechanicsPage = CreateFrame("Frame", "RPEDataEditorResourceInspectorMechanicsPage", self.ResourceInspectorPage)
    self.ResourceInspectorMechanicsPage:SetPoint("TOPLEFT", self.ResourceInspectorPage, "TOPLEFT", INSPECTOR_SIDE_PADDING, -24)
    self.ResourceInspectorMechanicsPage:SetPoint("TOPRIGHT", self.ResourceInspectorPage, "TOPRIGHT", -INSPECTOR_SIDE_PADDING, -24)
    self.ResourceInspectorMechanicsPage:SetPoint("BOTTOMLEFT", self.ResourceInspectorPage, "BOTTOMLEFT", INSPECTOR_SIDE_PADDING, 24)
    self.ResourceInspectorMechanicsPage:SetPoint("BOTTOMRIGHT", self.ResourceInspectorPage, "BOTTOMRIGHT", -INSPECTOR_SIDE_PADDING, 24)
    buildMechanicsPage(self, self.ResourceInspectorMechanicsPage)

    self.ResourceInspectorRegenerationPage = CreateFrame("Frame", "RPEDataEditorResourceInspectorRegenerationPage", self.ResourceInspectorPage)
    self.ResourceInspectorRegenerationPage:SetPoint("TOPLEFT", self.ResourceInspectorPage, "TOPLEFT", INSPECTOR_SIDE_PADDING, -24)
    self.ResourceInspectorRegenerationPage:SetPoint("TOPRIGHT", self.ResourceInspectorPage, "TOPRIGHT", -INSPECTOR_SIDE_PADDING, -24)
    self.ResourceInspectorRegenerationPage:SetPoint("BOTTOMLEFT", self.ResourceInspectorPage, "BOTTOMLEFT", INSPECTOR_SIDE_PADDING, 24)
    self.ResourceInspectorRegenerationPage:SetPoint("BOTTOMRIGHT", self.ResourceInspectorPage, "BOTTOMRIGHT", -INSPECTOR_SIDE_PADDING, 24)
    buildRegenerationPage(self, self.ResourceInspectorRegenerationPage)

    self.ResourceInspectorEmptyText = UI.CreateText(self.ResourceInspectorPage, "RPEDataEditorResourceInspectorEmptyText", "", {
        fontFile = (UI.Constants and UI.Constants.FontFiles and UI.Constants.FontFiles.Default) or "Fonts\\FRIZQT__.TTF",
        fontSize = (UI.Constants and UI.Constants.FontSizes and UI.Constants.FontSizes.Body) or 8,
        textColor = UI.ResolveColor(nil, "text.secondary"),
        width = 236,
        height = 20,
        justifyH = "LEFT",
    })
    self.ResourceInspectorEmptyText:GetFrame():SetPoint("BOTTOMLEFT", self.ResourceInspectorPage, "BOTTOMLEFT", 0, 0)

    setInspectorTab(self, "general")
    self:RefreshResourceInspectorPage()
    return self.ResourceInspectorPage
end

function DataEditor:RefreshResourceInspectorPage()
    local dataset, resource = getSelectedResourceAndDataset(self)
    local hasResource = resource ~= nil
    local currentDatasetId = dataset and dataset.id or nil
    local currentResourceId = resource and resource.id or nil
    local isDerived = hasResource and resource.valueMode == "derived"
    local isRegenDerived = hasResource and resource.regenMode == "derived"

    self._refreshingResourceInspector = true

    if self.ResourceInspectorNameInput then
        self.ResourceInspectorNameInput:SetText(resource and (resource.name or "") or "")
        setTextElementEnabled(self.ResourceInspectorNameInput, hasResource)
    end

    if self.ResourceInspectorIdText then
        self.ResourceInspectorIdText:SetText(("ID: %s"):format(resource and resource.id ~= nil and tostring(resource.id) or "-"))
    end

    if self.ResourceInspectorIconInput then
        self.ResourceInspectorIconInput:SetText(resource and (resource.icon or "") or "")
        setTextElementEnabled(self.ResourceInspectorIconInput, hasResource)
    end

    if self.ResourceInspectorSelectedColor then
        self.ResourceInspectorSelectedColor:SetColor(normalizeResourceColor(resource and resource.color or nil))
        self.ResourceInspectorSelectedColor:SetEnabled(hasResource)
    end

    if self.ResourceInspectorTagsInput then
        self.ResourceInspectorTagsInput:SetText(UI.Utils.JoinCommaSeparatedList(resource and resource.tags or nil))
        setTextElementEnabled(self.ResourceInspectorTagsInput, hasResource)
    end

    if self.ResourceInspectorSeedNPCResourceCheckbox then
        self.ResourceInspectorSeedNPCResourceCheckbox:SetChecked(resource and resource.seedNPCResource == true or false, true)
        setCheckboxEnabled(self.ResourceInspectorSeedNPCResourceCheckbox, hasResource)
    end

    if self.ResourceInspectorSpecialResourceCheckbox then
        self.ResourceInspectorSpecialResourceCheckbox:SetChecked(resource and resource.special == true or false, true)
        setCheckboxEnabled(self.ResourceInspectorSpecialResourceCheckbox, hasResource)
    end

    if self.ResourceInspectorDescriptionInput then
        self.ResourceInspectorDescriptionInput:SetText(resource and (resource.description or "") or "")
        setTextElementEnabled(self.ResourceInspectorDescriptionInput, hasResource)
    end

    if self.ResourceInspectorValueModeDropdown then
        self.ResourceInspectorValueModeDropdown:SetSelectedValue(resource and resource.valueMode or "manual", true)
        setDropdownEnabled(self.ResourceInspectorValueModeDropdown, hasResource)
    end

    if self.ResourceInspectorBaseValueInput then
        self.ResourceInspectorBaseValueInput:SetText(tostring(resource and resource.baseValue or 0))
        setTextElementEnabled(self.ResourceInspectorBaseValueInput, hasResource and not isDerived)
    end

    if self.ResourceInspectorMultiplierInput then
        self.ResourceInspectorMultiplierInput:SetText(tostring(resource and resource.multiplier or 0))
        setTextElementEnabled(self.ResourceInspectorMultiplierInput, hasResource and isDerived)
    end

    if self.ResourceInspectorStartsAtZeroCheckbox then
        self.ResourceInspectorStartsAtZeroCheckbox:SetChecked(resource and resource.startsAtZero == true or false, true)
        setCheckboxEnabled(self.ResourceInspectorStartsAtZeroCheckbox, hasResource)
    end

    if self.ResourceInspectorSourceDatasetDropdown then
        resolveSourceSelection(resource and resource.sourceStatRef or nil, {
            owner = self,
            dataset = self.ResourceInspectorSourceDatasetDropdown,
            stat = self.ResourceInspectorSourceStatDropdown,
            currentDatasetId = currentDatasetId,
            currentResourceId = currentResourceId,
        })
        setDropdownEnabled(self.ResourceInspectorSourceDatasetDropdown, hasResource and isDerived)
    end

    if self.ResourceInspectorSourceStatDropdown then
        setDropdownEnabled(self.ResourceInspectorSourceStatDropdown, hasResource and isDerived)
    end

    if self.ResourceInspectorRegenModeDropdown then
        self.ResourceInspectorRegenModeDropdown:SetSelectedValue(resource and resource.regenMode or "manual", true)
        setDropdownEnabled(self.ResourceInspectorRegenModeDropdown, hasResource)
    end

    if self.ResourceInspectorRegenPerSecondInput then
        self.ResourceInspectorRegenPerSecondInput:SetText(tostring(resource and resource.regenPerSecond or 0))
        setTextElementEnabled(self.ResourceInspectorRegenPerSecondInput, hasResource and not isRegenDerived)
    end

    if self.ResourceInspectorRegenMultiplierInput then
        self.ResourceInspectorRegenMultiplierInput:SetText(tostring(resource and resource.regenMultiplier or 0))
        setTextElementEnabled(self.ResourceInspectorRegenMultiplierInput, hasResource and isRegenDerived)
    end

    if self.ResourceInspectorRegenSourceDatasetDropdown then
        resolveSourceSelection(resource and resource.regenSourceStatRef or nil, {
            owner = self,
            dataset = self.ResourceInspectorRegenSourceDatasetDropdown,
            stat = self.ResourceInspectorRegenSourceStatDropdown,
            currentDatasetId = currentDatasetId,
            currentResourceId = currentResourceId,
        })
        setDropdownEnabled(self.ResourceInspectorRegenSourceDatasetDropdown, hasResource and isRegenDerived)
    end

    if self.ResourceInspectorRegenSourceStatDropdown then
        setDropdownEnabled(self.ResourceInspectorRegenSourceStatDropdown, hasResource and isRegenDerived)
    end

    self._refreshingResourceInspector = false

    if self.ResourceInspectorEmptyText then
        self.ResourceInspectorEmptyText:SetText(hasResource and "Adjust the selected resource definition here." or "Select a resource to inspect it.")
    end

    if hasResource and self.ActiveResourceInspectorTabKey == nil then
        setInspectorTab(self, "general")
    end
end
