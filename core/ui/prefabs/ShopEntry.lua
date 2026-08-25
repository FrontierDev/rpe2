local _, Addon = ...

local UI = Addon.UI or {}
Addon.UI = UI

local BaseElement = UI.BaseElement
local Image = UI.Image
local Text = UI.Text
local VerticalLayoutGroup = UI.VerticalLayoutGroup
local Constants = UI.Constants or {}

UI.ShopEntry = UI.ShopEntry or {}
local ShopEntry = UI.ShopEntry
ShopEntry.__index = ShopEntry
setmetatable(ShopEntry, { __index = BaseElement })

local DEFAULT_ICON = "Interface\\Icons\\INV_Misc_QuestionMark"
local DEFAULTS = {
    Width = 160,
    Height = 34,
    IconSize = 26,
    IconGap = 8,
    BorderSize = 1,
    TextPadding = 1,
    LineSpacing = 0,
}

local function getDefaults()
    local configured = Constants.Prefabs and Constants.Prefabs.ShopEntry or {}
    return {
        Width = configured.Width or DEFAULTS.Width,
        Height = configured.Height or DEFAULTS.Height,
        IconSize = configured.IconSize or DEFAULTS.IconSize,
        IconGap = configured.IconGap or DEFAULTS.IconGap,
        BorderSize = configured.BorderSize or DEFAULTS.BorderSize,
        TextPadding = configured.TextPadding or DEFAULTS.TextPadding,
        LineSpacing = configured.LineSpacing or DEFAULTS.LineSpacing,
    }
end

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

local function measureText(fontString, text)
    if not fontString or not fontString.SetText then
        return 0
    end

    fontString:SetText(text or "")
    if fontString.GetStringWidth then
        return tonumber(fontString:GetStringWidth()) or 0
    end

    return 0
end

