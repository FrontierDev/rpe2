local _, Addon = ...

local UI = Addon.UI or {}
Addon.UI = UI
local ButtonBase = UI.ButtonBase
local Debug = Addon.Debug or {}
local Constants = UI.Constants or {}
local Font = UI.Font or {}

UI.Checkbox = UI.Checkbox or {}
local Checkbox = UI.Checkbox
Checkbox.__index = Checkbox
setmetatable(Checkbox, { __index = ButtonBase })

function Checkbox:New(options)
    local instance = ButtonBase.New(self, options)
    instance.checked = options and options.checked == true or false
    instance.label = nil
    instance.checkMark = nil
    instance.checkFill = nil
    instance.box = nil
    return instance
end

function Checkbox:GetChecked()
    return self.checked == true
end

function Checkbox:SetChecked(value, suppressCallback)
    self.checked = value == true

    if self.checkMark and self.checkMark.SetShown then
        self.checkMark:SetShown(self.checked)
    elseif self.checkMark and self.checkMark.Show and self.checkMark.Hide then
        if self.checked then
            self.checkMark:Show()
        else
            self.checkMark:Hide()
        end
    end

    if self.checkFill and self.checkFill.SetShown then
        self.checkFill:SetShown(self.checked)
    elseif self.checkFill and self.checkFill.Show and self.checkFill.Hide then
        if self.checked then
            self.checkFill:Show()
        else
            self.checkFill:Hide()
        end
    end

    if self.checkFill and self.checkFill.SetAlpha then
        self.checkFill:SetAlpha(self.checked and 1 or 0)
    end

    if self.checkMark and self.checkMark.SetAlpha then
        self.checkMark:SetAlpha(self.checked and 1 or 0)
    end

    if self.box and self.box.SetAlpha then
        self.box:SetAlpha(self.checked and 1 or 0.9)
    end

    if not suppressCallback and self.options.onValueChanged then
        self.options.onValueChanged(self.checked, self)
    end
end

function Checkbox:Toggle()
    self:SetChecked(not self:GetChecked())
end

function Checkbox:SetText(text)
    self:SetOption("text", text)

    if self.label and self.label.SetText then
        self.label:SetText(text)
    end
end

function Checkbox:Create()
    if self.frame then
        return self.frame
    end

    local frame = CreateFrame("Button", self.name, self:GetParentFrame(), self.options.template)
    self:SetFrame(frame)
    self:ApplyButtonScripts()
    if frame.RegisterForClicks then
        frame:RegisterForClicks("AnyUp")
    end
    local boxSize = self.options.boxSize or 14
    local labelOffset = self.options.labelOffset or 6
    local contentInsetLeft = self.options.contentInsetLeft or self.options.checkboxInsetLeft or self.options.contentInset or 2
    local contentInsetRight = self.options.contentInsetRight or self.options.checkboxInsetRight or self.options.contentInset or 2

    if frame.SetHeight then
        frame:SetHeight(self.options.height or math.max(boxSize, 18))
    end

    self.box = frame:CreateTexture(nil, "ARTWORK")
    self.box:SetSize(boxSize, boxSize)
    self.box:SetPoint("LEFT", frame, "LEFT", contentInsetLeft, 0)
    local boxColor = UI.ResolveColor(self.options.boxBackgroundColor, "checkbox.boxBackground")
    self.box:SetColorTexture(boxColor.r or 0, boxColor.g or 0, boxColor.b or 0, boxColor.a or 1)

    local border = frame:CreateTexture(nil, "OVERLAY")
    border:SetPoint("TOPLEFT", self.box, "TOPLEFT", -1, 1)
    border:SetPoint("BOTTOMRIGHT", self.box, "BOTTOMRIGHT", 1, -1)
    local borderColor = UI.ResolveColor(self.options.borderColor, "checkbox.border")
    border:SetColorTexture(borderColor.r or 0, borderColor.g or 0, borderColor.b or 0, borderColor.a or 1)

    self.checkFill = frame:CreateTexture(nil, "OVERLAY")
    self.checkFill:SetPoint("TOPLEFT", self.box, "TOPLEFT", 3, -3)
    self.checkFill:SetPoint("BOTTOMRIGHT", self.box, "BOTTOMRIGHT", -3, 3)
    self.checkFill:SetColorTexture(1, 1, 1, 1)
    if self.checkFill.SetDrawLayer then
        self.checkFill:SetDrawLayer("OVERLAY", 1)
    end

    self.checkMark = frame:CreateTexture(nil, "OVERLAY")
    self.checkMark:SetPoint("TOPLEFT", self.box, "TOPLEFT", 5, -5)
    self.checkMark:SetPoint("BOTTOMRIGHT", self.box, "BOTTOMRIGHT", -5, 5)
    self.checkMark:SetColorTexture(1, 1, 1, 1)
    if self.checkMark.SetDrawLayer then
        self.checkMark:SetDrawLayer("OVERLAY", 2)
    end

    self.label = frame:CreateFontString(nil, "OVERLAY")
    self.label:SetPoint("LEFT", self.box, "RIGHT", labelOffset, 0)
    self.label:SetPoint("RIGHT", frame, "RIGHT", -contentInsetRight, 0)
    self.label:SetJustifyH("LEFT")
    self.label:SetJustifyV("MIDDLE")
    Font:Apply(self.label, self.options, {
        fontSize = (Constants.FontSizes and Constants.FontSizes.Checkbox) or 12,
    })

    local labelColor = UI.ResolveColor(self.options.labelColor, "text.primary")
    if labelColor and self.label.SetTextColor then
        local c = labelColor
        self.label:SetTextColor(c.r or 1, c.g or 1, c.b or 1, c.a or 1)
    end

    self:SetText(self.options.text or "")
    self:SetChecked(self.checked, true)

    frame:SetScript("OnClick", function()
        self:Toggle()
    end)

    frame:SetScript("OnMouseDown", function()
        if self.box and self.box.SetAlpha then
            self.box:SetAlpha(1)
        end
    end)

    frame:SetScript("OnMouseUp", function()
        if self.box and self.box.SetAlpha then
            self.box:SetAlpha(self.checked and 1 or 0.9)
        end
    end)

    return self.frame
end
