local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Client.UI = Addon.Client.UI or {}
Addon.Client.UI.Editor = Addon.Client.UI.Editor or {}

local DataEditor = Addon.Client.UI.Editor
local UI = Addon.UI or {}
local CONTROL_HEIGHT = 20

function DataEditor:BuildStatInspectorMechanicsPage(page)
    local root = UI.CreateLayout(UI.VerticalLayoutGroup, page, "RPEDataEditorStatInspectorMechanicsLayout", {
        spacing = 6,
        fitChildrenWidth = true,
        fitChildrenHeight = false,
    })
    UI.Utils.AnchorFill(root, page, 0, 0, 0, 0)

    root:AddChild(self:BuildStatInspectorLabel(root:GetFrame(), "RPEDataEditorStatInspectorValueModeLabel", "Value Mode"))
    self.StatInspectorValueModeDropdown = UI.CreateDropdown(root:GetFrame(), "RPEDataEditorStatInspectorValueModeDropdown", {
        width = 236,
        height = 18,
        items = {
            { label = "Manual", value = "manual" },
            { label = "Derived", value = "derived" },
        },
        onValueChanged = function(value)
            if self._refreshingStatInspector then
                return
            end

            self:CommitSelectedStat(function(stat)
                stat.valueMode = value == "derived" and "derived" or "manual"
                if stat.valueMode ~= "derived" then
                    stat.derivedSources = {}
                end
            end)
        end,
    })
    root:AddChild(self.StatInspectorValueModeDropdown)

    root:AddChild(self:BuildStatInspectorLabel(root:GetFrame(), "RPEDataEditorStatInspectorBaseValueLabel", "Base Value"))
    self.StatInspectorBaseValueInput = UI.CreateTextInput(root:GetFrame(), "RPEDataEditorStatInspectorBaseValueInput", {
        width = 236,
        height = CONTROL_HEIGHT,
        text = "0",
        borderColor = UI.ResolveColor(nil, "panel.border"),
    })
    self.StatInspectorBaseValueInput:SetScript("OnEnterPressed", function()
        self:CommitSelectedStat(function(stat)
            stat.baseValue = tonumber(self.StatInspectorBaseValueInput:GetText()) or 0
        end)
    end)
    self.StatInspectorBaseValueInput:SetScript("OnEditFocusLost", function()
        self:CommitSelectedStat(function(stat)
            stat.baseValue = tonumber(self.StatInspectorBaseValueInput:GetText()) or 0
        end)
    end)
    root:AddChild(self.StatInspectorBaseValueInput)

    root:AddChild(self:BuildStatInspectorLabel(root:GetFrame(), "RPEDataEditorStatInspectorItemLevelWeightLabel", "Item Level Weight"))
    self.StatInspectorItemLevelWeightInput = UI.CreateTextInput(root:GetFrame(), "RPEDataEditorStatInspectorItemLevelWeightInput", {
        width = 236,
        height = CONTROL_HEIGHT,
        text = "0",
        borderColor = UI.ResolveColor(nil, "panel.border"),
    })
    self.StatInspectorItemLevelWeightInput:SetScript("OnEnterPressed", function()
        self:CommitSelectedStat(function(stat)
            stat.itemLevelWeight = tonumber(self.StatInspectorItemLevelWeightInput:GetText()) or 0
        end)
    end)
    self.StatInspectorItemLevelWeightInput:SetScript("OnEditFocusLost", function()
        self:CommitSelectedStat(function(stat)
            stat.itemLevelWeight = tonumber(self.StatInspectorItemLevelWeightInput:GetText()) or 0
        end)
    end)
    root:AddChild(self.StatInspectorItemLevelWeightInput)

    root:AddChild(self:BuildStatInspectorLabel(root:GetFrame(), "RPEDataEditorStatInspectorSourcesLabel", "Derived Sources"))

    self.StatInspectorDerivedSourcesHeader = UI.CreateLayout(UI.HorizontalLayoutGroup, root:GetFrame(), "RPEDataEditorStatInspectorDerivedSourcesHeader", {
        width = 236,
        height = 14,
        spacing = 2,
        fitChildrenWidth = false,
        fitChildrenHeight = false,
    })
    root:AddChild(self.StatInspectorDerivedSourcesHeader)

    self.StatInspectorDerivedSourcesDatasetHeader = UI.CreateText(self.StatInspectorDerivedSourcesHeader:GetFrame(), "RPEDataEditorStatInspectorDerivedSourcesDatasetHeader", "Dataset", {
        fontFile = (UI.Constants and UI.Constants.FontFiles and UI.Constants.FontFiles.Default) or "Fonts\\FRIZQT__.TTF",
        fontSize = (UI.Constants and UI.Constants.FontSizes and UI.Constants.FontSizes.Body) or 8,
        textColor = UI.ResolveColor(nil, "text.secondary"),
        width = 78,
        height = 12,
        justifyH = "LEFT",
    })
    self.StatInspectorDerivedSourcesHeader:AddChild(self.StatInspectorDerivedSourcesDatasetHeader)

    self.StatInspectorDerivedSourcesStatHeader = UI.CreateText(self.StatInspectorDerivedSourcesHeader:GetFrame(), "RPEDataEditorStatInspectorDerivedSourcesStatHeader", "Stat", {
        fontFile = (UI.Constants and UI.Constants.FontFiles and UI.Constants.FontFiles.Default) or "Fonts\\FRIZQT__.TTF",
        fontSize = (UI.Constants and UI.Constants.FontSizes and UI.Constants.FontSizes.Body) or 8,
        textColor = UI.ResolveColor(nil, "text.secondary"),
        width = 82,
        height = 12,
        justifyH = "LEFT",
    })
    self.StatInspectorDerivedSourcesHeader:AddChild(self.StatInspectorDerivedSourcesStatHeader)

    self.StatInspectorDerivedSourcesCoefficientHeader = UI.CreateText(self.StatInspectorDerivedSourcesHeader:GetFrame(), "RPEDataEditorStatInspectorDerivedSourcesCoefficientHeader", "Coef", {
        fontFile = (UI.Constants and UI.Constants.FontFiles and UI.Constants.FontFiles.Default) or "Fonts\\FRIZQT__.TTF",
        fontSize = (UI.Constants and UI.Constants.FontSizes and UI.Constants.FontSizes.Body) or 8,
        textColor = UI.ResolveColor(nil, "text.secondary"),
        width = 34,
        height = 12,
        justifyH = "RIGHT",
    })
    self.StatInspectorDerivedSourcesHeader:AddChild(self.StatInspectorDerivedSourcesCoefficientHeader)

    self.StatInspectorDerivedSourcesPanel = UI.CreatePanel(root:GetFrame(), "RPEDataEditorStatInspectorDerivedSourcesPanel", {
        width = 236,
        height = 56,
        contentInset = 1,
        showBorder = true,
    })
    root:AddChild(self.StatInspectorDerivedSourcesPanel)

    self.StatInspectorDerivedSourcesScroll = UI.ScrollLayout:New({
        name = "RPEDataEditorStatInspectorDerivedSourcesScroll",
        width = 236,
        height = 54,
        visibleRows = 3,
        rowHeight = 18,
        rowSpacing = 0,
        border = false,
        rowElementClass = UI.TableRow,
    })
    self.StatInspectorDerivedSourcesScroll:SetParent(self.StatInspectorDerivedSourcesPanel:GetContentFrame())
    self.StatInspectorDerivedSourcesScroll:SetRowRenderer(function(row, item)
        if row.SetColumns then
            row:SetColumns({
                { key = "datasetName", width = 78, justifyH = "LEFT" },
                { key = "statName", width = 82, justifyH = "LEFT" },
                { key = "coefficientText", width = 34, justifyH = "RIGHT" },
            })
        end
        if row.SetRowData then
            row:SetRowData(item, item and item.rowIndex or 0)
        end
        if row.SetRowMouseUpHandler then
            row:SetRowMouseUpHandler(function(tableRow, button, rowData)
                if button == "RightButton" then
                    local anchor = tableRow and tableRow.GetFrame and tableRow:GetFrame() or nil
                    self:ShowStatInspectorDerivedSourceContextMenu(anchor, rowData)
                end
            end)
        end
    end)
    self.StatInspectorDerivedSourcesScroll:Create()
    UI.Utils.AnchorFill(self.StatInspectorDerivedSourcesScroll, self.StatInspectorDerivedSourcesPanel:GetContentFrame(), 0, 0, 0, 0)

    self.StatInspectorPendingSourceRow = UI.CreateLayout(UI.HorizontalLayoutGroup, root:GetFrame(), "RPEDataEditorStatInspectorPendingSourceRow", {
        width = 236,
        height = 18,
        spacing = 2,
        fitChildrenWidth = false,
        fitChildrenHeight = false,
    })
    root:AddChild(self.StatInspectorPendingSourceRow)

    self.StatInspectorPendingSourceDatasetDropdown = UI.CreateDropdown(self.StatInspectorPendingSourceRow:GetFrame(), "RPEDataEditorStatInspectorPendingSourceDatasetDropdown", {
        width = 78,
        height = 18,
        items = {
            { label = "None", value = "" },
        },
        onValueChanged = function()
            if self._refreshingStatInspector then
                return
            end

            self:RefreshStatInspectorPendingSourceStatDropdown()
            if self.StatInspectorPendingSourceStatDropdown and self.StatInspectorPendingSourceStatDropdown.SetSelectedValue then
                self.StatInspectorPendingSourceStatDropdown:SetSelectedValue("", true)
            end
        end,
    })
    self.StatInspectorPendingSourceRow:AddChild(self.StatInspectorPendingSourceDatasetDropdown)

    self.StatInspectorPendingSourceStatDropdown = UI.CreateDropdown(self.StatInspectorPendingSourceRow:GetFrame(), "RPEDataEditorStatInspectorPendingSourceStatDropdown", {
        width = 82,
        height = 18,
        items = {
            { label = "None", value = "" },
        },
    })
    self.StatInspectorPendingSourceRow:AddChild(self.StatInspectorPendingSourceStatDropdown)

    self.StatInspectorPendingCoefficientInput = UI.CreateTextInput(self.StatInspectorPendingSourceRow:GetFrame(), "RPEDataEditorStatInspectorPendingCoefficientInput", {
        width = 34,
        height = 18,
        text = "1",
        borderColor = UI.ResolveColor(nil, "panel.border"),
    })
    self.StatInspectorPendingSourceRow:AddChild(self.StatInspectorPendingCoefficientInput)

    self.StatInspectorAddSourceButton = UI.CreateButton(self.StatInspectorPendingSourceRow:GetFrame(), "RPEDataEditorStatInspectorAddSourceButton", "Add", 36, function()
        if self._refreshingStatInspector then
            return
        end

        local dependencies = self:GetStatInspectorDependenciesApi()
        local datasetId = self.StatInspectorPendingSourceDatasetDropdown and self.StatInspectorPendingSourceDatasetDropdown.GetSelectedValue and self.StatInspectorPendingSourceDatasetDropdown:GetSelectedValue() or ""
        local statId = self.StatInspectorPendingSourceStatDropdown and self.StatInspectorPendingSourceStatDropdown.GetSelectedValue and self.StatInspectorPendingSourceStatDropdown:GetSelectedValue() or ""
        local coefficient = tonumber(self.StatInspectorPendingCoefficientInput and self.StatInspectorPendingCoefficientInput:GetText()) or 1
        local sourceStatRef = dependencies.ComposeSourceStatRef and dependencies.ComposeSourceStatRef(datasetId, statId) or nil

        if not sourceStatRef then
            return
        end

        self:CommitSelectedStat(function(stat)
            local sources = self:GetStatInspectorDerivedSources(stat)
            sources[#sources + 1] = {
                sourceStatRef = sourceStatRef,
                coefficient = coefficient,
            }
            stat.derivedSources = sources
        end)
    end, {
        height = 18,
        fontSize = 7,
    })
    self.StatInspectorPendingSourceRow:AddChild(self.StatInspectorAddSourceButton)

    self.StatInspectorSourceDatasetDropdown = self.StatInspectorPendingSourceDatasetDropdown
    self.StatInspectorSourceStatDropdown = self.StatInspectorPendingSourceStatDropdown
end
