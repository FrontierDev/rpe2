local _, Addon = ...

local UI = Addon.UI or {}
Addon.UI = UI
local BaseElement = UI.BaseElement
local Constants = UI.Constants or {}
local Font = UI.Font or {}

UI.ProgressBar = UI.ProgressBar or {}
local ProgressBar = UI.ProgressBar
ProgressBar.__index = ProgressBar
setmetatable(ProgressBar, { __index = BaseElement })

local function Clamp(value, minValue, maxValue)
    value = tonumber(value) or minValue or 0
    minValue = tonumber(minValue) or 0
    maxValue = tonumber(maxValue) or 100

    if maxValue < minValue then
        minValue, maxValue = maxValue, minValue
    end

    if value < minValue then
        value = minValue
    elseif value > maxValue then
        value = maxValue
    end

    return value, minValue, maxValue
end

function ProgressBar:New(options)
    local instance = BaseElement.New(self, options)
    instance.value = options and options.value or 0
    instance.secondaryValue = options and options.secondaryValue ~= nil and options.secondaryValue or nil
    instance.minValue = options and options.minValue or 0
    instance.maxValue = options and options.maxValue or 100
    instance.barFrame = nil
    instance.contentFrame = nil
    instance.labelFrame = nil
    instance.label = nil
    instance.background = nil
    instance.borderTop = nil
    instance.borderBottom = nil
    instance.borderLeft = nil
    instance.borderRight = nil
    instance.secondaryBar = nil
    instance.primaryBar = nil
    instance.valueText = nil
    instance.backgroundColor = nil
    instance.secondaryColor = nil
    instance.primaryColor = nil
    instance.textColor = nil
    return instance
end

function ProgressBar:SetMinMax(minValue, maxValue)
    local value, resolvedMin, resolvedMax = Clamp(self.value, minValue or self.minValue or 0, maxValue or self.maxValue or 100)
    self.minValue = resolvedMin
    self.maxValue = resolvedMax
    self.value = value

    if self.secondaryValue ~= nil then
        self.secondaryValue = Clamp(self.secondaryValue, self.minValue, self.maxValue)
    end

    self:UpdateBars()
    self:UpdateLabel()
end

function ProgressBar:SetValue(value)
    self.value = Clamp(value, self.minValue or 0, self.maxValue or 100)
    self:UpdateBars()
    self:UpdateLabel()
end

function ProgressBar:SetSecondaryValue(value)
    if value == nil then
        self.secondaryValue = nil
    else
        self.secondaryValue = Clamp(value, self.minValue or 0, self.maxValue or 100)
    end

    self:UpdateBars()
end

function ProgressBar:GetValue()
    return self.value or 0
end

function ProgressBar:SetText(text)
    self:SetOption("text", text)
    self:UpdateLabel()
end

function ProgressBar:GetNormalizedValue(value)
    local minValue = self.minValue or 0
    local maxValue = self.maxValue or 100
    local range = maxValue - minValue

    if range <= 0 then
        return 0
    end

    return math.max(0, math.min(1, ((value or 0) - minValue) / range))
end

function ProgressBar:GetBarContentWidth()
    if not self.barFrame then
        return self.options.width or 0
    end

    return self.barFrame:GetWidth() or 0
end

function ProgressBar:UpdateLabel()
    if not self.label or not self.label.SetText then
        return
    end

    local text = self.options.text
    if text == nil then
        text = ("%d%%"):format(math.floor(self:GetValue()))
    end

    self.label:SetText(text)
end

