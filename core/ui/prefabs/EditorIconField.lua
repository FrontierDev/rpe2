local _, Addon = ...

local UI = Addon.UI or {}
Addon.UI = UI
local BaseElement = UI.BaseElement
local Image = UI.Image
local Text = UI.Text
local TextButton = UI.TextButton
local Font = UI.Font or {}
local Utils = UI.Utils or {}
local Constants = UI.Constants or {}

UI.EditorIconField = UI.EditorIconField or {}
local EditorIconField = UI.EditorIconField
EditorIconField.__index = EditorIconField
setmetatable(EditorIconField, { __index = BaseElement })

local DEFAULT_ICON = "Interface\\Icons\\INV_Misc_QuestionMark"

function EditorIconField:New(options)
    local instance = BaseElement.New(self, options)
    instance.options.border = false
    instance.buttonElement = nil
    instance.iconElement = nil
    instance.labelElement = nil
    instance.buttonLabel = nil
    instance.iconTexture = nil
    instance.labelRegion = nil
    return instance
end

function EditorIconField:SetButtonText(text)
    self:SetOption("buttonText", text)

    if self.buttonElement and self.buttonElement.SetText then
        self.buttonElement:SetText(text or "")
    end
end

function EditorIconField:SetIcon(texturePath)
    self:SetOption("iconTexture", texturePath)

    if self.iconElement and self.iconElement.SetTexture then
        self.iconElement:SetTexture(texturePath or DEFAULT_ICON)
    elseif self.iconTexture and self.iconTexture.SetTexture then
        self.iconTexture:SetTexture(texturePath or DEFAULT_ICON)
    end
end

function EditorIconField:SetLabelText(text)
    self:SetOption("labelText", text)

    if self.labelElement and self.labelElement.SetText then
        self.labelElement:SetText(text or "")
    elseif self.labelRegion and self.labelRegion.SetText then
        self.labelRegion:SetText(text or "")
    end
end

function EditorIconField:GetButton()
    return self.buttonElement
end

function EditorIconField:SetEnabled(enabled)
    self.enabled = enabled ~= false

    if self.buttonElement and self.buttonElement.SetEnabled then
        self.buttonElement:SetEnabled(self.enabled)
    end

    local alpha = self.enabled and 1 or 0.5

    if self.iconElement and self.iconElement.GetFrame and self.iconElement:GetFrame() and self.iconElement:GetFrame().SetAlpha then
        self.iconElement:GetFrame():SetAlpha(alpha)
    end

    if self.labelElement and self.labelElement.GetFrame and self.labelElement:GetFrame() and self.labelElement:GetFrame().SetAlpha then
        self.labelElement:GetFrame():SetAlpha(alpha)
    end

    if self.frame and self.frame.SetAlpha then
        self.frame:SetAlpha(alpha)
    end

    return self.enabled
end

function EditorIconField:Create()
    if self.frame then
        return self.frame
    end

    local parentFrame = self:GetParentFrame()
    if not parentFrame then
        error("An editor icon field prefab requires a parent frame before Create().", 2)
    end

    local defaults = (Constants.Prefabs and Constants.Prefabs.EditorIconField) or {}
    local width = self.options.width or defaults.Width or 236
    local height = self.options.height or defaults.Height or 20
    local buttonWidth = self.options.buttonWidth or defaults.ButtonWidth or 96
    local iconSize = self.options.iconSize or defaults.IconSize or 16
    local spacing = self.options.spacing or defaults.Spacing or 6
    local labelWidth = math.max(0, width - buttonWidth - iconSize - (spacing * 2))

    local frame = CreateFrame("Frame", self.name, parentFrame, self.options.template)
    self:SetFrame(frame)
    frame:SetSize(width, height)

    self.buttonElement = TextButton:New({
        name = (self.name or "EditorIconField") .. "Button",
        width = buttonWidth,
        height = height,
        text = self.options.buttonText or defaults.ButtonText or "Select Icon",
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
    self.buttonLabel = self.buttonElement.label

    self.iconElement = Image:New({
        name = (self.name or "EditorIconField") .. "Icon",
        width = iconSize,
        height = iconSize,
        textureInsetLeft = 0,
        textureInsetTop = 0,
        textureInsetRight = 0,
        textureInsetBottom = 0,
        border = false,
    })
    self.iconElement:SetParent(frame)
    self.iconElement:Create()
    self.iconElement:GetFrame():SetPoint("LEFT", self.buttonElement:GetFrame(), "RIGHT", spacing, 0)
    self.iconTexture = self.iconElement.textureRegion
    Utils.ApplyTexture(
        self.iconTexture,
        self.options.iconTexture or defaults.IconTexture or DEFAULT_ICON,
        Utils.ResolveTexCoord(self.options.iconTexCoord, defaults.IconTexCoord)
    )

    self.labelElement = Text:New({
        name = (self.name or "EditorIconField") .. "Label",
        width = labelWidth,
        height = height,
        textInsetLeft = 0,
        textInsetTop = 0,
        textInsetRight = 0,
        textInsetBottom = 0,
        border = false,
    })
    self.labelElement:SetParent(frame)
    self.labelElement:Create()
    self.labelElement:GetFrame():SetPoint("LEFT", self.iconElement:GetFrame(), "RIGHT", spacing, 0)
    self.labelRegion = self.labelElement.textRegion
    if self.labelRegion and self.labelRegion.SetJustifyH then
        self.labelRegion:SetJustifyH("LEFT")
    end
    if self.labelRegion and self.labelRegion.SetJustifyV then
        self.labelRegion:SetJustifyV("MIDDLE")
    end
    Font:Apply(self.labelRegion, self.options, {
        fontSize = self.options.fontSize or defaults.FontSize or (Constants.FontSizes and Constants.FontSizes.Body) or 10,
    })
    local labelColor = UI.ResolveColor(self.options.labelTextColor, "text.secondary")
    if self.labelRegion and self.labelRegion.SetTextColor then
        self.labelRegion:SetTextColor(labelColor.r or 1, labelColor.g or 1, labelColor.b or 1, labelColor.a or 1)
    end
    self:SetLabelText(self.options.labelText or defaults.LabelText or "")
    self:SetEnabled(self.options.enabled ~= false)

    return self.frame
end

return EditorIconField
