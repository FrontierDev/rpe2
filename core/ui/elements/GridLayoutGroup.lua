local addonName, Addon = ...
local UI = Addon.UI or {}
Addon.UI = UI

local GridLayoutGroup = {}
GridLayoutGroup.__index = GridLayoutGroup
setmetatable(GridLayoutGroup, { __index = UI.LayoutGroupBase })

local function ResolveSizeValue(value, reference)
    if UI.ResolveSizeValue then
        return UI.ResolveSizeValue(value, reference)
    end

    return value
end

local function ResolvePadding(value)
    if type(value) == "table" then
        local left = value.left or value.x or value[1] or 0
        local right = value.right or value.x or value[1] or left
        local top = value.top or value.y or value[2] or 0
        local bottom = value.bottom or value.y or value[2] or top

        return left, right, top, bottom
    end

    local amount = tonumber(value) or 0
    return amount, amount, amount, amount
end

local function GetChildFrame(child)
    if not child then
        return nil
    end

    if child.GetFrame then
        return child:GetFrame()
    end

    return child.frame
end

local function GetPreferredSize(child)
    local childFrame = GetChildFrame(child)
    local options = child and child.options or nil

    local width = (options and options.width) or (childFrame and childFrame:GetWidth()) or 0
    local height = (options and options.height) or (childFrame and childFrame:GetHeight()) or 0

    return width, height
end

local function BuildUniformSizes(count, availableSize)
    local sizes = {}

    if count <= 0 then
        return sizes
    end

    local base = math.floor(availableSize / count)
    local remainder = availableSize - (base * count)

    for index = 1, count do
        sizes[index] = base

        if index == count then
            sizes[index] = sizes[index] + remainder
        end
    end

    return sizes
end

local function BuildPreferredSizes(count, preferredByIndex)
    local sizes = {}

    for index = 1, count do
        sizes[index] = preferredByIndex[index] or 0
    end

    return sizes
end

local function BuildOffsets(sizes, spacing, leadingPadding)
    local offsets = {}
    local cursor = leadingPadding

    for index = 1, #sizes do
        offsets[index] = cursor
        cursor = cursor + sizes[index] + spacing
    end

    return offsets
end

function GridLayoutGroup:New(...)
    return UI.LayoutGroupBase.New(self, ...)
end

function GridLayoutGroup:Create()
    UI.LayoutGroupBase.Create(self)

    if self.frame then
        self.frame:SetScript("OnSizeChanged", function()
            if self._isRefreshing then
                return
            end

            self:RefreshLayout()
        end)
    end

    self:RefreshLayout()
    return self.frame
end

function GridLayoutGroup:RefreshLayout()
    if self._isRefreshing then
        return
    end

    self._isRefreshing = true
    self:LayoutChildren()
    self._isRefreshing = false
end

