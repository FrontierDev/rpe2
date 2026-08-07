local _, Addon = ...

local UI = Addon.UI or {}
Addon.UI = UI
local BaseElement = UI.BaseElement
local Debug = Addon.Debug or {}

UI.Panel = UI.Panel or {}
local Panel = UI.Panel
Panel.__index = Panel
setmetatable(Panel, { __index = BaseElement })

function Panel:New(options)
    local instance = BaseElement.New(self, options)
    instance.options.border = false
    instance.options.showWhenUIHidden = instance.options.showWhenUIHidden ~= false
    instance.elements = instance.children
    instance.contentFrame = nil
    instance.tabContainer = nil
    instance.panelBackgroundTexture = nil
    instance.panelBorders = nil
    return instance
end

function Panel:EnsureContentFrame()
    if self.contentFrame or not self.frame then
        return self.contentFrame
    end

    local inset = self.options.contentInset or self.options.panelContentInset or self.options.panelBorderSize or self.options.borderSize or 1
    self.contentFrame = CreateFrame("Frame", nil, self.frame)
    self.contentFrame:SetPoint("TOPLEFT", self.frame, "TOPLEFT", inset, -inset)
    self.contentFrame:SetPoint("BOTTOMRIGHT", self.frame, "BOTTOMRIGHT", -inset, inset)
    return self.contentFrame
end

function Panel:EnsureTabContainer()
    if self.tabContainer or not self.contentFrame or not UI.TabContainer then
        return self.tabContainer
    end

    local tabs = self.options.tabs
    if not tabs or #tabs == 0 then
        return nil
    end

    self.tabContainer = UI.TabContainer:New({
        name = (self.name or "Panel") .. "TabContainer",
        border = false,
        tabBarHeight = self.options.tabBarHeight or 20,
        tabButtonHeight = self.options.tabButtonHeight or 18,
        tabSpacing = self.options.tabSpacing or 4,
        tabRowSpacing = self.options.tabRowSpacing or 2,
        wrapTabs = self.options.wrapTabs == true,
        maxItemsPerRow = self.options.maxItemsPerRow,
        tabBarColor = UI.ResolveColor(self.options.tabBarColor, "tab.bar"),
        tabLabelColor = UI.ResolveColor(self.options.tabLabelColor, "tab.inactive"),
        tabFontFile = self.options.tabFontFile,
        tabFontSize = self.options.tabFontSize,
        tabFontFlags = self.options.tabFontFlags,
        activeTabIndex = self.options.activeTabIndex or 1,
        pagePaddingTop = self.options.pagePaddingTop or 2,
        pagePaddingLeft = self.options.pagePaddingLeft or 0,
        pagePaddingRight = self.options.pagePaddingRight or 0,
        pagePaddingBottom = self.options.pagePaddingBottom or 0,
    })
    self.tabContainer:SetParent(self.contentFrame)
    self.tabContainer:SetTabs(tabs)
    self.tabContainer:Create()
    return self.tabContainer
end

function Panel:GetContentFrame()
    if self.tabContainer and self.tabContainer.GetContentFrame then
        return self.tabContainer:GetContentFrame()
    end

    return self.contentFrame or self.frame
end

