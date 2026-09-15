local _, Addon = ...

local UI = Addon.UI or {}
Addon.UI = UI

UI.Inline = UI.Inline or {}
local Inline = UI.Inline

Inline.DefaultWidth = Inline.DefaultWidth or 12
Inline.DefaultHeight = Inline.DefaultHeight or 12
Inline.Icons = Inline.Icons or {}

local ADDON_TEXTURE_ROOT = "Interface\\AddOns\\RPEngine2\\data\\textures\\ui\\"

local function normalizeSize(value, fallback)
    local number = tonumber(value)
    if number and number > 0 then
        return number
    end

    return fallback
end

local function normalizeIconSpec(spec)
    if type(spec) == "string" then
        return {
            texture = spec,
        }
    end

    return type(spec) == "table" and spec or {}
end

local function buildTextureMarkup(texture, width, height, left, right, top, bottom)
    if type(texture) ~= "string" or texture == "" then
        return ""
    end

    width = normalizeSize(width, Inline.DefaultWidth)
    height = normalizeSize(height, Inline.DefaultHeight)

    if CreateTextureMarkup then
        return CreateTextureMarkup(texture, width, height, width, height, left, right, top, bottom)
    end

    if left ~= nil or right ~= nil or top ~= nil or bottom ~= nil then
        return ("|T%s:%d:%d:0:0:64:64:%d:%d:%d:%d|t"):format(
            texture,
            width,
            height,
            math.floor((left or 0) * 64 + 0.5),
            math.floor((right or 1) * 64 + 0.5),
            math.floor((top or 0) * 64 + 0.5),
            math.floor((bottom or 1) * 64 + 0.5)
        )
    end

    return ("|T%s:%d:%d|t"):format(texture, width, height)
end

function Inline:Register(name, spec)
    if type(name) ~= "string" or name == "" then
        error("Addon.UI.Inline:Register(name, spec) requires a non-empty string name.", 2)
    end

    self.Icons[name] = normalizeIconSpec(spec)
    return self.Icons[name]
end

function Inline:GetSpec(name)
    return self.Icons[name]
end

function Inline:Build(spec, width, height)
    local icon = normalizeIconSpec(spec)
    local texture = icon.texture or icon.file or icon.path
    local coords = icon.coords or icon.texCoords or nil

    return buildTextureMarkup(
        texture,
        width or icon.width,
        height or icon.height,
        coords and (coords.left or coords[1]) or nil,
        coords and (coords.right or coords[2]) or nil,
        coords and (coords.top or coords[3]) or nil,
        coords and (coords.bottom or coords[4]) or nil
    )
end

function Inline:Get(name, width, height)
    local spec = self:GetSpec(name)
    if not spec then
        return ""
    end

    return self:Build(spec, width, height)
end

function Inline:WithText(name, text, width, height)
    return ("%s %s"):format(self:Get(name, width, height), tostring(text or ""))
end

function Inline:RaidMarker(marker, width, height)
    local markerNumber = tonumber(marker) or 0
    if markerNumber < 1 or markerNumber > 8 then
        return ""
    end

    return self:Build({
        texture = ("Interface\\TargetingFrame\\UI-RaidTargetingIcon_%d"):format(markerNumber),
        coords = {
            left = 4 / 64,
            right = 60 / 64,
            top = 4 / 64,
            bottom = 60 / 64,
        },
        width = width,
        height = height,
    }, width, height)
end

Inline:Register("RPE", {
    texture = ADDON_TEXTURE_ROOT .. "rpe.png",
})

Inline:Register("Category", {
    texture = ADDON_TEXTURE_ROOT .. "category.png",
})

Inline:Register("Selected", {
    texture = ADDON_TEXTURE_ROOT .. "selected.png",
})

return Inline
