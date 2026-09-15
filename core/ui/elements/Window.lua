local _, Addon = ...

local UI = Addon.UI or {}
Addon.UI = UI
local BaseElement = UI.BaseElement
local Debug = Addon.Debug or {}
local Constants = UI.Constants or {}

UI.Window = UI.Window or {}
local Window = UI.Window
Window.__index = Window
setmetatable(Window, { __index = BaseElement })

function Window:New(options)
    local instance = BaseElement.New(self, options)
    instance.options.border = false
    instance.options.showWhenUIHidden = instance.options.showWhenUIHidden ~= false
    instance.panels = instance.children
    instance.contentFrame = nil
    instance.tabContainer = nil
    instance.headerTabFrame = nil
    instance.headerFrame = nil
    instance.backgroundTexture = nil
    instance.topBorder = nil
    instance.bottomBorder = nil
    instance.titleRegion = nil
    instance.titleText = nil
    instance.closeButton = nil
    return instance
end

local function GetCloseButtonTexture()
    return "Interface\\AddOns\\RPEngine2\\data\\textures\\ui\\close_button.png"
end

local function ApplyTitleStyle(titleRegion, options)
    if not titleRegion then
        return
    end

    if titleRegion.SetJustifyH then
        titleRegion:SetJustifyH("LEFT")
    end

    if titleRegion.SetTextColor then
        local titleColor = UI.ResolveColor(options and options.titleColor, "text.secondary")
        titleRegion:SetTextColor(titleColor.r or 0.72, titleColor.g or 0.74, titleColor.b or 0.78, titleColor.a or 1)
    end

    if titleRegion.SetFont then
        local fontFile = (options and options.titleFontFile) or ((Constants.FontFiles and Constants.FontFiles.Default) or "Fonts\\FRIZQT__.TTF")
        local fontSize = (Constants.FontSizes and Constants.FontSizes.WindowTitle)
        local fontFlags = (options and options.titleFontFlags) or nil
        titleRegion:SetFont(fontFile, fontSize, fontFlags)
    end
end

local function EnsureTitleRegion(self)
    if self.titleRegion then
        return self.titleRegion
    end

    local titleParent = self.headerFrame or self.frame
    if not titleParent then
        return nil
    end

    self.titleRegion = titleParent:CreateFontString(nil, "OVERLAY")
    self.titleRegion:SetPoint("LEFT", titleParent, "LEFT", 8, 0)
    self.titleRegion:SetPoint("RIGHT", titleParent, "RIGHT", -22, 0)
    ApplyTitleStyle(self.titleRegion, self.options)
    return self.titleRegion
end

local function EnsureCloseButton(self)
    if self.closeButton or not self.headerFrame then
        return self.closeButton
    end

    self.closeButton = UI.ImageButton:New({
        name = (self.name or "Window") .. "CloseButton",
        width = 16,
        height = 16,
        border = false,
        normalTexture = GetCloseButtonTexture(),
        highlightTexture = GetCloseButtonTexture(),
        pushedTexture = GetCloseButtonTexture(),
        disabledTexture = GetCloseButtonTexture(),
        template = nil,
    })
    self.closeButton:SetParent(self.headerFrame)
    self.closeButton:Create()
    self.closeButton:SetScript("OnClick", function()
        if self.options.onClose then
            self.options.onClose(self)
        end

        self:Hide()
    end)

    if self.closeButton.GetFrame and self.closeButton:GetFrame() then
        local closeFrame = self.closeButton:GetFrame()
        if closeFrame.SetSize then
            closeFrame:SetSize(16, 16)
        end
    end

    return self.closeButton
end

local function GetHeaderTabHostWidth(self)
    if self.options.headerTabWidth then
        return self.options.headerTabWidth
    end

    local totalWidth = 0
    local tabs = self.options.tabs or {}
    local spacing = self.options.tabSpacing or 4

    for index = 1, #tabs do
        local tab = tabs[index]
        local tabWidth = 90

        if type(tab) == "table" then
            tabWidth = tab.width or tab.tabWidth or tabWidth
        end

        totalWidth = totalWidth + tabWidth

        if index < #tabs then
            totalWidth = totalWidth + spacing
        end
    end

    return totalWidth
end

