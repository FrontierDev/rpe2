local _, Addon = ...

local UI = Addon.UI or {}
Addon.UI = UI
local BaseElement = UI.BaseElement
local Debug = Addon.Debug or {}
local Constants = UI.Constants or {}

UI.TextInput = UI.TextInput or {}
local TextInput = UI.TextInput
TextInput.__index = TextInput
setmetatable(TextInput, { __index = BaseElement })

local function NormalizeText(text)
    if text == nil then
        return ""
    end

    return tostring(text)
end

local function ApplyEditBoxFont(editBox, options)
    if not editBox then
        return
    end

    local fontObject = options and options.fontObject or (Constants.FontObjects and Constants.FontObjects.Body) or nil
    if fontObject and editBox.SetFontObject then
        local ok = pcall(function()
            editBox:SetFontObject(fontObject)
        end)
        if ok then
            return
        end
    end

    if editBox.SetFont then
        pcall(function()
            editBox:SetFont(
                (options and options.fontFile) or ((Constants.FontFiles and Constants.FontFiles.Default) or "Fonts\\FRIZQT__.TTF"),
                (options and options.fontSize) or ((Constants.FontSizes and Constants.FontSizes.Body) or 8),
                options and options.fontFlags or nil
            )
        end)
    end
end

function TextInput:New(options)
    local instance = BaseElement.New(self, options)
    instance.text = NormalizeText(options and options.text)
    instance.editBox = nil
    instance.backgroundTexture = nil
    instance.fieldBorderTextures = nil
    instance.scripts = {}
    instance.enabled = options == nil or options.enabled ~= false
    instance._syncingText = false
    instance._skipNextFocusLost = false
    instance._skipNextFocusLostText = nil
    return instance
end

function TextInput:GetEditBox()
    return self.editBox
end

function TextInput:SetScript(scriptName, handler)
    self.scripts = self.scripts or {}
    self.scripts[scriptName] = type(handler) == "function" and handler or nil
end

function TextInput:SetText(text)
    self.text = NormalizeText(text)

    if self.editBox and self.editBox.SetText then
        self._syncingText = true
        self.editBox:SetText(self.text)
        self._syncingText = false
    end

    return self.text
end

function TextInput:GetText()
    if self.editBox and self.editBox.GetText then
        self.text = NormalizeText(self.editBox:GetText())
    end

    return self.text
end

function TextInput:SetReadOnly(readOnly)
    self:SetOption("readOnly", readOnly == true)

    if self.editBox and self.editBox.EnableMouse then
        local interactive = readOnly ~= true and self.enabled ~= false
        self.editBox:EnableMouse(interactive)
        if not interactive and self.editBox.ClearFocus then
            self.editBox:ClearFocus()
        end
    end

    return self:GetOption("readOnly", false)
end

function TextInput:SetEnabled(enabled)
    self.enabled = enabled ~= false

    if self.editBox and self.editBox.EnableMouse then
        local interactive = self.enabled and not self:GetOption("readOnly", false)
        self.editBox:EnableMouse(interactive)
        if not interactive and self.editBox.ClearFocus then
            self.editBox:ClearFocus()
        end
    end

    if self.frame and self.frame.SetAlpha then
        self.frame:SetAlpha(self.enabled and 1 or 0.5)
    end

    return self.enabled
end

function TextInput:Focus()
    if self.editBox and self.editBox.SetFocus then
        self.editBox:SetFocus()
    end
end

function TextInput:ClearFocus()
    if self.editBox and self.editBox.ClearFocus then
        self.editBox:ClearFocus()
    end
end

function TextInput:InvokeScript(scriptName)
    local handler = self.scripts and self.scripts[scriptName] or nil
    if handler then
        return handler(self, self:GetText())
    end

    return nil
end

