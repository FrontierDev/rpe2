local _, Addon = ...

local UI = Addon.UI or {}
Addon.UI = UI
local BaseElement = UI.BaseElement
local Debug = Addon.Debug or {}
local Constants = UI.Constants or {}
local Font = UI.Font or {}

UI.TabContainer = UI.TabContainer or {}
local TabContainer = UI.TabContainer
TabContainer.__index = TabContainer
setmetatable(TabContainer, { __index = BaseElement })

local function NormalizeTab(tab, index)
    if type(tab) == "string" then
        return {
            label = tab,
            name = tab,
            builder = nil,
            width = 90,
            order = index,
            iconTexture = nil,
            iconInset = nil,
            tooltip = nil,
        }
    end

    local data = tab or {}
    return {
        label = data.label or data.name or ("Tab " .. index),
        name = data.name or data.label or ("Tab " .. index),
        builder = data.builder or data.build or nil,
        width = data.width or data.tabWidth or 90,
        order = data.order or index,
        options = data.options or {},
        iconTexture = data.iconTexture or data.icon or nil,
        iconInset = data.iconInset,
        tooltip = data.tooltip or nil,
    }
end

local function ApplyIconTextureCoords(texture, tab)
    if not texture or not texture.SetTexCoord then
        return
    end

    local coords = tab.iconTexCoord or { 0.08, 0.92, 0.08, 0.92 }
    texture:SetTexCoord(coords[1] or 0, coords[2] or 1, coords[3] or 0, coords[4] or 1)
end

local function CreateIconTabTexture(button, tab)
    if not button or not button.GetFrame then
        return nil
    end

    local frame = button:GetFrame()
    if not frame then
        return nil
    end

    local texturePath = tab.iconTexture
    if button.SetNormalTexture then
        button:SetNormalTexture(texturePath)
    end
    if button.SetHighlightTexture then
        button:SetHighlightTexture(texturePath)
    end
    if button.SetPushedTexture then
        button:SetPushedTexture(texturePath)
    end
    if button.SetDisabledTexture then
        button:SetDisabledTexture(texturePath)
    end

    local normal = frame.GetNormalTexture and frame:GetNormalTexture() or nil
    local highlight = frame.GetHighlightTexture and frame:GetHighlightTexture() or nil
    local pushed = frame.GetPushedTexture and frame:GetPushedTexture() or nil
    local disabled = frame.GetDisabledTexture and frame:GetDisabledTexture() or nil

    local inset = tab.iconInset
    if inset == nil then
        inset = 0
    end

    local textures = { normal, highlight, pushed, disabled }
    for index = 1, #textures do
        local texture = textures[index]
        if texture then
            if texture.ClearAllPoints then
                texture:ClearAllPoints()
            end
            if texture.SetPoint then
                texture:SetPoint("TOPLEFT", frame, "TOPLEFT", inset, -inset)
                texture:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -inset, inset)
            end
            ApplyIconTextureCoords(texture, tab)
        end
    end

    if highlight and highlight.SetBlendMode then
        highlight:SetBlendMode("ADD")
    end

    button.iconRegion = normal
    return normal
end

function TabContainer:New(options)
    local instance = BaseElement.New(self, options)
    instance.options.border = false
    instance.tabs = {}
    instance.tabButtons = {}
    instance.pageFrames = {}
    instance.builtTabs = {}
    instance.activeTabIndex = (options and options.activeTabIndex) or 1
    instance.tabBarFrame = nil
    instance.contentFrame = nil
    instance.tabBarBackground = nil
    instance.pagePaddingTop = options and options.pagePaddingTop or 2
    instance.pagePaddingLeft = options and options.pagePaddingLeft or 0
    instance.pagePaddingRight = options and options.pagePaddingRight or 0
    instance.pagePaddingBottom = options and options.pagePaddingBottom or 0
    instance.tabBarHeight = options and options.tabBarHeight or 20
    instance.tabSpacing = options and options.tabSpacing or 4
    instance.tabButtonHeight = options and options.tabButtonHeight or 18
    instance.tabRowSpacing = options and options.tabRowSpacing or 2
    instance.wrapTabs = options and options.wrapTabs == true or false
    instance.dynamicTabBarHeight = instance.tabBarHeight
    return instance
