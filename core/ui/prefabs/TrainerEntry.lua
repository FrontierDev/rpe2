local _, Addon = ...

local UI = Addon.UI or {}
Addon.UI = UI
local BaseElement = UI.BaseElement
local Image = UI.Image
local Text = UI.Text
local Constants = UI.Constants or {}

UI.TrainerEntry = UI.TrainerEntry or {}
local TrainerEntry = UI.TrainerEntry
TrainerEntry.__index = TrainerEntry
setmetatable(TrainerEntry, { __index = BaseElement })

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

local function applyBorderColor(texture, color)
    if not texture or not texture.SetColorTexture then
        return
    end

    texture:SetColorTexture(color.r or 1, color.g or 1, color.b or 1, color.a or 1)
end

function TrainerEntry:New(options)
    local instance = BaseElement.New(self, options)
    instance.options.border = false
    instance.enabled = options == nil or options.enabled ~= false
    instance.isSelected = options and options.selected == true or false
    instance.backgroundTexture = nil
    instance.hoverTexture = nil
    instance.iconFrame = nil
    instance.iconElement = nil
    instance.iconTexture = nil
    instance.iconBorderTop = nil
    instance.iconBorderBottom = nil
    instance.iconBorderLeft = nil
    instance.iconBorderRight = nil
    instance.nameElement = nil
    instance.nameRegion = nil
    instance.statusElement = nil
    instance.statusRegion = nil
    return instance
end

function TrainerEntry:SetIcon(texturePath)
    self:SetOption("iconTexture", texturePath)
    if self.iconElement and self.iconElement.SetTexture then
        self.iconElement:SetTexture(texturePath or DEFAULT_ICON)
    elseif self.iconTexture and self.iconTexture.SetTexture then
        self.iconTexture:SetTexture(texturePath or DEFAULT_ICON)
    end
end

function TrainerEntry:SetRecipeName(recipeName)
    self:SetOption("recipeName", recipeName)
    if self.nameElement and self.nameElement.SetText then
        self.nameElement:SetText(recipeName or "")
    elseif self.nameRegion and self.nameRegion.SetText then
        self.nameRegion:SetText(recipeName or "")
    end
end

function TrainerEntry:SetStatusText(statusText)
    self:SetOption("statusText", statusText)
    if self.statusElement and self.statusElement.SetText then
        self.statusElement:SetText(statusText or "")
    elseif self.statusRegion and self.statusRegion.SetText then
        self.statusRegion:SetText(statusText or "")
    end
end

function TrainerEntry:SetNameColor(r, g, b, a)
    if self.nameRegion and self.nameRegion.SetTextColor then
        self.nameRegion:SetTextColor(r or 1, g or 1, b or 1, a or 1)
    end
end

function TrainerEntry:SetStatusColor(r, g, b, a)
    if self.statusRegion and self.statusRegion.SetTextColor then
        self.statusRegion:SetTextColor(r or 1, g or 1, b or 1, a or 1)
    end
end

function TrainerEntry:SetBorderColor(r, g, b, a)
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

function TrainerEntry:SetSelected(selected)
    self.isSelected = selected == true

    if self.backgroundTexture and self.backgroundTexture.SetColorTexture then
        local token = self.isSelected and "list.rowHover" or "list.rowBackground"
        local color = UI.ResolveColor(nil, token)
        self.backgroundTexture:SetColorTexture(
            color.r or 0.08,
            color.g or 0.09,
            color.b or 0.11,
            self.isSelected and 0.75 or 0.45
        )
    end
end

