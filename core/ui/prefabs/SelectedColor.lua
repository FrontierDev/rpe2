local _, Addon = ...

local UI = Addon.UI or {}
Addon.UI = UI
local BaseElement = UI.BaseElement
local Panel = UI.Panel
local TextButton = UI.TextButton
local Constants = UI.Constants or {}

UI.SelectedColor = UI.SelectedColor or {}
local SelectedColor = UI.SelectedColor
SelectedColor.__index = SelectedColor
setmetatable(SelectedColor, { __index = BaseElement })

local DEFAULT_COLOR = {
    r = 1,
    g = 1,
    b = 1,
    a = 1,
}

local function copyColor(color, fallback)
    local source = type(color) == "table" and color or fallback or DEFAULT_COLOR
    return {
        r = math.max(0, math.min(1, tonumber(source.r) or DEFAULT_COLOR.r)),
        g = math.max(0, math.min(1, tonumber(source.g) or DEFAULT_COLOR.g)),
        b = math.max(0, math.min(1, tonumber(source.b) or DEFAULT_COLOR.b)),
        a = math.max(0, math.min(1, tonumber(source.a) or DEFAULT_COLOR.a)),
    }
end

local function applySwatchColor(panel, color)
    if not panel then
        return
    end

    local resolved = copyColor(color, DEFAULT_COLOR)
    if panel.SetOption then
        panel:SetOption("panelBackgroundColor", resolved)
    end
    if panel.panelBackgroundTexture and panel.panelBackgroundTexture.SetColorTexture then
        panel.panelBackgroundTexture:SetColorTexture(resolved.r, resolved.g, resolved.b, resolved.a)
    end
end

function SelectedColor:New(options)
    local instance = BaseElement.New(self, options)
    instance.options.border = false
    instance.buttonElement = nil
    instance.swatchElement = nil
    instance.enabled = options == nil or options.enabled ~= false
    instance.color = copyColor(options and options.color, DEFAULT_COLOR)
    return instance
end

function SelectedColor:SetButtonText(text)
    self:SetOption("buttonText", text)

    if self.buttonElement and self.buttonElement.SetText then
        self.buttonElement:SetText(text or "")
    end
end

function SelectedColor:GetButton()
    return self.buttonElement
end

function SelectedColor:SetColor(color)
    self.color = copyColor(color, DEFAULT_COLOR)
    applySwatchColor(self.swatchElement, self.color)
    return self.color
end

function SelectedColor:GetColor()
    return copyColor(self.color, DEFAULT_COLOR)
end

function SelectedColor:SetEnabled(enabled)
    self.enabled = enabled ~= false

    if self.buttonElement and self.buttonElement.SetEnabled then
        self.buttonElement:SetEnabled(self.enabled)
    end

    if self.swatchElement and self.swatchElement.GetFrame and self.swatchElement:GetFrame() and self.swatchElement:GetFrame().SetAlpha then
        self.swatchElement:GetFrame():SetAlpha(self.enabled and 1 or 0.5)
    end

    if self.frame and self.frame.SetAlpha then
        self.frame:SetAlpha(self.enabled and 1 or 0.5)
    end

    return self.enabled
end

function SelectedColor:Create()
    if self.frame then
        return self.frame
    end

    local parentFrame = self:GetParentFrame()
    if not parentFrame then
        error("A selected color prefab requires a parent frame before Create().", 2)
    end

    local defaults = (Constants.Prefabs and Constants.Prefabs.SelectedColor) or {}
    local width = self.options.width or defaults.Width or 236
    local height = self.options.height or defaults.Height or 20
    local swatchSize = self.options.swatchSize or defaults.SwatchSize or 16
    local spacing = self.options.spacing or defaults.Spacing or 6
    local buttonWidth = self.options.buttonWidth or defaults.ButtonWidth or 96

    local frame = CreateFrame("Frame", self.name, parentFrame, self.options.template)
    self:SetFrame(frame)
    frame:SetSize(width, height)

    self.buttonElement = TextButton:New({
        name = (self.name or "SelectedColor") .. "Button",
        width = buttonWidth,
        height = height,
        text = self.options.buttonText or defaults.ButtonText or "Select Color",
        fontFile = self.options.fontFile,
        fontSize = self.options.buttonFontSize or self.options.fontSize,
        labelColor = self.options.buttonLabelColor or UI.ResolveColor(nil, "text.primary"),
        backgroundColor = self.options.buttonBackgroundColor,
        borderTopColor = self.options.buttonBorderTopColor,
        borderBottomColor = self.options.buttonBorderBottomColor,
        enableMouse = self.options.enableMouse ~= false,
    })
    self.buttonElement:SetParent(frame)
    self.buttonElement:Create()
    self.buttonElement:GetFrame():SetPoint("LEFT", frame, "LEFT", 0, 0)

    self.swatchElement = Panel:New({
        name = (self.name or "SelectedColor") .. "Swatch",
        width = swatchSize,
        height = swatchSize,
        contentInset = 0,
        border = false,
        showBorder = true,
        panelBorderSize = 1,
        panelBorderColor = UI.ResolveColor(nil, "panel.border"),
        panelBackgroundColor = self.color,
    })
    self.swatchElement:SetParent(frame)
    self.swatchElement:Create()
    self.swatchElement:GetFrame():SetPoint("LEFT", self.buttonElement:GetFrame(), "RIGHT", spacing, 0)

    self:SetColor(self.color)
    self:SetEnabled(self.enabled)
    return self.frame
end

return SelectedColor
