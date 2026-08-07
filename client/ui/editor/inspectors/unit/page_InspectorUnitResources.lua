local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Client.UI = Addon.Client.UI or {}
Addon.Client.UI.Editor = Addon.Client.UI.Editor or {}

local DataEditor = Addon.Client.UI.Editor
local UI = Addon.UI or {}

function DataEditor:SetSelectedUnitInspectorResourceIndex(index)
    local _, unit = self:GetSelectedUnitAndDataset()
    local resources = unit and unit.resources or {}
    index = tonumber(index)

    if not index or not resources[index] then
        self.SelectedUnitInspectorResourceIndex = nil
    else
        self.SelectedUnitInspectorResourceIndex = index
    end
end

function DataEditor:GetSelectedUnitInspectorResource()
    local _, unit = self:GetSelectedUnitAndDataset()
    local resources = unit and unit.resources or {}
    local index = tonumber(self.SelectedUnitInspectorResourceIndex)
    if not index or not resources[index] then
        return nil, nil
    end

    return resources[index], index
end

function DataEditor:RefreshUnitInspectorResourceEditor()
    local resource, index = self:GetSelectedUnitInspectorResource()

    if self.UnitInspectorPendingResourceDropdown then
        if resource and self.UnitInspectorPendingResourceDropdown.SetSelectedValue then
            self.UnitInspectorPendingResourceDropdown:SetSelectedValue(resource.resourceRef or "", true)
        else
            self.UnitInspectorPendingResourceDropdown:SetSelectedValue("", true)
        end
    end

    if self.UnitInspectorPendingResourceValueInput then
        self.UnitInspectorPendingResourceValueInput:SetText(tostring(resource and resource.value or 0))
    end

    if self.UnitInspectorPendingResourcePerPlayerInput then
        self.UnitInspectorPendingResourcePerPlayerInput:SetText(tostring(resource and resource.perPlayer or 0))
    end

    if self.UnitInspectorAddResourceButton and self.UnitInspectorAddResourceButton.SetText then
        self.UnitInspectorAddResourceButton:SetText(index and "Apply" or "Add")
    end
end

function DataEditor:UnitInspectorHasDuplicateResourceRef(resourceRef, ignoreIndex)
    local _, unit = self:GetSelectedUnitAndDataset()
    if type(resourceRef) ~= "string" or resourceRef == "" then
        return false
    end

    for index = 1, #(unit and unit.resources or {}) do
        local entry = unit.resources[index]
        if index ~= ignoreIndex and entry and entry.resourceRef == resourceRef then
            return true
        end
    end

    return false
end

function DataEditor:EnsureUnitInspectorResourceContextMenu()
    if self.UnitInspectorResourceContextMenu then
        return self.UnitInspectorResourceContextMenu
    end

    self.UnitInspectorResourceContextMenu = UI.ContextMenu:New({
        name = "RPEDataEditorUnitInspectorResourceContextMenu",
        width = 120,
        panelWidth = 120,
        visibleRows = 2,
        rowHeight = 18,
        border = false,
        onItemInvoked = function(item, menu)
            if not item or item.value ~= "remove-resource" or not self.ContextMenuUnitResourceIndex then
                return
            end

            local removeIndex = self.ContextMenuUnitResourceIndex
            self:CommitSelectedUnit(function(unit)
                table.remove(unit.resources or {}, removeIndex)
            end)
            self:SetSelectedUnitInspectorResourceIndex(nil)
            self:RefreshUnitInspectorResourceEditor()

            if menu and menu.HideMenus then
                menu:HideMenus()
            end
        end,
    })
    self.UnitInspectorResourceContextMenu:SetParent(self.UnitInspectorPage or UIParent)
    self.UnitInspectorResourceContextMenu:Create()
    return self.UnitInspectorResourceContextMenu
end

