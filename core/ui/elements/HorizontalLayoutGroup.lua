local addonName, Addon = ...
local UI = Addon.UI or {}
Addon.UI = UI

local HorizontalLayoutGroup = {}
HorizontalLayoutGroup.__index = HorizontalLayoutGroup
setmetatable(HorizontalLayoutGroup, { __index = UI.LayoutGroupBase })

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

local function GetFrameSize(frame)
    if not frame then
        return 0, 0
    end

    return frame:GetWidth() or 0, frame:GetHeight() or 0
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
    local weight = options and options.weight or 0
    local expandWidth = options and (options.expandWidth == true or options.fillWidth == true) or false
    local expandHeight = options and (options.expandHeight == true or options.fillHeight == true) or false

    return width, height, weight, expandWidth, expandHeight
end

local function DistributeAcrossAvailable(entries, availableSize)
    local totalWeight = 0

    for index = 1, #entries do
        totalWeight = totalWeight + math.max(0, entries[index].weight or 0)
    end

    if totalWeight <= 0 then
        local equalShare = (#entries > 0) and math.floor(availableSize / #entries) or 0
        local remainder = availableSize - (equalShare * #entries)

        for index = 1, #entries do
            entries[index].size = equalShare

            if index == #entries then
                entries[index].size = entries[index].size + remainder
            end
        end

        return
    end

    local remaining = availableSize

    for index = 1, #entries do
        local entry = entries[index]

        if index == #entries then
            entry.size = math.max(0, remaining)
        else
            local share = availableSize * (entry.weight / totalWeight)
            local size = math.max(0, math.floor(share + 0.5))

            if size > remaining then
                size = math.max(0, remaining)
            end

            entry.size = size
            remaining = remaining - size
        end
    end
end

function HorizontalLayoutGroup:New(...)
    return UI.LayoutGroupBase.New(self, ...)
end

function HorizontalLayoutGroup:Create()
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

function HorizontalLayoutGroup:RefreshLayout()
    if self._isRefreshing then
        return
    end

    self._isRefreshing = true
    self:LayoutChildren()
    self._isRefreshing = false
end

function HorizontalLayoutGroup:LayoutChildren()
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

    local innerWidth = math.max(0, (frame:GetWidth() or 0) - paddingLeft - paddingRight)
    local innerHeight = math.max(0, (frame:GetHeight() or 0) - paddingTop - paddingBottom)

    local entries = {}
    local stretchEntries = {}
    local fixedWidth = 0
    local children = self.children or {}

    for index = 1, #children do
        local child = children[index]
        local childFrame = GetChildFrame(child)

        if childFrame then
            local preferredWidth, preferredHeight, weight, expandWidth, expandHeight = GetPreferredSize(child)
            preferredWidth = ResolveSizeValue(preferredWidth, innerWidth)
            preferredHeight = ResolveSizeValue(preferredHeight, innerHeight)

            entries[#entries + 1] = {
                child = child,
                frame = childFrame,
                preferredWidth = preferredWidth,
                preferredHeight = preferredHeight,
                weight = weight,
                width = preferredWidth,
                height = preferredHeight,
                expandWidth = expandWidth,
                expandHeight = expandHeight,
            }

            if expandWidth then
                stretchEntries[#stretchEntries + 1] = entries[#entries]
            else
                fixedWidth = fixedWidth + preferredWidth
            end
        end
    end

    if #entries == 0 then
        return
    end

    if fitChildrenWidth then
        local availableWidth = math.max(0, innerWidth - spacingX * (#entries - 1))

        if #stretchEntries > 0 then
            local stretchAvailable = math.max(0, availableWidth - fixedWidth)
            local stretchTotalWeight = 0

            for index = 1, #stretchEntries do
                local entry = stretchEntries[index]
                local weight = math.max(0, entry.weight or 0)

                if weight <= 0 then
                    weight = 1
                end

                entry.weight = weight
                stretchTotalWeight = stretchTotalWeight + weight
            end

            for index = 1, #entries do
                local entry = entries[index]

                if entry.expandWidth then
                    entry.size = 0
                else
                    entry.size = entry.preferredWidth
                end
            end

            if stretchTotalWeight <= 0 then
                local equalShare = (#stretchEntries > 0) and math.floor(stretchAvailable / #stretchEntries) or 0
                local remainder = stretchAvailable - (equalShare * #stretchEntries)

                for index = 1, #stretchEntries do
                    stretchEntries[index].size = equalShare

                    if index == #stretchEntries then
                        stretchEntries[index].size = stretchEntries[index].size + remainder
                    end
                end
            else
                local remaining = stretchAvailable

                for index = 1, #stretchEntries do
                    local entry = stretchEntries[index]

                    if index == #stretchEntries then
                        entry.size = math.max(0, remaining)
                    else
                        local share = stretchAvailable * (entry.weight / stretchTotalWeight)
                        local size = math.max(0, math.floor(share + 0.5))

                        if size > remaining then
                            size = math.max(0, remaining)
                        end

                        entry.size = size
                        remaining = remaining - size
                    end
                end
            end
        else
            DistributeAcrossAvailable(entries, availableWidth)
        end
    end

    local cursorX = paddingLeft

    for index = 1, #entries do
        local entry = entries[index]
        local childWidth = fitChildrenWidth and entry.size or entry.width
        local childHeight = fitChildrenHeight and innerHeight or entry.height

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
            entry.frame:SetPoint("TOPLEFT", frame, "TOPLEFT", cursorX, -paddingTop)
        end

        cursorX = cursorX + childWidth + spacingX
    end

    if options.autoSize then
        local totalWidth = paddingLeft + paddingRight + math.max(0, cursorX - paddingLeft - spacingX)
        local totalHeight = paddingTop + paddingBottom + innerHeight

        if not fitChildrenHeight then
            local tallest = 0

            for index = 1, #entries do
                tallest = math.max(tallest, entries[index].height)
            end

            totalHeight = paddingTop + paddingBottom + tallest
        end

        if frame.SetSize then
            frame:SetSize(totalWidth, totalHeight)
        end
    end
end

UI.HorizontalLayoutGroup = HorizontalLayoutGroup
