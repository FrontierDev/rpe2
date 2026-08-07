local _, Addon = ...

local UI = Addon.UI or {}
Addon.UI = UI
local BaseElement = UI.BaseElement
local Debug = Addon.Debug or {}
local Constants = UI.Constants or {}

UI.ScrollLayout = UI.ScrollLayout or {}
local ScrollLayout = UI.ScrollLayout
ScrollLayout.__index = ScrollLayout
setmetatable(ScrollLayout, { __index = BaseElement })

function ScrollLayout:New(options)
    local instance = BaseElement.New(self, options)
    instance.options.border = false
    instance.items = {}
    instance.rows = {}
    instance.viewportFrame = nil
    instance.rowsFrame = nil
    instance.scrollBar = nil
    instance.scrollBarTrack = nil
    instance.scrollBarThumb = nil
    instance.scrollOffset = 0
    instance.visibleRows = options and (options.visibleRows or options.rowCount) or ((Constants.Scroll and Constants.Scroll.DefaultVisibleRows) or 8)
    instance.autoFitRows = options and options.autoFitRows == true or false
    instance.minVisibleRows = math.max(1, tonumber(options and options.minVisibleRows) or 1)
    instance.maxVisibleRows = tonumber(options and options.maxVisibleRows) or nil
    instance.rowHeight = options and options.rowHeight or ((Constants.Scroll and Constants.Scroll.DefaultRowHeight) or 24)
    instance.rowSpacing = options and options.rowSpacing or ((Constants.Scroll and Constants.Scroll.RowSpacing) or 2)
    instance.rowInsetLeft = options and options.rowInsetLeft or 0
    instance.rowInsetRight = options and options.rowInsetRight or 0
    instance.rowInsetTop = options and options.rowInsetTop or 0
    instance.rowInsetBottom = options and options.rowInsetBottom or 0
    instance.contentInsetLeft = options and options.contentInsetLeft or 0
    instance.contentInsetRight = options and options.contentInsetRight or 0
    instance.contentInsetTop = options and options.contentInsetTop or 0
    instance.contentInsetBottom = options and options.contentInsetBottom or 0
    instance.scrollBarInsetRight = options and options.scrollBarInsetRight or 0
    instance.scrollBarInsetTop = options and options.scrollBarInsetTop or 0
    instance.scrollBarInsetBottom = options and options.scrollBarInsetBottom or 0
    instance.rowRenderer = options and options.rowRenderer or nil
    instance.rowElementClass = options and options.rowElementClass or UI.ScrollListEntry or UI.Text
    return instance
end

function ScrollLayout:GetContentFrame()
    return self.viewportFrame or self.frame
end

function ScrollLayout:GetMaxOffset()
    local itemCount = #self.items
    return math.max(0, itemCount - self.visibleRows)
end

function ScrollLayout:SetRowRenderer(renderer)
    self.rowRenderer = renderer
    self:RefreshRows()
end

function ScrollLayout:HandleMouseWheel(delta)
    if delta > 0 then
        self:ScrollBy(-1)
    elseif delta < 0 then
        self:ScrollBy(1)
    end
end

function ScrollLayout:SetItems(items)
    self.items = items or {}
    self:SetScrollOffset(self.scrollOffset or 0)
    self:UpdateGeometry()
    self:RefreshRows()
    return self.items
end

function ScrollLayout:GetItems()
    return self.items or {}
end

function ScrollLayout:GetScrollOffset()
    return self.scrollOffset or 0
end

function ScrollLayout:SetScrollOffset(offset)
    local maxOffset = self:GetMaxOffset()
    local clamped = math.max(0, math.min(math.floor(offset or 0), maxOffset))

    if clamped == self.scrollOffset then
        self:RefreshRows()
        return self.scrollOffset
    end

    self.scrollOffset = clamped

    if self.scrollBar and self.scrollBar.SetValue and self.scrollBar:GetValue() ~= clamped then
        self.scrollBar:SetValue(clamped)
    end

    self:RefreshRows()
    return self.scrollOffset
end

function ScrollLayout:ScrollBy(delta)
    return self:SetScrollOffset((self.scrollOffset or 0) + (delta or 0))
end

