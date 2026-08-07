local _, Addon = ...

local UI = Addon.UI or {}
Addon.UI = UI
local ButtonBase = UI.ButtonBase
local Debug = Addon.Debug or {}
local Constants = UI.Constants or {}
local Font = UI.Font or {}

UI.TextButton = UI.TextButton or {}
local TextButton = UI.TextButton
TextButton.__index = TextButton
setmetatable(TextButton, { __index = ButtonBase })

function TextButton:New(options)
    local instance = ButtonBase.New(self, options)
    instance.text = options and options.text or ""
    instance.options.suppressHighlight = true
    return instance
end

function TextButton:ApplyLabelFont()
    if not self.label then
        return
    end

    Font:Apply(self.label, self.options, {
        fontSize = (Constants.FontSizes and Constants.FontSizes.ButtonLabel) or 12,
    })
end

function TextButton:SetFont(fontFile, fontSize, fontFlags)
    self:SetOption("fontFile", fontFile)
    self:SetOption("fontSize", fontSize)
    self:SetOption("fontFlags", fontFlags)
    self:ApplyLabelFont()
end

function TextButton:SetText(text)
    self.text = text

    if self.label and self.label.SetText then
        self.label:SetText(text)
    elseif self.frame and self.frame.SetText then
        self.frame:SetText(text)
    end
end

function TextButton:SetLabelColor(r, g, b, a)
    self:SetOption("labelColor", { r = r, g = g, b = b, a = a })

    if self.label and self.label.SetTextColor then
        self.label:SetTextColor(r, g, b, a)
    end
end

function TextButton:GetText()
    return self.text
end

