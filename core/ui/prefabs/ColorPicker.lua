local _, Addon = ...

local UI = Addon.UI or {}
Addon.UI = UI
local BaseElement = UI.BaseElement
local Database = Addon.Internal and Addon.Internal.Database or {}
local Constants = UI.Constants or {}

UI.ColorPicker = UI.ColorPicker or {}
local ColorPicker = UI.ColorPicker
ColorPicker.__index = ColorPicker
setmetatable(ColorPicker, { __index = BaseElement })

local DEFAULT_COLOR = {
    r = 1,
    g = 1,
    b = 1,
    a = 1,
}

local DEFAULT_PALETTE = {
    { r = 1.00, g = 1.00, b = 1.00, a = 1 },
    { r = 0.75, g = 0.75, b = 0.75, a = 1 },
    { r = 0.95, g = 0.35, b = 0.35, a = 1 },
    { r = 1.00, g = 0.58, b = 0.18, a = 1 },
    { r = 1.00, g = 0.90, b = 0.25, a = 1 },
    { r = 0.35, g = 0.90, b = 0.45, a = 1 },
    { r = 0.30, g = 0.88, b = 0.92, a = 1 },
    { r = 0.42, g = 0.66, b = 0.98, a = 1 },
    { r = 0.72, g = 0.48, b = 0.96, a = 1 },
    { r = 0.96, g = 0.48, b = 0.78, a = 1 },
}

local SWATCH_SIZE = 18
local PALETTE_COLUMNS = 5
local PALETTE_SPACING = 4

local function copyColor(color, fallback)
    local source = type(color) == "table" and color or fallback or DEFAULT_COLOR
    return {
        r = math.max(0, math.min(1, tonumber(source.r) or DEFAULT_COLOR.r)),
        g = math.max(0, math.min(1, tonumber(source.g) or DEFAULT_COLOR.g)),
        b = math.max(0, math.min(1, tonumber(source.b) or DEFAULT_COLOR.b)),
        a = math.max(0, math.min(1, tonumber(source.a) or DEFAULT_COLOR.a)),
    }
end