function ScrollLayout:CreateRow(index, parentFrame)
    local rowClass = self.rowElementClass or UI.Text
    local row = rowClass:New({
        name = (self.name or "ScrollLayout") .. "Row" .. index,
        width = self.options.rowWidth or self.options.width or 1,
        height = self.rowHeight,
        border = false,
        fontFile = self.options.rowFontFile,
        fontSize = self.options.rowFontSize,
        fontFlags = self.options.rowFontFlags,
        textColor = UI.ResolveColor(self.options.rowTextColor, "text.primary"),
        wordWrap = self.options.rowWordWrap == true,
        categoryColor = UI.ResolveColor(self.options.rowCategoryColor, "text.secondary"),
        nameColor = UI.ResolveColor(self.options.rowNameColor, "text.primary"),
        statusColor = UI.ResolveColor(self.options.rowStatusColor, "text.muted"),
        detailColor = UI.ResolveColor(self.options.rowDetailColor, "text.muted"),
        descriptionInsetLeft = self.options.rowInsetLeft or 6,
        statusInsetRight = self.options.rowInsetRight or 8,
    })
    row:SetParent(parentFrame)
    row:Create()
    local rowFrame = row.GetFrame and row:GetFrame() or nil
    if rowFrame and rowFrame.EnableMouseWheel then
        rowFrame:EnableMouseWheel(true)
        rowFrame:SetScript("OnMouseWheel", function(_, delta)
            self:HandleMouseWheel(delta)
        end)
    end
    return row
end

function ScrollLayout:EnsureVisibleRowCount()
    if not self.rowsFrame then
        return
    end

    self.rows = self.rows or {}

    for index = (#self.rows + 1), self.visibleRows do
        self.rows[#self.rows + 1] = self:CreateRow(index, self.rowsFrame)
    end

    for index = 1, #self.rows do
        local row = self.rows[index]
        local rowFrame = row and row.GetFrame and row:GetFrame() or nil
        if rowFrame then
            if index <= self.visibleRows then
                if rowFrame.Show then
                    rowFrame:Show()
                end
            elseif rowFrame.Hide then
                rowFrame:Hide()
            end
        end
    end
end

function ScrollLayout:RefreshAutoFitVisibleRows()
    if self.autoFitRows ~= true or not self.frame then
        return false
    end

    local availableHeight = math.max(0, (self.frame.GetHeight and self.frame:GetHeight() or 0) - (self.contentInsetTop or 0) - (self.contentInsetBottom or 0))
    local rowExtent = math.max(1, (self.rowHeight or 0) + (self.rowSpacing or 0))
    local targetRows = math.max(self.minVisibleRows or 1, math.floor((availableHeight + (self.rowSpacing or 0)) / rowExtent))
    if self.maxVisibleRows and self.maxVisibleRows > 0 then
        targetRows = math.min(targetRows, self.maxVisibleRows)
    end
    targetRows = math.max(1, targetRows)

    if targetRows == self.visibleRows then
        return false
    end

    self.visibleRows = targetRows
    self:EnsureVisibleRowCount()
    if self.scrollOffset and self.scrollOffset > self:GetMaxOffset() then
        self.scrollOffset = self:GetMaxOffset()
    end
    return true
end

function ScrollLayout:BuildRows()
    if not self.rowsFrame then
        return
    end

    self:EnsureVisibleRowCount()
    self:UpdateGeometry()
    self:RefreshRows()
end

function ScrollLayout:UpdateGeometry()
    if not self.frame or not self.viewportFrame then
        return
    end

    self:RefreshAutoFitVisibleRows()

    local frame = self.frame
    local scrollBarWidth = self.options.scrollBarWidth or 12
    local showScrollBar = self:GetMaxOffset() > 0

    if self.viewportFrame.ClearAllPoints then
        self.viewportFrame:ClearAllPoints()
        self.viewportFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", self.contentInsetLeft or 0, -(self.contentInsetTop or 0))
        self.viewportFrame:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", self.contentInsetLeft or 0, self.contentInsetBottom or 0)
        if showScrollBar then
            self.viewportFrame:SetPoint("TOPRIGHT", self.scrollBar, "TOPLEFT", -(self.contentInsetRight or 0), -(self.contentInsetTop or 0))
            self.viewportFrame:SetPoint("BOTTOMRIGHT", self.scrollBar, "BOTTOMLEFT", -(self.contentInsetRight or 0), self.contentInsetBottom or 0)
        else
            self.viewportFrame:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -(self.contentInsetRight or 0), -(self.contentInsetTop or 0))
            self.viewportFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -(self.contentInsetRight or 0), self.contentInsetBottom or 0)
        end
    end

    if self.rowsFrame then
        self.rowsFrame:ClearAllPoints()
        self.rowsFrame:SetPoint("TOPLEFT", self.viewportFrame, "TOPLEFT", 0, 0)
        self.rowsFrame:SetPoint("BOTTOMRIGHT", self.viewportFrame, "BOTTOMRIGHT", 0, 0)
        if self.rowsFrame.SetClipsChildren then
            self.rowsFrame:SetClipsChildren(true)
        end
    end

    if self.scrollBar then
        self.scrollBar:ClearAllPoints()
        self.scrollBar:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -(self.scrollBarInsetRight or 0), -(self.scrollBarInsetTop or 0))
        self.scrollBar:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -(self.scrollBarInsetRight or 0), (self.scrollBarInsetBottom or 0))
        self.scrollBar:SetWidth(scrollBarWidth)
        if self.scrollBar.SetShown then
            self.scrollBar:SetShown(showScrollBar)
        elseif showScrollBar and self.scrollBar.Show then
            self.scrollBar:Show()
        elseif self.scrollBar.Hide then
            self.scrollBar:Hide()
        end
    end

    for index = 1, #self.rows do
        local row = self.rows[index]
        if row and row.GetFrame and row:GetFrame() then
            local rowFrame = row:GetFrame()
            if index <= self.visibleRows then
                rowFrame:ClearAllPoints()
                local rowOffsetY = -((index - 1) * (self.rowHeight + self.rowSpacing))
                local rowHeight = math.max(1, self.rowHeight - (self.rowInsetTop or 0) - (self.rowInsetBottom or 0))
                rowFrame:SetPoint("TOPLEFT", self.rowsFrame, "TOPLEFT", self.rowInsetLeft or 0, rowOffsetY + (self.rowInsetTop or 0))
                rowFrame:SetPoint("TOPRIGHT", self.rowsFrame, "TOPRIGHT", -(self.rowInsetRight or 0), rowOffsetY + (self.rowInsetTop or 0))
                rowFrame:SetHeight(rowHeight)
            elseif rowFrame.Hide then
                rowFrame:Hide()
            end
        end
    end

    self:RefreshScrollBar()
    self:RefreshRows()
