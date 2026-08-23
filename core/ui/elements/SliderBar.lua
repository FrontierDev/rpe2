local _, Addon = ...

local UI = Addon.UI or {}
Addon.UI = UI
local BaseElement = UI.BaseElement
local Constants = UI.Constants or {}
local Font = UI.Font or {}

UI.SliderBar = UI.SliderBar or {}
local SliderBar = UI.SliderBar
SliderBar.__index = SliderBar
setmetatable(SliderBar, { __index = BaseElement })

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

local function Quantize(value, minValue, maxValue, step)
    local clamped = Clamp(value, minValue, maxValue)
    step = tonumber(step) or 0

    if step > 0 then
        local offset = clamped - minValue
        clamped = minValue + (math.floor((offset / step) + 0.5) * step)
        clamped = Clamp(clamped, minValue, maxValue)
    end

    return clamped
end

function SliderBar:New(options)
    local instance = BaseElement.New(self, options)
    instance.value = options and options.value or 0
    instance.minValue = options and options.minValue or 0
    instance.maxValue = options and options.maxValue or 100
    instance.step = options and options.step or 1
    instance.slider = nil
    instance.barFrame = nil
    instance.valueFrame = nil
    instance.background = nil
    instance.borderTop = nil
    instance.borderBottom = nil
    instance.borderLeft = nil
    instance.borderRight = nil
    instance.track = nil
    instance.fill = nil
    instance.thumb = nil
    instance.thumbTexture = nil
    instance.valueText = nil
    instance.dragging = false
    instance.dragStartValue = instance.value
    instance.pendingDragCallback = false
    instance.trackColor = nil
    instance.fillColor = nil
    instance.thumbColor = nil
    instance.textColor = nil
    return instance
end

function SliderBar:SetMinMax(minValue, maxValue)
    local value, resolvedMin, resolvedMax = Clamp(self.value, minValue or self.minValue or 0, maxValue or self.maxValue or 100)
    self.minValue = resolvedMin
    self.maxValue = resolvedMax

    if self.slider then
        self.slider.minValue = self.minValue
        self.slider.maxValue = self.maxValue
    end

    self:SetValue(value, true)
    self:UpdateLayout()
end

function SliderBar:SetStep(step)
    self.step = tonumber(step) or self.step or 1
    self:SetValue(self.value, true)
    self:UpdateLayout()
end

function SliderBar:SetValue(value, suppressCallback)
    local resolved = Quantize(value, self.minValue or 0, self.maxValue or 100, self.step or 1)
    local previous = self.value
    self.value = resolved

    if self.slider then
        self.slider.value = resolved
    end

    self:UpdateLayout()

    if not suppressCallback and self.options.onValueChanged and previous ~= resolved then
        if self.dragging and self.options.deferValueChangedUntilMouseUp == true then
            self.pendingDragCallback = true
            return
        end

        self.options.onValueChanged(self.value, self)
    end
end

function SliderBar:GetValue()
    return self.value or 0
end

function SliderBar:GetNormalizedValue()
    local minValue = self.minValue or 0
    local maxValue = self.maxValue or 100
    local range = maxValue - minValue

    if range <= 0 then
        return 0
    end

    return math.max(0, math.min(1, (self.value - minValue) / range))
end

function SliderBar:FormatValue(value)
    local format = self.options.valueFormat
    if format and type(format) == "string" then
        return format:format(value)
    end

    return tostring(math.floor(value or 0))
end

function SliderBar:UpdateValueText()
    if not self.valueText or not self.valueText.SetText then
        return
    end

    self.valueText:SetText(self:FormatValue(self.value))
end

function SliderBar:UpdateThumbPosition()
    if not self.barFrame or not self.thumb then
        return
    end

    local orientation = (self.options.orientation or "HORIZONTAL"):upper()
    local barWidth = self.barFrame.GetWidth and self.barFrame:GetWidth() or 0
    local barHeight = self.barFrame.GetHeight and self.barFrame:GetHeight() or 0
    local thumbWidth = self.thumb.GetWidth and self.thumb:GetWidth() or 0
    local thumbHeight = self.thumb.GetHeight and self.thumb:GetHeight() or 0
    local insetLeft = self.options.trackInsetLeft or 2
    local insetRight = self.options.trackInsetRight or 2
    local insetTop = self.options.trackInsetTop or 2
    local insetBottom = self.options.trackInsetBottom or 2
    local normalized = self:GetNormalizedValue()

    if orientation == "VERTICAL" then
        local innerHeight = math.max(1, barHeight - insetTop - insetBottom - thumbHeight)
        local offsetY = insetBottom + (normalized * innerHeight)

        self.thumb:ClearAllPoints()
        self.thumb:SetPoint("BOTTOM", self.barFrame, "BOTTOM", 0, offsetY)

        if self.fill then
            self.fill:ClearAllPoints()
            self.fill:SetPoint("LEFT", self.track, "LEFT", 0, 0)
            self.fill:SetPoint("RIGHT", self.track, "RIGHT", 0, 0)
            self.fill:SetPoint("BOTTOM", self.track, "BOTTOM", 0, 0)
            self.fill:SetPoint("TOP", self.thumb, "CENTER", 0, 0)
        end
    else
        local innerWidth = math.max(1, barWidth - insetLeft - insetRight - thumbWidth)
        local offsetX = insetLeft + (normalized * innerWidth)

        self.thumb:ClearAllPoints()
        self.thumb:SetPoint("LEFT", self.barFrame, "LEFT", offsetX, 0)

        if self.fill then
            self.fill:ClearAllPoints()
            self.fill:SetPoint("LEFT", self.track, "LEFT", 0, 0)
            self.fill:SetPoint("TOP", self.track, "TOP", 0, 0)
            self.fill:SetPoint("BOTTOM", self.track, "BOTTOM", 0, 0)
            self.fill:SetPoint("RIGHT", self.thumb, "CENTER", 0, 0)
        end
    end
