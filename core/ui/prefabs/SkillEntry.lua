local _, Addon = ...

local UI = Addon.UI or {}
Addon.UI = UI
local BaseElement = UI.BaseElement
local Image = UI.Image
local Text = UI.Text
local ProgressBar = UI.ProgressBar

UI.SkillEntry = UI.SkillEntry or {}
local SkillEntry = UI.SkillEntry
SkillEntry.__index = SkillEntry
setmetatable(SkillEntry, { __index = BaseElement })

local DEFAULT_ICON = "Interface\\Icons\\INV_Misc_QuestionMark"

local function createBorderTexture(frame, pointA, pointB, size, isVertical)
    local texture = frame:CreateTexture(nil, "OVERLAY")
    texture:SetPoint(pointA, frame, pointA, 0, 0)
    texture:SetPoint(pointB, frame, pointB, 0, 0)
    if isVertical then
        texture:SetWidth(size)
    else
        texture:SetHeight(size)
    end
    return texture
end

function SkillEntry:New(options)
    local instance = BaseElement.New(self, options)
    instance.options.border = false
    instance.enabled = options == nil or options.enabled ~= false
    instance.isSelected = false
    instance.backgroundTexture = nil
    instance.hoverTexture = nil
    return instance
end

function SkillEntry:SetIcon(texturePath)
    if self.iconElement and self.iconElement.SetTexture then
        self.iconElement:SetTexture(texturePath or DEFAULT_ICON)
    end
end

function SkillEntry:SetSkillName(name)
    if self.nameElement and self.nameElement.SetText then
        self.nameElement:SetText(name or "")
    end
end

function SkillEntry:SetValueText(text)
    if self.valueElement and self.valueElement.SetText then
        self.valueElement:SetText(text or "")
    end
end

function SkillEntry:SetProgress(value, maxValue, text)
    if not self.progressBar then
        return
    end

    self.progressBar:SetMinMax(0, math.max(0, tonumber(maxValue) or 0))
    self.progressBar:SetValue(math.max(0, tonumber(value) or 0))
    self.progressBar:SetText(text or "")
end

function SkillEntry:SetBorderColor(r, g, b, a)
    local textures = {
        self.iconBorderTop,
        self.iconBorderBottom,
        self.iconBorderLeft,
        self.iconBorderRight,
    }
    for index = 1, #textures do
        local texture = textures[index]
        if texture and texture.SetColorTexture then
            texture:SetColorTexture(r or 1, g or 1, b or 1, a or 1)
        end
    end
end

function SkillEntry:SetEnabled(enabled)
    self.enabled = enabled ~= false
    if self.frame and self.frame.SetAlpha then
        self.frame:SetAlpha(self.enabled and 1 or 0.65)
    end
end

function SkillEntry:SetSelected(selected)
    self.isSelected = selected == true

    if self.backgroundTexture and self.backgroundTexture.SetColorTexture then
        local token = self.isSelected and "list.rowHover" or "list.rowBackground"
        local color = UI.ResolveColor(nil, token)
        self.backgroundTexture:SetColorTexture(color.r or 0.08, color.g or 0.09, color.b or 0.11, self.isSelected and 0.75 or 0.45)
    end
end