function DataEditor:ShowUnitInspectorResourceContextMenu(anchorFrame, rowData)
    if not rowData or not rowData.rowIndex then
        return
    end

    local menu = self:EnsureUnitInspectorResourceContextMenu()
    self.ContextMenuUnitResourceIndex = rowData.rowIndex
    menu:SetItems({
        { label = "Remove", value = "remove-resource" },
    })
    menu:ShowAt(anchorFrame)
end

function DataEditor:BuildUnitInspectorResourceRows(unit)
    local rows = {}

    for index = 1, #(unit and unit.resources or {}) do
        local entry = unit.resources[index]
        rows[#rows + 1] = {
            rowIndex = index,
            resourceText = self:ResolveUnitInspectorReferenceLabel("resources", entry and entry.resourceRef or ""),
            valueText = tostring(entry and entry.value or 0),
            perPlayerText = tostring(entry and entry.perPlayer or 0),
        }
    end

    return rows
end

function DataEditor:RefreshUnitInspectorResourcesTable()
    local _, unit = self:GetSelectedUnitAndDataset()
    if self.UnitInspectorResourcesScroll and self.UnitInspectorResourcesScroll.SetItems then
        self.UnitInspectorResourcesScroll:SetItems(self:BuildUnitInspectorResourceRows(unit))
    end
    self:SetSelectedUnitInspectorResourceIndex(self.SelectedUnitInspectorResourceIndex)
    self:RefreshUnitInspectorResourceEditor()
end

