local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Client.UI = Addon.Client.UI or {}
Addon.Client.UI.Editor = Addon.Client.UI.Editor or {}

local DataEditor = Addon.Client.UI.Editor
local UI = Addon.UI or {}

function DataEditor:SetSelectedMountInspectorStatIndex(index)
    local _, mount = self:GetSelectedMountAndDataset()
    local stats = mount and mount.stats or {}
    index = tonumber(index)

    if not index or not stats[index] then
        self.SelectedMountInspectorStatIndex = nil
    else
        self.SelectedMountInspectorStatIndex = index
    end
end

function DataEditor:GetSelectedMountInspectorStat()
    local _, mount = self:GetSelectedMountAndDataset()
    local stats = mount and mount.stats or {}
    local index = tonumber(self.SelectedMountInspectorStatIndex)
    if not index or not stats[index] then
        return nil, nil
    end

    return stats[index], index
end

function DataEditor:RefreshMountInspectorStatEditor()
    local stat, index = self:GetSelectedMountInspectorStat()

    if self.MountInspectorPendingStatDropdown then
        if stat and self.MountInspectorPendingStatDropdown.SetSelectedValue then
            self.MountInspectorPendingStatDropdown:SetSelectedValue(stat.statRef or "", true)
        else
            self.MountInspectorPendingStatDropdown:SetSelectedValue("", true)
        end
    end

    if self.MountInspectorPendingStatValueInput then
        self.MountInspectorPendingStatValueInput:SetText(tostring(stat and stat.value or 0))
    end

    if self.MountInspectorAddStatButton and self.MountInspectorAddStatButton.SetText then
        self.MountInspectorAddStatButton:SetText(index and "Apply" or "Add")
    end
end

function DataEditor:MountInspectorHasDuplicateStatRef(statRef, ignoreIndex)
    local _, mount = self:GetSelectedMountAndDataset()
    if type(statRef) ~= "string" or statRef == "" then
        return false
    end

    for index = 1, #(mount and mount.stats or {}) do
        local entry = mount.stats[index]
        if index ~= ignoreIndex and entry and entry.statRef == statRef then
            return true
        end
    end

    return false
end

function DataEditor:EnsureMountInspectorStatContextMenu()
    if self.MountInspectorStatContextMenu then
        return self.MountInspectorStatContextMenu
    end

    self.MountInspectorStatContextMenu = UI.ContextMenu:New({
        name = "RPEDataEditorMountInspectorStatContextMenu",
        width = 120,
        panelWidth = 120,
        visibleRows = 1,
        rowHeight = 18,
        border = false,
        onItemInvoked = function(item, menu)
            if not item or item.value ~= "remove-stat" or not self.ContextMenuMountStatIndex then
                return
            end

            local removeIndex = self.ContextMenuMountStatIndex
            self:CommitSelectedMount(function(mount)
                table.remove(mount.stats or {}, removeIndex)
            end)
            self:SetSelectedMountInspectorStatIndex(nil)
            self:RefreshMountInspectorStatEditor()

            if menu and menu.HideMenus then
                menu:HideMenus()
            end
        end,
    })
    self.MountInspectorStatContextMenu:SetParent(self.MountInspectorPage or UIParent)
    self.MountInspectorStatContextMenu:Create()
    return self.MountInspectorStatContextMenu
end

function DataEditor:ShowMountInspectorStatContextMenu(anchorFrame, rowData)
    if not rowData or not rowData.rowIndex then
        return
    end

    local menu = self:EnsureMountInspectorStatContextMenu()
    self.ContextMenuMountStatIndex = rowData.rowIndex
    menu:SetItems({
        { label = "Remove", value = "remove-stat" },
    })
    menu:ShowAt(anchorFrame)
end

function DataEditor:BuildMountInspectorStatRows(mount)
    local rows = {}

    for index = 1, #(mount and mount.stats or {}) do
        local entry = mount.stats[index]
        rows[#rows + 1] = {
            rowIndex = index,
            statText = self:ResolveUnitInspectorReferenceLabel("stats", entry and entry.statRef or ""),
            valueText = tostring(entry and entry.value or 0),
        }
    end

    return rows
end

function DataEditor:RefreshMountInspectorStatsTable()
    local _, mount = self:GetSelectedMountAndDataset()
    if self.MountInspectorStatsScroll and self.MountInspectorStatsScroll.SetItems then
        self.MountInspectorStatsScroll:SetItems(self:BuildMountInspectorStatRows(mount))
    end
    self:SetSelectedMountInspectorStatIndex(self.SelectedMountInspectorStatIndex)
    self:RefreshMountInspectorStatEditor()
end

