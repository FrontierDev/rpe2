local _, Addon = ...

local UI = Addon.UI or {}
Addon.UI = UI
local BaseElement = UI.BaseElement
local Font = UI.Font or {}
local Constants = UI.Constants or {}

UI.TableRow = UI.TableRow or {}
local TableRow = UI.TableRow
TableRow.__index = TableRow
setmetatable(TableRow, { __index = BaseElement })

local function ApplyText(region, options, defaults)
    Font:Apply(region, options, defaults)

    local color = UI.ResolveColor(options and options.textColor, "text.primary")
    if color and region and region.SetTextColor then
        region:SetTextColor(color.r or 1, color.g or 1, color.b or 1, color.a or 1)
    end
end

local function ColumnsMatch(currentColumns, nextColumns)
    if currentColumns == nextColumns then
        return true
    end

    if #currentColumns ~= #nextColumns then
        return false
    end

    for index = 1, #nextColumns do
        local current = currentColumns[index]
        local nextColumn = nextColumns[index]
        if not current or not nextColumn then
            return false
        end

        if current.key ~= nextColumn.key or current.width ~= nextColumn.width or current.justifyH ~= nextColumn.justifyH then
            return false
        end
    end

    return true
end

function TableRow:New(options)
    local instance = BaseElement.New(self, options)
    instance.columns = {}
    instance.rowData = nil
    instance.rowIndex = 0
    instance.cells = {}
    instance.cellOrder = {}
    instance.background = nil
    instance.rowMouseUpHandler = nil
    return instance
end

function TableRow:SetColumns(columns)
    local nextColumns = columns or {}
    if ColumnsMatch(self.columns or {}, nextColumns) then
        self.columns = nextColumns
        return
    end

    self.columns = nextColumns
    self:RebuildCells()
    self:Refresh()
end

function TableRow:SetRowData(rowData, rowIndex)
    self.rowData = rowData
    self.rowIndex = rowIndex or 0
    self:Refresh()
end

function TableRow:SetRowMouseUpHandler(handler)
    self.rowMouseUpHandler = type(handler) == "function" and handler or nil

    local frame = self:GetFrame()
    if not frame then
        return
    end

    frame:EnableMouse(self.rowMouseUpHandler ~= nil)
end

function TableRow:ClearCellTooltip(cell)
    if not cell or not cell.frame then
        return
    end

    cell.tooltip = nil
    if cell.frame.EnableMouse then
        cell.frame:EnableMouse(false)
    end
    cell.frame:SetScript("OnEnter", nil)
    cell.frame:SetScript("OnLeave", nil)
    cell.frame:SetScript("OnHide", nil)
end

function TableRow:BindCellTooltip(cell, tooltip)
    self:ClearCellTooltip(cell)

    if not tooltip or not cell or not cell.frame then
        return
    end

    cell.tooltip = tooltip
    if cell.frame.EnableMouse then
        cell.frame:EnableMouse(true)
    end
    cell.frame:SetScript("OnEnter", function()
        if UI.Tooltip and UI.Tooltip.ShowForElement then
            UI.Tooltip:ShowForElement(cell.frame, tooltip)
        end
    end)
    cell.frame:SetScript("OnLeave", function()
        if UI.Tooltip and UI.Tooltip.Hide then
            UI.Tooltip:Hide()
        end
    end)
    cell.frame:SetScript("OnHide", function()
        if UI.Tooltip and UI.Tooltip.Hide then
            UI.Tooltip:Hide()
        end
    end)
end

function TableRow:HandleMouseUp(button)
    if self.rowMouseUpHandler then
        self.rowMouseUpHandler(self, button, self.rowData, self.rowIndex)
    end
end