function TextButton:Create()
    if self.frame then
        return self.frame
    end

    local frame = self:CreateButton(self.options.template)

    self.background = frame:CreateTexture(nil, "BACKGROUND")
    self.background:SetAllPoints(frame)
    local backgroundColor = UI.ResolveColor(self.options.backgroundColor, "panel.background")
    self.background:SetColorTexture(backgroundColor.r or 0.08, backgroundColor.g or 0.09, backgroundColor.b or 0.12, backgroundColor.a or 0.85)

    self.topBorder = frame:CreateTexture(nil, "ARTWORK")
    self.topBorder:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
    self.topBorder:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
    self.topBorder:SetHeight(self.options.borderSize or 1)
    local topColor = UI.ResolveColor(self.options.borderTopColor, "panel.border")
    self.topBorder:SetColorTexture(topColor.r or 0.16, topColor.g or 0.18, topColor.b or 0.22, topColor.a or 1)

    self.bottomBorder = frame:CreateTexture(nil, "ARTWORK")
    self.bottomBorder:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 0)
    self.bottomBorder:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
    self.bottomBorder:SetHeight(self.options.borderSize or 1)
    local bottomColor = UI.ResolveColor(self.options.borderBottomColor, "panel.border")
    self.bottomBorder:SetColorTexture(bottomColor.r or 0.12, bottomColor.g or 0.14, bottomColor.b or 0.17, bottomColor.a or 1)

    self.label = frame:CreateFontString(nil, "OVERLAY")
    self.label:SetPoint("CENTER", frame, "CENTER", 0, 0)

    self:ApplyLabelFont()

    local labelColor = UI.ResolveColor(self.options.labelColor, "button.label")
    if labelColor and self.label.SetTextColor then
        local c = labelColor
        self.label:SetTextColor(c.r or 1, c.g or 1, c.b or 1, c.a or 1)
    end

    self:SetText(self.text)

    local normalColor = UI.ResolveColor(self.options.backgroundColor, "panel.background")

    local function AdjustColor(color, amount)
        local base = color or normalColor or {}
        local r = math.max(0, math.min(1, (base.r or 0.08) + amount))
        local g = math.max(0, math.min(1, (base.g or 0.09) + amount))
        local b = math.max(0, math.min(1, (base.b or 0.12) + amount))
        local a = base.a or 1
        return { r = r, g = g, b = b, a = a }
    end

    local hoverColor = self.options.hoverColor or AdjustColor(normalColor, 0.08)
    local downColor = self.options.pressedColor or AdjustColor(normalColor, -0.06)
    local labelHoverColor = UI.ResolveColor(self.options.hoverLabelColor, nil, UI.ResolveColor(self.options.labelColor, "button.label"))
    local labelDownColor = UI.ResolveColor(self.options.pressedLabelColor, nil, labelHoverColor)

    frame:SetScript("OnEnter", function()
        if self.background and self.background.SetColorTexture then
            self.background:SetColorTexture(hoverColor.r or 0.1, hoverColor.g or 0.11, hoverColor.b or 0.15, hoverColor.a or 0.95)
        end

        if self.topBorder and self.topBorder.SetColorTexture then
            self.topBorder:SetColorTexture(hoverColor.r or 0.12, hoverColor.g or 0.14, hoverColor.b or 0.18, 1)
        end

        if self.bottomBorder and self.bottomBorder.SetColorTexture then
            self.bottomBorder:SetColorTexture(hoverColor.r or 0.1, hoverColor.g or 0.12, hoverColor.b or 0.16, 1)
        end

        if self.label and self.label.SetTextColor then
            local c = labelHoverColor or {}
            self.label:SetTextColor(c.r or 1, c.g or 1, c.b or 1, c.a or 1)
        end
    end)

    frame:SetScript("OnLeave", function()
        if self.background and self.background.SetColorTexture then
            self.background:SetColorTexture(normalColor.r or 0.08, normalColor.g or 0.09, normalColor.b or 0.12, normalColor.a or 0.85)
        end

        if self.topBorder and self.topBorder.SetColorTexture then
            local c = UI.ResolveColor(self.options.borderTopColor, "panel.border")
            self.topBorder:SetColorTexture(c.r or 0.16, c.g or 0.18, c.b or 0.22, c.a or 1)
        end

        if self.bottomBorder and self.bottomBorder.SetColorTexture then
            local c = UI.ResolveColor(self.options.borderBottomColor, "panel.border")
            self.bottomBorder:SetColorTexture(c.r or 0.12, c.g or 0.14, c.b or 0.17, c.a or 1)
        end

        if self.label and self.label.SetTextColor then
            local c = UI.ResolveColor(self.options.labelColor, "button.label")
            self.label:SetTextColor(c.r or 1, c.g or 1, c.b or 1, c.a or 1)
        end
    end)

    frame:SetScript("OnMouseDown", function()
        if self.background and self.background.SetColorTexture then
            self.background:SetColorTexture(downColor.r or 0.06, downColor.g or 0.07, downColor.b or 0.1, downColor.a or 1)
        end

        if self.topBorder and self.topBorder.SetColorTexture then
            self.topBorder:SetColorTexture(downColor.r or 0.08, downColor.g or 0.09, downColor.b or 0.12, 1)
        end

        if self.bottomBorder and self.bottomBorder.SetColorTexture then
            self.bottomBorder:SetColorTexture(downColor.r or 0.06, downColor.g or 0.07, downColor.b or 0.1, 1)
        end

        if self.label and self.label.SetTextColor then
            local c = labelDownColor or {}
            self.label:SetTextColor(c.r or 1, c.g or 1, c.b or 1, c.a or 1)
        end
    end)

    frame:SetScript("OnMouseUp", function()
        if self.background and self.background.SetColorTexture then
            self.background:SetColorTexture(hoverColor.r or 0.1, hoverColor.g or 0.11, hoverColor.b or 0.15, hoverColor.a or 0.95)
        end

        if self.label and self.label.SetTextColor then
            local c = labelHoverColor or {}
            self.label:SetTextColor(c.r or 1, c.g or 1, c.b or 1, c.a or 1)
        end
    end)

    return self.frame
end
