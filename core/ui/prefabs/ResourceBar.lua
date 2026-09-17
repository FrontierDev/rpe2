local _, Addon = ...

local UI = Addon.UI or {}
Addon.UI = UI
local BaseElement = UI.BaseElement
local Image = UI.Image
local Text = UI.Text
local ProgressBar = UI.ProgressBar
local Font = UI.Font or {}
local Constants = UI.Constants or {}

UI.ResourceBar = UI.ResourceBar or {}
local ResourceBar = UI.ResourceBar
ResourceBar.__index = ResourceBar
setmetatable(ResourceBar, { __index = BaseElement })

local DEFAULT_ICON = "Interface\\Icons\\INV_Misc_QuestionMark"
local ABSORPTION_TEXTURE = "Interface\\Buttons\\WHITE8X8"
local ABSORPTION_COLOR = { r = 1, g = 1, b = 1, a = 1 }
local ABSORPTION_EDGE_COLOR = { r = 1, g = 1, b = 1, a = 0.95 }

local function ResolveDefaults(options)
    local defaults = (Constants.Prefabs and Constants.Prefabs.ResourceBar) or {}
    local width = options.width or defaults.Width or 220
    local height = options.height or defaults.Height or 14
    local iconSize = options.iconSize or defaults.IconSize or 14
    local valueWidth = options.valueWidth or defaults.ValueWidth or 44
    local progressFontSize = options.progressFontSize or defaults.ProgressFontSize or 10
    local valueFontSize = options.valueFontSize or defaults.ValueFontSize or 10

    return {
        width = width,
        height = height,
        iconSize = iconSize,
        valueWidth = valueWidth,
        progressFontSize = progressFontSize,
        valueFontSize = valueFontSize,
        iconTexture = options.iconTexture or defaults.IconTexture or DEFAULT_ICON,
    }
end

local function ApplyLabelStyle(labelRegion, fontSize)
    if not labelRegion or type(labelRegion.GetFont) ~= "function" or type(labelRegion.SetFont) ~= "function" then
        return false
    end

    local fontFile = labelRegion:GetFont()
    if type(fontFile) ~= "string" or fontFile == "" then
        return false
    end

    labelRegion:SetFont(fontFile, tonumber(fontSize) or 10, "OUTLINE")
    return true
end

local function DimColor(color)
    local source = type(color) == "table" and color or { r = 0.18, g = 0.18, b = 0.18, a = 1 }
    return {
        r = math.max(0, math.min(1, (tonumber(source.r) or 1) * 0.35)),
        g = math.max(0, math.min(1, (tonumber(source.g) or 1) * 0.35)),
        b = math.max(0, math.min(1, (tonumber(source.b) or 1) * 0.35)),
        a = tonumber(source.a) or 1,
    }
end

function ResourceBar:New(options)
    local instance = BaseElement.New(self, options)
    instance.options.border = false
    instance.panel = nil
    instance.background = nil
    instance.icon = nil
    instance.valueText = nil
    instance.progressBar = nil
    instance.absorptionOvershieldIndicator = nil
    instance.state = nil
    return instance
end

function ResourceBar:SetIcon(texturePath)
    self:SetOption("iconTexture", texturePath)
    if self.icon and self.icon.SetTexture then
        self.icon:SetTexture(texturePath or DEFAULT_ICON)
    end
end

function ResourceBar:SetValueText(text)
    self:SetOption("currentText", text)
    if self.valueText and self.valueText.SetText then
        self.valueText:SetText(text or "")
    end
end

function ResourceBar:SetBarWidth(width)
    local frame = self.progressBar and self.progressBar.GetFrame and self.progressBar:GetFrame() or nil
    if frame and frame.SetWidth then
        frame:SetWidth(math.max(0, tonumber(width) or 0))
    end
    if self.progressBar and self.progressBar.UpdateLayout then
        self.progressBar:UpdateLayout()
    end
end

function ResourceBar:SetState(state)
    self.state = state or {}

    local resolvedState = self.state
    self:SetIcon(resolvedState.icon or self.options.iconTexture or DEFAULT_ICON)
    self:SetValueText(resolvedState.currentText or "")

    local maximum = math.max(1, tonumber(resolvedState.maxValue) or 1)
    local current = math.max(0, math.min(maximum, tonumber(resolvedState.currentValue) or 0))
    local absorption = math.max(0, tonumber(resolvedState.absorption) or tonumber(resolvedState.totalAbsorption) or 0)
    local hasAbsorption = absorption > 0
    local secondaryColor = hasAbsorption
        and ABSORPTION_COLOR
        or resolvedState.secondaryColor
        or self.options.secondaryColor
        or DimColor(resolvedState.color or self.options.primaryColor)

    if self.progressBar and self.progressBar.SetOption then
        self.progressBar:SetOption("primaryColor", resolvedState.color or self.options.primaryColor)
        self.progressBar:SetOption("secondaryColor", secondaryColor)
        self.progressBar:SetOption("secondaryTexture", hasAbsorption and ABSORPTION_TEXTURE or nil)
        self.progressBar:SetOption("secondaryOverlayTexture", nil)
        self.progressBar:ApplyColors()
    end
    if self.progressBar and self.progressBar.SetMinMax then
        self.progressBar:SetMinMax(0, maximum)
    end
    if self.progressBar and self.progressBar.SetValue then
        self.progressBar:SetValue(current)
    end
    if self.progressBar and self.progressBar.SetSecondaryValue then
        self.progressBar:SetSecondaryValue(hasAbsorption and math.min(maximum, current + absorption) or nil)
    end

    local edgeFrame = self.absorptionOvershieldIndicator
        and self.absorptionOvershieldIndicator.GetFrame
        and self.absorptionOvershieldIndicator:GetFrame()
        or nil
    local barFrame = self.progressBar and self.progressBar.barFrame or nil
    local overAbsorb = hasAbsorption and absorption > math.max(0, maximum - current)
    if edgeFrame then
        if overAbsorb and barFrame then
            edgeFrame:ClearAllPoints()
            edgeFrame:SetPoint("TOPLEFT", barFrame, "TOPRIGHT", 0, 0)
            edgeFrame:SetPoint("BOTTOMLEFT", barFrame, "BOTTOMRIGHT", 0, 0)
            edgeFrame:SetWidth(2)
            edgeFrame:Show()
        else
            edgeFrame:Hide()
        end
    end
    if self.progressBar and self.progressBar.SetText then
        self.progressBar:SetText(resolvedState.progressText or "")
    end

    if self.progressBar and self.progressBar.label then
        ApplyLabelStyle(self.progressBar.label, self.options.progressFontSize or 10)
        if resolvedState.progressText and resolvedState.progressText ~= "" then
            self.progressBar.label:Show()
        else
            self.progressBar.label:Hide()
        end
    end

    return self.state