end

function ScrollLayout:RefreshScrollBar()
    if not self.scrollBar then
        return
    end

    local maxOffset = self:GetMaxOffset()
    self.scrollBar:SetMinMaxValues(0, maxOffset)
    self.scrollBar:SetValueStep(1)

    if self.scrollBar.SetValue then
        self.scrollBar:SetValue(self.scrollOffset or 0)
    end

    local thumb = self.scrollBar:GetThumbTexture() and self.scrollBar:GetThumbTexture() or nil
    if thumb and thumb.SetVertexColor then
        local thumbColor = UI.ResolveColor(self.options.scrollbarThumbColor, "scrollbar.thumb")
        thumb:SetVertexColor(thumbColor.r or 0.42, thumbColor.g or 0.46, thumbColor.b or 0.52, thumbColor.a or 1)
    end
end

function ScrollLayout:RefreshRows()
    if not self.rows or #self.rows == 0 then
        return
    end

    local startIndex = self.scrollOffset or 0

    for visibleIndex = 1, #self.rows do
        local row = self.rows[visibleIndex]
        local rowFrame = row and row.GetFrame and row:GetFrame() or nil
        if visibleIndex > self.visibleRows then
            if rowFrame and rowFrame.Hide then
                rowFrame:Hide()
            end
        else
            local itemIndex = startIndex + visibleIndex
            local item = self.items[itemIndex]
            if rowFrame then
                if item then
                    if rowFrame.Show then
                        rowFrame:Show()
                    end

                    if self.rowRenderer then
                        self.rowRenderer(row, item, itemIndex, visibleIndex, self)
                    elseif row.SetCategory or row.SetTestName then
                        local category = ""
                        local name = ""
                        local status = ""
                        local detail = ""

                        if type(item) == "table" then
                            category = item.category or "General"
                            name = item.name or item.description or item.text or item.label or tostring(item.value or itemIndex)
                            status = item.status or (item.passed == true and "PASS" or item.passed == false and "FAIL" or "")
                            detail = item.message or item.trace or ""
                        else
                            name = tostring(item)
                        end

                        if row.SetCategory then
                            row:SetCategory(category)
                        end

                        if row.SetTestName then
                            row:SetTestName(name)
                        end

                        if row.SetStatus then
                            row:SetStatus(status)
                        end

                        if row.SetDetail then
                            row:SetDetail(detail)
                        end
                    elseif row.SetDescription or row.SetStatus then
                        local description = item
                        local status = ""
                        local detail = ""

                        if type(item) == "table" then
                            description = item.description or item.text or item.name or item.label or tostring(item.value or itemIndex)
                            status = item.status or (item.passed == true and "PASS" or item.passed == false and "FAIL" or "")
                            detail = item.message or item.trace or ""
                        else
                            description = tostring(item)
                        end

                        if row.SetDescription then
                            row:SetDescription(description)
                        end

                        if row.SetStatus then
                            row:SetStatus(status)
                        end

                        if row.SetDetail then
                            row:SetDetail(detail)
                        end
                    elseif row.SetText then
                        if type(item) == "table" then
                            row:SetText(item.text or item.message or item.label or tostring(item.value or itemIndex))
                        else
                            row:SetText(tostring(item))
                        end
                    end
                else
                    if rowFrame.Hide then
                        rowFrame:Hide()
                    end
                end
            end
        end
    end
