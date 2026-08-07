local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Client.UI = Addon.Client.UI or {}
Addon.Client.UI.Editor = Addon.Client.UI.Editor or {}

local DataEditor = Addon.Client.UI.Editor
local UI = Addon.UI or {}

function DataEditor:SetSelectedUnitInspectorStatIndex(index)
    local _, unit = self:GetSelectedUnitAndDataset()
    local stats = unit and unit.stats or {}
    index = tonumber(index)

    if not index or not stats[index] then
        self.SelectedUnitInspectorStatIndex = nil
    else
        self.SelectedUnitInspectorStatIndex = index
    end
end

function DataEditor:GetSelectedUnitInspectorStat()
    local _, unit = self:GetSelectedUnitAndDataset()
    local stats = unit and unit.stats or {}
    local index = tonumber(self.SelectedUnitInspectorStatIndex)
    if not index or not stats[index] then
        return nil, nil
    end

    return stats[index], index
end

function DataEditor:RefreshUnitInspectorStatEditor()
    local stat, index = self:GetSelectedUnitInspectorStat()

    if self.UnitInspectorPendingStatDropdown then
        if stat and self.UnitInspectorPendingStatDropdown.SetSelectedValue then
            self.UnitInspectorPendingStatDropdown:SetSelectedValue(stat.statRef or "", true)
        else
            self.UnitInspectorPendingStatDropdown:SetSelectedValue("", true)
        end
    end

    if self.UnitInspectorPendingStatValueInput then
        self.UnitInspectorPendingStatValueInput:SetText(tostring(stat and stat.value or 0))
    end

    if self.UnitInspectorAddStatButton and self.UnitInspectorAddStatButton.SetText then
        self.UnitInspectorAddStatButton:SetText(index and "Apply" or "Add")
    end
end

function DataEditor:UnitInspectorHasDuplicateStatRef(statRef, ignoreIndex)
    local _, unit = self:GetSelectedUnitAndDataset()
    if type(statRef) ~= "string" or statRef == "" then
        return false
    end

    for index = 1, #(unit and unit.stats or {}) do
        local entry = unit.stats[index]
        if index ~= ignoreIndex and entry and entry.statRef == statRef then
            return true
        end
    end

    return false
end

function DataEditor:EnsureUnitInspectorResistanceContextMenu()
    if self.UnitInspectorResistanceContextMenu then
        return self.UnitInspectorResistanceContextMenu
    end

    self.UnitInspectorResistanceContextMenu = UI.ContextMenu:New({
        name = "RPEDataEditorUnitInspectorResistanceContextMenu",
        width = 120,
        panelWidth = 120,
        visibleRows = 2,
        rowHeight = 18,
        border = false,
        onItemInvoked = function(item, menu)
            if not item or item.value ~= "remove-resistance" or not self.ContextMenuUnitResistanceIndex then
                return
            end

            local removeIndex = self.ContextMenuUnitResistanceIndex
            self:CommitSelectedUnit(function(unit)
                table.remove(unit.resistances or {}, removeIndex)
            end)

            if menu and menu.HideMenus then
                menu:HideMenus()
            end
        end,
    })
    self.UnitInspectorResistanceContextMenu:SetParent(self.UnitInspectorPage or UIParent)
    self.UnitInspectorResistanceContextMenu:Create()
    return self.UnitInspectorResistanceContextMenu
end

function DataEditor:ShowUnitInspectorResistanceContextMenu(anchorFrame, rowData)
    if not rowData or not rowData.rowIndex then
        return
    end

    local menu = self:EnsureUnitInspectorResistanceContextMenu()
    self.ContextMenuUnitResistanceIndex = rowData.rowIndex
    menu:SetItems({
        { label = "Remove", value = "remove-resistance" },
    })
    menu:ShowAt(anchorFrame)
end