function TrainerEntry:SetLayoutMetrics(width, height)
    local defaults = (Constants.Prefabs and Constants.Prefabs.TrainerEntry) or {}
    local resolvedWidth = width or self.options.width or defaults.Width or 296
    local resolvedHeight = height or self.options.height or defaults.Height or 24
    local iconSize = self.options.iconSize or defaults.IconSize or 22
    local iconGap = self.options.iconGap or defaults.IconGap or 8
    local statusWidth = self.options.statusWidth or defaults.StatusWidth or 104
    local statusGap = self.options.statusGap or defaults.StatusGap or 8
    local textWidth = math.max(0, resolvedWidth - iconSize - iconGap - statusWidth - statusGap)

    self.options.width = resolvedWidth
    self.options.height = resolvedHeight

    if self.frame and self.frame.SetSize then
        self.frame:SetSize(resolvedWidth, resolvedHeight)
    end
    if self.iconFrame and self.iconFrame.SetSize then
        self.iconFrame:SetSize(iconSize, iconSize)
    end

    local nameFrame = self.nameElement and self.nameElement.GetFrame and self.nameElement:GetFrame() or nil
    if nameFrame and nameFrame.SetSize then
        nameFrame:SetSize(textWidth, resolvedHeight)
    end

    local statusFrame = self.statusElement and self.statusElement.GetFrame and self.statusElement:GetFrame() or nil
    if statusFrame and statusFrame.SetSize then
        statusFrame:SetSize(statusWidth, resolvedHeight)
    end
end

function TrainerEntry:RefreshVisualState()
    local enabled = self.enabled ~= false
    local brightness = enabled and 1 or 0.55
    local alpha = enabled and 1 or 0.8

    if self.iconTexture and self.iconTexture.SetDesaturated then
        self.iconTexture:SetDesaturated(not enabled)
    end
    if self.iconTexture and self.iconTexture.SetVertexColor then
        self.iconTexture:SetVertexColor(brightness, brightness, brightness, 1)
    end

    if self.nameRegion and self.nameRegion.SetAlpha then
        self.nameRegion:SetAlpha(alpha)
    end
    if self.statusRegion and self.statusRegion.SetAlpha then
        self.statusRegion:SetAlpha(alpha)
    end
    if self.frame and self.frame.SetAlpha then
        self.frame:SetAlpha(enabled and 1 or 0.9)
    end
end

function TrainerEntry:SetEnabled(enabled)
    self.enabled = enabled ~= false
    if self.frame and self.frame.EnableMouse then
        self.frame:EnableMouse(self.enabled)
    end
    self:RefreshVisualState()
    return self.enabled
end

