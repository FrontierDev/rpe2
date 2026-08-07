local _, Addon = ...

local UI = Addon.UI or {}
Addon.UI = UI
local BaseElement = UI.BaseElement
local Debug = Addon.Debug or {}
local Constants = UI.Constants or {}

UI.ClipboardTextArea = UI.ClipboardTextArea or {}
local ClipboardTextArea = UI.ClipboardTextArea
ClipboardTextArea.__index = ClipboardTextArea
setmetatable(ClipboardTextArea, { __index = BaseElement })

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

function ClipboardTextArea:New(options)
    local instance = BaseElement.New(self, options)
    instance.text = NormalizeText(options and options.text)
    instance.scrollFrame = nil
    instance.editBox = nil
    instance.backgroundTexture = nil
    instance.fieldBorderTextures = nil
    instance.scripts = {}
    instance._syncingText = false
    instance.enabled = options == nil or options.enabled ~= false
    return instance
end

function ClipboardTextArea:GetEditBox()
    return self.editBox
end

function ClipboardTextArea:SetText(text)
    self.text = NormalizeText(text)

    if self.editBox and self.editBox.SetText then
        self._syncingText = true
        self.editBox:SetText(self.text)
        self._syncingText = false
        self:RefreshGeometry()
        self:ScrollTo(0)
    end

    return self.text
end

function ClipboardTextArea:GetText()
    if self.editBox and self.editBox.GetText then
        self.text = NormalizeText(self.editBox:GetText())
    end

    return self.text
end

function ClipboardTextArea:SetTextColor(r, g, b, a)
    self:SetOption("textColor", { r = r, g = g, b = b, a = a })

    if self.editBox and self.editBox.SetTextColor then
        self.editBox:SetTextColor(r, g, b, a)
    end
end

function ClipboardTextArea:SetScript(scriptName, handler)
    self.scripts = self.scripts or {}
    self.scripts[scriptName] = type(handler) == "function" and handler or nil
end

function ClipboardTextArea:InvokeScript(scriptName)
    local handler = self.scripts and self.scripts[scriptName] or nil
    if handler then
        return handler(self, self:GetText())
    end

    return nil
end

function ClipboardTextArea:SetReadOnly(readOnly)
    self:SetOption("readOnly", readOnly ~= false)

    if self.editBox and self.editBox.EnableMouse then
        local interactive = self.enabled ~= false
        self.editBox:EnableMouse(interactive)
        if not interactive and self.editBox.ClearFocus then
            self.editBox:ClearFocus()
        end
    end

    return self:GetOption("readOnly", true)
end

function ClipboardTextArea:SetEnabled(enabled)
    self.enabled = enabled ~= false

    if self.editBox and self.editBox.EnableMouse then
        local interactive = self.enabled
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

function ClipboardTextArea:Focus()
    if self.editBox and self.editBox.SetFocus then
        self.editBox:SetFocus()
    end
end

function ClipboardTextArea:ClearFocus()
    if self.editBox and self.editBox.ClearFocus then
        self.editBox:ClearFocus()
    end
end

function ClipboardTextArea:HighlightText(startPosition, endPosition)
    if not (self.editBox and self.editBox.HighlightText) then
        return
    end

    if startPosition == nil and endPosition == nil then
        self.editBox:HighlightText()
    else
        self.editBox:HighlightText(startPosition or 0, endPosition or -1)
    end
end

function ClipboardTextArea:ScrollTo(offset)
    if not (self.scrollFrame and self.scrollFrame.SetVerticalScroll) then
        return
    end

    local maxOffset = 0
    if self.editBox and self.scrollFrame.GetHeight and self.editBox.GetHeight then
        maxOffset = math.max(0, (self.editBox:GetHeight() or 0) - (self.scrollFrame:GetHeight() or 0))
    end

    local clamped = math.max(0, math.min(maxOffset, offset or 0))
    self.scrollFrame:SetVerticalScroll(clamped)
end

function ClipboardTextArea:RefreshGeometry()
    if not (self.scrollFrame and self.editBox) then
        return
    end

    local width = 1
    if self.scrollFrame.GetWidth then
        width = math.max(1, (self.scrollFrame:GetWidth() or 0) - ((self.options.textInsetLeft or 4) + (self.options.textInsetRight or 4)))
    end

    if self.editBox.SetWidth then
        self.editBox:SetWidth(width)
    end

    if self.editBox.GetStringHeight and self.editBox.SetHeight and self.scrollFrame.GetHeight then
        local minimumHeight = math.max(1, (self.scrollFrame:GetHeight() or 0) - ((self.options.textInsetTop or 4) + (self.options.textInsetBottom or 4)))
        self.editBox:SetHeight(math.max(minimumHeight, self.editBox:GetStringHeight() or 0))
    end
end

