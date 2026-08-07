local _, Addon = ...

local UI = Addon.UI or {}
Addon.UI = UI
local BaseElement = UI.BaseElement
local Debug = Addon.Debug or {}
local Constants = UI.Constants or {}
local Font = UI.Font or {}

UI.Text = UI.Text or {}
local Text = UI.Text
Text.__index = Text
setmetatable(Text, { __index = BaseElement })

function Text:New(options)
    local instance = BaseElement.New(self, options)
    instance.text = options and options.text or ""
    instance.textRegion = nil
    return instance
end

function Text:SetText(text)
    self.text = text

    if self.textRegion and self.textRegion.SetText then
        self.textRegion:SetText(text)
    elseif self.frame and self.frame.SetText then
        self.frame:SetText(text)
    end
end

function Text:GetText()
    return self.text
end

function Text:SetFontObject(fontObject)
    self:SetOption("fontObject", fontObject)

    if self.textRegion and self.textRegion.SetFontObject then
        self.textRegion:SetFontObject(fontObject)
    elseif self.frame and self.frame.SetFontObject then
        self.frame:SetFontObject(fontObject)
    end
end

function Text:SetFont(fontFile, fontSize, fontFlags)
    self:SetOption("fontFile", fontFile)
    self:SetOption("fontSize", fontSize)
    self:SetOption("fontFlags", fontFlags)

    if self.textRegion and self.textRegion.SetFont then
        self.textRegion:SetFont(fontFile, fontSize, fontFlags)
    elseif self.frame and self.frame.SetFont then
        self.frame:SetFont(fontFile, fontSize, fontFlags)
    end
end

function Text:SetTextColor(r, g, b, a)
    self:SetOption("textColor", { r = r, g = g, b = b, a = a })

    if self.textRegion and self.textRegion.SetTextColor then
        self.textRegion:SetTextColor(r, g, b, a)
    elseif self.frame and self.frame.SetTextColor then
        self.frame:SetTextColor(r, g, b, a)
    end
end

function Text:SetJustifyH(value)
    self:SetOption("justifyH", value)

    if self.textRegion and self.textRegion.SetJustifyH then
        self.textRegion:SetJustifyH(value)
    elseif self.frame and self.frame.SetJustifyH then
        self.frame:SetJustifyH(value)
    end
end

function Text:SetJustifyV(value)
    self:SetOption("justifyV", value)

    if self.textRegion and self.textRegion.SetJustifyV then
        self.textRegion:SetJustifyV(value)
    elseif self.frame and self.frame.SetJustifyV then
        self.frame:SetJustifyV(value)
    end
end

function Text:SetWordWrap(enabled)
    self:SetOption("wordWrap", enabled)

    if self.textRegion and self.textRegion.SetWordWrap then
        self.textRegion:SetWordWrap(enabled)
    elseif self.frame and self.frame.SetWordWrap then
        self.frame:SetWordWrap(enabled)
    end
end

function Text:Create()
    if self.frame then
        return self.frame
    end

    local parentFrame = self:GetParentFrame()
    if not parentFrame then
        if Debug.Internal then
            Debug.Internal("Addon.UI.Text requires a parent frame before Create().")
        end

        error("A text element requires a parent frame before Create().", 2)
    end

    local frame = CreateFrame("Frame", self.name, parentFrame, self.options.template)
    self:SetFrame(frame)

    local fontString = frame:CreateFontString(nil, self.options.layer or "OVERLAY")
    self.textRegion = fontString
    fontString:SetPoint("TOPLEFT", frame, "TOPLEFT", self.options.textInsetLeft or 2, -(self.options.textInsetTop or 2))
    fontString:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -(self.options.textInsetRight or 2), self.options.textInsetBottom or 2)

    Font:Apply(fontString, self.options, {
        fontSize = (Constants.FontSizes and Constants.FontSizes.Body) or 12,
    })

    if self.text ~= nil and fontString.SetText then
        fontString:SetText(self.text)
    end

    local textColor = UI.ResolveColor(self.options.textColor, "text.primary")
    if textColor and fontString.SetTextColor then
        local c = textColor
        fontString:SetTextColor(c.r or 1, c.g or 1, c.b or 1, c.a or 1)
    end

    if self.options.justifyH and fontString.SetJustifyH then
        fontString:SetJustifyH(self.options.justifyH)
    end

    if self.options.justifyV and fontString.SetJustifyV then
        fontString:SetJustifyV(self.options.justifyV)
    end

    if self.options.wordWrap ~= nil and fontString.SetWordWrap then
        fontString:SetWordWrap(self.options.wordWrap)
    end

    return self.frame
end