end

function SliderBar:UpdateLayout()
    self:UpdateValueText()
    self:UpdateThumbPosition()
end

function SliderBar:UpdateValueFromCursor()
    if not self.barFrame then
        return
    end

    local orientation = (self.options.orientation or "HORIZONTAL"):upper()
    local scale = self.barFrame.GetEffectiveScale and self.barFrame:GetEffectiveScale() or 1
    local cursorX, cursorY = GetCursorPosition()
    cursorX = cursorX / scale
    cursorY = cursorY / scale

    local minValue = self.minValue or 0
    local maxValue = self.maxValue or 100
    local thumbWidth = self.thumb and self.thumb.GetWidth and self.thumb:GetWidth() or 0
    local thumbHeight = self.thumb and self.thumb.GetHeight and self.thumb:GetHeight() or 0
    local insetLeft = self.options.trackInsetLeft or 2
    local insetRight = self.options.trackInsetRight or 2
    local insetTop = self.options.trackInsetTop or 2
    local insetBottom = self.options.trackInsetBottom or 2

    if orientation == "VERTICAL" then
        local bottom = self.barFrame.GetBottom and self.barFrame:GetBottom() or 0
        local height = self.barFrame.GetHeight and self.barFrame:GetHeight() or 1
        local usableHeight = math.max(1, height - insetTop - insetBottom - thumbHeight)
        local normalized = (cursorY - bottom - insetBottom - (thumbHeight * 0.5)) / usableHeight
        local value = minValue + (math.max(0, math.min(1, normalized)) * (maxValue - minValue))
        self:SetValue(value)
    else
        local left = self.barFrame.GetLeft and self.barFrame:GetLeft() or 0
        local width = self.barFrame.GetWidth and self.barFrame:GetWidth() or 1
        local usableWidth = math.max(1, width - insetLeft - insetRight - thumbWidth)
        local normalized = (cursorX - left - insetLeft - (thumbWidth * 0.5)) / usableWidth
        local value = minValue + (math.max(0, math.min(1, normalized)) * (maxValue - minValue))
        self:SetValue(value)
    end
end

function SliderBar:StartDragging()
    self.dragging = true
    self.dragStartValue = self.value
    self.pendingDragCallback = false
    if self.frame and self.frame.SetScript then
        self.frame:SetScript("OnUpdate", function()
            if self.dragging then
                self:UpdateValueFromCursor()
            end
        end)
    end
    self:UpdateValueFromCursor()
end

function SliderBar:StopDragging()
    self.dragging = false
    if self.frame and self.frame.SetScript then
        self.frame:SetScript("OnUpdate", nil)
    end

    if self.options.deferValueChangedUntilMouseUp == true
        and self.pendingDragCallback
        and self.options.onValueChanged
        and self.dragStartValue ~= self.value
    then
        self.pendingDragCallback = false
        self.options.onValueChanged(self.value, self)
        return
    end

    self.pendingDragCallback = false
end

function SliderBar:ApplyColors()
    self.backgroundColor = UI.ResolveColor(self.options.backgroundColor or self.options.trackColor, self.options.backgroundToken or self.options.trackToken or "slider.background")
    self.trackColor = self.backgroundColor
    self.fillColor = UI.ResolveColor(self.options.fillColor, self.options.fillToken or "slider.fill")
    self.thumbColor = UI.ResolveColor(self.options.thumbColor, self.options.thumbToken or "slider.thumb")
    self.textColor = UI.ResolveColor(self.options.textColor, self.options.textToken or "slider.text")
end

