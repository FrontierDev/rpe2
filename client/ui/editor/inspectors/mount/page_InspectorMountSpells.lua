local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Client.UI = Addon.Client.UI or {}
Addon.Client.UI.Editor = Addon.Client.UI.Editor or {}

local DataEditor = Addon.Client.UI.Editor
local UI = Addon.UI or {}

function DataEditor:EnsureMountInspectorSpellContextMenu()
    if self.MountInspectorSpellContextMenu then
        return self.MountInspectorSpellContextMenu
    end

    self.MountInspectorSpellContextMenu = UI.ContextMenu:New({
        name = "RPEDataEditorMountInspectorSpellContextMenu",
        width = 120,
        panelWidth = 120,
        visibleRows = 1,
        rowHeight = 18,
        border = false,
        onItemInvoked = function(item, menu)
            if not item or item.value ~= "remove-spell" or not self.ContextMenuMountSpellIndex then
                return
            end

            local removeIndex = self.ContextMenuMountSpellIndex
            self:CommitSelectedMount(function(mount)
                table.remove(mount.spells or {}, removeIndex)
            end)

            if menu and menu.HideMenus then
                menu:HideMenus()
            end
        end,
    })
    self.MountInspectorSpellContextMenu:SetParent(self.MountInspectorPage or UIParent)
    self.MountInspectorSpellContextMenu:Create()
    return self.MountInspectorSpellContextMenu
end

function DataEditor:ShowMountInspectorSpellContextMenu(anchorFrame, rowData)
    if not rowData or not rowData.rowIndex then
        return
    end

    local menu = self:EnsureMountInspectorSpellContextMenu()
    self.ContextMenuMountSpellIndex = rowData.rowIndex
    menu:SetItems({
        { label = "Remove", value = "remove-spell" },
    })
    menu:ShowAt(anchorFrame)
end

function DataEditor:BuildMountInspectorSpellRows(mount)
    local rows = {}

    for index = 1, #(mount and mount.spells or {}) do
        local spellRef = mount.spells[index]
        rows[#rows + 1] = {
            rowIndex = index,
            spellText = self:ResolveUnitInspectorReferenceLabel("spells", spellRef),
        }
    end

    return rows
end

function DataEditor:RefreshMountInspectorSpellsTable()
    local _, mount = self:GetSelectedMountAndDataset()
    if self.MountInspectorSpellsScroll and self.MountInspectorSpellsScroll.SetItems then
        self.MountInspectorSpellsScroll:SetItems(self:BuildMountInspectorSpellRows(mount))
    end
end

function DataEditor:BuildMountInspectorSpellsPage(page)
    local root = UI.CreateLayout(UI.VerticalLayoutGroup, page, "RPEDataEditorMountInspectorSpellsLayout", {
        spacing = 6,
        fitChildrenWidth = true,
        fitChildrenHeight = false,
    })
    UI.Utils.AnchorFill(root, page, 0, 0, 0, 0)

    root:AddChild(self:BuildMountInspectorLabel(root:GetFrame(), "RPEDataEditorMountInspectorSpellsLabel", "Mounted Action Bar Spells"))

    self.MountInspectorSpellsPanel = UI.CreatePanel(root:GetFrame(), "RPEDataEditorMountInspectorSpellsPanel", {
        width = self.MountInspectorFieldWidth,
        height = 146,
        contentInset = 1,
        showBorder = true,
    })
    root:AddChild(self.MountInspectorSpellsPanel)

    self.MountInspectorSpellsScroll = UI.ScrollLayout:New({
        name = "RPEDataEditorMountInspectorSpellsScroll",
        width = self.MountInspectorFieldWidth,
        height = 144,
        visibleRows = 8,
        rowHeight = 18,
        rowSpacing = 0,
        border = false,
        rowElementClass = UI.TableRow,
    })
    self.MountInspectorSpellsScroll:SetParent(self.MountInspectorSpellsPanel:GetContentFrame())
    self.MountInspectorSpellsScroll:SetRowRenderer(function(row, item, itemIndex)
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
                    self:ShowMountInspectorSpellContextMenu(anchor, rowData)
                end
            end)
        end
    end)
    self.MountInspectorSpellsScroll:Create()
    UI.Utils.AnchorFill(self.MountInspectorSpellsScroll, self.MountInspectorSpellsPanel:GetContentFrame(), 0, 0, 0, 0)

    self.MountInspectorPendingSpellRow = UI.CreateLayout(UI.HorizontalLayoutGroup, root:GetFrame(), "RPEDataEditorMountInspectorPendingSpellRow", {
        width = self.MountInspectorFieldWidth,
        height = 18,
        spacing = 2,
        fitChildrenWidth = false,
        fitChildrenHeight = false,
    })
    root:AddChild(self.MountInspectorPendingSpellRow)

    self.MountInspectorPendingSpellDropdown = UI.CreateDropdown(self.MountInspectorPendingSpellRow:GetFrame(), "RPEDataEditorMountInspectorPendingSpellDropdown", {
        width = 198,
        height = 18,
        items = {
            { label = "None", value = "" },
        },
    })
    self.MountInspectorPendingSpellRow:AddChild(self.MountInspectorPendingSpellDropdown)

    self.MountInspectorAddSpellButton = UI.CreateButton(self.MountInspectorPendingSpellRow:GetFrame(), "RPEDataEditorMountInspectorAddSpellButton", "Add", 36, function()
        if self._refreshingMountInspector then
            return
        end

        local spellRef = self.MountInspectorPendingSpellDropdown and self.MountInspectorPendingSpellDropdown.GetSelectedValue and self.MountInspectorPendingSpellDropdown:GetSelectedValue() or ""
        if spellRef == "" then
            return
        end

        self:CommitSelectedMount(function(mount)
            mount.spells = mount.spells or {}
            mount.spells[#mount.spells + 1] = spellRef
        end)
    end, {
        height = 18,
        fontSize = 7,
    })
    self.MountInspectorPendingSpellRow:AddChild(self.MountInspectorAddSpellButton)
end
