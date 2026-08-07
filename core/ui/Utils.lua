local _, Addon = ...

local UI = Addon.UI or {}
Addon.UI = UI

UI.Utils = UI.Utils or {}
local Utils = UI.Utils

local function GetFrame(target)
    if not target then
        return nil
    end

    if target.GetFrame then
        return target:GetFrame() or target.frame
    end

    return target.frame or target
end

function Utils.GetFrame(target)
    return GetFrame(target)
end

function Utils.AnchorFill(target, relativeTo, left, top, right, bottom)
    local frame = GetFrame(target)
    local parent = GetFrame(relativeTo)

    if not frame or not frame.SetPoint then
        return frame
    end

    frame:ClearAllPoints()
    frame:SetPoint("TOPLEFT", parent, "TOPLEFT", left or 0, -(top or 0))
    frame:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -(right or 0), bottom or 0)
    return frame
end

function Utils.ApplyTexture(texture, texturePath, texCoord)
    if not texture then
        return texture
    end

    if texture.SetTexture then
        texture:SetTexture(texturePath)
    end

    if texCoord and texture.SetTexCoord then
        texture:SetTexCoord(
            texCoord.left or texCoord[1] or 0,
            texCoord.right or texCoord[2] or 1,
            texCoord.top or texCoord[3] or 0,
            texCoord.bottom or texCoord[4] or 1
        )
    end

    return texture
end

function Utils.ResolveTexCoord(texCoord, fallback)
    local coords = texCoord or fallback
    if not coords then
        return nil
    end

    return {
        left = coords.left or coords[1] or 0,
        right = coords.right or coords[2] or 1,
        top = coords.top or coords[3] or 0,
        bottom = coords.bottom or coords[4] or 1,
    }
end

function Utils.TrimText(value)
    local text = tostring(value or "")
    text = text:gsub("^%s+", "")
    text = text:gsub("%s+$", "")
    return text
end

function Utils.ParseCommaSeparatedList(value)
    local items = {}
    local seen = {}

    for rawItem in tostring(value or ""):gmatch("[^,]+") do
        local normalized = Utils.TrimText(rawItem)
        if normalized ~= "" and not seen[normalized] then
            items[#items + 1] = normalized
            seen[normalized] = true
        end
    end

    return items
end

function Utils.JoinCommaSeparatedList(items)
    if type(items) ~= "table" or #items == 0 then
        return ""
    end

    return table.concat(items, ", ")
end

return Utils