function TextInput:Create()
    if self.frame then
        return self.frame
    end

    local parentFrame = self:GetParentFrame()
    if not parentFrame then
        if Debug.Internal then
            Debug.Internal("Addon.UI.TextInput requires a parent frame before Create().")
        end

        error("A text input requires a parent frame before Create().", 2)
    end

    local frame = CreateFrame("Frame", self.name, parentFrame, self.options.template)
    self:SetFrame(frame)

    self.backgroundTexture = frame:CreateTexture(nil, "BACKGROUND")
    self.backgroundTexture:SetAllPoints(frame)
    local backgroundColor = UI.ResolveColor(self.options.backgroundColor, "panel.background")
    self.backgroundTexture:SetColorTexture(backgroundColor.r or 0.06, backgroundColor.g or 0.07, backgroundColor.b or 0.1, backgroundColor.a or 0.95)

    local borderSize = self.options.borderSize or 1
    local borderColor = UI.ResolveColor(self.options.borderColor, "panel.border")
    self.fieldBorderTextures = self.fieldBorderTextures or {}
    local borders = self.fieldBorderTextures

    if not borders.top then
        borders.top = frame:CreateTexture(nil, "ARTWORK")
    end
    if not borders.bottom then
        borders.bottom = frame:CreateTexture(nil, "ARTWORK")
    end
    if not borders.left then
        borders.left = frame:CreateTexture(nil, "ARTWORK")
    end
    if not borders.right then
        borders.right = frame:CreateTexture(nil, "ARTWORK")
    end

    borders.top:ClearAllPoints()
    borders.top:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
    borders.top:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
    borders.top:SetHeight(borderSize)
    borders.top:SetColorTexture(borderColor.r or 0.16, borderColor.g or 0.18, borderColor.b or 0.22, borderColor.a or 1)

    borders.bottom:ClearAllPoints()
    borders.bottom:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 0)
    borders.bottom:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
    borders.bottom:SetHeight(borderSize)
    borders.bottom:SetColorTexture(borderColor.r or 0.16, borderColor.g or 0.18, borderColor.b or 0.22, borderColor.a or 1)

    borders.left:ClearAllPoints()
    borders.left:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
    borders.left:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 0)
    borders.left:SetWidth(borderSize)
    borders.left:SetColorTexture(borderColor.r or 0.16, borderColor.g or 0.18, borderColor.b or 0.22, borderColor.a or 1)

    borders.right:ClearAllPoints()
    borders.right:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
    borders.right:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
    borders.right:SetWidth(borderSize)
    borders.right:SetColorTexture(borderColor.r or 0.16, borderColor.g or 0.18, borderColor.b or 0.22, borderColor.a or 1)
    borders.top:Show()
    borders.bottom:Show()
    borders.left:Show()
    borders.right:Show()

    self.editBox = CreateFrame("EditBox", (self.name or "TextInput") .. "EditBox", frame)
    self.editBox:SetAutoFocus(false)
    self.editBox:SetMultiLine(false)
    self.editBox:SetPoint("LEFT", frame, "LEFT", self.options.textInsetLeft or 6, 0)
    self.editBox:SetPoint("RIGHT", frame, "RIGHT", -(self.options.textInsetRight or 6), 0)
    self.editBox:SetPoint("CENTER", frame, "CENTER", 0, self.options.textOffsetY or 0)
    self.editBox:SetHeight(self.options.textHeight or math.max(12, (self.options.height or 24) - ((self.options.textInsetTop or 4) + (self.options.textInsetBottom or 4))))

    ApplyEditBoxFont(self.editBox, self.options)

    local textColor = UI.ResolveColor(self.options.textColor, "text.primary")
    if textColor and self.editBox.SetTextColor then
        self.editBox:SetTextColor(textColor.r or 1, textColor.g or 1, textColor.b or 1, textColor.a or 1)
    end

    if self.editBox.SetJustifyH then
        self.editBox:SetJustifyH(self.options.justifyH or "LEFT")
    end

    if self.editBox.SetJustifyV then
        self.editBox:SetJustifyV("MIDDLE")
    end

    if self.editBox.SetScript then
        self.editBox:SetScript("OnTextChanged", function()
            if not self._syncingText then
                self.text = NormalizeText(self.editBox:GetText())
                if self._skipNextFocusLostText ~= nil and self.text ~= self._skipNextFocusLostText then
                    self._skipNextFocusLost = false
                    self._skipNextFocusLostText = nil
                end
                self:InvokeScript("OnTextChanged")
            end
        end)
        self.editBox:SetScript("OnEnterPressed", function()
            self.text = NormalizeText(self.editBox:GetText())
            self._skipNextFocusLost = true
            self._skipNextFocusLostText = self.text
            self:InvokeScript("OnEnterPressed")
            self:ClearFocus()
        end)
        self.editBox:SetScript("OnEditFocusLost", function()
            self.text = NormalizeText(self.editBox:GetText())
            if self._skipNextFocusLost and self._skipNextFocusLostText == self.text then
                self._skipNextFocusLost = false
                self._skipNextFocusLostText = nil
                return
            end
            self._skipNextFocusLost = false
            self._skipNextFocusLostText = nil
            self:InvokeScript("OnEditFocusLost")
        end)
        self.editBox:SetScript("OnEscapePressed", function()
            self._syncingText = true
            self.editBox:SetText(self.text)
            self._syncingText = false
            self._skipNextFocusLost = true
            self._skipNextFocusLostText = self.text
            self:InvokeScript("OnEscapePressed")
            self:ClearFocus()
        end)
    end

    self:SetText(self.text)
    self:SetReadOnly(self:GetOption("readOnly", false))
    self:SetEnabled(self.enabled)

    return self.frame
end

return TextInput