local function LayoutHeaderChrome(self)
    if not self.headerFrame then
        return
    end

    local headerHeight = self.options.headerHeight or ((Constants.Heights and Constants.Heights.WindowHeader) or 16)
    local hasTabs = self.options.tabs and #self.options.tabs > 0 and self.headerTabFrame ~= nil
    local titleRegion = EnsureTitleRegion(self)
    local closeButton = EnsureCloseButton(self)
    local closeFrame = closeButton and closeButton.GetFrame and closeButton:GetFrame() or nil

    if self.headerTabFrame then
        self.headerTabFrame:ClearAllPoints()
    end

    if titleRegion then
        titleRegion:ClearAllPoints()
        titleRegion:SetPoint("LEFT", self.headerFrame, "LEFT", 8, 0)

        if hasTabs and self.headerTabFrame then
            titleRegion:SetPoint("RIGHT", self.headerTabFrame, "LEFT", -8, 0)
        else
            titleRegion:SetPoint("RIGHT", self.headerFrame, "RIGHT", -22, 0)
        end
    end

    if closeFrame and closeFrame.SetPoint then
        closeFrame:ClearAllPoints()
        closeFrame:SetPoint("RIGHT", self.headerFrame, "RIGHT", -1, 0)
    end

    if hasTabs and self.headerTabFrame then
        local tabWidth = GetHeaderTabHostWidth(self)
        self.headerTabFrame:SetWidth(tabWidth)
        if closeFrame then
            self.headerTabFrame:SetPoint("RIGHT", closeFrame, "LEFT", -6, 0)
        else
            self.headerTabFrame:SetPoint("RIGHT", self.headerFrame, "RIGHT", -22, 0)
        end
        self.headerTabFrame:SetPoint("TOP", self.headerFrame, "TOP", 0, 0)
        self.headerTabFrame:SetPoint("BOTTOM", self.headerFrame, "BOTTOM", 0, 0)
        self.headerTabFrame:SetHeight(headerHeight)
    end
end

function Window:EnsureTabContainer()
    if self.tabContainer or not self.contentFrame or not UI.TabContainer then
        return self.tabContainer
    end

    local tabs = self.options.tabs
    if not tabs or #tabs == 0 then
        return nil
    end

    if not self.headerTabFrame and self.headerFrame then
        self.headerTabFrame = CreateFrame("Frame", nil, self.headerFrame)
    end

    self.tabContainer = UI.TabContainer:New({
        name = (self.name or "Window") .. "TabContainer",
        border = false,
        tabBarHeight = self.options.tabBarHeight or ((Constants.Heights and Constants.Heights.WindowHeader) or 16),
        tabButtonHeight = self.options.tabButtonHeight or 16,
        tabSpacing = self.options.tabSpacing or 4,
        tabBarColor = UI.ResolveColor(self.options.tabBarColor, "tab.bar"),
        tabLabelColor = UI.ResolveColor(self.options.tabLabelColor, "tab.inactive"),
        tabFontFile = self.options.tabFontFile,
        tabFontSize = self.options.tabFontSize,
        tabFontFlags = self.options.tabFontFlags,
        contentFrame = self.contentFrame,
        activeTabIndex = self.options.activeTabIndex or 1,
        pagePaddingTop = self.options.pagePaddingTop or 2,
        pagePaddingLeft = self.options.pagePaddingLeft or 0,
        pagePaddingRight = self.options.pagePaddingRight or 0,
        pagePaddingBottom = self.options.pagePaddingBottom or 0,
    })
    self.tabContainer:SetParent(self.headerTabFrame or self.headerFrame)
    self.tabContainer:SetTabs(tabs)
    self.tabContainer:Create()
    LayoutHeaderChrome(self)
    return self.tabContainer
end

function Window:GetActiveContentFrame()
    if self.tabContainer and self.tabContainer.GetContentFrame then
        return self.tabContainer:GetContentFrame()
    end

    return self.contentFrame or self.frame
end

function Window:ApplyChrome()
    if not self.frame then
        return
    end

    local frame = self.frame
    local borderSize = self.options.borderSize or ((Constants.Window and Constants.Window.BorderSize) or 2)
    local headerHeight = self.options.headerHeight or ((Constants.Heights and Constants.Heights.WindowHeader) or 16)
    local bg = UI.ResolveColor(self.options.backgroundColor, "window.background")
    local border = UI.ResolveColor(self.options.borderColor, "window.border")
    local headerBg = UI.ResolveColor(self.options.headerBackgroundColor, "window.headerBackground")

    if not self.backgroundTexture then
        self.backgroundTexture = frame:CreateTexture(nil, "BACKGROUND")
        self.backgroundTexture:SetPoint("TOPLEFT", frame, "TOPLEFT", borderSize, -borderSize)
        self.backgroundTexture:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -borderSize, borderSize)
    end
    self.backgroundTexture:SetColorTexture(bg.r or 0, bg.g or 0, bg.b or 0, bg.a or 0.88)

    if not self.topBorder then
        self.topBorder = frame:CreateTexture(nil, "BORDER")
        self.topBorder:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
        self.topBorder:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
    end
    self.topBorder:SetHeight(borderSize)
    self.topBorder:SetColorTexture(border.r or 1, border.g or 1, border.b or 1, border.a or 1)

    if not self.bottomBorder then
        self.bottomBorder = frame:CreateTexture(nil, "BORDER")
        self.bottomBorder:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 0)
        self.bottomBorder:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
    end
    self.bottomBorder:SetHeight(borderSize)
    self.bottomBorder:SetColorTexture(border.r or 1, border.g or 1, border.b or 1, border.a or 1)

    if not self.headerFrame then
        self.headerFrame = CreateFrame("Frame", nil, frame)
        self.headerFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", borderSize, -borderSize)
        self.headerFrame:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -borderSize, -borderSize)
        self.headerFrame:SetHeight(headerHeight)
    end

    if not self.headerFrame.backgroundTexture then
        self.headerFrame.backgroundTexture = self.headerFrame:CreateTexture(nil, "BACKGROUND")
        self.headerFrame.backgroundTexture:SetAllPoints(self.headerFrame)
    end
    self.headerFrame.backgroundTexture:SetColorTexture(headerBg.r or 0, headerBg.g or 0, headerBg.b or 0, headerBg.a or 1)

    EnsureTitleRegion(self)
    EnsureCloseButton(self)
    if self.options.tabs and #self.options.tabs > 0 then
        if not self.headerTabFrame then
            self.headerTabFrame = CreateFrame("Frame", nil, self.headerFrame)
        end

        self.headerTabFrame:SetPoint("TOP", self.headerFrame, "TOP", 0, 0)
        self.headerTabFrame:SetPoint("BOTTOM", self.headerFrame, "BOTTOM", 0, 0)
    end

    LayoutHeaderChrome(self)