end

function ScrollLayout:Create()
    if self.frame then
        return self.frame
    end

    local parentFrame = self:GetParentFrame()
    if not parentFrame then
        if Debug.Internal then
            Debug.Internal("A scroll layout requires a parent frame before Create().")
        end

        error("A scroll layout requires a parent frame before Create().", 2)
    end

    local frame = CreateFrame("Frame", self.name, parentFrame, self.options.template)
    self:SetFrame(frame)
    frame:EnableMouseWheel(true)

    self.viewportFrame = CreateFrame("Frame", nil, frame)
    self.viewportFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
    self.viewportFrame:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 0)
    self.viewportFrame:EnableMouseWheel(true)
    self.viewportFrame:SetScript("OnMouseWheel", function(_, delta)
        self:HandleMouseWheel(delta)
    end)

    self.rowsFrame = CreateFrame("Frame", nil, self.viewportFrame)
    self.rowsFrame:SetPoint("TOPLEFT", self.viewportFrame, "TOPLEFT", 0, 0)
    self.rowsFrame:SetPoint("BOTTOMRIGHT", self.viewportFrame, "BOTTOMRIGHT", 0, 0)
    if self.rowsFrame.SetClipsChildren then
        self.rowsFrame:SetClipsChildren(true)
    end
    self.rowsFrame:EnableMouseWheel(true)
    self.rowsFrame:SetScript("OnMouseWheel", function(_, delta)
        self:HandleMouseWheel(delta)
    end)

    self.scrollBar = CreateFrame("Slider", nil, frame)
    self.scrollBar:SetOrientation("VERTICAL")
    self.scrollBar:SetMinMaxValues(0, self:GetMaxOffset())
    self.scrollBar:SetValueStep(1)
    self.scrollBar:SetObeyStepOnDrag(true)

    self.scrollBarTrack = self.scrollBar:CreateTexture(nil, "BACKGROUND")
    self.scrollBarTrack:SetAllPoints(self.scrollBar)
    local trackColor = UI.ResolveColor(self.options.scrollbarTrackColor, "scrollbar.track")
    self.scrollBarTrack:SetColorTexture(trackColor.r or 0.08, trackColor.g or 0.09, trackColor.b or 0.11, trackColor.a or 0.95)

    self.scrollBar:SetThumbTexture("Interface\\Buttons\\WHITE8x8")
    local thumb = self.scrollBar:GetThumbTexture() and self.scrollBar:GetThumbTexture() or nil
    if thumb and thumb.SetVertexColor then
        local thumbColor = UI.ResolveColor(self.options.scrollbarThumbColor, "scrollbar.thumb")
        thumb:SetVertexColor(thumbColor.r or 0.42, thumbColor.g or 0.46, thumbColor.b or 0.52, thumbColor.a or 1)
    end
    self.scrollBar:SetValue(0)

    self.scrollBar:SetScript("OnValueChanged", function(_, value)
        local offset = math.floor(value or 0)
        if offset ~= self.scrollOffset then
            self.scrollOffset = offset
            self:RefreshRows()
        end
    end)

    frame:SetScript("OnMouseWheel", function(_, delta)
        self:HandleMouseWheel(delta)
    end)

    frame:SetScript("OnSizeChanged", function()
        self:UpdateGeometry()
    end)

    self:BuildRows()
    self:UpdateGeometry()
    self:RefreshScrollBar()
    self:RefreshRows()
    return self.frame
end
