local _, Addon = ...

local UI = Addon.UI or {}
Addon.UI = UI

UI.ColorScheme = UI.ColorScheme or {}
local ColorScheme = UI.ColorScheme
ColorScheme.__index = ColorScheme

local DEFAULT_SCHEME = {
    window = {
        background = { r = 0.08, g = 0.09, b = 0.12, a = 0.88 },
        border = { r = 0.42, g = 0.46, b = 0.52, a = 0.95 },
        headerBackground = { r = 0.12, g = 0.13, b = 0.18, a = 0.95 },
    },
    panel = {
        background = { r = 0.06, g = 0.07, b = 0.1, a = 0.9 },
        border = { r = 0.18, g = 0.2, b = 0.25, a = 1 },
    },
    text = {
        primary = { r = 0.92, g = 0.94, b = 0.98, a = 1 },
        secondary = { r = 0.8, g = 0.82, b = 0.88, a = 1 },
        muted = { r = 0.62, g = 0.66, b = 0.72, a = 1 },
    },
    accent = { r = 0.42, g = 0.66, b = 0.98, a = 1 },
    success = { r = 0.35, g = 0.9, b = 0.45, a = 1 },
    danger = { r = 0.95, g = 0.35, b = 0.35, a = 1 },
    warning = { r = 0.95, g = 0.9, b = 0.7, a = 1 },
    tab = {
        bar = { r = 0.11, g = 0.12, b = 0.16, a = 0.95 },
        active = { r = 0.92, g = 0.94, b = 0.98, a = 1 },
        inactive = { r = 0.62, g = 0.66, b = 0.72, a = 1 },
    },
    scrollbar = {
        track = { r = 0.08, g = 0.09, b = 0.11, a = 0.95 },
        thumb = { r = 0.42, g = 0.46, b = 0.52, a = 1 },
    },
    list = {
        rowBackground = { r = 0.08, g = 0.09, b = 0.11, a = 0.9 },
        rowHover = { r = 0.12, g = 0.14, b = 0.18, a = 0.95 },
        rowStatusPass = { r = 0.35, g = 0.9, b = 0.45, a = 1 },
        rowStatusFail = { r = 0.95, g = 0.35, b = 0.35, a = 1 },
    },
    button = {
        label = { r = 0.92, g = 0.94, b = 0.98, a = 1 },
    },
    progress = {
        background = { r = 0.08, g = 0.09, b = 0.12, a = 0.95 },
        border = { r = 0.16, g = 0.18, b = 0.22, a = 1 },
        barPrimary = { r = 0.42, g = 0.66, b = 0.98, a = 1 },
        barSecondary = { r = 0.25, g = 0.42, b = 0.68, a = 1 },
        text = { r = 0.8, g = 0.82, b = 0.88, a = 1 },
    },
    slider = {
        background = { r = 0.08, g = 0.09, b = 0.12, a = 0.95 },
        track = { r = 0.08, g = 0.09, b = 0.12, a = 0.95 },
        fill = { r = 0.42, g = 0.66, b = 0.98, a = 1 },
        thumb = { r = 0.92, g = 0.94, b = 0.98, a = 1 },
        text = { r = 0.8, g = 0.82, b = 0.88, a = 1 },
    },
    dropdown = {
        background = { r = 0.08, g = 0.09, b = 0.12, a = 0.98 },
        border = { r = 0.2, g = 0.22, b = 0.28, a = 1 },
        selectedText = { r = 0.42, g = 0.66, b = 0.98, a = 1 },
        categoryText = { r = 0.62, g = 0.66, b = 0.72, a = 1 },
        categoryIcon = { r = 0.62, g = 0.66, b = 0.72, a = 1 },
    },
    checkbox = {
        boxBackground = { r = 0.12, g = 0.14, b = 0.18, a = 1 },
        border = { r = 0.24, g = 0.27, b = 0.32, a = 1 },
        check = { r = 0.42, g = 0.66, b = 0.98, a = 1 },
    },
}

local activeScheme = nil

local function IsColorTable(value)
    return type(value) == "table" and (value.r ~= nil or value.g ~= nil or value.b ~= nil or value.a ~= nil)
end

local function CloneColor(color)
    if not IsColorTable(color) then
        return nil
    end

    return {
        r = color.r or 0,
        g = color.g or 0,
        b = color.b or 0,
        a = color.a or 1,
    }
end

local function DeepCopy(value)
    if type(value) ~= "table" then
        return value
    end

    local copy = {}
    for key, child in pairs(value) do
        copy[key] = DeepCopy(child)
    end
    return copy
end

local function DeepMerge(base, override)
    local result = DeepCopy(base or {})

    for key, value in pairs(override or {}) do
        if type(value) == "table" and not IsColorTable(value) then
            result[key] = DeepMerge(result[key], value)
        else
            result[key] = DeepCopy(value)
        end
    end

    return result
end

local function LookupPath(source, path)
    if type(source) ~= "table" or type(path) ~= "string" or path == "" then
        return nil
    end

    local current = source
    for segment in string.gmatch(path, "[^%.]+") do
        if type(current) ~= "table" then
            return nil
        end

        current = current[segment]
        if current == nil then
            return nil
        end
    end

    return current
end

local function ResolveCandidate(candidate)
    if IsColorTable(candidate) then
        return candidate
    end

    if type(candidate) == "string" and candidate ~= "" then
        return LookupPath(activeScheme or DEFAULT_SCHEME, candidate) or LookupPath(DEFAULT_SCHEME, candidate)
    end

    return nil
end

function ColorScheme:GetDefaultScheme()
    return DEFAULT_SCHEME
end

function ColorScheme:GetActiveScheme()
    return activeScheme or DEFAULT_SCHEME
end

function ColorScheme:SetActiveScheme(scheme)
    if scheme == nil then
        activeScheme = nil
    else
        activeScheme = DeepMerge(DEFAULT_SCHEME, scheme)
    end

    return self:GetActiveScheme()
end

function ColorScheme:ResetActiveScheme()
    activeScheme = nil
    return self:GetActiveScheme()
end

function ColorScheme:Get(path, fallback)
    local resolved = LookupPath(self:GetActiveScheme(), path) or LookupPath(DEFAULT_SCHEME, path) or ResolveCandidate(fallback)
    return CloneColor(resolved) or CloneColor(fallback) or nil
end

function ColorScheme:Resolve(override, token, fallback)
    local resolved = ResolveCandidate(override) or ResolveCandidate(token) or ResolveCandidate(fallback)
    return CloneColor(resolved) or { r = 1, g = 1, b = 1, a = 1 }
end

UI.GetColorScheme = function()
    return ColorScheme:GetActiveScheme()
end

UI.SetColorScheme = function(scheme)
    return ColorScheme:SetActiveScheme(scheme)
end

UI.ResetColorScheme = function()
    return ColorScheme:ResetActiveScheme()
end

UI.GetColor = function(path, fallback)
    return ColorScheme:Get(path, fallback)
end

UI.ResolveColor = function(override, token, fallback)
    return ColorScheme:Resolve(override, token, fallback)
end