function Panel:ApplyPanelBorders()
    if not self.frame or not self.frame.CreateTexture then
        return
    end

    if self.options.showBorder == false or (self.options.panelBorderSize or self.options.borderSize or 1) <= 0 then
        if self.panelBorders then
            for _, border in pairs(self.panelBorders) do
                if border and border.Hide then
                    border:Hide()
                end
            end
        end
        return
    end

    local frame = self.frame
    local borderSize = self.options.panelBorderSize or self.options.borderSize or 1
    local borderColor = UI.ResolveColor(self.options.panelBorderColor, "panel.border")
    local topColor = UI.ResolveColor(self.options.panelBorderTopColor, nil, borderColor)
    local leftColor = UI.ResolveColor(self.options.panelBorderLeftColor, nil, borderColor)
    local rightColor = UI.ResolveColor(self.options.panelBorderRightColor, nil, borderColor)
    local bottomColor = UI.ResolveColor(self.options.panelBorderBottomColor, nil, borderColor)
    local borders = self.panelBorders or {}
    self.panelBorders = borders

    if not borders.top then
        borders.top = frame:CreateTexture(nil, "ARTWORK")
    end
    if not borders.bottom then
        borders.bottom = frame:CreateTexture(nil, "ARTWORK")
    end
    if not borders.left then
        borders.left = frame:CreateTexture(nil, "ARTWORK")
    end
    if not borders.right then
        borders.right = frame:CreateTexture(nil, "ARTWORK")
    end

    borders.top:ClearAllPoints()
    borders.top:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
    borders.top:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
    borders.top:SetHeight(borderSize)
    borders.top:SetColorTexture(topColor.r or 0, topColor.g or 0, topColor.b or 0, topColor.a or 1)
    borders.top:Show()

    borders.bottom:ClearAllPoints()
    borders.bottom:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 0)
    borders.bottom:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
    borders.bottom:SetHeight(borderSize)
    borders.bottom:SetColorTexture(bottomColor.r or 0, bottomColor.g or 0, bottomColor.b or 0, bottomColor.a or 1)
    borders.bottom:Show()

    borders.left:ClearAllPoints()
    borders.left:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
    borders.left:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 0)
    borders.left:SetWidth(borderSize)
    borders.left:SetColorTexture(leftColor.r or 0, leftColor.g or 0, leftColor.b or 0, leftColor.a or 1)
    borders.left:Show()

    borders.right:ClearAllPoints()
    borders.right:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
    borders.right:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
    borders.right:SetWidth(borderSize)
    borders.right:SetColorTexture(rightColor.r or 0, rightColor.g or 0, rightColor.b or 0, rightColor.a or 1)
    borders.right:Show()
end

function Panel:AddElement(element)
    self.children = self.children or {}
    table.insert(self.children, element)

    local parent = self:GetContentFrame() or self.frame or self
    if element and element.SetParent then
        element:SetParent(parent)
    end

    if self.frame and element and element.Create and not element:IsCreated() then
        element:Create()
    end

    return element
end

function Panel:AddPanel(panel)
    return self:AddElement(panel)
end

function Panel:GetElements()
    return self:GetChildren()
end

function Panel:GetTabs()
    if self.tabContainer and self.tabContainer.GetTabs then
        return self.tabContainer:GetTabs()
    end

    return self.options.tabs or {}
end

function Panel:SetTabs(tabs)
    self.options.tabs = tabs or {}

    if self.tabContainer and self.tabContainer.SetTabs then
        self.tabContainer:SetTabs(self.options.tabs)
    elseif self.frame then
        self:EnsureContentFrame()
        self:EnsureTabContainer()
    end

    return self.options.tabs
end

function Panel:AddTab(tab)
    self.options.tabs = self.options.tabs or {}
    table.insert(self.options.tabs, tab)

    if self.tabContainer and self.tabContainer.AddTab then
        self.tabContainer:AddTab(tab)
    elseif self.frame then
        self:EnsureContentFrame()
        self:EnsureTabContainer()
    end

    return tab
end

function Panel:GetActiveTab()
    if self.tabContainer and self.tabContainer.GetActiveTab then
        return self.tabContainer:GetActiveTab()
    end

    return nil
end

function Panel:SetActiveTab(index)
    if self.tabContainer and self.tabContainer.SetActiveTab then
        return self.tabContainer:SetActiveTab(index)
    end

    self.options.activeTabIndex = index
    return index
end

function Panel:Create()
    if self.frame then
        return self.frame
    end

    local frame = CreateFrame("Frame", self.name, self:GetParentFrame(), self.options.template)
    self:SetFrame(frame)

    if self.options.backdrop and frame.SetBackdrop then
        frame:SetBackdrop(self.options.backdrop)
    end

    local backgroundColor = UI.ResolveColor(self.options.panelBackgroundColor or self.options.backgroundColor or self.options.backdropColor, "panel.background")
    if backgroundColor and frame.CreateTexture then
        if not self.panelBackgroundTexture then
            self.panelBackgroundTexture = frame:CreateTexture(nil, "BACKGROUND")
            self.panelBackgroundTexture:SetAllPoints(frame)
        end

        self.panelBackgroundTexture:SetColorTexture(
            backgroundColor.r or 0,
            backgroundColor.g or 0,
            backgroundColor.b or 0,
            backgroundColor.a or 1
        )
    elseif frame.SetBackdropColor then
        local c = UI.ResolveColor(self.options.backdropColor or self.options.panelBackgroundColor or self.options.backgroundColor, "panel.background")
        frame:SetBackdropColor(c.r or 0, c.g or 0, c.b or 0, c.a or 1)
    end

    self:ApplyPanelBorders()

    self:EnsureContentFrame()
    self:EnsureTabContainer()

    self:CreateChildren(self:GetContentFrame())
    return self.frame
end
