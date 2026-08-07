local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Client.UI = Addon.Client.UI or {}
Addon.Client.UI.Editor = Addon.Client.UI.Editor or {}

local DataEditor = Addon.Client.UI.Editor
local UI = Addon.UI or {}
local Shared = DataEditor.ItemInspectorShared or {}
local FIELD_WIDTH = Shared.FIELD_WIDTH or 236
local buildLabel = Shared.buildLabel
local getDependenciesApi = Shared.getDependenciesApi
local normalizeItemStats = Shared.normalizeItemStats
local normalizeItemSkillBonuses = Shared.normalizeItemSkillBonuses

local function buildStatsPage(self, page)
    local root = UI.CreateLayout(UI.VerticalLayoutGroup, page, "RPEDataEditorItemInspectorStatsLayout", {
        spacing = 6,
        fitChildrenWidth = true,
        fitChildrenHeight = false,
    })
    UI.Utils.AnchorFill(root, page, 0, 0, 0, 0)

    root:AddChild(buildLabel(root:GetFrame(), "RPEDataEditorItemInspectorStatsHeaderLabel", "Item Stats"))

    self.ItemInspectorStatsHeader = UI.CreateLayout(UI.HorizontalLayoutGroup, root:GetFrame(), "RPEDataEditorItemInspectorStatsHeader", {
        width = FIELD_WIDTH,
        height = 14,
        spacing = 2,
        fitChildrenWidth = false,
        fitChildrenHeight = false,
    })
    root:AddChild(self.ItemInspectorStatsHeader)

    self.ItemInspectorStatsDatasetHeader = UI.CreateText(self.ItemInspectorStatsHeader:GetFrame(), "RPEDataEditorItemInspectorStatsDatasetHeader", "Dataset", {
        width = 82,
        height = 12,
        justifyH = "LEFT",
        textColor = UI.ResolveColor(nil, "text.secondary"),
    })
    self.ItemInspectorStatsHeader:AddChild(self.ItemInspectorStatsDatasetHeader)

    self.ItemInspectorStatsStatHeader = UI.CreateText(self.ItemInspectorStatsHeader:GetFrame(), "RPEDataEditorItemInspectorStatsStatHeader", "Stat", {
        width = 90,
        height = 12,
        justifyH = "LEFT",
        textColor = UI.ResolveColor(nil, "text.secondary"),
    })
    self.ItemInspectorStatsHeader:AddChild(self.ItemInspectorStatsStatHeader)

    self.ItemInspectorStatsValueHeader = UI.CreateText(self.ItemInspectorStatsHeader:GetFrame(), "RPEDataEditorItemInspectorStatsValueHeader", "Value", {
        width = 46,
        height = 12,
        justifyH = "RIGHT",
        textColor = UI.ResolveColor(nil, "text.secondary"),
    })
    self.ItemInspectorStatsHeader:AddChild(self.ItemInspectorStatsValueHeader)

    self.ItemInspectorStatsPanel = UI.CreatePanel(root:GetFrame(), "RPEDataEditorItemInspectorStatsPanel", {
        width = FIELD_WIDTH,
        height = 56,
        contentInset = 1,
        showBorder = true,
    })
    root:AddChild(self.ItemInspectorStatsPanel)

    self.ItemInspectorStatsScroll = UI.ScrollLayout:New({
        name = "RPEDataEditorItemInspectorStatsScroll",
        width = FIELD_WIDTH,
        height = 54,
        visibleRows = 3,
        rowHeight = 18,
        rowSpacing = 0,
        border = false,
        rowElementClass = UI.TableRow,
    })
    self.ItemInspectorStatsScroll:SetParent(self.ItemInspectorStatsPanel:GetContentFrame())
    self.ItemInspectorStatsScroll:SetRowRenderer(function(row, item, itemIndex)
        if row.SetColumns then
            row:SetColumns({
                { key = "datasetName", width = 82, justifyH = "LEFT" },
                { key = "statName", width = 90, justifyH = "LEFT" },
                { key = "valueText", width = 46, justifyH = "RIGHT" },
            })
        end
        if row.SetRowData then
            row:SetRowData(item, itemIndex or 0)
        end
        if row.SetRowMouseUpHandler then
            row:SetRowMouseUpHandler(function(tableRow, button, rowData)
                if button == "RightButton" then
                    local anchor = tableRow and tableRow.GetFrame and tableRow:GetFrame() or nil
                    self:ShowItemInspectorStatContextMenu(anchor, rowData)
                end
            end)
        end
    end)
    self.ItemInspectorStatsScroll:Create()
    UI.Utils.AnchorFill(self.ItemInspectorStatsScroll, self.ItemInspectorStatsPanel:GetContentFrame(), 0, 0, 0, 0)

    self.ItemInspectorPendingStatRow = UI.CreateLayout(UI.HorizontalLayoutGroup, root:GetFrame(), "RPEDataEditorItemInspectorPendingStatRow", {
        width = FIELD_WIDTH,
        height = 18,
        spacing = 2,
        fitChildrenWidth = false,
        fitChildrenHeight = false,
    })
    root:AddChild(self.ItemInspectorPendingStatRow)

    self.ItemInspectorPendingStatDatasetDropdown = UI.CreateDropdown(self.ItemInspectorPendingStatRow:GetFrame(), "RPEDataEditorItemInspectorPendingStatDatasetDropdown", {
        width = 82,
        height = 18,
        items = {
            { label = "None", value = "" },
        },
        onValueChanged = function()
            if self._refreshingItemInspector then
                return
            end

            self:RefreshItemInspectorPendingStatDropdown()
            if self.ItemInspectorPendingStatDropdown and self.ItemInspectorPendingStatDropdown.SetSelectedValue then
                self.ItemInspectorPendingStatDropdown:SetSelectedValue("", true)
            end
        end,
    })
    self.ItemInspectorPendingStatRow:AddChild(self.ItemInspectorPendingStatDatasetDropdown)

    self.ItemInspectorPendingStatDropdown = UI.CreateDropdown(self.ItemInspectorPendingStatRow:GetFrame(), "RPEDataEditorItemInspectorPendingStatDropdown", {
        width = 90,
        height = 18,
        items = {
            { label = "None", value = "" },
        },
    })
    self.ItemInspectorPendingStatRow:AddChild(self.ItemInspectorPendingStatDropdown)

    self.ItemInspectorPendingStatValueInput = UI.CreateTextInput(self.ItemInspectorPendingStatRow:GetFrame(), "RPEDataEditorItemInspectorPendingStatValueInput", {
        width = 46,
        height = 18,
        text = "0",
        borderColor = UI.ResolveColor(nil, "panel.border"),
    })
    self.ItemInspectorPendingStatRow:AddChild(self.ItemInspectorPendingStatValueInput)

    self.ItemInspectorAddStatButton = UI.CreateButton(self.ItemInspectorPendingStatRow:GetFrame(), "RPEDataEditorItemInspectorAddStatButton", "Add", 36, function()
        if self._refreshingItemInspector then
            return
        end

        local dependencies = getDependenciesApi()
        local datasetId = self.ItemInspectorPendingStatDatasetDropdown and self.ItemInspectorPendingStatDatasetDropdown.GetSelectedValue and self.ItemInspectorPendingStatDatasetDropdown:GetSelectedValue() or ""
        local statId = self.ItemInspectorPendingStatDropdown and self.ItemInspectorPendingStatDropdown.GetSelectedValue and self.ItemInspectorPendingStatDropdown:GetSelectedValue() or ""
        local value = tonumber(self.ItemInspectorPendingStatValueInput and self.ItemInspectorPendingStatValueInput:GetText()) or 0
        local sourceStatRef = dependencies.ComposeSourceStatRef and dependencies.ComposeSourceStatRef(datasetId, statId) or nil

        if not sourceStatRef then
            return
        end

        self:CommitSelectedItem(function(item)
            local stats = normalizeItemStats(item)
            stats[#stats + 1] = {
                sourceStatRef = sourceStatRef,
                value = value,
            }
            item.stats = stats
        end)
    end, {
        height = 18,
        fontSize = 7,
    })
    self.ItemInspectorPendingStatRow:AddChild(self.ItemInspectorAddStatButton)

    root:AddChild(buildLabel(root:GetFrame(), "RPEDataEditorItemInspectorSkillsHeaderLabel", "Skill Bonuses"))

    self.ItemInspectorSkillsHeader = UI.CreateLayout(UI.HorizontalLayoutGroup, root:GetFrame(), "RPEDataEditorItemInspectorSkillsHeader", {
        width = FIELD_WIDTH,
        height = 14,
        spacing = 2,
        fitChildrenWidth = false,
        fitChildrenHeight = false,
    })
    root:AddChild(self.ItemInspectorSkillsHeader)

    self.ItemInspectorSkillsDatasetHeader = UI.CreateText(self.ItemInspectorSkillsHeader:GetFrame(), "RPEDataEditorItemInspectorSkillsDatasetHeader", "Dataset", {
        width = 82,
        height = 12,
        justifyH = "LEFT",
        textColor = UI.ResolveColor(nil, "text.secondary"),
    })
    self.ItemInspectorSkillsHeader:AddChild(self.ItemInspectorSkillsDatasetHeader)

    self.ItemInspectorSkillsSkillHeader = UI.CreateText(self.ItemInspectorSkillsHeader:GetFrame(), "RPEDataEditorItemInspectorSkillsSkillHeader", "Skill", {
        width = 90,
        height = 12,
        justifyH = "LEFT",
        textColor = UI.ResolveColor(nil, "text.secondary"),
    })
    self.ItemInspectorSkillsHeader:AddChild(self.ItemInspectorSkillsSkillHeader)

    self.ItemInspectorSkillsValueHeader = UI.CreateText(self.ItemInspectorSkillsHeader:GetFrame(), "RPEDataEditorItemInspectorSkillsValueHeader", "Value", {
        width = 46,
        height = 12,
        justifyH = "RIGHT",
        textColor = UI.ResolveColor(nil, "text.secondary"),
    })
    self.ItemInspectorSkillsHeader:AddChild(self.ItemInspectorSkillsValueHeader)

    self.ItemInspectorSkillsPanel = UI.CreatePanel(root:GetFrame(), "RPEDataEditorItemInspectorSkillsPanel", {
        width = FIELD_WIDTH,
        height = 56,
        contentInset = 1,
        showBorder = true,
    })
    root:AddChild(self.ItemInspectorSkillsPanel)

    self.ItemInspectorSkillsScroll = UI.ScrollLayout:New({
        name = "RPEDataEditorItemInspectorSkillsScroll",
        width = FIELD_WIDTH,
        height = 54,
        visibleRows = 3,
        rowHeight = 18,
        rowSpacing = 0,
        border = false,
        rowElementClass = UI.TableRow,
    })
    self.ItemInspectorSkillsScroll:SetParent(self.ItemInspectorSkillsPanel:GetContentFrame())
    self.ItemInspectorSkillsScroll:SetRowRenderer(function(row, item, itemIndex)
        if row.SetColumns then
            row:SetColumns({
                { key = "datasetName", width = 82, justifyH = "LEFT" },
                { key = "skillName", width = 90, justifyH = "LEFT" },
                { key = "valueText", width = 46, justifyH = "RIGHT" },
            })
        end
        if row.SetRowData then
            row:SetRowData(item, itemIndex or 0)
        end
        if row.SetRowMouseUpHandler then
            row:SetRowMouseUpHandler(function(tableRow, button, rowData)
                if button == "RightButton" then
                    local anchor = tableRow and tableRow.GetFrame and tableRow:GetFrame() or nil
                    self:ShowItemInspectorSkillContextMenu(anchor, rowData)
                end
            end)
        end
    end)
    self.ItemInspectorSkillsScroll:Create()
    UI.Utils.AnchorFill(self.ItemInspectorSkillsScroll, self.ItemInspectorSkillsPanel:GetContentFrame(), 0, 0, 0, 0)

    self.ItemInspectorPendingSkillRow = UI.CreateLayout(UI.HorizontalLayoutGroup, root:GetFrame(), "RPEDataEditorItemInspectorPendingSkillRow", {
        width = FIELD_WIDTH,
        height = 18,
        spacing = 2,
        fitChildrenWidth = false,
        fitChildrenHeight = false,
    })
    root:AddChild(self.ItemInspectorPendingSkillRow)

    self.ItemInspectorPendingSkillDatasetDropdown = UI.CreateDropdown(self.ItemInspectorPendingSkillRow:GetFrame(), "RPEDataEditorItemInspectorPendingSkillDatasetDropdown", {
        width = 82,
        height = 18,
        items = {
            { label = "None", value = "" },
        },
        onValueChanged = function()
            if self._refreshingItemInspector then
                return
            end

            self:RefreshItemInspectorPendingSkillDropdown()
            if self.ItemInspectorPendingSkillDropdown and self.ItemInspectorPendingSkillDropdown.SetSelectedValue then
                self.ItemInspectorPendingSkillDropdown:SetSelectedValue("", true)
            end
        end,
    })
    self.ItemInspectorPendingSkillRow:AddChild(self.ItemInspectorPendingSkillDatasetDropdown)

    self.ItemInspectorPendingSkillDropdown = UI.CreateDropdown(self.ItemInspectorPendingSkillRow:GetFrame(), "RPEDataEditorItemInspectorPendingSkillDropdown", {
        width = 90,
        height = 18,
        items = {
            { label = "None", value = "" },
        },
    })
    self.ItemInspectorPendingSkillRow:AddChild(self.ItemInspectorPendingSkillDropdown)

    self.ItemInspectorPendingSkillValueInput = UI.CreateTextInput(self.ItemInspectorPendingSkillRow:GetFrame(), "RPEDataEditorItemInspectorPendingSkillValueInput", {
        width = 46,
        height = 18,
        text = "0",
        borderColor = UI.ResolveColor(nil, "panel.border"),
    })
    self.ItemInspectorPendingSkillRow:AddChild(self.ItemInspectorPendingSkillValueInput)

    self.ItemInspectorAddSkillButton = UI.CreateButton(self.ItemInspectorPendingSkillRow:GetFrame(), "RPEDataEditorItemInspectorAddSkillButton", "Add", 36, function()
        if self._refreshingItemInspector then
            return
        end

        local skillRef = self.ItemInspectorPendingSkillDropdown and self.ItemInspectorPendingSkillDropdown.GetSelectedValue and self.ItemInspectorPendingSkillDropdown:GetSelectedValue() or ""
        if skillRef == "" then
            return
        end

        local value = tonumber(self.ItemInspectorPendingSkillValueInput and self.ItemInspectorPendingSkillValueInput:GetText()) or 0
        self:CommitSelectedItem(function(item)
            local bonuses = normalizeItemSkillBonuses(item)
            bonuses[#bonuses + 1] = {
                skillRef = skillRef,
                value = value,
            }
            item.skillBonuses = bonuses
        end)
    end, {
        height = 18,
        fontSize = 7,
    })
    self.ItemInspectorPendingSkillRow:AddChild(self.ItemInspectorAddSkillButton)
end

function DataEditor:BuildItemInspectorStatsPage(page)
    return buildStatsPage(self, page)
end