function DataEditor:BuildUnitInspectorResourcesPage(page)
    local root = UI.CreateLayout(UI.VerticalLayoutGroup, page, "RPEDataEditorUnitInspectorResourcesLayout", {
        spacing = 6,
        fitChildrenWidth = true,
        fitChildrenHeight = false,
    })
    UI.Utils.AnchorFill(root, page, 0, 0, 0, 0)

    root:AddChild(self:BuildUnitInspectorLabel(root:GetFrame(), "RPEDataEditorUnitInspectorResourcesLabel", "Resources"))

    self.UnitInspectorResourcesPanel = UI.CreatePanel(root:GetFrame(), "RPEDataEditorUnitInspectorResourcesPanel", {
        width = self.UnitInspectorFieldWidth,
        height = 128,
        contentInset = 1,
        showBorder = true,
    })
    root:AddChild(self.UnitInspectorResourcesPanel)

    self.UnitInspectorResourcesScroll = UI.ScrollLayout:New({
        name = "RPEDataEditorUnitInspectorResourcesScroll",
        width = self.UnitInspectorFieldWidth,
        height = 126,
        visibleRows = 7,
        rowHeight = 18,
        rowSpacing = 0,
        border = false,
        rowElementClass = UI.TableRow,
    })
    self.UnitInspectorResourcesScroll:SetParent(self.UnitInspectorResourcesPanel:GetContentFrame())
    self.UnitInspectorResourcesScroll:SetRowRenderer(function(row, item, itemIndex)
        if row.SetColumns then
            row:SetColumns({
                { key = "resourceText", width = 148, justifyH = "LEFT" },
                { key = "valueText", width = 32, justifyH = "RIGHT" },
                { key = "perPlayerText", width = 36, justifyH = "RIGHT" },
            })
        end
        if row.SetRowData then
            row:SetRowData(item, itemIndex or 0)
        end
        if row.SetRowMouseUpHandler then
            row:SetRowMouseUpHandler(function(tableRow, button, rowData)
                if button == "LeftButton" then
                    self:SetSelectedUnitInspectorResourceIndex(rowData and rowData.rowIndex or nil)
                    self:RefreshUnitInspectorResourceEditor()
                elseif button == "RightButton" then
                    local anchor = tableRow and tableRow.GetFrame and tableRow:GetFrame() or nil
                    self:ShowUnitInspectorResourceContextMenu(anchor, rowData)
                end
            end)
        end
    end)
    self.UnitInspectorResourcesScroll:Create()
    UI.Utils.AnchorFill(self.UnitInspectorResourcesScroll, self.UnitInspectorResourcesPanel:GetContentFrame(), 0, 0, 0, 0)

    self.UnitInspectorPendingResourceRow = UI.CreateLayout(UI.HorizontalLayoutGroup, root:GetFrame(), "RPEDataEditorUnitInspectorPendingResourceRow", {
        width = self.UnitInspectorFieldWidth,
        height = 18,
        spacing = 2,
        fitChildrenWidth = false,
        fitChildrenHeight = false,
    })
    root:AddChild(self.UnitInspectorPendingResourceRow)

    self.UnitInspectorPendingResourceDropdown = UI.CreateDropdown(self.UnitInspectorPendingResourceRow:GetFrame(), "RPEDataEditorUnitInspectorPendingResourceDropdown", {
        width = 126,
        height = 18,
        items = {
            { label = "None", value = "" },
        },
    })
    self.UnitInspectorPendingResourceRow:AddChild(self.UnitInspectorPendingResourceDropdown)

    self.UnitInspectorPendingResourceValueInput = UI.CreateTextInput(self.UnitInspectorPendingResourceRow:GetFrame(), "RPEDataEditorUnitInspectorPendingResourceValueInput", {
        width = 30,
        height = 18,
        text = "0",
        borderColor = UI.ResolveColor(nil, "panel.border"),
    })
    self.UnitInspectorPendingResourceRow:AddChild(self.UnitInspectorPendingResourceValueInput)

    self.UnitInspectorPendingResourcePerPlayerInput = UI.CreateTextInput(self.UnitInspectorPendingResourceRow:GetFrame(), "RPEDataEditorUnitInspectorPendingResourcePerPlayerInput", {
        width = 30,
        height = 18,
        text = "0",
        borderColor = UI.ResolveColor(nil, "panel.border"),
    })
    self.UnitInspectorPendingResourceRow:AddChild(self.UnitInspectorPendingResourcePerPlayerInput)

    self.UnitInspectorAddResourceButton = UI.CreateButton(self.UnitInspectorPendingResourceRow:GetFrame(), "RPEDataEditorUnitInspectorAddResourceButton", "Add", 36, function()
        if self._refreshingUnitInspector then
            return
        end

        local resourceRef = self.UnitInspectorPendingResourceDropdown and self.UnitInspectorPendingResourceDropdown.GetSelectedValue and self.UnitInspectorPendingResourceDropdown:GetSelectedValue() or ""
        if resourceRef == "" then
            return
        end

        local _, selectedIndex = self:GetSelectedUnitInspectorResource()
        if self:UnitInspectorHasDuplicateResourceRef(resourceRef, selectedIndex) then
            return
        end

        local value = tonumber(self.UnitInspectorPendingResourceValueInput and self.UnitInspectorPendingResourceValueInput:GetText()) or 0
        local perPlayer = tonumber(self.UnitInspectorPendingResourcePerPlayerInput and self.UnitInspectorPendingResourcePerPlayerInput:GetText()) or 0
        self:CommitSelectedUnit(function(unit)
            unit.resources = unit.resources or {}
            if selectedIndex and unit.resources[selectedIndex] then
                unit.resources[selectedIndex].resourceRef = resourceRef
                unit.resources[selectedIndex].value = value
                unit.resources[selectedIndex].perPlayer = perPlayer
            else
                unit.resources[#unit.resources + 1] = {
                    resourceRef = resourceRef,
                    value = value,
                    perPlayer = perPlayer,
                }
            end
        end)
        self:SetSelectedUnitInspectorResourceIndex(nil)
        self:RefreshUnitInspectorResourceEditor()
    end, {
        height = 18,
        fontSize = 7,
    })
    self.UnitInspectorPendingResourceRow:AddChild(self.UnitInspectorAddResourceButton)

    self:RefreshUnitInspectorResourceEditor()
end