function SkillEntry:Create()
    if self.frame then
        return self.frame
    end

    local frame = CreateFrame("Button", self.name, self:GetParentFrame(), self.options.template)
    self:SetFrame(frame)
    frame:SetSize(self.options.width or 320, self.options.height or 28)
    frame:RegisterForClicks("AnyUp")

    self.backgroundTexture = frame:CreateTexture(nil, "BACKGROUND")
    self.backgroundTexture:SetAllPoints(frame)

    self.hoverTexture = frame:CreateTexture(nil, "ARTWORK")
    self.hoverTexture:SetAllPoints(frame)
    self.hoverTexture:SetColorTexture(1, 1, 1, 0.04)
    self.hoverTexture:Hide()

    self.rootLayout = UI.CreateLayout(UI.HorizontalLayoutGroup, frame, (self.name or "SkillEntry") .. "RootLayout", {
        spacing = 6,
        padding = { left = 0, right = 0, top = 2, bottom = 2 },
        fitChildrenWidth = true,
        fitChildrenHeight = false,
    })
    UI.Utils.AnchorFill(self.rootLayout, frame, 0, 0, 0, 0)

    self.iconPanel = UI.CreatePanel(self.rootLayout:GetFrame(), (self.name or "SkillEntry") .. "IconPanel", {
        width = 20,
        height = 20,
        contentInset = 0,
        showBorder = false,
    })
    self.rootLayout:AddChild(self.iconPanel)

    local iconFrame = self.iconPanel:GetFrame()

    self.iconBorderTop = createBorderTexture(iconFrame, "TOPLEFT", "TOPRIGHT", 1, false)
    self.iconBorderBottom = createBorderTexture(iconFrame, "BOTTOMLEFT", "BOTTOMRIGHT", 1, false)
    self.iconBorderLeft = createBorderTexture(iconFrame, "TOPLEFT", "BOTTOMLEFT", 1, true)
    self.iconBorderRight = createBorderTexture(iconFrame, "TOPRIGHT", "BOTTOMRIGHT", 1, true)
    self:SetBorderColor(0.42, 0.46, 0.52, 1)

    self.iconElement = Image:New({
        name = (self.name or "SkillEntry") .. "Icon",
        width = 20,
        height = 20,
        texture = self.options.iconTexture or DEFAULT_ICON,
        border = false,
        textureInsetLeft = 1,
        textureInsetTop = 1,
        textureInsetRight = 1,
        textureInsetBottom = 1,
    })
    self.iconElement:SetParent(iconFrame)
    self.iconElement:Create()
    self.iconElement:GetFrame():SetAllPoints(iconFrame)

    self.detailsLayout = UI.CreateLayout(UI.VerticalLayoutGroup, self.rootLayout:GetFrame(), (self.name or "SkillEntry") .. "DetailsLayout", {
        width = math.max(0, (self.options.width or 320) - 26),
        height = 20,
        spacing = 2,
        fitChildrenWidth = true,
        fitChildrenHeight = false,
        expandWidth = true,
        weight = 1,
    })
    self.rootLayout:AddChild(self.detailsLayout)

    self.headerRow = UI.CreateLayout(UI.HorizontalLayoutGroup, self.detailsLayout:GetFrame(), (self.name or "SkillEntry") .. "HeaderRow", {
        width = math.max(0, (self.options.width or 320) - 26),
        height = 12,
        spacing = 6,
        fitChildrenWidth = true,
        fitChildrenHeight = false,
    })
    self.detailsLayout:AddChild(self.headerRow)

    self.nameElement = Text:New({
        name = (self.name or "SkillEntry") .. "Name",
        width = 160,
        height = 12,
        text = "",
        justifyH = "LEFT",
        textColor = UI.ResolveColor(nil, "text.primary"),
        border = false,
        fontSize = 8,
        expandWidth = true,
        weight = 1,
    })
    self.headerRow:AddChild(self.nameElement)

    self.valueElement = Text:New({
        name = (self.name or "SkillEntry") .. "Value",
        width = 64,
        height = 12,
        text = "",
        justifyH = "RIGHT",
        textColor = UI.ResolveColor(nil, "text.secondary"),
        border = false,
        fontSize = 8,
    })
    self.headerRow:AddChild(self.valueElement)

    self.progressBar = ProgressBar:New({
        name = (self.name or "SkillEntry") .. "Progress",
        width = math.max(0, (self.options.width or 320) - 26),
        height = 6,
        text = "",
        fontSize = 6,
    })
    self.detailsLayout:AddChild(self.progressBar)
    if self.progressBar.label and self.progressBar.label.Hide then
        self.progressBar.label:Hide()
    end

    frame:HookScript("OnEnter", function()
        if self.hoverTexture and self.hoverTexture.Show and not self.isSelected then
            self.hoverTexture:Show()
        end
    end)
    frame:HookScript("OnLeave", function()
        if self.hoverTexture and self.hoverTexture.Hide then
            self.hoverTexture:Hide()
        end
    end)

    self:SetIcon(self.options.iconTexture or DEFAULT_ICON)
    self:SetSelected(false)
    self:SetEnabled(self.enabled)
    return self.frame
end

return SkillEntry
