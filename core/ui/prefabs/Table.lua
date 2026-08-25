local _, Addon = ...

local UI = Addon.UI or {}
Addon.UI = UI
local BaseElement = UI.BaseElement
local Constants = UI.Constants or {}

UI.Table = UI.Table or {}
local Table = UI.Table
Table.__index = Table
setmetatable(Table, { __index = BaseElement })

local function CopyArray(values)
    local output = {}
    for index = 1, #(values or {}) do
        output[index] = values[index]
    end
    return output
end

local function BuildSelectionSet(values)
    local set = {}
    if type(values) ~= "table" then
        return set
    end

    for key, value in pairs(values) do
        if value == true then
            set[key] = true
        elseif value ~= nil then
            set[value] = true
        end
    end

    return set
end

local function CountSelectionSet(values)
    local count = 0
    for _, selected in pairs(values or {}) do
        if selected == true then
            count = count + 1
        end
    end
    return count
end

local function NormalizeSortDirection(direction)
    if direction == "ascending" or direction == "asc" then
        return "ascending"
    end

    if direction == "descending" or direction == "desc" then
        return "descending"
    end

    return nil
end

local function SerializeFilterValue(value)
    local valueType = type(value)
    if value == nil then
        return "__nil"
    end

    if valueType == "string" then
        return "string:" .. value
    end

    if valueType == "number" then
        return "number:" .. tostring(value)
    end

    if valueType == "boolean" then
        return "boolean:" .. tostring(value)
    end

    return valueType .. ":" .. tostring(value)
end

local function ResolveComparableValue(value)
    if value == nil then
        return nil
    end

    local valueType = type(value)
    if valueType == "number" or valueType == "string" or valueType == "boolean" then
        return value
    end

    return tostring(value)
end

local function CompareValues(left, right, direction)
    if left == right then
        return 0
    end

    if left == nil then
        return 1
    end

    if right == nil then
        return -1
    end

    if type(left) == "boolean" then
        left = left and 1 or 0
    end
    if type(right) == "boolean" then
        right = right and 1 or 0
    end

    if type(left) == "number" and type(right) == "number" then
        if left < right then
            return direction == "descending" and 1 or -1
        end

        return direction == "descending" and -1 or 1
    end

    local leftText = tostring(left):lower()
    local rightText = tostring(right):lower()
    if leftText < rightText then
        return direction == "descending" and 1 or -1
    end

    return direction == "descending" and -1 or 1
end

local function ResolveColumnValue(column, rowData, rowIndex, rowElement)
    if column.value then
        return column.value(rowData, rowIndex, column, rowElement)
    end

    return rowData[column.key]
end

function Table:New(options)
    local instance = BaseElement.New(self, options)
    instance.options.border = options and options.border ~= false
    instance.columns = CopyArray(options and options.columns or {})
    instance.rows = CopyArray(options and options.rows or {})
    instance.displayRows = {}
    instance.sortState = {
        columnKey = nil,
        direction = nil,
    }
    instance.columnFilters = {}
    instance.filterMenu = nil
    instance.activeFilterColumnKey = nil
    instance.headerFrame = nil
    instance.headerCells = {}
    instance.bodyScroll = nil
    instance.resolvedColumns = {}
    instance.showColumnHeaders = options == nil or options.showColumnHeaders ~= false
    instance.rowHeaderColumn = options and options.rowHeaderColumn or nil
    return instance
end

function Table:GetRows()
    return self.rows
end

function Table:SetRows(rows)
    self.rows = CopyArray(rows or {})
    self:Refresh()
    return self.rows
end

function Table:SetColumns(columns)
    self.columns = CopyArray(columns or {})
    if self.frame then
        self.resolvedColumns = self:BuildEffectiveColumns()
        self:BuildHeader()
    end
    self:Refresh()
    return self.columns
end

function Table:GetSort()
    return self.sortState.columnKey, self.sortState.direction
end

function Table:SetSort(columnKey, direction)
    self.sortState.columnKey = columnKey
    self.sortState.direction = NormalizeSortDirection(direction)
    if not self.sortState.direction then
        self.sortState.columnKey = nil
    end
    self:Refresh()
end

function Table:SetColumnFilter(columnKey, selectedValues)
    local selectionSet = BuildSelectionSet(selectedValues)
    if CountSelectionSet(selectionSet) == 0 then
        self.columnFilters[columnKey] = nil
    else
        self.columnFilters[columnKey] = selectionSet
    end

    self:Refresh()
end