end

function TabContainer:UpdateContentFrameLayout()
    if not self.contentFrame or self.options.contentFrame then
        return
    end

    local frame = self.frame
    if not frame then
        return
    end

    local topInset = self.options.contentInsetTop or 0
    local barHeight = self.dynamicTabBarHeight or self.tabBarHeight

    self.contentFrame:ClearAllPoints()
    self.contentFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, -(barHeight + topInset))
    self.contentFrame:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, -(barHeight + topInset))
    self.contentFrame:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 0)
    self.contentFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
end

function TabContainer:GetContentFrame()
    if self.pageFrames and self.pageFrames[self.activeTabIndex or 1] then
        return self.pageFrames[self.activeTabIndex or 1]
    end

    return self.contentFrame or self.frame
end

function TabContainer:GetActivePageFrame()
    return self:GetContentFrame()
end

function TabContainer:GetActiveTab()
    return self.tabs[self.activeTabIndex or 1]
end

function TabContainer:GetTabCount()
    return #self.tabs
end

function TabContainer:GetTabs()
    return self.tabs or {}
end

function TabContainer:AddTab(tab)
    local normalized = NormalizeTab(tab, #self.tabs + 1)
    self.tabs[#self.tabs + 1] = normalized

    if self.frame then
        self:BuildTab(#self.tabs, normalized)
        self:LayoutTabs()
        self:ApplyActiveTab()
    end

    return normalized
end

function TabContainer:SetTabs(tabs)
    self.tabs = {}
    self.tabButtons = {}
    self.pageFrames = {}
    self.builtTabs = {}

    for index = 1, #(tabs or {}) do
        self.tabs[#self.tabs + 1] = NormalizeTab(tabs[index], index)
    end

    if self.frame then
        self:BuildTabs()
        self:LayoutTabs()
        self:SetActiveTab(self.activeTabIndex or 1)
    end
end

function TabContainer:SetActiveTab(index)
    if #self.tabs == 0 then
        self.activeTabIndex = 0
        return 0
    end

    local clamped = math.max(1, math.min(index or 1, #self.tabs))
    self.activeTabIndex = clamped
    self:ApplyActiveTab()
    return clamped
end

function TabContainer:EnsureTabBuilt(index)
    if not index or self.builtTabs[index] then
        return self.pageFrames[index]
    end

    local page = self.pageFrames[index]
    local tab = self.tabs[index]
    if not page or not tab then
        return page
    end

    if tab.builder then
        tab.builder(page, self, tab)
    end

    self.builtTabs[index] = true
    return page
end

function TabContainer:BuildTab(index, tab)
    local button = nil
    if tab.iconTexture then
        button = UI.ImageButton:New({
            name = (self.name or "TabContainer") .. "TabButton" .. index,
            width = tab.width or self.tabButtonHeight,
            height = self.tabButtonHeight,
            enableMouse = true,
            border = false,
            normalTexture = tab.iconTexture,
            highlightTexture = tab.iconTexture,
            pushedTexture = tab.iconTexture,
            disabledTexture = tab.iconTexture,
            tooltip = tab.tooltip or {
                title = tab.label or ("Tab " .. index),
            },
        })
    else
        button = UI.TextButton:New({
            name = (self.name or "TabContainer") .. "TabButton" .. index,
            width = tab.width or 90,
            height = self.tabButtonHeight,
            text = tab.label or ("Tab " .. index),
            fontFile = self.options.tabFontFile,
            fontSize = self.options.tabFontSize or ((Constants.FontSizes and Constants.FontSizes.TabLabel) or 10),
            fontFlags = self.options.tabFontFlags,
            labelColor = UI.ResolveColor(self.options.tabLabelColor, "tab.inactive"),
            enableMouse = true,
            border = false,
            tooltip = tab.tooltip,
        })
    end
    button:SetParent(self.tabBarFrame)
    button:Create()
    if tab.iconTexture then
        CreateIconTabTexture(button, tab)
        if button.ApplyThinBorder then
            button:ApplyThinBorder(button:GetFrame(), {
                borderColor = UI.ResolveColor(nil, "panel.border"),
                borderSize = 1,
            })
        end
        local frame = button:GetFrame()
        if frame and frame.CreateTexture then
            button.backgroundTexture = button.backgroundTexture or frame:CreateTexture(nil, "BACKGROUND")
            button.backgroundTexture:SetAllPoints(frame)
            local bg = UI.ResolveColor(nil, "panel.background")
            button.backgroundTexture:SetColorTexture(bg.r or 0.08, bg.g or 0.09, bg.b or 0.12, bg.a or 0.85)
            if button.iconRegion and button.iconRegion.SetDrawLayer then
                button.iconRegion:SetDrawLayer("ARTWORK", 1)
            end
        end
    end
    button:SetScript("OnClick", function()
        self:SetActiveTab(index)
    end)
    self.tabButtons[index] = button

    local page = CreateFrame("Frame", (self.name or "TabContainer") .. "Page" .. index, self.contentFrame)
    page:SetPoint("TOPLEFT", self.contentFrame, "TOPLEFT", self.pagePaddingLeft, -self.pagePaddingTop)
    page:SetPoint("TOPRIGHT", self.contentFrame, "TOPRIGHT", -self.pagePaddingRight, -self.pagePaddingTop)
    page:SetPoint("BOTTOMLEFT", self.contentFrame, "BOTTOMLEFT", self.pagePaddingLeft, self.pagePaddingBottom)
    page:SetPoint("BOTTOMRIGHT", self.contentFrame, "BOTTOMRIGHT", -self.pagePaddingRight, self.pagePaddingBottom)
    self.pageFrames[index] = page

    return button, page
end

function TabContainer:BuildTabs()
    for index = 1, #self.tabs do
        self:BuildTab(index, self.tabs[index])
    end
end

function TabContainer:LayoutTabs()
    if not self.tabBarFrame then
        return
    end

    local availableWidth = self.tabBarFrame:GetWidth() or 0
    if availableWidth <= 0 and self.frame and self.frame.GetWidth then
        availableWidth = self.frame:GetWidth() or 0
    end
    if availableWidth <= 0 then
        local parentFrame = self:GetParentFrame()
        if parentFrame and parentFrame.GetWidth then
            availableWidth = parentFrame:GetWidth() or 0
        end
    end
    availableWidth = math.max(0, availableWidth)
    local rows = {}
    local currentRow = {
        items = {},
        width = 0,
    }
    local maxItemsPerRow = tonumber(self.options.maxItemsPerRow) or tonumber(self.maxItemsPerRow)
    if maxItemsPerRow and maxItemsPerRow < 1 then
        maxItemsPerRow = nil
    end

    local function PushCurrentRow()
        if #currentRow.items > 0 then
            rows[#rows + 1] = currentRow
        end
        currentRow = {
            items = {},
            width = 0,
        }
    end

    for index = 1, #self.tabButtons do
        local button = self.tabButtons[index]
        if button and button.GetFrame and button:GetFrame() then
            local frame = button:GetFrame()
            local width = self.tabs[index].width or 90
            local itemWidth = width
            if #currentRow.items > 0 then
                itemWidth = itemWidth + self.tabSpacing
            end

            local hitWidthLimit = self.wrapTabs and #currentRow.items > 0 and availableWidth > 0 and (currentRow.width + itemWidth) > availableWidth
            local hitCountLimit = maxItemsPerRow and #currentRow.items >= maxItemsPerRow
            if hitWidthLimit or hitCountLimit then
                PushCurrentRow()
                itemWidth = width
            end

            currentRow.items[#currentRow.items + 1] = {
                frame = frame,
                width = width,
            }
            currentRow.width = currentRow.width + itemWidth
        end
    end
    PushCurrentRow()

    local rowCount = #rows
    local cursorY = 0

    for rowIndex = 1, rowCount do
        local row = rows[rowIndex]
        local cursorX = 0

        for itemIndex = 1, #row.items do
            local item = row.items[itemIndex]
            item.frame:ClearAllPoints()
            item.frame:SetPoint("TOPLEFT", self.tabBarFrame, "TOPLEFT", cursorX, -cursorY)
            item.frame:SetSize(item.width, self.tabButtonHeight)
            cursorX = cursorX + item.width + self.tabSpacing
        end

        cursorY = cursorY + self.tabButtonHeight + self.tabRowSpacing
    end

    local usedHeight = (rowCount * self.tabButtonHeight) + math.max(0, rowCount - 1) * self.tabRowSpacing
    self.dynamicTabBarHeight = math.max(self.tabBarHeight, usedHeight)
    self.tabBarFrame:SetHeight(self.dynamicTabBarHeight)
    self:UpdateContentFrameLayout()
end

function TabContainer:ApplyActiveTab()
    self:EnsureTabBuilt(self.activeTabIndex)

    for index = 1, #self.pageFrames do
        local page = self.pageFrames[index]
        if page and page.Show and page.Hide then
            if index == self.activeTabIndex then
                page:Show()
            else
                page:Hide()
            end
        end

        local button = self.tabButtons[index]
        if button and button.GetFrame and button:GetFrame() then
            local frame = button:GetFrame()
            if frame.SetAlpha then
                frame:SetAlpha(index == self.activeTabIndex and 1 or 0.75)
            end

            if button.SetLabelColor then
                local color = index == self.activeTabIndex and UI.ResolveColor(self.options.tabActiveLabelColor, "tab.active") or UI.ResolveColor(self.options.tabInactiveLabelColor, "tab.inactive")
                button:SetLabelColor(color.r or 1, color.g or 1, color.b or 1, color.a or 1)
            end
            if button.iconRegion and button.iconRegion.SetVertexColor then
                local color = index == self.activeTabIndex and UI.ResolveColor(nil, "tab.active") or UI.ResolveColor(nil, "tab.inactive")
                button.iconRegion:SetVertexColor(color.r or 1, color.g or 1, color.b or 1, 1)
            end
        end
    end
end

function TabContainer:Create()
    if self.frame then
        return self.frame
    end

    local parentFrame = self:GetParentFrame()
    if not parentFrame then
        if Debug.Internal then
            Debug.Internal("Addon.UI.TabContainer requires a parent frame before Create().")
        end

        error("A tab container requires a parent frame before Create().", 2)
    end

    local frame = CreateFrame("Frame", self.name, parentFrame, self.options.template)
    self:SetFrame(frame)
    self:SetPoint("TOPLEFT", parentFrame, "TOPLEFT", 0, 0)
    self:SetPoint("BOTTOMRIGHT", parentFrame, "BOTTOMRIGHT", 0, 0)
    frame:SetScript("OnSizeChanged", function()
        self:LayoutTabs()
    end)
    frame:SetScript("OnShow", function()
        self:LayoutTabs()
    end)

    self.tabBarFrame = CreateFrame("Frame", nil, frame)
    self.tabBarFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
    self.tabBarFrame:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
    self.tabBarFrame:SetHeight(self.tabBarHeight)
    self.tabBarFrame:SetScript("OnSizeChanged", function()
        self:LayoutTabs()
    end)

    self.tabBarBackground = self.tabBarFrame:CreateTexture(nil, "BACKGROUND")
    self.tabBarBackground:SetAllPoints(self.tabBarFrame)
    local bg = UI.ResolveColor(self.options.tabBarColor, "tab.bar")
    self.tabBarBackground:SetColorTexture(bg.r or 0, bg.g or 0, bg.b or 0, bg.a or 1)

    if self.options.contentFrame then
        self.contentFrame = self.options.contentFrame
    else
        self.contentFrame = CreateFrame("Frame", nil, frame)
        self:UpdateContentFrameLayout()
    end

    self:BuildTabs()
    self:LayoutTabs()
    self:SetActiveTab(self.activeTabIndex or 1)
    return self.frame
end
