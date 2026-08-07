local _, Addon = ...

local Debug = Addon.Debug or {}
Addon.Debug = Debug

local UI = Addon.UI or {}
local Constants = UI.Constants or {}

Debug.Clipboard = Debug.Clipboard or {}
local Clipboard = Debug.Clipboard

local function NormalizeText(text)
    if text == nil then
        return ""
    end

    return tostring(text)
end

function Clipboard:BuildWindow()
    if self.window then
        return self.window
    end

    local window = UI.Window:New({
        name = "RPEngineDebugClipboardWindow",
        width = 520,
        height = 360,
        point = "CENTER",
        relativeTo = UIParent,
        relativePoint = "CENTER",
        frameStrata = "HIGH",
        frameLevel = 25,
        movable = true,
        clampedToScreen = true,
        toplevel = true,
        hidden = true,
        titleFontFile = (Constants.FontFiles and Constants.FontFiles.Default) or "Fonts\\FRIZQT__.TTF",
        titleFontSize = (Constants.FontSizes and Constants.FontSizes.Heading1) or 12,
        contentInsetLeft = 12,
        contentInsetRight = 12,
        contentInsetTop = 28,
        contentInsetBottom = 12,
        borderSize = (Constants.Window and Constants.Window.BorderSize) or 2,
        onClose = function()
            if self.textArea and self.textArea.ClearFocus then
                self.textArea:ClearFocus()
            end
        end,
    })
    window:SetTitle("Clipboard")
    window:Create()

    self.window = window

    self.rootPanel = UI.Panel:New({
        name = "RPEngineDebugClipboardRootPanel",
        border = false,
        contentInset = 0,
        panelBackgroundColor = UI.ResolveColor(nil, "panel.background"),
    })
    self.rootPanel:SetParent(window:GetContentFrame())
    self.rootPanel:Create()
    self.rootPanel:SetPoint("TOPLEFT", window:GetContentFrame(), "TOPLEFT", 0, 0)
    self.rootPanel:SetPoint("TOPRIGHT", window:GetContentFrame(), "TOPRIGHT", 0, 0)
    self.rootPanel:SetPoint("BOTTOMLEFT", window:GetContentFrame(), "BOTTOMLEFT", 0, 0)
    self.rootPanel:SetPoint("BOTTOMRIGHT", window:GetContentFrame(), "BOTTOMRIGHT", 0, 0)

    self.instructionText = UI.Text:New({
        name = "RPEngineDebugClipboardInstructionText",
        width = 420,
        height = 14,
        text = "Select the text below and copy it with Ctrl-C.",
        fontFile = (Constants.FontFiles and Constants.FontFiles.Default) or "Fonts\\FRIZQT__.TTF",
        fontSize = (Constants.FontSizes and Constants.FontSizes.Body) or 8,
        textColor = UI.ResolveColor(nil, "text.secondary"),
        justifyH = "LEFT",
        justifyV = "TOP",
        wordWrap = false,
        border = false,
    })
    self.instructionText:SetParent(self.rootPanel:GetContentFrame())
    self.instructionText:Create()
    self.instructionText:SetPoint("TOPLEFT", self.rootPanel:GetContentFrame(), "TOPLEFT", 0, 0)

    self.selectAllButton = UI.TextButton:New({
        name = "RPEngineDebugClipboardSelectAllButton",
        width = 72,
        height = 18,
        text = "Select All",
        border = false,
        fontFile = (Constants.FontFiles and Constants.FontFiles.Default) or "Fonts\\FRIZQT__.TTF",
        fontSize = (Constants.FontSizes and Constants.FontSizes.ButtonLabel) or 8,
        enableMouse = true,
    })
    self.selectAllButton:SetParent(self.rootPanel:GetContentFrame())
    self.selectAllButton:Create()
    self.selectAllButton:SetPoint("TOPRIGHT", self.rootPanel:GetContentFrame(), "TOPRIGHT", 0, 0)
    self.selectAllButton:SetScript("OnClick", function()
        if self.textArea then
            self.textArea:Focus()
            self.textArea:HighlightText()
        end
    end)

    self.textArea = UI.ClipboardTextArea:New({
        name = "RPEngineDebugClipboardTextArea",
        border = true,
        readOnly = true,
        autoHighlightOnFocus = false,
        fontFile = (Constants.FontFiles and Constants.FontFiles.Default) or "Fonts\\FRIZQT__.TTF",
        fontSize = (Constants.FontSizes and Constants.FontSizes.Body) or 8,
        textColor = UI.ResolveColor(nil, "text.primary"),
        backgroundColor = UI.ResolveColor(nil, "window.background"),
    })
    self.textArea:SetParent(self.rootPanel:GetContentFrame())
    self.textArea:Create()
    self.textArea:SetPoint("TOPLEFT", self.instructionText:GetFrame(), "BOTTOMLEFT", 0, -8)
    self.textArea:SetPoint("TOPRIGHT", self.rootPanel:GetContentFrame(), "TOPRIGHT", 0, -26)
    self.textArea:SetPoint("BOTTOMLEFT", self.rootPanel:GetContentFrame(), "BOTTOMLEFT", 0, 0)
    self.textArea:SetPoint("BOTTOMRIGHT", self.rootPanel:GetContentFrame(), "BOTTOMRIGHT", 0, 0)

    self:SetText(self.text or "")
    return self.window
end

function Clipboard:SetText(text)
    self.text = NormalizeText(text)

    if self.textArea and self.textArea.SetText then
        self.textArea:SetText(self.text)
    end

    return self.text
end

function Clipboard:GetText()
    return self.text or ""
end

function Clipboard:Show(text)
    if text ~= nil then
        self:SetText(text)
    end

    local window = self:BuildWindow()
    window:Show()

    if self.textArea then
        self.textArea:Focus()
        self.textArea:HighlightText()
    end

    return window
end

function Clipboard:Hide()
    if self.textArea and self.textArea.ClearFocus then
        self.textArea:ClearFocus()
    end

    if self.window and self.window.Hide then
        self.window:Hide()
    end

    return self.window
end

function Clipboard:Toggle(text)
    if text ~= nil then
        self:SetText(text)
    end

    local frame = self.window and self.window.GetFrame and self.window:GetFrame() or nil
    if frame and frame.IsShown and frame:IsShown() then
        self:Hide()
        return self.window
    end

    return self:Show()
end

Clipboard.text = Clipboard.text or ""

return Clipboard