local function normalizePalette(palette)
    local normalized = {}
    for index = 1, #(type(palette) == "table" and palette or {}) do
        normalized[#normalized + 1] = copyColor(palette[index], DEFAULT_COLOR)
    end
    return normalized
end

local function formatHex(color)
    local resolved = copyColor(color, DEFAULT_COLOR)
    return ("#%02X%02X%02X"):format(
        math.floor((resolved.r * 255) + 0.5),
        math.floor((resolved.g * 255) + 0.5),
        math.floor((resolved.b * 255) + 0.5)
    )
end

local function parseHex(value)
    local text = tostring(value or ""):gsub("%s+", ""):gsub("^#", "")
    if #text ~= 6 then
        return nil
    end

    local red = tonumber(text:sub(1, 2), 16)
    local green = tonumber(text:sub(3, 4), 16)
    local blue = tonumber(text:sub(5, 6), 16)
    if not red or not green or not blue then
        return nil
    end

    return {
        r = red / 255,
        g = green / 255,
        b = blue / 255,
        a = 1,
    }
end

local function colorsMatch(left, right)
    local first = copyColor(left, DEFAULT_COLOR)
    local second = copyColor(right, DEFAULT_COLOR)
    return math.floor((first.r * 255) + 0.5) == math.floor((second.r * 255) + 0.5)
        and math.floor((first.g * 255) + 0.5) == math.floor((second.g * 255) + 0.5)
        and math.floor((first.b * 255) + 0.5) == math.floor((second.b * 255) + 0.5)
end

local function setPanelColor(panel, color)
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

local function getPaletteSettingKey(self)
    return tostring(self.paletteSettingKey or self.options.paletteSettingKey or "resourceColorPalette")
end

local function getStoredPalette(self)
    local palette = Database.GetGlobalSetting and Database.GetGlobalSetting(getPaletteSettingKey(self), nil) or nil
    if palette == nil then
        return normalizePalette(DEFAULT_PALETTE)
    end
    return normalizePalette(palette)
end

local function storePalette(self, palette)
    local normalized = normalizePalette(palette)
    if Database.SetGlobalSetting then
        Database.SetGlobalSetting(getPaletteSettingKey(self), normalized)
    end
    return normalized
end

local function createLabel(parent, name, text, width)
    return UI.CreateText(parent, name, text, {
        width = width or 18,
        height = 18,
        fontFile = (Constants.FontFiles and Constants.FontFiles.Default) or "Fonts\\FRIZQT__.TTF",
        fontSize = (Constants.FontSizes and Constants.FontSizes.Body) or 8,
        textColor = UI.ResolveColor(nil, "text.secondary"),
        justifyH = "LEFT",
        justifyV = "MIDDLE",
        wordWrap = false,
    })
end

function ColorPicker.CopyColor(color, fallback)
    return copyColor(color, fallback)
end

function ColorPicker.NormalizeColor(color, fallback)
    return copyColor(color, fallback)
end

function ColorPicker.FormatHex(color)
    return formatHex(color)
end

function ColorPicker.ParseHex(value)
    return parseHex(value)
end

function ColorPicker:New(options)
    local instance = BaseElement.New(self, options)
    instance.options.border = false
    instance.window = nil
    instance.rootLayout = nil
    instance.previewPanel = nil
    instance.hexInput = nil
    instance.redSlider = nil
    instance.greenSlider = nil
    instance.blueSlider = nil
    instance.paletteRows = {}
    instance.paletteSwatches = {}
    instance.paletteGrid = nil
    instance.baseWindowHeight = options and options.height or 228
    instance.currentColor = copyColor(options and options.color, DEFAULT_COLOR)
    instance.paletteSettingKey = options and options.paletteSettingKey or "resourceColorPalette"
    instance.palette = getStoredPalette(instance)
    instance.onApply = nil
    instance.onCancel = nil
    instance._syncing = false
    return instance
end

function ColorPicker:SetApplyHandler(handler)
    self.onApply = type(handler) == "function" and handler or nil
end

function ColorPicker:SetCancelHandler(handler)
    self.onCancel = type(handler) == "function" and handler or nil
end

function ColorPicker:GetColor()
    return copyColor(self.currentColor, DEFAULT_COLOR)
end

function ColorPicker:SetColor(color)
    self.currentColor = copyColor(color, DEFAULT_COLOR)
    self:RefreshControls()
    return self.currentColor
end

function ColorPicker:LoadPalette()
    self.palette = getStoredPalette(self)
    self:RefreshPalette()
    return self.palette
end

function ColorPicker:SetPalette(palette, persist)
    self.palette = normalizePalette(palette)

    if persist == true then
        self.palette = storePalette(self, self.palette)
    end

    self:RefreshPalette()
    return self.palette
end

function ColorPicker:UpdateWindowHeight()
    if not self.frame or not self.frame.SetHeight then
        return
    end

    local paletteCount = #(self.palette or {})
    local visibleRows = math.max(2, math.ceil(paletteCount / PALETTE_COLUMNS))
    local extraRows = math.max(0, visibleRows - 2)
    local extraHeight = extraRows * (SWATCH_SIZE + PALETTE_SPACING)
    self.frame:SetHeight((self.baseWindowHeight or 228) + extraHeight)
end

function ColorPicker:CreatePaletteSwatch(index)
    local swatch = UI.CreatePanel(self.paletteGrid:GetFrame(), (self.name or "RPEColorPicker") .. "PaletteSwatch" .. index, {
        width = SWATCH_SIZE,
        height = SWATCH_SIZE,
        contentInset = 0,
        border = false,
        enableMouse = true,
        showBorder = true,
        panelBorderSize = 1,
        panelBorderColor = UI.ResolveColor(nil, "panel.border"),
        panelBackgroundColor = self.palette[index] or { r = 0, g = 0, b = 0, a = 0.15 },
    })
    local swatchFrame = swatch.GetFrame and swatch:GetFrame() or nil
    if swatchFrame and swatchFrame.SetScript then
        swatchFrame:SetScript("OnMouseUp", function(_, button)
            local swatchColor = self.palette[index]
            if not swatchColor then
                return
            end

            if button == "RightButton" then
                self:RemoveColorFromPalette(swatchColor)
                return
            end

            if button == "LeftButton" then
                self:SetColor(swatchColor)
            end
        end)
    end

    return swatch
end

function ColorPicker:SyncPaletteSwatches()
    if not self.paletteGrid then
        return
    end

    local paletteCount = #(self.palette or {})

    while #self.paletteSwatches > paletteCount do
        local swatch = table.remove(self.paletteSwatches)
        if swatch and self.paletteGrid.RemoveChild then
            self.paletteGrid:RemoveChild(swatch)
        end
        local frame = swatch and swatch.GetFrame and swatch:GetFrame() or nil
        if frame and frame.Hide then
            frame:Hide()
        end
    end

    while #self.paletteSwatches < paletteCount do
        local swatchIndex = #self.paletteSwatches + 1
        local swatch = self:CreatePaletteSwatch(swatchIndex)
        self.paletteSwatches[swatchIndex] = swatch
        self.paletteGrid:AddChild(swatch)
    end

    if paletteCount == 0 then
        local gridFrame = self.paletteGrid.GetFrame and self.paletteGrid:GetFrame() or nil
        if gridFrame and gridFrame.SetSize then
            gridFrame:SetSize(0, 0)
        end
    elseif self.paletteGrid.RefreshLayout then
        self.paletteGrid:RefreshLayout()
    end
end

function ColorPicker:RefreshPalette()
    self:SyncPaletteSwatches()

    for index = 1, #(self.paletteSwatches or {}) do
        local swatch = self.paletteSwatches[index]
        local color = self.palette[index]
        if swatch then
            local frame = swatch.GetFrame and swatch:GetFrame() or nil
            setPanelColor(swatch, color or { r = 0, g = 0, b = 0, a = 0.15 })
            if frame and frame.EnableMouse then
                frame:EnableMouse(color ~= nil)
            end
            if frame and frame.SetAlpha then
                frame:SetAlpha(color and 1 or 0.35)
            end
            if swatch.SetOption then
                swatch:SetOption("panelBorderColor", UI.ResolveColor(nil, colorsMatch(color, self.currentColor) and "warning" or "panel.border"))
            end
            if swatch.ApplyPanelBorders then
                swatch:ApplyPanelBorders()
            end
        end
    end

    self:UpdateWindowHeight()
    if self.rootLayout and self.rootLayout.RefreshLayout then
        self.rootLayout:RefreshLayout()
    end
end

function ColorPicker:RefreshControls()
    self._syncing = true

    if self.redSlider and self.redSlider.SetValue then
        self.redSlider:SetValue(math.floor((self.currentColor.r or 0) * 255 + 0.5), true)
    end
    if self.greenSlider and self.greenSlider.SetValue then
        self.greenSlider:SetValue(math.floor((self.currentColor.g or 0) * 255 + 0.5), true)
    end
    if self.blueSlider and self.blueSlider.SetValue then
        self.blueSlider:SetValue(math.floor((self.currentColor.b or 0) * 255 + 0.5), true)
    end
    if self.hexInput and self.hexInput.SetText then
        self.hexInput:SetText(formatHex(self.currentColor))
    end

    setPanelColor(self.previewPanel, self.currentColor)
    self:RefreshPalette()

    self._syncing = false
end

function ColorPicker:TryApplyHexInput(resetOnFailure)
    local color = parseHex(self.hexInput and self.hexInput.GetText and self.hexInput:GetText() or "")
    if color then
        self.currentColor = color
        self:RefreshControls()
        return true
    end

    if resetOnFailure and self.hexInput and self.hexInput.SetText then
        self.hexInput:SetText(formatHex(self.currentColor))
    end

    return false
end

function ColorPicker:UpdateChannel(channel, value)
    if self._syncing then
        return
    end

    local normalized = math.max(0, math.min(255, math.floor(tonumber(value) or 0))) / 255
    self.currentColor = copyColor(self.currentColor, DEFAULT_COLOR)
    self.currentColor[channel] = normalized
    self:RefreshControls()
end

function ColorPicker:SaveCurrentColorToPalette()
    self:TryApplyHexInput(true)

    local palette = {}
    for index = 1, #(self.palette or {}) do
        local color = self.palette[index]
        if not colorsMatch(color, self.currentColor) then
            palette[#palette + 1] = copyColor(color, DEFAULT_COLOR)
        end
    end

    palette[#palette + 1] = copyColor(self.currentColor, DEFAULT_COLOR)

    self.palette = storePalette(self, palette)
    self:RefreshPalette()
    return self.palette
end

function ColorPicker:RemoveColorFromPalette(color)
    local targetColor = copyColor(color, DEFAULT_COLOR)
    local palette = {}

    for index = 1, #(self.palette or {}) do
        local existingColor = self.palette[index]
        if not colorsMatch(existingColor, targetColor) then
            palette[#palette + 1] = copyColor(existingColor, DEFAULT_COLOR)
        end
    end

    self.palette = storePalette(self, palette)
    self:RefreshPalette()
    return self.palette
end

function ColorPicker:RemoveCurrentColorFromPalette()
    self:TryApplyHexInput(true)
    return self:RemoveColorFromPalette(self.currentColor)
end

function ColorPicker:Open(options)
    if not self.frame then
        self:Create()
    end

    options = options or {}
    if options.paletteSettingKey then
        self.paletteSettingKey = tostring(options.paletteSettingKey)
    end
    if options.onApply ~= nil then
        self:SetApplyHandler(options.onApply)
    end
    if options.onCancel ~= nil then
        self:SetCancelHandler(options.onCancel)
    end

    self:LoadPalette()
    self:SetColor(options.color or self.currentColor or DEFAULT_COLOR)
    self:Show()

    if self.frame and self.frame.Raise then
        self.frame:Raise()
    end
end

function ColorPicker:Create()
    if self.frame then
        return self.frame
    end

    local parentFrame = self:GetParentFrame()
    if not parentFrame then
        error("A color picker prefab requires a parent frame before Create().", 2)
    end

    self.window = UI.Window:New({
        name = self.name or "RPEColorPicker",
        width = self.options.width or 280,
        height = self.baseWindowHeight,
        point = self.options.point or "CENTER",
        relativeTo = self.options.relativeTo,
        relativePoint = self.options.relativePoint,
        x = self.options.x or 0,
        y = self.options.y or 0,
        movable = self.options.movable ~= false,
        clampedToScreen = true,
        toplevel = true,
        hidden = self.options.hidden ~= false,
        contentInsetLeft = self.options.contentInsetLeft or ((Constants.Window and Constants.Window.ContentInsetLeft) or 8),
        contentInsetRight = self.options.contentInsetRight or ((Constants.Window and Constants.Window.ContentInsetRight) or 8),
        contentInsetTop = self.options.contentInsetTop or ((Constants.Window and Constants.Window.ContentInsetTop) or 20),
        contentInsetBottom = self.options.contentInsetBottom or ((Constants.Window and Constants.Window.ContentInsetBottom) or 8),
        onClose = function()
            if self.onCancel then
                self.onCancel()
            end
        end,
    })
    self.window:SetParent(parentFrame)
    self.window:Create()
    self.window:SetTitle(self.options.title or "Color Picker")
    self.frame = self.window:GetFrame()

    local content = self.window:GetContentFrame()
    self.rootLayout = UI.CreateLayout(UI.VerticalLayoutGroup, content, (self.name or "RPEColorPicker") .. "RootLayout", {
        spacing = 6,
        fitChildrenWidth = true,
        fitChildrenHeight = false,
    })
    UI.Utils.AnchorFill(self.rootLayout, content, 0, 0, 0, 0)

    local previewRow = UI.CreateLayout(UI.HorizontalLayoutGroup, self.rootLayout:GetFrame(), (self.name or "RPEColorPicker") .. "PreviewRow", {
        spacing = 6,
        autoSize = true,
        fitChildrenWidth = false,
        fitChildrenHeight = false,
    })
    self.rootLayout:AddChild(previewRow)

    previewRow:AddChild(createLabel(previewRow:GetFrame(), (self.name or "RPEColorPicker") .. "HexLabel", "Hex", 24))
    self.hexInput = UI.CreateTextInput(previewRow:GetFrame(), (self.name or "RPEColorPicker") .. "HexInput", {
        width = 104,
        height = 20,
        text = formatHex(self.currentColor),
        borderColor = UI.ResolveColor(nil, "panel.border"),
    })
    self.hexInput:SetScript("OnTextChanged", function()
        if self._syncing then
            return
        end

        local parsed = parseHex(self.hexInput:GetText())
        if parsed then
            self.currentColor = parsed
            self:RefreshControls()
        end
    end)
    self.hexInput:SetScript("OnEnterPressed", function()
        self:TryApplyHexInput(true)
    end)
    self.hexInput:SetScript("OnEditFocusLost", function()
        self:TryApplyHexInput(true)
    end)
    previewRow:AddChild(self.hexInput)

    self.previewPanel = UI.CreatePanel(previewRow:GetFrame(), (self.name or "RPEColorPicker") .. "PreviewPanel", {
        width = 20,
        height = 20,
        contentInset = 0,
        border = false,
        showBorder = true,
        panelBorderSize = 1,
        panelBorderColor = UI.ResolveColor(nil, "panel.border"),
        panelBackgroundColor = self.currentColor,
    })
    previewRow:AddChild(self.previewPanel)

    local function addChannelRow(labelText, suffix, channelKey)
        local row = UI.CreateLayout(UI.HorizontalLayoutGroup, self.rootLayout:GetFrame(), (self.name or "RPEColorPicker") .. suffix .. "Row", {
            spacing = 6,
            autoSize = true,
            fitChildrenWidth = false,
            fitChildrenHeight = false,
        })
        self.rootLayout:AddChild(row)
        row:AddChild(createLabel(row:GetFrame(), (self.name or "RPEColorPicker") .. suffix .. "Label", labelText, 12))

        local slider = UI.SliderBar:New({
            name = (self.name or "RPEColorPicker") .. suffix .. "Slider",
            width = 220,
            height = 18,
            minValue = 0,
            maxValue = 255,
            step = 1,
            value = math.floor(((self.currentColor[channelKey] or 0) * 255) + 0.5),
            valueTextWidth = 28,
            labelSpacing = 4,
            onValueChanged = function(value)
                self:UpdateChannel(channelKey, value)
            end,
        })
        slider:SetParent(row:GetFrame())
        slider:Create()
        row:AddChild(slider)
        return slider
    end

    self.redSlider = addChannelRow("R", "Red", "r")
    self.greenSlider = addChannelRow("G", "Green", "g")
    self.blueSlider = addChannelRow("B", "Blue", "b")

    local paletteLabel = UI.CreateText(self.rootLayout:GetFrame(), (self.name or "RPEColorPicker") .. "PaletteLabel", "Palette", {
        width = 236,
        height = 12,
        fontFile = (Constants.FontFiles and Constants.FontFiles.Default) or "Fonts\\FRIZQT__.TTF",
        fontSize = (Constants.FontSizes and Constants.FontSizes.Body) or 8,
        textColor = UI.ResolveColor(nil, "text.secondary"),
        justifyH = "LEFT",
    })
    self.rootLayout:AddChild(paletteLabel)

    self.paletteGrid = UI.CreateLayout(UI.GridLayoutGroup, self.rootLayout:GetFrame(), (self.name or "RPEColorPicker") .. "PaletteGrid", {
        columns = PALETTE_COLUMNS,
        spacing = PALETTE_SPACING,
        cellWidth = SWATCH_SIZE,
        cellHeight = SWATCH_SIZE,
        autoSize = true,
        fitChildrenWidth = false,
        fitChildrenHeight = false,
    })
    self.rootLayout:AddChild(self.paletteGrid)

    local actionRow = UI.CreateLayout(UI.HorizontalLayoutGroup, self.rootLayout:GetFrame(), (self.name or "RPEColorPicker") .. "ActionRow", {
        spacing = 6,
        autoSize = true,
        fitChildrenWidth = false,
        fitChildrenHeight = false,
    })
    self.rootLayout:AddChild(actionRow)

    self.savePaletteButton = UI.CreateButton(actionRow:GetFrame(), (self.name or "RPEColorPicker") .. "SavePaletteButton", "Save Palette", 86, function()
        self:SaveCurrentColorToPalette()
    end, {
        height = 20,
        fontSize = 8,
    })
    actionRow:AddChild(self.savePaletteButton)

    self.removePaletteButton = UI.CreateButton(actionRow:GetFrame(), (self.name or "RPEColorPicker") .. "RemovePaletteButton", "Remove", 62, function()
        self:RemoveCurrentColorFromPalette()
    end, {
        height = 20,
        fontSize = 8,
    })
    actionRow:AddChild(self.removePaletteButton)

    self.cancelButton = UI.CreateButton(actionRow:GetFrame(), (self.name or "RPEColorPicker") .. "CancelButton", "Cancel", 62, function()
        self:Hide()
        if self.onCancel then
            self.onCancel()
        end
    end, {
        height = 20,
        fontSize = 8,
    })
    actionRow:AddChild(self.cancelButton)

    self.applyButton = UI.CreateButton(actionRow:GetFrame(), (self.name or "RPEColorPicker") .. "ApplyButton", "Apply", 62, function()
        self:TryApplyHexInput(true)
        local color = copyColor(self.currentColor, DEFAULT_COLOR)
        self:Hide()
        if self.onApply then
            self.onApply(color)
        end
    end, {
        height = 20,
        fontSize = 8,
    })
    actionRow:AddChild(self.applyButton)

    self:RefreshControls()
    self:UpdateWindowHeight()
    return self.frame
end

return ColorPicker