function GridLayoutGroup:LayoutChildren()
    local frame = self.frame

    if not frame then
        return
    end

    local options = self.options or {}
    local paddingLeft, paddingRight, paddingTop, paddingBottom = ResolvePadding(options.padding)
    local spacingX = options.spacingX or options.spacing or 0
    local spacingY = options.spacingY or options.spacing or 0
    local fitChildrenWidth = options.fitChildrenWidth == true
    local fitChildrenHeight = options.fitChildrenHeight == true
    local explicitColumns = math.max(1, options.columns or 1)

    local children = self.children or {}
    local entries = {}

    for index = 1, #children do
        local child = children[index]
        local childFrame = GetChildFrame(child)

        if childFrame then
            local preferredWidth, preferredHeight = GetPreferredSize(child)

            entries[#entries + 1] = {
                child = child,
                frame = childFrame,
                preferredWidth = preferredWidth,
                preferredHeight = preferredHeight,
                width = preferredWidth,
                height = preferredHeight,
                expandWidth = child and child.options and child.options.expandWidth,
                expandHeight = child and child.options and child.options.expandHeight,
            }
        end
    end

    if #entries == 0 then
        return
    end

    local columns = math.min(explicitColumns, #entries)
    if columns <= 0 then
        columns = 1
    end

    local rows = math.max(1, math.ceil(#entries / columns))
    local innerWidth = math.max(0, (frame:GetWidth() or 0) - paddingLeft - paddingRight)
    local innerHeight = math.max(0, (frame:GetHeight() or 0) - paddingTop - paddingBottom)

    for index = 1, #entries do
        local entry = entries[index]
        entry.preferredWidth = ResolveSizeValue(entry.preferredWidth, innerWidth)
        entry.preferredHeight = ResolveSizeValue(entry.preferredHeight, innerHeight)
        entry.width = entry.preferredWidth
        entry.height = entry.preferredHeight
    end

    local columnWidths = {}
    local rowHeights = {}

    if fitChildrenWidth then
        local availableWidth = math.max(0, innerWidth - spacingX * (columns - 1))
        columnWidths = BuildUniformSizes(columns, availableWidth)
    else
        if options.cellWidth then
            for columnIndex = 1, columns do
                columnWidths[columnIndex] = options.cellWidth
            end
        else
            for columnIndex = 1, columns do
                columnWidths[columnIndex] = 0
            end

            for index = 1, #entries do
                local columnIndex = ((index - 1) % columns) + 1
                columnWidths[columnIndex] = math.max(columnWidths[columnIndex], entries[index].preferredWidth)
            end
        end
    end

    if fitChildrenHeight then
        local availableHeight = math.max(0, innerHeight - spacingY * (rows - 1))
        rowHeights = BuildUniformSizes(rows, availableHeight)
    else
        if options.cellHeight then
            for rowIndex = 1, rows do
                rowHeights[rowIndex] = options.cellHeight
            end
        else
            for rowIndex = 1, rows do
                rowHeights[rowIndex] = 0
            end

            for index = 1, #entries do
                local rowIndex = math.floor((index - 1) / columns) + 1
                rowHeights[rowIndex] = math.max(rowHeights[rowIndex], entries[index].preferredHeight)
            end
        end
    end

    local columnOffsets = BuildOffsets(columnWidths, spacingX, paddingLeft)
    local rowOffsets = BuildOffsets(rowHeights, spacingY, paddingTop)

    for index = 1, #entries do
        local entry = entries[index]
        local columnIndex = ((index - 1) % columns) + 1
        local rowIndex = math.floor((index - 1) / columns) + 1
        local childWidth = ((entry.expandWidth ~= false) and (columnWidths[columnIndex] or 0)) or entry.width
        local childHeight = ((entry.expandHeight ~= false) and (rowHeights[rowIndex] or 0)) or entry.height

        if childWidth < 0 then
            childWidth = 0
        end

        if childHeight < 0 then
            childHeight = 0
        end

        childWidth = math.floor(childWidth + 0.5)
        childHeight = math.floor(childHeight + 0.5)

        if entry.frame.ClearAllPoints then
            entry.frame:ClearAllPoints()
        end

        if entry.frame.SetSize then
            entry.frame:SetSize(childWidth, childHeight)
        end

        if entry.frame.SetPoint then
            entry.frame:SetPoint("TOPLEFT", frame, "TOPLEFT", columnOffsets[columnIndex] or paddingLeft, -(rowOffsets[rowIndex] or paddingTop))
        end
    end

    if options.autoSize then
        local totalWidth = paddingLeft + paddingRight
        local totalHeight = paddingTop + paddingBottom

        for index = 1, #columnWidths do
            totalWidth = totalWidth + columnWidths[index]
        end

        for index = 1, #rowHeights do
            totalHeight = totalHeight + rowHeights[index]
        end

        totalWidth = totalWidth + spacingX * math.max(0, columns - 1)
        totalHeight = totalHeight + spacingY * math.max(0, rows - 1)

        if frame.SetSize then
            frame:SetSize(totalWidth, totalHeight)
        end
    end
end

UI.GridLayoutGroup = GridLayoutGroup
