local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Client.UI = Addon.Client.UI or {}
Addon.Client.UI.Editor = Addon.Client.UI.Editor or {}

local DataEditor = Addon.Client.UI.Editor
local UI = Addon.UI or {}

function DataEditor:EnsureUnitInspectorSpellContextMenu()
    if self.UnitInspectorSpellContextMenu then
        return self.UnitInspectorSpellContextMenu
    end

    self.UnitInspectorSpellContextMenu = UI.ContextMenu:New({
        name = "RPEDataEditorUnitInspectorSpellContextMenu",
        width = 120,
        panelWidth = 120,
        visibleRows = 2,
        rowHeight = 18,
        border = false,
        onItemInvoked = function(item, menu)
            if not item or item.value ~= "remove-spell" or not self.ContextMenuUnitSpellIndex then
                return
            end

            local removeIndex = self.ContextMenuUnitSpellIndex
            self:CommitSelectedUnit(function(unit)
                table.remove(unit.spells or {}, removeIndex)
            end)

            if menu and menu.HideMenus then
                menu:HideMenus()
            end
        end,
    })
    self.UnitInspectorSpellContextMenu:SetParent(self.UnitInspectorPage or UIParent)
    self.UnitInspectorSpellContextMenu:Create()
    return self.UnitInspectorSpellContextMenu
end

function DataEditor:ShowUnitInspectorSpellContextMenu(anchorFrame, rowData)
    if not rowData or not rowData.rowIndex then
        return
    end

    local menu = self:EnsureUnitInspectorSpellContextMenu()
    self.ContextMenuUnitSpellIndex = rowData.rowIndex
    menu:SetItems({
        { label = "Remove", value = "remove-spell" },
    })
    menu:ShowAt(anchorFrame)
end

function DataEditor:BuildUnitInspectorSpellRows(unit)
    local rows = {}

    for index = 1, #(unit and unit.spells or {}) do
        local spellRef = unit.spells[index]
        rows[#rows + 1] = {
            rowIndex = index,
            spellText = self:ResolveUnitInspectorReferenceLabel("spells", spellRef),
        }
    end

    return rows
end

function DataEditor:RefreshUnitInspectorSpellsTable()
    local _, unit = self:GetSelectedUnitAndDataset()
    if self.UnitInspectorSpellsScroll and self.UnitInspectorSpellsScroll.SetItems then
        self.UnitInspectorSpellsScroll:SetItems(self:BuildUnitInspectorSpellRows(unit))
    end
end

function DataEditor:BuildUnitInspectorSpellsPage(page)
    local root = UI.CreateLayout(UI.VerticalLayoutGroup, page, "RPEDataEditorUnitInspectorSpellsLayout", {
        spacing = 6,
        fitChildrenWidth = true,
        fitChildrenHeight = false,
    })
    UI.Utils.AnchorFill(root, page, 0, 0, 0, 0)

    root:AddChild(self:BuildUnitInspectorLabel(root:GetFrame(), "RPEDataEditorUnitInspectorSpellsLabel", "Spells"))

    self.UnitInspectorSpellsPanel = UI.CreatePanel(root:GetFrame(), "RPEDataEditorUnitInspectorSpellsPanel", {
        width = self.UnitInspectorFieldWidth,
        height = 128,
        contentInset = 1,
        showBorder = true,
    })
    root:AddChild(self.UnitInspectorSpellsPanel)

    self.UnitInspectorSpellsScroll = UI.ScrollLayout:New({
        name = "RPEDataEditorUnitInspectorSpellsScroll",
        width = self.UnitInspectorFieldWidth,
        height = 126,
        visibleRows = 7,
        rowHeight = 18,
        rowSpacing = 0,
        border = false,
        rowElementClass = UI.TableRow,
    })
    self.UnitInspectorSpellsScroll:SetParent(self.UnitInspectorSpellsPanel:GetContentFrame())
    self.UnitInspectorSpellsScroll:SetRowRenderer(function(row, item, itemIndex)
        if row.SetColumns then
            row:SetColumns({
                { key = "spellText", width = 220, justifyH = "LEFT" },
            })
        end
        if row.SetRowData then
            row:SetRowData(item, itemIndex or 0)
        end
        if row.SetRowMouseUpHandler then
            row:SetRowMouseUpHandler(function(tableRow, button, rowData)
                if button == "RightButton" then
                    local anchor = tableRow and tableRow.GetFrame and tableRow:GetFrame() or nil
                    self:ShowUnitInspectorSpellContextMenu(anchor, rowData)
                end
            end)
        end
    end)
    self.UnitInspectorSpellsScroll:Create()
    UI.Utils.AnchorFill(self.UnitInspectorSpellsScroll, self.UnitInspectorSpellsPanel:GetContentFrame(), 0, 0, 0, 0)

    self.UnitInspectorPendingSpellRow = UI.CreateLayout(UI.HorizontalLayoutGroup, root:GetFrame(), "RPEDataEditorUnitInspectorPendingSpellRow", {
        width = self.UnitInspectorFieldWidth,
        height = 18,
        spacing = 2,
        fitChildrenWidth = false,
        fitChildrenHeight = false,
    })
    root:AddChild(self.UnitInspectorPendingSpellRow)

    self.UnitInspectorPendingSpellDropdown = UI.CreateDropdown(self.UnitInspectorPendingSpellRow:GetFrame(), "RPEDataEditorUnitInspectorPendingSpellDropdown", {
        width = 198,
        height = 18,
        items = {
            { label = "None", value = "" },
        },
    })
    self.UnitInspectorPendingSpellRow:AddChild(self.UnitInspectorPendingSpellDropdown)

    self.UnitInspectorAddSpellButton = UI.CreateButton(self.UnitInspectorPendingSpellRow:GetFrame(), "RPEDataEditorUnitInspectorAddSpellButton", "Add", 36, function()
        if self._refreshingUnitInspector then
            return
        end

        local spellRef = self.UnitInspectorPendingSpellDropdown and self.UnitInspectorPendingSpellDropdown.GetSelectedValue and self.UnitInspectorPendingSpellDropdown:GetSelectedValue() or ""
        if spellRef == "" then
            return
        end

        self:CommitSelectedUnit(function(unit)
            unit.spells = unit.spells or {}
            unit.spells[#unit.spells + 1] = spellRef
        end)
    end, {
        height = 18,
        fontSize = 7,
    })
    self.UnitInspectorPendingSpellRow:AddChild(self.UnitInspectorAddSpellButton)
end
