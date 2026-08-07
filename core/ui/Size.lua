local _, Addon = ...

local UI = Addon.UI or {}
Addon.UI = UI

local function ResolveSizeValue(value, reference)
    if type(value) ~= "string" then
        return value
    end

    local percent = value:match("^%s*([%d%.]+)%%%s*$")
    if percent then
        local base = tonumber(reference)
        if base == nil then
            return value
        end

        return base * (tonumber(percent) or 0) / 100
    end

    local percentValue, operator, offset = value:match("^%s*([%d%.]+)%%([%+%-])%s*(%d+)%s*$")
    if percentValue and operator and offset then
        local base = tonumber(reference)
        if base == nil then
            return value
        end

        local size = base * (tonumber(percentValue) or 0) / 100
        offset = tonumber(offset) or 0
        if operator == "-" then
            size = size - offset
        else
            size = size + offset
        end

        return size
    end

    return value
end

local function ResolveFrameReference(reference)
    if type(reference) ~= "table" then
        return reference
    end

    if reference.GetFrame then
        return reference:GetFrame() or reference.frame
    end

    return reference.frame or reference
end

local function ResolveFrameSize(reference)
    local frame = ResolveFrameReference(reference)
    if not frame then
        return nil, nil
    end

    local width = frame.GetWidth and frame:GetWidth() or nil
    local height = frame.GetHeight and frame:GetHeight() or nil
    return width, height
end

UI.ResolveSizeValue = UI.ResolveSizeValue or ResolveSizeValue
UI.ResolveFrameSize = UI.ResolveFrameSize or ResolveFrameSize

return UI