function DataEditor:EnsureUnitInspectorStatContextMenu()
    if self.UnitInspectorStatContextMenu then
        return self.UnitInspectorStatContextMenu
    end

    self.UnitInspectorStatContextMenu = UI.ContextMenu:New({
        name = "RPEDataEditorUnitInspectorStatContextMenu",
        width = 120,
        panelWidth = 120,
        visibleRows = 2,
        rowHeight = 18,
        border = false,
        onItemInvoked = function(item, menu)
            if not item or item.value ~= "remove-stat" or not self.ContextMenuUnitStatIndex then
                return
            end

            local removeIndex = self.ContextMenuUnitStatIndex
            self:CommitSelectedUnit(function(unit)
                table.remove(unit.stats or {}, removeIndex)
            end)
            self:SetSelectedUnitInspectorStatIndex(nil)
            self:RefreshUnitInspectorStatEditor()

            if menu and menu.HideMenus then
                menu:HideMenus()
            end
        end,
    })
    self.UnitInspectorStatContextMenu:SetParent(self.UnitInspectorPage or UIParent)
    self.UnitInspectorStatContextMenu:Create()
    return self.UnitInspectorStatContextMenu
end

function DataEditor:ShowUnitInspectorStatContextMenu(anchorFrame, rowData)
    if not rowData or not rowData.rowIndex then
        return
    end

    local menu = self:EnsureUnitInspectorStatContextMenu()
    self.ContextMenuUnitStatIndex = rowData.rowIndex
    menu:SetItems({
        { label = "Remove", value = "remove-stat" },
    })
    menu:ShowAt(anchorFrame)
end

function DataEditor:BuildUnitInspectorStatRows(unit)
    local rows = {}

    for index = 1, #(unit and unit.stats or {}) do
        local entry = unit.stats[index]
        rows[#rows + 1] = {
            rowIndex = index,
            statText = self:ResolveUnitInspectorReferenceLabel("stats", entry and entry.statRef or ""),
            valueText = tostring(entry and entry.value or 0),
        }
    end

    return rows
end

function DataEditor:RefreshUnitInspectorStatsTable()
    local _, unit = self:GetSelectedUnitAndDataset()
    if self.UnitInspectorStatsScroll and self.UnitInspectorStatsScroll.SetItems then
        self.UnitInspectorStatsScroll:SetItems(self:BuildUnitInspectorStatRows(unit))
    end
    self:SetSelectedUnitInspectorStatIndex(self.SelectedUnitInspectorStatIndex)
    self:RefreshUnitInspectorStatEditor()
end

function DataEditor:BuildUnitInspectorResistanceRows(unit)
    local rows = {}

    for index = 1, #(unit and unit.resistances or {}) do
        local entry = unit.resistances[index]
        rows[#rows + 1] = {
            rowIndex = index,
            resistanceText = self:ResolveUnitInspectorReferenceLabel("damageSchools", entry and entry.damageSchoolRef or ""),
            coefficientText = tostring(entry and entry.coefficient or 0),
        }
    end

    return rows
end

function DataEditor:RefreshUnitInspectorResistancesTable()
    local _, unit = self:GetSelectedUnitAndDataset()
    if self.UnitInspectorResistancesScroll and self.UnitInspectorResistancesScroll.SetItems then
        self.UnitInspectorResistancesScroll:SetItems(self:BuildUnitInspectorResistanceRows(unit))
    end
end

