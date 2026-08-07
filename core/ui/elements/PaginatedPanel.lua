local _, Addon = ...

local UI = Addon.UI or {}
Addon.UI = UI
local Panel = UI.Panel
local Debug = Addon.Debug or {}
local Constants = UI.Constants or {}
local Font = UI.Font or {}

UI.PaginatedPanel = UI.PaginatedPanel or {}
local PaginatedPanel = UI.PaginatedPanel
PaginatedPanel.__index = PaginatedPanel
setmetatable(PaginatedPanel, { __index = Panel })

function PaginatedPanel:New(options)
    local instance = Panel.New(self, options)
    instance.pages = {}
    instance.activePageIndex = 1
    instance.pageContainer = nil
    instance.navBar = nil
    instance.previousButton = nil
    instance.nextButton = nil
    instance.pageLabel = nil
    return instance
end

function PaginatedPanel:GetPageCount()
    return #self.pages
end

function PaginatedPanel:GetContentFrame()
    return self.pageContainer or self.frame
end

function PaginatedPanel:AttachPage(page)
    if not page then
        return page
    end

    if self.pageContainer and page.SetParent then
        page:SetParent(self.pageContainer)
    end

    local frame = page.GetFrame and page:GetFrame() or nil
    if frame and self.pageContainer and frame.ClearAllPoints and frame.SetPoint then
        frame:ClearAllPoints()
        frame:SetPoint("TOPLEFT", self.pageContainer, "TOPLEFT", 0, 0)
        frame:SetPoint("TOPRIGHT", self.pageContainer, "TOPRIGHT", 0, 0)
        frame:SetPoint("BOTTOMLEFT", self.pageContainer, "BOTTOMLEFT", 0, 0)
        frame:SetPoint("BOTTOMRIGHT", self.pageContainer, "BOTTOMRIGHT", 0, 0)
    end

    return page
end

function PaginatedPanel:AddPage(page)
    self.pages[#self.pages + 1] = page

    local alreadyChild = false
    for index = 1, #(self.children or {}) do
        if self.children[index] == page then
            alreadyChild = true
            break
        end
    end

    if not alreadyChild then
        self.children = self.children or {}
        table.insert(self.children, page)
    end

    if self.frame and page and page.Create and not page:IsCreated() then
        page:Create()
    end

    self:AttachPage(page)

    self:RefreshPages()
    return page
end

function PaginatedPanel:SetPage(index)
    if #self.pages == 0 then
        self.activePageIndex = 0
        return
    end

    self.activePageIndex = math.max(1, math.min(index or 1, #self.pages))
    self:RefreshPages()
end

function PaginatedPanel:NextPage()
    self:SetPage((self.activePageIndex or 1) + 1)
end

function PaginatedPanel:PreviousPage()
    self:SetPage((self.activePageIndex or 1) - 1)
end

function PaginatedPanel:RefreshPages()
    for index = 1, #self.pages do
        local page = self.pages[index]
        local frame = page and page.GetFrame and page:GetFrame() or nil

        if frame and frame.Show and frame.Hide then
            if index == self.activePageIndex then
                frame:Show()
            else
                frame:Hide()
            end
        end
    end

    if self.pageLabel and self.pageLabel.SetText then
        self.pageLabel:SetText(("%d / %d"):format(self.activePageIndex or 0, #self.pages))
    end

    if self.previousButton and self.previousButton.Enable and self.previousButton.Disable then
        if (self.activePageIndex or 1) > 1 then
            self.previousButton:Enable()
        else
            self.previousButton:Disable()
        end
    end

    if self.nextButton and self.nextButton.Enable and self.nextButton.Disable then
        if (self.activePageIndex or 1) < #self.pages then
            self.nextButton:Enable()
        else
            self.nextButton:Disable()
        end
    end
end

function PaginatedPanel:Create()
    if self.frame then
        return self.frame
    end

    local frame = CreateFrame("Frame", self.name, self:GetParentFrame(), self.options.template)
    self:SetFrame(frame)

    if self.options.backdrop and frame.SetBackdrop then
        frame:SetBackdrop(self.options.backdrop)
    end

    if frame.SetBackdropColor then
        local c = UI.ResolveColor(self.options.backdropColor or self.options.panelBackgroundColor or self.options.backgroundColor, "panel.background")
        frame:SetBackdropColor(c.r or 0, c.g or 0, c.b or 0, c.a or 1)
    end

    self:ApplyPanelBorders()

    self.pageContainer = CreateFrame("Frame", nil, frame)
    self.pageContainer:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
    self.pageContainer:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
    self.pageContainer:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 34)
    self.pageContainer:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 34)

    self.navBar = CreateFrame("Frame", nil, frame)
    self.navBar:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 0)
    self.navBar:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
    self.navBar:SetHeight(30)

    self.previousButton = UI.TextButton:New({
        name = (self.name or "PaginatedPanel") .. "Previous",
        width = 80,
        height = 22,
        text = self.options.previousText or "Previous",
        fontFile = self.options.navFontFile,
        fontSize = self.options.navFontSize or ((Constants.FontSizes and Constants.FontSizes.PaginatedNav) or 12),
        fontFlags = self.options.navFontFlags,
        labelColor = UI.ResolveColor(self.options.navLabelColor, "text.primary"),
        enableMouse = true,
    })
    self.previousButton:SetParent(self.navBar)
    self.previousButton:Create()
    self.previousButton:SetScript("OnClick", function()
        self:PreviousPage()
    end)

    self.nextButton = UI.TextButton:New({
        name = (self.name or "PaginatedPanel") .. "Next",
        width = 80,
        height = 22,
        text = self.options.nextText or "Next",
        fontFile = self.options.navFontFile,
        fontSize = self.options.navFontSize or ((Constants.FontSizes and Constants.FontSizes.PaginatedNav) or 12),
        fontFlags = self.options.navFontFlags,
        labelColor = UI.ResolveColor(self.options.navLabelColor, "text.primary"),
        enableMouse = true,
    })
    self.nextButton:SetParent(self.navBar)
    self.nextButton:Create()
    self.nextButton:SetScript("OnClick", function()
        self:NextPage()
    end)

    self.pageLabel = self.navBar:CreateFontString(nil, "OVERLAY")
    self.pageLabel:SetPoint("CENTER", self.navBar, "CENTER", 0, 0)
    Font:Apply(self.pageLabel, self.options, {
        fontSize = (Constants.FontSizes and Constants.FontSizes.PaginatedPage) or 10,
    })
    if self.pageLabel.SetTextColor then
        local color = UI.ResolveColor(self.options.pageLabelColor, "text.secondary")
        self.pageLabel:SetTextColor(color.r or 1, color.g or 1, color.b or 1, color.a or 1)
    end
    self.pageLabel:SetText("0 / 0")

    self.previousButton:SetPoint("LEFT", self.navBar, "LEFT", 6, 0)
    self.nextButton:SetPoint("RIGHT", self.navBar, "RIGHT", -6, 0)

    self:CreateChildren(self.pageContainer)

    for index = 1, #self.pages do
        self:AttachPage(self.pages[index])
    end

    self:RefreshPages()
    return self.frame
end