function Table:ClearColumnFilter(columnKey)
    self.columnFilters[columnKey] = nil
    self:Refresh()
end

function Table:GetColumnByKey(columnKey)
    if self.rowHeaderColumn and self.rowHeaderColumn.key == columnKey then
        return self.rowHeaderColumn
    end

    for index = 1, #(self.columns or {}) do
        local column = self.columns[index]
        if column.key == columnKey then
            return column
        end
    end

    return nil
end

function Table:GetResolvedColumns()
    return self.resolvedColumns or {}
end

function Table:BuildEffectiveColumns()
    local effective = {}
    if self.rowHeaderColumn then
        local rowHeaderColumn = {}
        for key, value in pairs(self.rowHeaderColumn) do
            rowHeaderColumn[key] = value
        end
        rowHeaderColumn.isRowHeader = true
        effective[#effective + 1] = rowHeaderColumn
    end

    for index = 1, #(self.columns or {}) do
        local source = self.columns[index]
        local column = {}
        for key, value in pairs(source) do
            column[key] = value
        end
        effective[#effective + 1] = column
    end

    local totalWidth = self.options.width or 300
    local scrollBarWidth = self.options.scrollBarWidth or 12
    local availableWidth = math.max(80, totalWidth - scrollBarWidth)
    local fixedWidth = 0
    local flexibleCount = 0

    for index = 1, #effective do
        local width = tonumber(effective[index].width)
        if width and width > 0 then
            fixedWidth = fixedWidth + width
        else
            flexibleCount = flexibleCount + 1
        end
    end

    local remainingWidth = math.max(0, availableWidth - fixedWidth)
    local flexibleWidth = flexibleCount > 0 and math.max(40, math.floor(remainingWidth / flexibleCount)) or 0

    for index = 1, #effective do
        effective[index].width = tonumber(effective[index].width) or flexibleWidth
        effective[index].label = effective[index].label or effective[index].key or ("Column " .. index)
    end

    return effective
end

function Table:GetColumnFilterSelection(columnKey)
    return self.columnFilters[columnKey] or {}
end

function Table:BuildColumnFilterItems(column)
    local seen = {}
    local items = {}

    for rowIndex = 1, #(self.rows or {}) do
        local rowData = self.rows[rowIndex]
        local rawValue = ResolveColumnValue(column, rowData, rowIndex)
        local serialized = SerializeFilterValue(rawValue)
        if not seen[serialized] then
            seen[serialized] = true
            local label = nil
            if column.format then
                label = column.format(rawValue, rowData, rowIndex, column)
            elseif rawValue == nil then
                label = "(blank)"
            else
                label = tostring(rawValue)
            end

            items[#items + 1] = {
                label = label,
                value = serialized,
            }
        end
    end

    table.sort(items, function(left, right)
        return tostring(left.label or ""):lower() < tostring(right.label or ""):lower()
    end)

    return items
end

function Table:GetSelectedFilterValuesForMenu(columnKey)
    local active = self.columnFilters[columnKey]
    if not active then
        return {}
    end

    local values = {}
    for value, selected in pairs(active) do
        if selected == true then
            values[#values + 1] = value
        end
    end

    return values
end

function Table:ApplyMenuSelection(columnKey, selectedValues)
    self:SetColumnFilter(columnKey, BuildSelectionSet(selectedValues))
end

function Table:HideFilterMenu()
    if self.filterMenu and self.filterMenu.HideMenus then
        self.filterMenu:HideMenus()
        self.filterMenu.anchorOwner = nil
    end

    self.activeFilterColumnKey = nil
end

function Table:EnsureFilterMenu()
    if self.filterMenu or not UI.ContextMenu then
        return self.filterMenu
    end

    self.filterMenu = UI.ContextMenu:New({
        name = (self.name or "Table") .. "FilterMenu",
        width = (self.options.filterMenuWidth or 120) * 4,
        panelWidth = self.options.filterMenuWidth or 120,
        visibleRows = self.options.filterVisibleRows or 8,
        rowHeight = self.options.filterRowHeight or 18,
        rowSpacing = 0,
        multiSelect = true,
        showSelectionActions = true,
        border = false,
        frameStrata = self.options.filterMenuFrameStrata or "TOOLTIP",
        frameLevel = self.options.filterMenuFrameLevel or 200,
        onValueChanged = function(value)
            if not self.activeFilterColumnKey then
                return
            end

            self:ApplyMenuSelection(self.activeFilterColumnKey, value)
        end,
        onItemInvoked = function()
            self:HideFilterMenu()
        end,
    })
    self.filterMenu:SetParent(self:GetParentFrame())
    self.filterMenu:Create()
    return self.filterMenu
end

function Table:OpenFilterMenu(columnKey, anchorFrame)
    local column = self:GetColumnByKey(columnKey)
    if not column or not column.filterable then
        return
    end

    local menu = self:EnsureFilterMenu()
    if not menu then
        return
    end

    local menuFrame = menu.GetFrame and menu:GetFrame() or nil
    if menuFrame and menuFrame.IsShown and menuFrame:IsShown() and menu.anchorOwner == anchorFrame and self.activeFilterColumnKey == columnKey then
        self:HideFilterMenu()
        return
    end

    self.activeFilterColumnKey = columnKey
    menu:SetParent(self:GetParentFrame())
    menu:SetItems(self:BuildColumnFilterItems(column))
    menu:SetSelectedValues(self:GetSelectedFilterValuesForMenu(columnKey), true)
    menu.anchorOwner = anchorFrame
    menu:ShowAt(anchorFrame)
end

function Table:CycleSort(columnKey)
    self:HideFilterMenu()

    if self.sortState.columnKey ~= columnKey then
        self:SetSort(columnKey, "ascending")
        return
    end

    if self.sortState.direction == "ascending" then
        self:SetSort(columnKey, "descending")
        return
    end

    if self.sortState.direction == "descending" then
        self:SetSort(nil, nil)
        return
    end

    self:SetSort(columnKey, "ascending")
end

function Table:RowPassesFilters(rowData, rowIndex)
    for columnKey, selectedValues in pairs(self.columnFilters or {}) do
        if CountSelectionSet(selectedValues) > 0 then
            local column = self:GetColumnByKey(columnKey)
            if column then
                local rawValue = ResolveColumnValue(column, rowData, rowIndex)
                local serialized = SerializeFilterValue(rawValue)
                if selectedValues[serialized] ~= true then
                    return false
                end
            end
        end
    end

    return true
end

function Table:BuildDisplayRows()
    local filtered = {}
    for rowIndex = 1, #(self.rows or {}) do
        local rowData = self.rows[rowIndex]
        if self:RowPassesFilters(rowData, rowIndex) then
            filtered[#filtered + 1] = {
                rowData = rowData,
                sourceIndex = rowIndex,
            }
        end
    end

    local sortColumn = self.sortState.columnKey and self:GetColumnByKey(self.sortState.columnKey) or nil
    local sortDirection = self.sortState.direction
    if sortColumn and sortDirection then
        table.sort(filtered, function(left, right)
            local leftValue = nil
            local rightValue = nil

            if sortColumn.sortValue then
                leftValue = sortColumn.sortValue(left.rowData, left.sourceIndex, sortColumn)
                rightValue = sortColumn.sortValue(right.rowData, right.sourceIndex, sortColumn)
            else
                leftValue = ResolveColumnValue(sortColumn, left.rowData, left.sourceIndex)
                rightValue = ResolveColumnValue(sortColumn, right.rowData, right.sourceIndex)
            end

            local comparison = CompareValues(ResolveComparableValue(leftValue), ResolveComparableValue(rightValue), sortDirection)
            if comparison == 0 then
                return left.sourceIndex < right.sourceIndex
            end

            return comparison < 0
        end)
    end

    return filtered
end

function Table:RefreshHeaderVisuals()
    for _, headerCell in pairs(self.headerCells or {}) do
        local column = headerCell.column
        if headerCell.label and headerCell.label.SetText then
            local text = column.label or column.key or ""
            if column.sortable and self.sortState.columnKey == column.key then
                if self.sortState.direction == "ascending" then
                    text = text .. " ^"
                elseif self.sortState.direction == "descending" then
                    text = text .. " v"
                end
            end
            headerCell.label:SetText(text)
        end

        if headerCell.filterButton and headerCell.filterButton.text then
            local activeCount = CountSelectionSet(self.columnFilters[column.key])
            headerCell.filterButton.text:SetText(activeCount > 0 and tostring(activeCount) or "v")
        end
    end
end

function Table:Refresh()
    self.resolvedColumns = self:BuildEffectiveColumns()
    self.displayRows = self:BuildDisplayRows()

    if self.bodyScroll and self.bodyScroll.SetItems then
        self.bodyScroll:SetItems(self.displayRows)
    end

    if self.bodyScroll and self.bodyScroll.rows then
        for index = 1, #self.bodyScroll.rows do
            local row = self.bodyScroll.rows[index]
            if row and row.SetColumns then
                row:SetColumns(self.resolvedColumns)
            end
        end
    end

    self:RefreshHeaderVisuals()
    return self.displayRows
end

function Table:CreateHeaderCell(column, offsetX)
    local frame = CreateFrame("Button", nil, self.headerFrame)
    frame:SetPoint("TOPLEFT", self.headerFrame, "TOPLEFT", offsetX, 0)
    frame:SetPoint("BOTTOMLEFT", self.headerFrame, "BOTTOMLEFT", offsetX, 0)
    frame:SetWidth(column.width or 40)
    frame:EnableMouse(true)
    if frame.RegisterForClicks then
        frame:RegisterForClicks("AnyUp")
    end

    local background = frame:CreateTexture(nil, "BACKGROUND")
    background:SetAllPoints(frame)
    local backgroundColor = UI.ResolveColor(column.headerBackgroundColor, "panel.background")
    background:SetColorTexture(backgroundColor.r or 0.08, backgroundColor.g or 0.09, backgroundColor.b or 0.12, backgroundColor.a or 0.9)

    local border = frame:CreateTexture(nil, "ARTWORK")
    border:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
    border:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
    border:SetWidth(1)
    local borderColor = UI.ResolveColor(column.borderColor, "panel.border")
    border:SetColorTexture(borderColor.r or 0.16, borderColor.g or 0.18, borderColor.b or 0.22, borderColor.a or 1)

    local label = frame:CreateFontString(nil, "OVERLAY")
    label:SetPoint("LEFT", frame, "LEFT", 4, 0)
    label:SetPoint("RIGHT", frame, "RIGHT", column.filterable and -22 or -4, 0)
    label:SetJustifyH(column.justifyH or "LEFT")
    label:SetJustifyV("MIDDLE")
    label:SetWordWrap(false)
    if UI.Font and UI.Font.Apply then
        UI.Font:Apply(label, {
            fontFile = column.headerFontFile or self.options.fontFile,
            fontSize = column.headerFontSize or self.options.headerFontSize or (Constants.FontSizes and Constants.FontSizes.Dropdown) or 10,
            fontFlags = column.headerFontFlags or self.options.fontFlags,
        }, {
            fontSize = column.headerFontSize or self.options.headerFontSize or (Constants.FontSizes and Constants.FontSizes.Dropdown) or 10,
        })
    end
    local textColor = UI.ResolveColor(column.headerTextColor, "text.primary")
    label:SetTextColor(textColor.r or 1, textColor.g or 1, textColor.b or 1, textColor.a or 1)

    local filterButton = nil
    if column.filterable then
        local filterFrame = CreateFrame("Button", nil, frame)
        filterFrame:SetPoint("RIGHT", frame, "RIGHT", -2, 0)
        filterFrame:SetSize(18, math.max(14, (self.options.headerHeight or 20) - 4))
        filterFrame:EnableMouse(true)
        if filterFrame.RegisterForClicks then
            filterFrame:RegisterForClicks("AnyUp")
        end

        local filterBackground = filterFrame:CreateTexture(nil, "BACKGROUND")
        filterBackground:SetAllPoints(filterFrame)
        local filterBackgroundColor = UI.ResolveColor(column.filterButtonBackgroundColor, "dropdown.background")
        filterBackground:SetColorTexture(filterBackgroundColor.r or 0.12, filterBackgroundColor.g or 0.13, filterBackgroundColor.b or 0.17, filterBackgroundColor.a or 0.95)

        local filterText = filterFrame:CreateFontString(nil, "OVERLAY")
        filterText:SetPoint("CENTER", filterFrame, "CENTER", 0, 0)
        if UI.Font and UI.Font.Apply then
            UI.Font:Apply(filterText, {
                fontFile = self.options.fontFile,
                fontSize = self.options.headerFontSize or (Constants.FontSizes and Constants.FontSizes.Dropdown) or 10,
            }, {
                fontSize = self.options.headerFontSize or (Constants.FontSizes and Constants.FontSizes.Dropdown) or 10,
            })
        end
        local filterTextColor = UI.ResolveColor(column.filterButtonTextColor, "text.secondary")
        filterText:SetTextColor(filterTextColor.r or 1, filterTextColor.g or 1, filterTextColor.b or 1, filterTextColor.a or 1)
        filterText:SetText("v")

        filterFrame:SetScript("OnClick", function()
            self:OpenFilterMenu(column.key, filterFrame)
        end)

        filterButton = {
            frame = filterFrame,
            text = filterText,
        }
    end

    if column.tooltip then
        frame:SetScript("OnEnter", function()
            if UI.Tooltip and UI.Tooltip.ShowForElement then
                UI.Tooltip:ShowForElement(frame, column.tooltip)
            end
        end)
        frame:SetScript("OnLeave", function()
            if UI.Tooltip and UI.Tooltip.Hide then
                UI.Tooltip:Hide()
            end
        end)
    end

    if column.sortable and not column.isRowHeader then
        frame:SetScript("OnClick", function(_, button)
            if button == "LeftButton" then
                self:CycleSort(column.key)
            end
        end)
    end

    return {
        frame = frame,
        label = label,
        column = column,
        filterButton = filterButton,
    }
end

function Table:BuildHeader()
    if self.headerFrame then
        self.headerFrame:Hide()
        self.headerFrame:SetParent(nil)
        self.headerFrame = nil
        self.headerCells = {}
    end

    if not self.showColumnHeaders then
        return
    end

    self.headerFrame = CreateFrame("Frame", nil, self.frame)
    self.headerFrame:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 0, 0)
    self.headerFrame:SetPoint("TOPRIGHT", self.frame, "TOPRIGHT", 0, 0)
    self.headerFrame:SetHeight(self.options.headerHeight or 20)

    local offsetX = 0
    for index = 1, #(self.resolvedColumns or {}) do
        local column = self.resolvedColumns[index]
        local headerCell = self:CreateHeaderCell(column, offsetX)
        self.headerCells[column.key] = headerCell
        offsetX = offsetX + (column.width or 40)
    end
end

function Table:BuildBody()
    if self.bodyScroll then
        self.bodyScroll:SetItems({})
    end

    local topOffset = self.showColumnHeaders and (self.options.headerHeight or 20) or 0
    self.bodyScroll = UI.ScrollLayout:New({
        name = (self.name or "Table") .. "BodyScroll",
        width = self.options.width or 300,
        height = self.options.height or 200,
        visibleRows = self.options.visibleRows or 6,
        rowHeight = self.options.rowHeight or 20,
        rowSpacing = self.options.rowSpacing or 0,
        autoFitRows = self.options.autoFitRows == true,
        minVisibleRows = self.options.minVisibleRows,
        maxVisibleRows = self.options.maxVisibleRows,
        border = false,
        rowElementClass = UI.TableRow,
        rowFontFile = self.options.fontFile,
        rowFontSize = self.options.fontSize or (Constants.FontSizes and Constants.FontSizes.Body) or 10,
        scrollBarWidth = self.options.scrollBarWidth or 12,
    })
    self.bodyScroll:SetParent(self.frame)
    self.bodyScroll:SetRowRenderer(function(row, item, absoluteIndex)
        row:SetColumns(self.resolvedColumns)
        row:SetRowData(item and item.rowData or nil, item and item.sourceIndex or absoluteIndex)
    end)
    self.bodyScroll:Create()
    self.bodyScroll:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 0, -topOffset)
    self.bodyScroll:SetPoint("TOPRIGHT", self.frame, "TOPRIGHT", 0, -topOffset)
    self.bodyScroll:SetPoint("BOTTOMLEFT", self.frame, "BOTTOMLEFT", 0, 0)
    self.bodyScroll:SetPoint("BOTTOMRIGHT", self.frame, "BOTTOMRIGHT", 0, 0)
end

function Table:Create()
    if self.frame then
        return self.frame
    end

    local parentFrame = self:GetParentFrame()
    if not parentFrame then
        error("A table prefab requires a parent frame before Create().", 2)
    end

    local frame = CreateFrame("Frame", self.name, parentFrame, self.options.template)
    self:SetFrame(frame)
    frame:EnableMouse(false)

    local background = frame:CreateTexture(nil, "BACKGROUND")
    background:SetAllPoints(frame)
    local backgroundColor = UI.ResolveColor(self.options.backgroundColor, "panel.background")
    background:SetColorTexture(backgroundColor.r or 0.05, backgroundColor.g or 0.06, backgroundColor.b or 0.08, backgroundColor.a or 0.9)
    self.background = background

    self.resolvedColumns = self:BuildEffectiveColumns()
    self:BuildHeader()
    self:BuildBody()
    self:EnsureFilterMenu()
    self:Refresh()
    return self.frame
end

return Table
