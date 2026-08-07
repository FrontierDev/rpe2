local _, Addon = ...

Addon.Server = Addon.Server or {}
Addon.Server.UI = Addon.Server.UI or {}

local Server = Addon.Server
local ServerUI = Addon.Server.UI
local UI = Addon.UI or {}
local C = UI.Constants or {}

ServerUI.EventManage = ServerUI.EventManage or {}
local EventManage = ServerUI.EventManage

function EventManage:BindUnitsTableRowHandlers()
    if not (self.UnitsTable and self.UnitsTable.bodyScroll and self.UnitsTable.bodyScroll.rows) then
        return false
    end

    for index = 1, #self.UnitsTable.bodyScroll.rows do
        local row = self.UnitsTable.bodyScroll.rows[index]
        if row and row.SetRowMouseUpHandler then
            row:SetRowMouseUpHandler(function(targetRow, button, rowData)
                if button == "RightButton" then
                    EventManage:ShowUnitsContextMenu(targetRow, rowData)
                elseif button == "LeftButton" and rowData and rowData.isPlayer ~= true and ServerUI and ServerUI.EventUnit and ServerUI.EventUnit.OpenForView then
                    ServerUI.EventUnit:OpenForView(rowData.sourceUnit)
                end
            end)
        end
    end

    return true
end