function TrainerEntry:Create()
    if self.frame then
        return self.frame
    end

    local parentFrame = self:GetParentFrame()
    if not parentFrame then
        error("A trainer entry prefab requires a parent frame before Create().", 2)
    end

    local defaults = (Constants.Prefabs and Constants.Prefabs.TrainerEntry) or {}
    local width = self.options.width or defaults.Width or 296
    local height = self.options.height or defaults.Height or 24
    local iconSize = self.options.iconSize or defaults.IconSize or 22
    local iconGap = self.options.iconGap or defaults.IconGap or 8
    local statusWidth = self.options.statusWidth or defaults.StatusWidth or 104
    local statusGap = self.options.statusGap or defaults.StatusGap or 8
    local textWidth = math.max(0, width - iconSize - iconGap - statusWidth - statusGap)

    local frame = CreateFrame("Button", self.name, parentFrame, self.options.template)
    self:SetFrame(frame)
    frame:RegisterForClicks("AnyUp")
    frame:SetSize(width, height)
    frame:EnableMouse(true)

    self.backgroundTexture = frame:CreateTexture(nil, "BACKGROUND")
    self.backgroundTexture:SetAllPoints(frame)

    self.hoverTexture = frame:CreateTexture(nil, "ARTWORK")
    self.hoverTexture:SetAllPoints(frame)
    self.hoverTexture:SetColorTexture(1, 1, 1, 0.04)
    self.hoverTexture:Hide()

    self.iconFrame = CreateFrame("Frame", (self.name or "TrainerEntry") .. "IconFrame", frame)
    self.iconFrame:SetPoint("LEFT", frame, "LEFT", 0, 0)
    self.iconFrame:SetSize(iconSize, iconSize)
    local borderSize = self.options.iconBorderSize or 1
    local borderColor = UI.ResolveColor(self.options.iconBorderColor, "panel.border")
    self.iconBorderTop = createBorderTexture(self.iconFrame, "TOPLEFT", "TOPRIGHT", borderSize, false)
    self.iconBorderBottom = createBorderTexture(self.iconFrame, "BOTTOMLEFT", "BOTTOMRIGHT", borderSize, false)
    self.iconBorderLeft = createBorderTexture(self.iconFrame, "TOPLEFT", "BOTTOMLEFT", borderSize, true)
    self.iconBorderRight = createBorderTexture(self.iconFrame, "TOPRIGHT", "BOTTOMRIGHT", borderSize, true)
    applyBorderColor(self.iconBorderTop, borderColor)
    applyBorderColor(self.iconBorderBottom, borderColor)
    applyBorderColor(self.iconBorderLeft, borderColor)
    applyBorderColor(self.iconBorderRight, borderColor)

    self.iconElement = Image:New({
        name = (self.name or "TrainerEntry") .. "Icon",
        width = iconSize,
        height = iconSize,
        textureInsetLeft = 1,
        textureInsetTop = 1,
        textureInsetRight = 1,
        textureInsetBottom = 1,
        border = false,
        texture = self.options.iconTexture or defaults.IconTexture or DEFAULT_ICON,
        texCoord = self.options.iconTexCoord or defaults.IconTexCoord or {
            left = 0.08,
            right = 0.92,
            top = 0.08,
            bottom = 0.92,
        },
    })
    self.iconElement:SetParent(self.iconFrame)
    self.iconElement:Create()
    local iconElementFrame = self.iconElement:GetFrame()
    if iconElementFrame and iconElementFrame.SetAllPoints then
        iconElementFrame:ClearAllPoints()
        iconElementFrame:SetAllPoints(self.iconFrame)
    end
    self.iconTexture = self.iconElement.textureRegion

    self.nameElement = Text:New({
        name = (self.name or "TrainerEntry") .. "Name",
        width = textWidth,
        height = height,
        text = self.options.recipeName or defaults.RecipeName or "Recipe",
        justifyH = "LEFT",
        justifyV = "MIDDLE",
        wordWrap = false,
        textColor = UI.ResolveColor(self.options.textColor, "text.primary"),
        border = false,
        textInsetLeft = 0,
        textInsetTop = 0,
        textInsetRight = 0,
        textInsetBottom = 0,
        fontSize = self.options.fontSize or defaults.FontSize or ((Constants.FontSizes and Constants.FontSizes.Body) or 10),
    })
    self.nameElement:SetParent(frame)
    self.nameElement:Create()
    self.nameElement:GetFrame():SetPoint("LEFT", self.iconFrame, "RIGHT", iconGap, 0)
    self.nameRegion = self.nameElement.textRegion

    self.statusElement = Text:New({
        name = (self.name or "TrainerEntry") .. "Status",
        width = statusWidth,
        height = height,
        text = self.options.statusText or defaults.StatusText or "",
        justifyH = "RIGHT",
        justifyV = "MIDDLE",
        wordWrap = false,
        textColor = UI.ResolveColor(self.options.statusColor, "text.secondary"),
        border = false,
        textInsetLeft = 0,
        textInsetTop = 0,
        textInsetRight = 0,
        textInsetBottom = 0,
        fontSize = self.options.statusFontSize or self.options.fontSize or defaults.FontSize or ((Constants.FontSizes and Constants.FontSizes.Body) or 10),
    })
    self.statusElement:SetParent(frame)
    self.statusElement:Create()
    self.statusElement:GetFrame():SetPoint("RIGHT", frame, "RIGHT", 0, 0)
    self.statusRegion = self.statusElement.textRegion

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

    self:SetIcon(self.options.iconTexture or defaults.IconTexture or DEFAULT_ICON)
    self:SetRecipeName(self.options.recipeName or defaults.RecipeName or "Recipe")
    self:SetStatusText(self.options.statusText or defaults.StatusText or "")
    self:SetLayoutMetrics(width, height)
    self:SetSelected(self.isSelected)
    self:SetEnabled(self.enabled)

    return self.frame
end

return TrainerEntry