function DataEditor:BuildUnitInspectorStatsPage(page)
    local root = UI.CreateLayout(UI.VerticalLayoutGroup, page, "RPEDataEditorUnitInspectorStatsLayout", {
        spacing = 6,
        fitChildrenWidth = true,
        fitChildrenHeight = false,
    })
    UI.Utils.AnchorFill(root, page, 0, 0, 0, 0)

    root:AddChild(self:BuildUnitInspectorLabel(root:GetFrame(), "RPEDataEditorUnitInspectorStatsLabel", "Stats"))

    self.UnitInspectorStatsPanel = UI.CreatePanel(root:GetFrame(), "RPEDataEditorUnitInspectorStatsPanel", {
        width = self.UnitInspectorFieldWidth,
        height = 128,
        contentInset = 1,
        showBorder = true,
    })
    root:AddChild(self.UnitInspectorStatsPanel)

    self.UnitInspectorStatsScroll = UI.ScrollLayout:New({
        name = "RPEDataEditorUnitInspectorStatsScroll",
        width = self.UnitInspectorFieldWidth,
        height = 126,
        visibleRows = 7,
        rowHeight = 18,
        rowSpacing = 0,
        border = false,
        rowElementClass = UI.TableRow,
    })
    self.UnitInspectorStatsScroll:SetParent(self.UnitInspectorStatsPanel:GetContentFrame())
    self.UnitInspectorStatsScroll:SetRowRenderer(function(row, item, itemIndex)
        if row.SetColumns then
            row:SetColumns({
                { key = "statText", width = 184, justifyH = "LEFT" },
                { key = "valueText", width = 36, justifyH = "RIGHT" },
            })
        end
        if row.SetRowData then
            row:SetRowData(item, itemIndex or 0)
        end
        if row.SetRowMouseUpHandler then
            row:SetRowMouseUpHandler(function(tableRow, button, rowData)
                if button == "LeftButton" then
                    self:SetSelectedUnitInspectorStatIndex(rowData and rowData.rowIndex or nil)
                    self:RefreshUnitInspectorStatEditor()
                elseif button == "RightButton" then
                    local anchor = tableRow and tableRow.GetFrame and tableRow:GetFrame() or nil
                    self:ShowUnitInspectorStatContextMenu(anchor, rowData)
                end
            end)
        end
    end)
    self.UnitInspectorStatsScroll:Create()
    UI.Utils.AnchorFill(self.UnitInspectorStatsScroll, self.UnitInspectorStatsPanel:GetContentFrame(), 0, 0, 0, 0)

    self.UnitInspectorPendingStatRow = UI.CreateLayout(UI.HorizontalLayoutGroup, root:GetFrame(), "RPEDataEditorUnitInspectorPendingStatRow", {
        width = self.UnitInspectorFieldWidth,
        height = 18,
        spacing = 2,
        fitChildrenWidth = false,
        fitChildrenHeight = false,
    })
    root:AddChild(self.UnitInspectorPendingStatRow)

    self.UnitInspectorPendingStatDropdown = UI.CreateDropdown(self.UnitInspectorPendingStatRow:GetFrame(), "RPEDataEditorUnitInspectorPendingStatDropdown", {
        width = 154,
        height = 18,
        items = {
            { label = "None", value = "" },
        },
    })
    self.UnitInspectorPendingStatRow:AddChild(self.UnitInspectorPendingStatDropdown)

    self.UnitInspectorPendingStatValueInput = UI.CreateTextInput(self.UnitInspectorPendingStatRow:GetFrame(), "RPEDataEditorUnitInspectorPendingStatValueInput", {
        width = 42,
        height = 18,
        text = "0",
        borderColor = UI.ResolveColor(nil, "panel.border"),
    })
    self.UnitInspectorPendingStatRow:AddChild(self.UnitInspectorPendingStatValueInput)

    self.UnitInspectorAddStatButton = UI.CreateButton(self.UnitInspectorPendingStatRow:GetFrame(), "RPEDataEditorUnitInspectorAddStatButton", "Add", 36, function()
        if self._refreshingUnitInspector then
            return
        end

        local statRef = self.UnitInspectorPendingStatDropdown and self.UnitInspectorPendingStatDropdown.GetSelectedValue and self.UnitInspectorPendingStatDropdown:GetSelectedValue() or ""
        if statRef == "" then
            return
        end

        local _, selectedIndex = self:GetSelectedUnitInspectorStat()
        if self:UnitInspectorHasDuplicateStatRef(statRef, selectedIndex) then
            return
        end

        local value = tonumber(self.UnitInspectorPendingStatValueInput and self.UnitInspectorPendingStatValueInput:GetText()) or 0
        self:CommitSelectedUnit(function(unit)
            unit.stats = unit.stats or {}
            if selectedIndex and unit.stats[selectedIndex] then
                unit.stats[selectedIndex].statRef = statRef
                unit.stats[selectedIndex].value = value
            else
                unit.stats[#unit.stats + 1] = {
                    statRef = statRef,
                    value = value,
                }
            end
        end)
        self:SetSelectedUnitInspectorStatIndex(nil)
        self:RefreshUnitInspectorStatEditor()
    end, {
        height = 18,
        fontSize = 7,
    })
    self.UnitInspectorPendingStatRow:AddChild(self.UnitInspectorAddStatButton)

    root:AddChild(self:BuildUnitInspectorLabel(root:GetFrame(), "RPEDataEditorUnitInspectorResistancesLabel", "Resistances"))

    self.UnitInspectorResistancesPanel = UI.CreatePanel(root:GetFrame(), "RPEDataEditorUnitInspectorResistancesPanel", {
        width = self.UnitInspectorFieldWidth,
        height = 92,
        contentInset = 1,
        showBorder = true,
    })
    root:AddChild(self.UnitInspectorResistancesPanel)

    self.UnitInspectorResistancesScroll = UI.ScrollLayout:New({
        name = "RPEDataEditorUnitInspectorResistancesScroll",
        width = self.UnitInspectorFieldWidth,
        height = 90,
        visibleRows = 5,
        rowHeight = 18,
        rowSpacing = 0,
        border = false,
        rowElementClass = UI.TableRow,
    })
    self.UnitInspectorResistancesScroll:SetParent(self.UnitInspectorResistancesPanel:GetContentFrame())
    self.UnitInspectorResistancesScroll:SetRowRenderer(function(row, item, itemIndex)
        if row.SetColumns then
            row:SetColumns({
                { key = "resistanceText", width = 184, justifyH = "LEFT" },
                { key = "coefficientText", width = 36, justifyH = "RIGHT" },
            })
        end
        if row.SetRowData then
            row:SetRowData(item, itemIndex or 0)
        end
        if row.SetRowMouseUpHandler then
            row:SetRowMouseUpHandler(function(tableRow, button, rowData)
                if button == "RightButton" then
                    local anchor = tableRow and tableRow.GetFrame and tableRow:GetFrame() or nil
                    self:ShowUnitInspectorResistanceContextMenu(anchor, rowData)
                end
            end)
        end
    end)
    self.UnitInspectorResistancesScroll:Create()
    UI.Utils.AnchorFill(self.UnitInspectorResistancesScroll, self.UnitInspectorResistancesPanel:GetContentFrame(), 0, 0, 0, 0)

    self.UnitInspectorPendingResistanceRow = UI.CreateLayout(UI.HorizontalLayoutGroup, root:GetFrame(), "RPEDataEditorUnitInspectorPendingResistanceRow", {
        width = self.UnitInspectorFieldWidth,
        height = 18,
        spacing = 2,
        fitChildrenWidth = false,
        fitChildrenHeight = false,
    })
    root:AddChild(self.UnitInspectorPendingResistanceRow)

    self.UnitInspectorPendingResistanceDropdown = UI.CreateDropdown(self.UnitInspectorPendingResistanceRow:GetFrame(), "RPEDataEditorUnitInspectorPendingResistanceDropdown", {
        width = 154,
        height = 18,
        items = {
            { label = "None", value = "" },
        },
    })
    self.UnitInspectorPendingResistanceRow:AddChild(self.UnitInspectorPendingResistanceDropdown)

    self.UnitInspectorPendingResistanceCoefficientInput = UI.CreateTextInput(self.UnitInspectorPendingResistanceRow:GetFrame(), "RPEDataEditorUnitInspectorPendingResistanceCoefficientInput", {
        width = 42,
        height = 18,
        text = "0",
        borderColor = UI.ResolveColor(nil, "panel.border"),
    })
    self.UnitInspectorPendingResistanceRow:AddChild(self.UnitInspectorPendingResistanceCoefficientInput)

    self.UnitInspectorAddResistanceButton = UI.CreateButton(self.UnitInspectorPendingResistanceRow:GetFrame(), "RPEDataEditorUnitInspectorAddResistanceButton", "Add", 36, function()
        if self._refreshingUnitInspector then
            return
        end

        local damageSchoolRef = self.UnitInspectorPendingResistanceDropdown and self.UnitInspectorPendingResistanceDropdown.GetSelectedValue and self.UnitInspectorPendingResistanceDropdown:GetSelectedValue() or ""
        if damageSchoolRef == "" then
            return
        end

        local coefficient = tonumber(self.UnitInspectorPendingResistanceCoefficientInput and self.UnitInspectorPendingResistanceCoefficientInput:GetText()) or 0
        self:CommitSelectedUnit(function(unit)
            unit.resistances = unit.resistances or {}
            unit.resistances[#unit.resistances + 1] = {
                damageSchoolRef = damageSchoolRef,
                coefficient = coefficient,
            }
        end)
    end, {
        height = 18,
        fontSize = 7,
    })
    self.UnitInspectorPendingResistanceRow:AddChild(self.UnitInspectorAddResistanceButton)

    self:RefreshUnitInspectorStatEditor()
end