function TableRow:CreateCell(column)
    local frame = CreateFrame("Frame", nil, self.frame)
    frame:EnableMouse(false)
    frame:SetScript("OnMouseUp", function(_, button)
        self:HandleMouseUp(button)
    end)

    local text = frame:CreateFontString(nil, "OVERLAY")
    text:SetPoint("TOPLEFT", frame, "TOPLEFT", 4, -2)
    text:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -4, 2)
    text:SetJustifyH(column.justifyH or "LEFT")
    text:SetJustifyV("MIDDLE")
    text:SetWordWrap(column.wordWrap == true)

    ApplyText(text, {
        fontFile = column.fontFile or self.options.fontFile,
        fontSize = column.fontSize or self.options.fontSize or (Constants.FontSizes and Constants.FontSizes.Body) or 10,
        fontFlags = column.fontFlags or self.options.fontFlags,
        fontObject = column.fontObject or self.options.fontObject,
        textColor = column.textColor or self.options.textColor,
    }, {
        fontSize = column.fontSize or self.options.fontSize or (Constants.FontSizes and Constants.FontSizes.Body) or 10,
    })

    local border = frame:CreateTexture(nil, "ARTWORK")
    border:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
    border:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
    border:SetWidth(1)
    local borderColor = UI.ResolveColor(column.borderColor, "panel.border")
    border:SetColorTexture(borderColor.r or 0.16, borderColor.g or 0.18, borderColor.b or 0.22, borderColor.a or 1)

    return {
        frame = frame,
        text = text,
        border = border,
        key = column.key,
        tooltip = nil,
    }
end

function TableRow:RebuildCells()
    if not self.frame then
        return
    end

    for index = 1, #self.cellOrder do
        local cell = self.cellOrder[index]
        self:ClearCellTooltip(cell)
        if cell and cell.frame and cell.frame.Hide then
            cell.frame:Hide()
            cell.frame:SetParent(nil)
        end
    end

    self.cells = {}
    self.cellOrder = {}

    local offsetX = 0
    for index = 1, #(self.columns or {}) do
        local column = self.columns[index]
        local cell = self:CreateCell(column)
        cell.frame:SetPoint("TOPLEFT", self.frame, "TOPLEFT", offsetX, 0)
        cell.frame:SetPoint("BOTTOMLEFT", self.frame, "BOTTOMLEFT", offsetX, 0)
        cell.frame:SetWidth(column.width or 40)
        offsetX = offsetX + (column.width or 40)
        self.cells[column.key] = cell
        self.cellOrder[#self.cellOrder + 1] = cell
    end
end

function TableRow:Refresh()
    if not self.frame or not self.columns then
        return
    end

    local rowData = self.rowData or {}
    local rowIndex = self.rowIndex or 0

    for index = 1, #(self.columns or {}) do
        local column = self.columns[index]
        local cell = self.cells[column.key]
        if cell and cell.text and cell.text.SetText then
            local value = nil
            if column.value then
                value = column.value(rowData, rowIndex, column, self)
            else
                value = rowData[column.key]
            end

            local displayValue = value
            if column.format then
                displayValue = column.format(value, rowData, rowIndex, column, self)
            elseif displayValue == nil then
                displayValue = ""
            else
                displayValue = tostring(displayValue)
            end

            cell.text:SetText(displayValue)

            local tooltip = nil
            if column.cellTooltip then
                tooltip = column.cellTooltip(value, rowData, rowIndex, column, self)
            end
            self:BindCellTooltip(cell, tooltip)
        end
    end
end

function TableRow:Create()
    if self.frame then
        return self.frame
    end

    local parentFrame = self:GetParentFrame()
    if not parentFrame then
        error("A table row requires a parent frame before Create().", 2)
    end

    local frame = CreateFrame("Frame", self.name, parentFrame, self.options.template)
    self:SetFrame(frame)
    frame:EnableMouse(self.rowMouseUpHandler ~= nil)
    frame:SetScript("OnMouseUp", function(_, button)
        self:HandleMouseUp(button)
    end)

    self.background = frame:CreateTexture(nil, "BACKGROUND")
    self.background:SetAllPoints(frame)
    local backgroundColor = UI.ResolveColor(self.options.backgroundColor, "list.rowBackground")
    self.background:SetColorTexture(backgroundColor.r or 0.08, backgroundColor.g or 0.09, backgroundColor.b or 0.11, backgroundColor.a or 0.85)

    self:RebuildCells()
    self:Refresh()
    return self.frame
end

return TableRow