end

function Window:GetContentFrame()
    return self:GetActiveContentFrame()
end

function Window:SetTitle(text)
    self.titleText = text

    if not self.frame then
        return
    end

    if not self.titleRegion then
        EnsureTitleRegion(self)
    end

    if self.titleRegion and self.titleRegion.SetFont then
        self.titleRegion:SetFont(self.options.titleFontFile or ((Constants.FontFiles and Constants.FontFiles.Default) or "Fonts\\FRIZQT__.TTF"), self.options.titleFontSize or ((Constants.FontSizes and Constants.FontSizes.WindowTitle) or 12), self.options.titleFontFlags)
    end

    ApplyTitleStyle(self.titleRegion, self.options)
    LayoutHeaderChrome(self)

    if self.titleRegion then
        self.titleRegion:SetText(text)
    end
end

function Window:GetTitle()
    return self.titleText
end

function Window:AddPanel(panel)
    self.children = self.children or {}
    table.insert(self.children, panel)

    local parent = self:GetContentFrame() or self.frame or self
    if panel and panel.SetParent then
        panel:SetParent(parent)
    end

    if self.frame and panel and panel.Create and not panel:IsCreated() then
        panel:Create()
    end

    return panel
end

function Window:GetPanels()
    return self.panels or {}
end

function Window:GetTabs()
    if self.tabContainer and self.tabContainer.GetTabs then
        return self.tabContainer:GetTabs()
    end

    return self.options.tabs or {}
end

function Window:SetTabs(tabs)
    self.options.tabs = tabs or {}

    if self.tabContainer and self.tabContainer.SetTabs then
        self.tabContainer:SetTabs(self.options.tabs)
    elseif self.frame then
        self:EnsureTabContainer()
    end

    return self.options.tabs
end

function Window:AddTab(tab)
    self.options.tabs = self.options.tabs or {}
    table.insert(self.options.tabs, tab)

    if self.tabContainer and self.tabContainer.AddTab then
        self.tabContainer:AddTab(tab)
    elseif self.frame then
        self:EnsureTabContainer()
    end

    return tab
end

function Window:GetActiveTab()
    if self.tabContainer and self.tabContainer.GetActiveTab then
        return self.tabContainer:GetActiveTab()
    end

    return nil
end

function Window:SetActiveTab(index)
    if self.tabContainer and self.tabContainer.SetActiveTab then
        return self.tabContainer:SetActiveTab(index)
    end

    self.options.activeTabIndex = index
    return index
end

function Window:Create()
    if self.frame then
        return self.frame
    end

    local template = self.options.template
    local frame = CreateFrame("Frame", self.name, self:GetParentFrame(), template)
    self:SetFrame(frame)
    self:ApplyChrome()

    if self.options.movable then
        self.headerFrame:EnableMouse(true)
        self.headerFrame:SetMovable(true)
        self.headerFrame:RegisterForDrag("LeftButton")
        self.headerFrame:SetScript("OnMouseDown", function(_, button)
            if button == "LeftButton" then
                frame:StartMoving()
            end
        end)
        self.headerFrame:SetScript("OnMouseUp", function()
            frame:StopMovingOrSizing()
        end)
    end

    self.contentFrame = CreateFrame("Frame", nil, frame)
    self.contentFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", self.options.contentInsetLeft or 0, -(self.options.contentInsetTop or 0))
    self.contentFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -(self.options.contentInsetRight or 0), self.options.contentInsetBottom or 0)

    self:EnsureTabContainer()

    if self.titleText then
        self:SetTitle(self.titleText)
    end

    self:CreateChildren(self:GetContentFrame())
    return self.frame
end