function DataEditor:BuildMountInspectorStatsPage(page)
    local root = UI.CreateLayout(UI.VerticalLayoutGroup, page, "RPEDataEditorMountInspectorStatsLayout", {
        spacing = 6,
        fitChildrenWidth = true,
        fitChildrenHeight = false,
    })
    UI.Utils.AnchorFill(root, page, 0, 0, 0, 0)

    root:AddChild(self:BuildMountInspectorLabel(root:GetFrame(), "RPEDataEditorMountInspectorStatsLabel", "Mounted Stat Bonuses"))

    self.MountInspectorStatsPanel = UI.CreatePanel(root:GetFrame(), "RPEDataEditorMountInspectorStatsPanel", {
        width = self.MountInspectorFieldWidth,
        height = 146,
        contentInset = 1,
        showBorder = true,
    })
    root:AddChild(self.MountInspectorStatsPanel)

    self.MountInspectorStatsScroll = UI.ScrollLayout:New({
        name = "RPEDataEditorMountInspectorStatsScroll",
        width = self.MountInspectorFieldWidth,
        height = 144,
        visibleRows = 8,
        rowHeight = 18,
        rowSpacing = 0,
        border = false,
        rowElementClass = UI.TableRow,
    })
    self.MountInspectorStatsScroll:SetParent(self.MountInspectorStatsPanel:GetContentFrame())
    self.MountInspectorStatsScroll:SetRowRenderer(function(row, item, itemIndex)
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
                    self:SetSelectedMountInspectorStatIndex(rowData and rowData.rowIndex or nil)
                    self:RefreshMountInspectorStatEditor()
                elseif button == "RightButton" then
                    local anchor = tableRow and tableRow.GetFrame and tableRow:GetFrame() or nil
                    self:ShowMountInspectorStatContextMenu(anchor, rowData)
                end
            end)
        end
    end)
    self.MountInspectorStatsScroll:Create()
    UI.Utils.AnchorFill(self.MountInspectorStatsScroll, self.MountInspectorStatsPanel:GetContentFrame(), 0, 0, 0, 0)

    self.MountInspectorPendingStatRow = UI.CreateLayout(UI.HorizontalLayoutGroup, root:GetFrame(), "RPEDataEditorMountInspectorPendingStatRow", {
        width = self.MountInspectorFieldWidth,
        height = 18,
        spacing = 2,
        fitChildrenWidth = false,
        fitChildrenHeight = false,
    })
    root:AddChild(self.MountInspectorPendingStatRow)

    self.MountInspectorPendingStatDropdown = UI.CreateDropdown(self.MountInspectorPendingStatRow:GetFrame(), "RPEDataEditorMountInspectorPendingStatDropdown", {
        width = 154,
        height = 18,
        items = {
            { label = "None", value = "" },
        },
    })
    self.MountInspectorPendingStatRow:AddChild(self.MountInspectorPendingStatDropdown)

    self.MountInspectorPendingStatValueInput = UI.CreateTextInput(self.MountInspectorPendingStatRow:GetFrame(), "RPEDataEditorMountInspectorPendingStatValueInput", {
        width = 42,
        height = 18,
        text = "0",
        borderColor = UI.ResolveColor(nil, "panel.border"),
    })
    self.MountInspectorPendingStatRow:AddChild(self.MountInspectorPendingStatValueInput)

    self.MountInspectorAddStatButton = UI.CreateButton(self.MountInspectorPendingStatRow:GetFrame(), "RPEDataEditorMountInspectorAddStatButton", "Add", 36, function()
        if self._refreshingMountInspector then
            return
        end

        local statRef = self.MountInspectorPendingStatDropdown and self.MountInspectorPendingStatDropdown.GetSelectedValue and self.MountInspectorPendingStatDropdown:GetSelectedValue() or ""
        if statRef == "" then
            return
        end

        local _, selectedIndex = self:GetSelectedMountInspectorStat()
        if self:MountInspectorHasDuplicateStatRef(statRef, selectedIndex) then
            return
        end

        local value = tonumber(self.MountInspectorPendingStatValueInput and self.MountInspectorPendingStatValueInput:GetText()) or 0
        self:CommitSelectedMount(function(mount)
            mount.stats = mount.stats or {}
            if selectedIndex and mount.stats[selectedIndex] then
                mount.stats[selectedIndex].statRef = statRef
                mount.stats[selectedIndex].value = value
            else
                mount.stats[#mount.stats + 1] = {
                    statRef = statRef,
                    value = value,
                }
            end
        end)
        self:SetSelectedMountInspectorStatIndex(nil)
        self:RefreshMountInspectorStatEditor()
    end, {
        height = 18,
        fontSize = 7,
    })
    self.MountInspectorPendingStatRow:AddChild(self.MountInspectorAddStatButton)

    self:RefreshMountInspectorStatEditor()
end