function EventManage:BuildUnitsPage(page)
    if self.UnitsRootLayout then
        return self.UnitsRootLayout
    end

    local layout = self.Layout or {}
    local contentWidth = layout.PageContentWidth or 480
    local tablePanelHeight = layout.UnitsTablePanelHeight or 258
    local tableWidth = layout.UnitsTableWidth or 468
    local visibleRows = layout.UnitsVisibleRows or 9

    self.UnitsPage = self.UnitsPage or page
    self.UnitsRootLayout = UI.CreateLayout(UI.VerticalLayoutGroup, page, "RPEServerEventManagepage_UnitsRootLayout", {
        spacing = 10,
        paddingLeft = 0,
        paddingTop = 0,
        fitChildrenWidth = true,
    })
    self.UnitsRootLayout:SetPoint("TOPLEFT", page, "TOPLEFT", 0, 0)
    self.UnitsRootLayout:SetPoint("TOPRIGHT", page, "TOPRIGHT", 0, 0)
    self.UnitsRootLayout:SetPoint("BOTTOMLEFT", page, "BOTTOMLEFT", 0, 0)
    self.UnitsRootLayout:SetPoint("BOTTOMRIGHT", page, "BOTTOMRIGHT", 0, 0)

    local toolbarLayout = UI.CreateLayout(UI.HorizontalLayoutGroup, self.UnitsRootLayout:GetFrame(), "RPEServerEventManageUnitsToolbarLayout", {
        spacing = 8,
        autoSize = true,
        fitChildrenWidth = false,
        fitChildrenHeight = false,
    })

    self.UnitsToolbarInfoText = UI.CreateText(toolbarLayout:GetFrame(), "RPEServerEventManageUnitsToolbarInfoText", "Total: 0  Players: 0  NPCs: 0", {
        fontFile = (C.FontFiles and C.FontFiles.Default) or "Fonts\\FRIZQT__.TTF",
        fontSize = (C.FontSizes and C.FontSizes.Body) or 8,
        textColor = UI.ResolveColor(nil, "text.secondary"),
        width = 220,
        height = 24,
        justifyH = "LEFT",
    })
    toolbarLayout:AddChild(self.UnitsToolbarInfoText)

    self.UnitsAddNpcButton = UI.CreateButton(toolbarLayout:GetFrame(), "RPEServerEventManageUnitsAddNpcButton", "Add NPC", 88, function()
        if not ServerUI or not ServerUI.OpenEventUnitWindow then
            return
        end

        ServerUI:OpenEventUnitWindow(function(registryId, _, options)
            if not registryId or registryId == "" or not Server.AddEventNpcUnitFromDefinition then
                return
            end

            Server:AddEventNpcUnitFromDefinition(registryId, options)
            EventManage:RefreshUnitsPage()
        end)
    end)
    toolbarLayout:AddChild(self.UnitsAddNpcButton)

    self.UnitsClearNpcButton = UI.CreateButton(toolbarLayout:GetFrame(), "RPEServerEventManageUnitsClearNpcButton", "Clear NPCs", 92, function()
        if not Server.ClearEventNpcUnits then
            return
        end

        Server:ClearEventNpcUnits()
        EventManage:RefreshUnitsPage()
    end)
    toolbarLayout:AddChild(self.UnitsClearNpcButton)

    self.UnitsRootLayout:AddChild(toolbarLayout)

    local tablePanel = UI.CreatePanel(self.UnitsRootLayout:GetFrame(), "RPEServerEventManageUnitsTablePanel", {
        width = contentWidth,
        height = tablePanelHeight,
        contentInset = 2,
    })

    self.UnitsTable = UI.Table:New({
        name = "RPEServerEventManageUnitsTable",
        width = tableWidth,
        height = tablePanelHeight - 12,
        visibleRows = visibleRows,
        rowHeight = 24,
        showColumnHeaders = true,
        columns = {
            {
                key = "raidMarker",
                label = "Raid",
                width = 48,
                sortable = true,
                cellTooltip = function(value, rowData)
                    return EventManage:BuildUnitCellTooltip(value, rowData)
                end,
                format = function(value)
                    local marker = tonumber(value) or 0
                    if marker <= 0 then
                        return "-"
                    end

                    local inline = UI.Inline
                    if inline and inline.RaidMarker then
                        return inline:RaidMarker(marker, 14, 14)
                    end

                    return tostring(marker)
                end,
            },
            {
                key = "team",
                label = "Team",
                width = 72,
                sortable = true,
                cellTooltip = function(value, rowData)
                    return EventManage:BuildUnitCellTooltip(value, rowData)
                end,
                format = function(value, rowData)
                    return tostring(rowData and rowData.teamName or value or "-")
                end,
            },
            {
                key = "eventID",
                label = "Event ID",
                width = 56,
                sortable = true,
                cellTooltip = function(value, rowData)
                    return EventManage:BuildUnitCellTooltip(value, rowData)
                end,
            },
            {
                key = "boss",
                label = "Boss",
                width = 44,
                sortable = true,
                cellTooltip = function(value, rowData)
                    return EventManage:BuildUnitCellTooltip(value, rowData)
                end,
                format = function(value)
                    return value == true and "Yes" or "-"
                end,
            },
            {
                key = "name",
                label = "Name",
                width = 136,
                sortable = true,
                cellTooltip = function(value, rowData)
                    return EventManage:BuildUnitCellTooltip(value, rowData)
                end,
            },
            {
                key = "registryID",
                label = "RegistryID",
                width = 104,
                sortable = true,
                cellTooltip = function(value, rowData)
                    return EventManage:BuildUnitCellTooltip(value, rowData)
                end,
                format = function(value)
                    return value ~= nil and value ~= "" and tostring(value) or "-"
                end,
            },
        },
        rows = self:BuildUnitRows(),
        border = false,
    })
    self.UnitsTable:SetParent(tablePanel:GetContentFrame())
    self.UnitsTable:Create()
    self.UnitsTable:GetFrame():SetPoint("TOPLEFT", tablePanel:GetContentFrame(), "TOPLEFT", 0, 0)
    self.UnitsTable:GetFrame():SetPoint("TOPRIGHT", tablePanel:GetContentFrame(), "TOPRIGHT", 0, 0)
    self.UnitsTable:GetFrame():SetPoint("BOTTOMLEFT", tablePanel:GetContentFrame(), "BOTTOMLEFT", 0, 0)
    self.UnitsTable:GetFrame():SetPoint("BOTTOMRIGHT", tablePanel:GetContentFrame(), "BOTTOMRIGHT", 0, 0)

    self:BindUnitsTableRowHandlers()

    self.UnitsRootLayout:AddChild(tablePanel)
    self:RefreshUnitsPage()
    return self.UnitsRootLayout
end
