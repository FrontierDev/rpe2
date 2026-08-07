local _, Addon = ...

local UI = Addon.UI or {}
Addon.UI = UI
local Constants = UI.Constants or {}

UI.Font = UI.Font or {}
local Font = UI.Font

local function ResolveFontOptions(options, defaults)
    options = options or {}
    defaults = defaults or {}

    local fontFile = options.fontFile or defaults.fontFile or ((Constants.FontFiles and Constants.FontFiles.Default) or "Fonts\\FRIZQT__.TTF")
    local fontSize = options.fontSize or defaults.fontSize
    local fontFlags = options.fontFlags or defaults.fontFlags
    local fontObject = options.fontObject or defaults.fontObject

    return fontFile, fontSize, fontFlags, fontObject
end

function Font:Apply(region, options, defaults)
    if not region then
        return
    end

    local fontFile, fontSize, fontFlags, fontObject = ResolveFontOptions(options, defaults)

    if region.SetFont and (fontSize ~= nil or fontFlags ~= nil or (options and options.fontFile ~= nil) or (defaults and defaults.fontSize ~= nil) or (defaults and defaults.fontFlags ~= nil) or (defaults and defaults.fontFile ~= nil)) then
        region:SetFont(fontFile, fontSize, fontFlags)
        return
    end

    if region.SetFontObject and fontObject then
        region:SetFontObject(fontObject)
    end
end

return Font
