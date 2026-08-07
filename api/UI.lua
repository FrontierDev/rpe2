local _, Addon = ...

local UI = Addon.UI or {}
Addon.UI = UI

function UI.CreateText(parent, name, text, options)
    local element = UI.Text:New(options or {})
    element:SetName(name)
    element:SetParent(parent)
    element:SetText(text or "")
    element:Create()
    return element
end

function UI.CreatePanel(parent, name, options)
    local panel = UI.Panel:New(options or {})
    panel:SetName(name)
    panel:SetParent(parent)
    panel:Create()
    return panel
end

function UI.CreateScrollingMessageFrame(parent, name, options)
    local element = UI.ScrollingMessageFrame:New(options or {})
    element:SetName(name)
    element:SetParent(parent)
    element:Create()
    return element
end

function UI.CreateLayout(layoutClass, parent, name, options)
    local layout = layoutClass:New(options or {})
    layout:SetName(name)
    layout:SetParent(parent)
    layout:Create()
    return layout
end

function UI.CreateButton(parent, name, text, width, onClick, options)
    local settings = {}
    for key, value in pairs(options or {}) do
        settings[key] = value
    end

    settings.name = name
    settings.width = width
    settings.height = settings.height or 24
    settings.text = text
    settings.fontFile = settings.fontFile or ((UI.Constants and UI.Constants.FontFiles and UI.Constants.FontFiles.Default) or "Fonts\\FRIZQT__.TTF")
    settings.fontSize = settings.fontSize or ((UI.Constants and UI.Constants.FontSizes and UI.Constants.FontSizes.ButtonLabel) or 12)
    settings.labelColor = settings.labelColor or UI.ResolveColor(nil, "text.primary")
    if settings.enableMouse == nil then
        settings.enableMouse = true
    end

    local button = UI.TextButton:New(settings)
    button:SetParent(parent)
    button:SetScript("OnClick", onClick)
    button:Create()
    return button
end

function UI.CreateTextInput(parent, name, options)
    local input = UI.TextInput:New(options or {})
    input:SetName(name)
    input:SetParent(parent)
    input:Create()
    return input
end

function UI.CreateDropdown(parent, name, options)
    local dropdown = UI.Dropdown:New(options or {})
    dropdown:SetName(name)
    dropdown:SetParent(parent)
    dropdown:Create()
    return dropdown
end

function UI.CreateTextArea(parent, name, options)
    local textArea = UI.ClipboardTextArea:New(options or {})
    textArea:SetName(name)
    textArea:SetParent(parent)
    textArea:Create()
    return textArea
end