function ClipboardTextArea:EnsureCursorVisible(y, height)
    if not (self.scrollFrame and self.scrollFrame.GetVerticalScroll and self.scrollFrame.GetHeight) then
        return
    end

    local current = self.scrollFrame:GetVerticalScroll() or 0
    local viewportHeight = self.scrollFrame:GetHeight() or 0
    local cursorTop = y or 0
    local cursorBottom = cursorTop + (height or 0)

    if cursorTop < current then
        self:ScrollTo(cursorTop)
    elseif cursorBottom > current + viewportHeight then
        self:ScrollTo(cursorBottom - viewportHeight)
    end
end

function ClipboardTextArea:HandleTextChanged()
    if not self.editBox then
        return
    end

    local current = self.editBox:GetText() or ""
    local readOnly = self:GetOption("readOnly", true)

    if readOnly and not self._syncingText and current ~= self.text then
        local cursorPosition = self.editBox.GetCursorPosition and self.editBox:GetCursorPosition() or 0

        self._syncingText = true
        self.editBox:SetText(self.text or "")
        self._syncingText = false

        if self.editBox.SetCursorPosition then
            self.editBox:SetCursorPosition(math.min(cursorPosition or 0, #(self.text or "")))
        end
    elseif not readOnly and not self._syncingText then
        self.text = current
    end

    self:RefreshGeometry()
end

function ClipboardTextArea:Create()
    if self.frame then
        return self.frame
    end

    local parentFrame = self:GetParentFrame()
    if not parentFrame then
        if Debug.Internal then
            Debug.Internal("Addon.UI.ClipboardTextArea requires a parent frame before Create().")
        end

        error("A clipboard text area requires a parent frame before Create().", 2)
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

    self.scrollFrame = CreateFrame("ScrollFrame", (self.name or "ClipboardTextArea") .. "ScrollFrame", frame)
    self.scrollFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", 1, -1)
    self.scrollFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -1, 1)
    self.scrollFrame:EnableMouseWheel(true)

    self.editBox = CreateFrame("EditBox", (self.name or "ClipboardTextArea") .. "EditBox", self.scrollFrame)
    local rawSetText = self.editBox.SetText
    self.editBox:SetMultiLine(true)
    self.editBox:SetAutoFocus(false)
    self.editBox:EnableMouse(true)
    self.editBox:SetPoint("TOPLEFT", self.scrollFrame, "TOPLEFT", self.options.textInsetLeft or 4, -(self.options.textInsetTop or 4))

    if rawSetText then
        self.editBox.SetText = function(editBox, text)
            if self._syncingText then
                return rawSetText(editBox, text)
            end

            if self:GetOption("readOnly", true) then
                self._syncingText = true
                local result = rawSetText(editBox, self.text or "")
                self._syncingText = false
                self:RefreshGeometry()
                return result
            end

            local result = rawSetText(editBox, text)
            self.text = NormalizeText(text)
            self:RefreshGeometry()
            return result
        end
    end

    ApplyEditBoxFont(self.editBox, self.options)

    local textColor = UI.ResolveColor(self.options.textColor, "text.primary")
    if textColor and self.editBox.SetTextColor then
        self.editBox:SetTextColor(textColor.r or 1, textColor.g or 1, textColor.b or 1, textColor.a or 1)
    end

    if self.editBox.SetJustifyH then
        self.editBox:SetJustifyH(self.options.justifyH or "LEFT")
    end

    if self.editBox.SetJustifyV then
        self.editBox:SetJustifyV(self.options.justifyV or "TOP")
    end

    if self.editBox.SetTextInsets then
        self.editBox:SetTextInsets(0, 0, 0, self.options.textInsetBottom or 4)
    end

    if self.editBox.SetScript then
        self.editBox:SetScript("OnTextChanged", function()
            self:HandleTextChanged()
            self:InvokeScript("OnTextChanged")
        end)
        self.editBox:SetScript("OnCursorChanged", function(_, _, y, _, height)
            self:EnsureCursorVisible(y, height)
        end)
        self.editBox:SetScript("OnEscapePressed", function()
            self:InvokeScript("OnEscapePressed")
            self:ClearFocus()
        end)
        self.editBox:SetScript("OnEditFocusGained", function()
            self:InvokeScript("OnEditFocusGained")
            if self:GetOption("autoHighlightOnFocus", false) then
                self:HighlightText()
            end
        end)
        self.editBox:SetScript("OnEditFocusLost", function()
            self:InvokeScript("OnEditFocusLost")
        end)
        self.editBox:SetScript("OnMouseDown", function()
            if self.enabled and self.editBox.SetFocus then
                self.editBox:SetFocus()
            end
        end)
    end

    self.scrollFrame:SetScript("OnMouseWheel", function(_, delta)
        local step = self.options.scrollStep or 24
        self:ScrollTo((self.scrollFrame:GetVerticalScroll() or 0) - ((delta or 0) * step))
    end)
    self.scrollFrame:SetScript("OnSizeChanged", function()
        self:RefreshGeometry()
    end)
    self.scrollFrame:SetScrollChild(self.editBox)

    self:SetText(self.text)
    self:SetReadOnly(self:GetOption("readOnly", true))
    self:SetEnabled(self.enabled)
    self:RefreshGeometry()

    return self.frame
end

return ClipboardTextArea