end

function ResourceBar:Create()
    if self.frame then
        return self.frame
    end

    local parentFrame = self:GetParentFrame()
    if not parentFrame then
        error("A resource bar prefab requires a parent frame before Create().", 2)
    end

    local defaults = ResolveDefaults(self.options)
    local frame = CreateFrame("Frame", self.name, parentFrame, self.options.template)
    self:SetFrame(frame)
    frame:SetSize(defaults.width, defaults.height)

    self.background = frame:CreateTexture(nil, "BACKGROUND")
    self.background:SetAllPoints(frame)
    self.background:SetColorTexture(0, 0, 0, 0)

    self.icon = Image:New({
        name = (self.name or "ResourceBar") .. "Icon",
        width = defaults.iconSize,
        height = defaults.iconSize,
        texture = defaults.iconTexture,
        border = false,
        showWhenUIHidden = false,
    })
    self.icon:SetParent(frame)
    self.icon:Create()

    self.valueText = Text:New({
        name = (self.name or "ResourceBar") .. "Value",
        width = defaults.valueWidth,
        height = defaults.height,
        fontSize = defaults.valueFontSize,
        justifyH = "RIGHT",
        justifyV = "MIDDLE",
        wordWrap = false,
        textColor = UI.ResolveColor(nil, "text.primary"),
        border = false,
        showWhenUIHidden = false,
    })
    self.valueText:SetParent(frame)
    self.valueText:Create()

    self.progressBar = ProgressBar:New({
        name = (self.name or "ResourceBar") .. "Progress",
        width = math.max(0, defaults.width - defaults.iconSize - defaults.valueWidth - 8),
        height = defaults.height,
        minValue = 0,
        maxValue = 100,
        value = 0,
        text = "",
        fontSize = defaults.progressFontSize,
        fontFlags = "OUTLINE",
        backgroundToken = "progress.background",
        borderToken = "progress.border",
        textToken = "progress.text",
        showWhenUIHidden = false,
    })
    self.progressBar:SetParent(frame)
    self.progressBar:Create()

    self.absorptionOvershieldIndicator = Image:New({
        name = (self.name or "ResourceBar") .. "AbsorptionOvershield",
        width = 2,
        height = defaults.height,
        texture = ABSORPTION_TEXTURE,
        border = false,
        layer = "OVERLAY",
        textureInsetLeft = 0,
        textureInsetTop = 0,
        textureInsetRight = 0,
        textureInsetBottom = 0,
        vertexColor = ABSORPTION_EDGE_COLOR,
        showWhenUIHidden = false,
    })
    self.absorptionOvershieldIndicator:SetParent(frame)
    self.absorptionOvershieldIndicator:Create()
    self.absorptionOvershieldIndicator:GetFrame():Hide()

    self:ApplyLayout()
    self:SetState(self.options.state or {})
    return self.frame
end

function ResourceBar:ApplyLayout()
    if not self.frame then
        return false
    end

    local defaults = ResolveDefaults(self.options)
    local frame = self.frame
    local iconFrame = self.icon and self.icon.GetFrame and self.icon:GetFrame() or nil
    local valueFrame = self.valueText and self.valueText.GetFrame and self.valueText:GetFrame() or nil
    local progressFrame = self.progressBar and self.progressBar.GetFrame and self.progressBar:GetFrame() or nil

    if iconFrame and iconFrame.ClearAllPoints then
        iconFrame:ClearAllPoints()
        iconFrame:SetPoint("LEFT", frame, "LEFT", 0, 0)
        iconFrame:SetWidth(defaults.iconSize)
        iconFrame:SetHeight(defaults.iconSize)
    end

    if valueFrame and valueFrame.ClearAllPoints then
        valueFrame:ClearAllPoints()
        valueFrame:SetPoint("RIGHT", frame, "RIGHT", 0, 0)
        valueFrame:SetWidth(defaults.valueWidth)
        valueFrame:SetHeight(defaults.height)
    end

    if progressFrame and progressFrame.ClearAllPoints then
        progressFrame:ClearAllPoints()
        progressFrame:SetPoint("LEFT", iconFrame, "RIGHT", 4, 0)
        progressFrame:SetPoint("RIGHT", valueFrame, "LEFT", -4, 0)
        progressFrame:SetHeight(defaults.height)
        progressFrame:SetWidth(math.max(0, defaults.width - defaults.iconSize - defaults.valueWidth - 8))
    end

    return true
end

return ResourceBar