function SliderBar:Create()
    if self.frame then
        return self.frame
    end

    local frame = CreateFrame("Frame", self.name, self:GetParentFrame(), self.options.template)
    self:SetFrame(frame)
    self.slider = frame

    local orientation = (self.options.orientation or "HORIZONTAL"):upper()
    local width = self.options.width or 180
    local height = self.options.height or ((Constants.Heights and Constants.Heights.SliderControl) or 12)
    local valueWidth = self.options.valueTextWidth or self.options.labelWidth or 48
    local labelSpacing = self.options.labelSpacing or 8
    local barInsetLeft = self.options.barInsetLeft or 6
    local barInsetRight = self.options.barInsetRight or 4
    local barInsetTop = self.options.barInsetTop or 4
    local barInsetBottom = self.options.barInsetBottom or 4

    frame:SetSize(width, height)
    frame:EnableMouse(true)
    frame:EnableMouseWheel(false)

    self.valueFrame = CreateFrame("Frame", nil, frame)
    self.valueFrame:SetWidth(valueWidth)
    self.valueFrame:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -barInsetRight, -barInsetTop)
    self.valueFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -barInsetRight, barInsetBottom)
    self.valueFrame:EnableMouse(true)

    self.valueText = self.valueFrame:CreateFontString(nil, "OVERLAY")
    self.valueText:SetPoint("LEFT", self.valueFrame, "LEFT", 0, 0)
    self.valueText:SetPoint("RIGHT", self.valueFrame, "RIGHT", 0, 0)
    self.valueText:SetJustifyH("RIGHT")
    Font:Apply(self.valueText, self.options, {
        fontSize = (Constants.FontSizes and Constants.FontSizes.SliderBar) or 10,
    })

    self.barFrame = CreateFrame("Frame", nil, frame)
    self.barFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", barInsetLeft + 1, -(barInsetTop + 1))
    self.barFrame:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", barInsetLeft + 1, barInsetBottom + 1)
    self.barFrame:SetPoint("RIGHT", self.valueFrame, "LEFT", -(labelSpacing + 1), 0)
    self.barFrame:EnableMouse(true)

    self.background = self.barFrame:CreateTexture(nil, "BACKGROUND")
    self.background:SetAllPoints(self.barFrame)
    self.track = self.background

    self.fill = self.barFrame:CreateTexture(nil, "ARTWORK")

    self.thumb = CreateFrame("Button", nil, self.barFrame)
    self.thumb:SetSize(self.options.thumbSize or (orientation == "VERTICAL" and 14 or 10), self.options.thumbSize or (orientation == "VERTICAL" and 14 or 10))
    self.thumb:SetFrameLevel((frame.GetFrameLevel and frame:GetFrameLevel() or 0) + 2)
    self.thumb:EnableMouse(true)

    self.thumbTexture = self.thumb:CreateTexture(nil, "OVERLAY")
    self.thumbTexture:SetAllPoints(self.thumb)

    self:ApplyColors()

    if self.backgroundColor then
        local c = self.backgroundColor
        self.background:SetColorTexture(c.r or 0.05, c.g or 0.06, c.b or 0.08, c.a or 0.95)
    end

    if self.fillColor then
        local c = self.fillColor
        self.fill:SetColorTexture(c.r or 0.42, c.g or 0.66, c.b or 0.98, c.a or 1)
    end

    if self.thumbColor then
        local c = self.thumbColor
        self.thumbTexture:SetColorTexture(c.r or 0.92, c.g or 0.94, c.b or 0.98, c.a or 1)
    end

    if self.options.thumbTexture then
        self.thumbTexture:SetTexture(self.options.thumbTexture)
    end

    if self.textColor and self.valueText.SetTextColor then
        local c = self.textColor
        self.valueText:SetTextColor(c.r or 1, c.g or 1, c.b or 1, c.a or 1)
    end

    self.valueFrame:SetScript("OnMouseUp", function(_, button)
        if button ~= "LeftButton" then
            return
        end

        if self.options.resetValue ~= nil then
            self:SetValue(self.options.resetValue)
        end
    end)

    if self.options.backdrop and frame.SetBackdrop then
        frame:SetBackdrop(self.options.backdrop)
    end

    self.barFrame:SetScript("OnMouseDown", function(_, button)
        if button ~= "LeftButton" then
            return
        end

        self:StartDragging()
    end)

    self.barFrame:SetScript("OnMouseUp", function(_, button)
        if button ~= "LeftButton" then
            return
        end

        self:StopDragging()
    end)

    self.thumb:SetScript("OnMouseDown", function(_, button)
        if button ~= "LeftButton" then
            return
        end

        self:StartDragging()
    end)

    self.thumb:SetScript("OnMouseUp", function(_, button)
        if button ~= "LeftButton" then
            return
        end

        self:StopDragging()
    end)

    frame:SetScript("OnMouseUp", function(_, button)
        if button == "LeftButton" then
            self:StopDragging()
        end
    end)

    frame:SetScript("OnSizeChanged", function()
        self:UpdateLayout()
    end)

    self:SetValue(self.value, true)
    self:UpdateLayout()
    return self.frame
end