function ProgressBar:UpdateBars()
    if not self.barFrame or not self.primaryBar then
        return
    end

    local normalizedValue = self:GetNormalizedValue(self.value)
    local barWidth = self.barFrame:GetWidth() or 0
    local barHeight = self.barFrame:GetHeight() or 0

    self.primaryBar:ClearAllPoints()
    self.primaryBar:SetPoint("LEFT", self.barFrame, "LEFT", 0, 0)
    self.primaryBar:SetPoint("BOTTOM", self.barFrame, "BOTTOM", 0, 0)
    self.primaryBar:SetPoint("TOP", self.barFrame, "TOP", 0, 0)
    self.primaryBar:SetWidth(math.max(0, barWidth * normalizedValue))

    if self.secondaryBar then
        self.secondaryBar:ClearAllPoints()
        self.secondaryBar:SetPoint("LEFT", self.barFrame, "LEFT", 0, 0)
        self.secondaryBar:SetPoint("BOTTOM", self.barFrame, "BOTTOM", 0, 0)
        self.secondaryBar:SetPoint("TOP", self.barFrame, "TOP", 0, 0)

        if self.secondaryValue == nil then
            self.secondaryBar:Hide()
        else
            self.secondaryBar:Show()
            local normalizedSecondary = self:GetNormalizedValue(self.secondaryValue)
            self.secondaryBar:SetWidth(math.max(0, barWidth * normalizedSecondary))
        end
    end

end

function ProgressBar:UpdateLayout()
    self:UpdateBars()
    self:UpdateLabel()
end

function ProgressBar:ApplyColors()
    self.backgroundColor = UI.ResolveColor(self.options.backgroundColor, self.options.backgroundToken or "progress.background")
    self.borderColor = UI.ResolveColor(self.options.borderColor, self.options.borderToken or "progress.border")
    self.secondaryColor = UI.ResolveColor(self.options.secondaryColor or self.options.barSecondaryColor or self.options.barSecondary, self.options.secondaryToken or "progress.barSecondary")
    self.primaryColor = UI.ResolveColor(self.options.primaryColor or self.options.barColor, self.options.primaryToken or "progress.barPrimary")
    self.textColor = UI.ResolveColor(self.options.textColor, self.options.textToken or "progress.text")

    if self.background and self.background.SetColorTexture and self.backgroundColor then
        local c = self.backgroundColor
        self.background:SetColorTexture(c.r or 0.08, c.g or 0.09, c.b or 0.12, c.a or 1)
    end

    if self.borderColor then
        local c = self.borderColor
        local r = c.r or 0.16
        local g = c.g or 0.18
        local b = c.b or 0.22
        local a = c.a or 1
        if self.borderTop and self.borderTop.SetColorTexture then self.borderTop:SetColorTexture(r, g, b, a) end
        if self.borderBottom and self.borderBottom.SetColorTexture then self.borderBottom:SetColorTexture(r, g, b, a) end
        if self.borderLeft and self.borderLeft.SetColorTexture then self.borderLeft:SetColorTexture(r, g, b, a) end
        if self.borderRight and self.borderRight.SetColorTexture then self.borderRight:SetColorTexture(r, g, b, a) end
    end

    if self.secondaryBar and self.secondaryBar.SetColorTexture and self.secondaryColor then
        local c = self.secondaryColor
        self.secondaryBar:SetColorTexture(c.r or 0.25, c.g or 0.42, c.b or 0.68, c.a or 1)
    end

    if self.primaryBar and self.primaryBar.SetColorTexture and self.primaryColor then
        local c = self.primaryColor
        self.primaryBar:SetColorTexture(c.r or 0.42, c.g or 0.66, c.b or 0.98, c.a or 1)
    end

    if self.textColor and self.label and self.label.SetTextColor then
        local c = self.textColor
        self.label:SetTextColor(c.r or 1, c.g or 1, c.b or 1, c.a or 1)
    end
end