local function tokenizeDisplayText(text)
    local tokens = {}
    local value = tostring(text or "")
    local cursor = 1

    while cursor <= #value do
        local textureStart, textureEnd = value:find("|T.-|t", cursor)
        if textureStart == cursor then
            tokens[#tokens + 1] = value:sub(textureStart, textureEnd)
            cursor = textureEnd + 1
        else
            local nextCursor = textureStart or (#value + 1)
            for index = cursor, nextCursor - 1 do
                tokens[#tokens + 1] = value:sub(index, index)
            end
            cursor = nextCursor
        end
    end

    return tokens
end

local function fitTextWithEllipsis(fontString, fullText, maxWidth)
    local text = tostring(fullText or "")
    local width = math.max(0, tonumber(maxWidth) or 0)
    if text == "" then
        return ""
    end

    if measureText(fontString, text) <= width then
        return text
    end

    local ellipsis = "..."
    if width <= 0 or measureText(fontString, ellipsis) > width then
        return ""
    end

    local tokens = tokenizeDisplayText(text)
    local low = 0
    local high = #tokens
    local best = ellipsis

    while low <= high do
        local middle = math.floor((low + high) / 2)
        local candidate = table.concat(tokens, "", 1, middle) .. ellipsis
        if measureText(fontString, candidate) <= width then
            best = candidate
            low = middle + 1
        else
            high = middle - 1
        end
    end

    return best
end

local function getTextLineMetrics(height, padding, spacing)
    local contentHeight = math.max(0, height - (padding * 2))
    if contentHeight <= 1 then
        return contentHeight, 0
    end

    local nameHeight = math.max(1, math.floor((contentHeight - spacing) * 0.58))
    local costHeight = math.max(0, contentHeight - nameHeight - spacing)
    return nameHeight, costHeight
end

function ShopEntry:New(options)
    local instance = BaseElement.New(self, options)
    instance.options.border = false
    instance.enabled = options == nil or options.enabled ~= false
    instance.fullItemName = tostring(options and options.itemName or "")
    instance.costText = tostring(options and options.costText or "")
    instance.itemNameDisplay = ""
    instance.costTextDisplay = ""
    instance.textWidth = 0
    instance.iconFrame = nil
    instance.iconElement = nil
    instance.iconTexture = nil
    instance.nameElement = nil
    instance.nameRegion = nil
    instance.costElement = nil
    instance.costRegion = nil
    instance.textLayout = nil
    instance.hoverTexture = nil
    instance.iconBorderTop = nil
    instance.iconBorderBottom = nil
    instance.iconBorderLeft = nil
    instance.iconBorderRight = nil
    return instance
end

function ShopEntry:SetIcon(texturePath)
    self:SetOption("iconTexture", texturePath)
    if self.iconElement and self.iconElement.SetTexture then
        self.iconElement:SetTexture(texturePath or DEFAULT_ICON)
    elseif self.iconTexture and self.iconTexture.SetTexture then
        self.iconTexture:SetTexture(texturePath or DEFAULT_ICON)
    end

    return texturePath or DEFAULT_ICON
end

function ShopEntry:SetItemName(itemName)
    self.fullItemName = tostring(itemName or "")
    self:SetOption("itemName", self.fullItemName)
    self:RefreshText()
    return self.fullItemName
end

function ShopEntry:SetCostText(costText)
    self.costText = tostring(costText or "")
    self:SetOption("costText", self.costText)
    self:RefreshText()
    return self.costText
end

function ShopEntry:SetBorderColor(r, g, b, a)
    local color = {
        r = r or 1,
        g = g or 1,
        b = b or 1,
        a = a or 1,
    }
    self:SetOption("iconBorderColor", color)

    local textures = {
        self.iconBorderTop,
        self.iconBorderBottom,
        self.iconBorderLeft,
        self.iconBorderRight,
    }
    for index = 1, #textures do
        local texture = textures[index]
        if texture and texture.SetColorTexture then
            texture:SetColorTexture(color.r, color.g, color.b, color.a)
        end
    end

    return color
end

function ShopEntry:RefreshText()
    if self.nameRegion then
        self.itemNameDisplay = fitTextWithEllipsis(
            self.nameRegion,
            self.fullItemName,
            self.textWidth
        )
        self.nameRegion:SetText(self.itemNameDisplay)
    end

    if self.costRegion then
        self.costTextDisplay = fitTextWithEllipsis(
            self.costRegion,
            self.costText,
            self.textWidth
        )
        self.costRegion:SetText(self.costTextDisplay)
    end
end

function ShopEntry:SetLayoutMetrics(width, height)
    local defaults = getDefaults()
    local resolvedWidth = tonumber(width) or self.options.width or defaults.Width
    local resolvedHeight = tonumber(height) or self.options.height or defaults.Height
    local iconSize = tonumber(self.options.iconSize) or defaults.IconSize
    local iconGap = tonumber(self.options.iconGap) or defaults.IconGap
    local textWidth = math.max(0, resolvedWidth - iconSize - iconGap)
    local textPadding = tonumber(self.options.textPadding) or defaults.TextPadding
    local lineSpacing = tonumber(self.options.lineSpacing) or defaults.LineSpacing
    local nameHeight, costHeight = getTextLineMetrics(resolvedHeight, textPadding, lineSpacing)

    self.options.width = resolvedWidth
    self.options.height = resolvedHeight
    self.textWidth = textWidth

    if self.frame and self.frame.SetSize then
        self.frame:SetSize(resolvedWidth, resolvedHeight)
    end
    if self.iconFrame and self.iconFrame.SetSize then
        self.iconFrame:SetSize(iconSize, iconSize)
    end
    if self.textLayout then
        self.textLayout:SetSize(textWidth, resolvedHeight)
        self.textLayout.options.padding = {
            left = 0,
            right = 0,
            top = textPadding,
            bottom = textPadding,
        }
        self.textLayout.options.spacing = lineSpacing
    end
    if self.nameElement and self.nameElement.SetSize then
        self.nameElement:SetSize(textWidth, nameHeight)
    end
    if self.costElement and self.costElement.SetSize then
        self.costElement:SetSize(textWidth, costHeight)
    end

    if self.textLayout and self.textLayout.RefreshLayout then
        self.textLayout:RefreshLayout()
    end
    self:RefreshText()

    return resolvedWidth, resolvedHeight
end

function ShopEntry:RefreshVisualState()
    local enabled = self.enabled ~= false
    local brightness = enabled and 1 or 0.5
    local alpha = enabled and 1 or 0.7

    if self.iconTexture and self.iconTexture.SetDesaturated then
        self.iconTexture:SetDesaturated(not enabled)
    end
    if self.iconTexture and self.iconTexture.SetVertexColor then
        self.iconTexture:SetVertexColor(brightness, brightness, brightness, 1)
    end
    if self.nameRegion and self.nameRegion.SetAlpha then
        self.nameRegion:SetAlpha(alpha)
    end
    if self.costRegion and self.costRegion.SetAlpha then
        self.costRegion:SetAlpha(alpha)
    end
    if self.frame and self.frame.SetAlpha then
        self.frame:SetAlpha(enabled and 1 or 0.85)
    end
end

function ShopEntry:SetEnabled(enabled)
    self.enabled = enabled ~= false
    self:SetOption("enabled", self.enabled)
    if self.frame and self.frame.EnableMouse then
        local keepMouseEnabled = self.options.keepMouseEnabled == true
        self.frame:EnableMouse(self.enabled or keepMouseEnabled)
    end
    self:RefreshVisualState()
    return self.enabled
end

function ShopEntry:Create()
    if self.frame then
        return self.frame
    end

    local parentFrame = self:GetParentFrame()
    if not parentFrame then
        error("A shop entry prefab requires a parent frame before Create().", 2)
    end

    local defaults = getDefaults()
    local width = tonumber(self.options.width) or defaults.Width
    local height = tonumber(self.options.height) or defaults.Height
    local iconSize = tonumber(self.options.iconSize) or defaults.IconSize
    local iconGap = tonumber(self.options.iconGap) or defaults.IconGap
    local textWidth = math.max(0, width - iconSize - iconGap)
    local textPadding = tonumber(self.options.textPadding) or defaults.TextPadding
    local lineSpacing = tonumber(self.options.lineSpacing) or defaults.LineSpacing
    local nameHeight, costHeight = getTextLineMetrics(height, textPadding, lineSpacing)
    local fontSize = tonumber(self.options.fontSize)
        or ((Constants.FontSizes and Constants.FontSizes.Body) or 10)
    local costFontSize = tonumber(self.options.costFontSize) or math.max(8, fontSize - 1)

    local frame = CreateFrame("Button", self.name, parentFrame, self.options.template)
    self:SetFrame(frame)
    frame:RegisterForClicks("AnyUp")
    frame:SetSize(width, height)
    frame:EnableMouse(true)

    self.hoverTexture = frame:CreateTexture(nil, "BACKGROUND")
    self.hoverTexture:SetAllPoints(frame)
    self.hoverTexture:SetColorTexture(1, 1, 1, 0.05)
    self.hoverTexture:Hide()

    self.iconFrame = CreateFrame("Frame", (self.name or "ShopEntry") .. "IconFrame", frame)
    self.iconFrame:SetPoint("LEFT", frame, "LEFT", 0, 0)
    self.iconFrame:SetSize(iconSize, iconSize)
    local borderSize = tonumber(self.options.iconBorderSize) or defaults.BorderSize
    local borderColor = UI.ResolveColor(self.options.iconBorderColor, "panel.border")
    self.iconBorderTop = createBorderTexture(self.iconFrame, "TOPLEFT", "TOPRIGHT", borderSize, false)
    self.iconBorderBottom = createBorderTexture(self.iconFrame, "BOTTOMLEFT", "BOTTOMRIGHT", borderSize, false)
    self.iconBorderLeft = createBorderTexture(self.iconFrame, "TOPLEFT", "BOTTOMLEFT", borderSize, true)
    self.iconBorderRight = createBorderTexture(self.iconFrame, "TOPRIGHT", "BOTTOMRIGHT", borderSize, true)

    self.iconElement = Image:New({
        name = (self.name or "ShopEntry") .. "Icon",
        width = iconSize,
        height = iconSize,
        textureInsetLeft = 1,
        textureInsetTop = 1,
        textureInsetRight = 1,
        textureInsetBottom = 1,
        border = false,
        texture = self.options.iconTexture or DEFAULT_ICON,
        texCoord = self.options.iconTexCoord or {
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

    self.textLayout = VerticalLayoutGroup:New({
        name = (self.name or "ShopEntry") .. "TextLayout",
        width = textWidth,
        height = height,
        spacing = lineSpacing,
        padding = {
            left = 0,
            right = 0,
            top = textPadding,
            bottom = textPadding,
        },
        fitChildrenWidth = true,
    })
    self.textLayout:SetParent(frame)

    self.nameElement = Text:New({
        name = (self.name or "ShopEntry") .. "Name",
        width = textWidth,
        height = nameHeight,
        text = "",
        justifyH = "LEFT",
        justifyV = "MIDDLE",
        wordWrap = false,
        textColor = UI.ResolveColor(self.options.textColor, "text.primary"),
        border = false,
        textInsetLeft = 0,
        textInsetTop = 0,
        textInsetRight = 0,
        textInsetBottom = 0,
        fontSize = fontSize,
    })
    self.costElement = Text:New({
        name = (self.name or "ShopEntry") .. "Cost",
        width = textWidth,
        height = costHeight,
        text = "",
        justifyH = "LEFT",
        justifyV = "MIDDLE",
        wordWrap = false,
        textColor = UI.ResolveColor(self.options.costColor, "text.secondary"),
        border = false,
        textInsetLeft = 0,
        textInsetTop = 0,
        textInsetRight = 0,
        textInsetBottom = 0,
        fontSize = costFontSize,
    })
    self.textLayout:AddChild(self.nameElement)
    self.textLayout:AddChild(self.costElement)
    self.textLayout:Create()
    local textLayoutFrame = self.textLayout:GetFrame()
    if textLayoutFrame then
        textLayoutFrame:SetPoint("LEFT", self.iconFrame, "RIGHT", iconGap, 0)
    end
    self.nameRegion = self.nameElement.textRegion
    self.costRegion = self.costElement.textRegion

    frame:HookScript("OnEnter", function()
        if self.hoverTexture and self.hoverTexture.Show then
            self.hoverTexture:Show()
        end
    end)
    frame:HookScript("OnLeave", function()
        if self.hoverTexture and self.hoverTexture.Hide then
            self.hoverTexture:Hide()
        end
    end)

    self:SetIcon(self.options.iconTexture or DEFAULT_ICON)
    self:SetBorderColor(borderColor.r, borderColor.g, borderColor.b, borderColor.a)
    self:SetItemName(self.fullItemName or self.options.itemName or "")
    self:SetCostText(self.costText or self.options.costText or "")
    self:SetLayoutMetrics(width, height)
    self:SetEnabled(self.enabled)

    return self.frame
end

return ShopEntry