function ProgressBar:Create()
    if self.frame then
        return self.frame
    end

    local frame = CreateFrame("Frame", self.name, self:GetParentFrame(), self.options.template)
    self:SetFrame(frame)

    local width = self.options.width or 220
    local height = self.options.height or ((Constants.Heights and (Constants.Heights.ProgressBar or Constants.Heights.ProgressControl)) or 16)
    frame:SetSize(width, height)

    self.contentFrame = CreateFrame("Frame", nil, frame)
    self.contentFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", 2, 0)
    self.contentFrame:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -2, 0)
    self.contentFrame:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 2, 0)
    self.contentFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -2, 0)
    self.contentFrame:SetFrameLevel((frame.GetFrameLevel and frame:GetFrameLevel() or 0) + 1)

    self.background = self.contentFrame:CreateTexture(nil, "BACKGROUND")
    self.background:SetAllPoints(self.contentFrame)

    self.barFrame = self.contentFrame

    self.labelFrame = CreateFrame("Frame", nil, frame)
    self.labelFrame:SetAllPoints(frame)
    self.labelFrame:SetFrameLevel((frame.GetFrameLevel and frame:GetFrameLevel() or 0) + 2)

    self.label = self.labelFrame:CreateFontString(nil, "OVERLAY")
    self.label:SetPoint("CENTER", self.labelFrame, "CENTER", 0, 0)
    self.label:SetJustifyH("CENTER")
    Font:Apply(self.label, self.options, {
        fontSize = (Constants.FontSizes and Constants.FontSizes.ProgressBar) or 10,
        fontFlags = self.options.fontFlags,
    })

    self.borderTop = frame:CreateTexture(nil, "ARTWORK")
    self.borderTop:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
    self.borderTop:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
    self.borderTop:SetHeight(1)

    self.borderBottom = frame:CreateTexture(nil, "ARTWORK")
    self.borderBottom:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 0)
    self.borderBottom:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
    self.borderBottom:SetHeight(1)

    self.borderLeft = frame:CreateTexture(nil, "ARTWORK")
    self.borderLeft:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
    self.borderLeft:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 0)
    self.borderLeft:SetWidth(1)

    self.borderRight = frame:CreateTexture(nil, "ARTWORK")
    self.borderRight:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
    self.borderRight:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
    self.borderRight:SetWidth(1)

    self.secondaryBar = self.barFrame:CreateTexture(nil, "ARTWORK")
    self.secondaryBar:SetPoint("LEFT", self.barFrame, "LEFT", 0, 0)
    self.secondaryBar:SetPoint("BOTTOM", self.barFrame, "BOTTOM", 0, 0)
    self.secondaryBar:SetPoint("TOP", self.barFrame, "TOP", 0, 0)

    self.primaryBar = self.barFrame:CreateTexture(nil, "OVERLAY")
    self.primaryBar:SetPoint("LEFT", self.barFrame, "LEFT", 0, 0)
    self.primaryBar:SetPoint("BOTTOM", self.barFrame, "BOTTOM", 0, 0)
    self.primaryBar:SetPoint("TOP", self.barFrame, "TOP", 0, 0)
    self.bar = self.primaryBar

    self:ApplyColors()

    if self.backgroundColor then
        local c = self.backgroundColor
        self.background:SetColorTexture(c.r or 0.08, c.g or 0.09, c.b or 0.12, c.a or 1)
    end

    if self.borderColor then
        local c = self.borderColor
        local r = c.r or 0.16
        local g = c.g or 0.18
        local b = c.b or 0.22
        local a = c.a or 1
        if self.borderTop then self.borderTop:SetColorTexture(r, g, b, a) end
        if self.borderBottom then self.borderBottom:SetColorTexture(r, g, b, a) end
        if self.borderLeft then self.borderLeft:SetColorTexture(r, g, b, a) end
        if self.borderRight then self.borderRight:SetColorTexture(r, g, b, a) end
    end

    if self.secondaryColor then
        local c = self.secondaryColor
        self.secondaryBar:SetColorTexture(c.r or 0.25, c.g or 0.42, c.b or 0.68, c.a or 1)
    end

    if self.primaryColor then
        local c = self.primaryColor
        self.primaryBar:SetColorTexture(c.r or 0.42, c.g or 0.66, c.b or 0.98, c.a or 1)
    end

    if self.textColor and self.label.SetTextColor then
        local c = self.textColor
        self.label:SetTextColor(c.r or 1, c.g or 1, c.b or 1, c.a or 1)
    end

    if self.options.backdrop and frame.SetBackdrop then
        frame:SetBackdrop(self.options.backdrop)
    end

    frame:SetScript("OnSizeChanged", function()
        self:UpdateLayout()
    end)

    self:UpdateLayout()
    return self.frame
end
