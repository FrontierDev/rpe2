local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Client.UI = Addon.Client.UI or {}
Addon.Client.UI.Tooltips = Addon.Client.UI.Tooltips or {}

local Tooltips = Addon.Client.UI.Tooltips
local Registry = Addon.Internal and Addon.Internal.Registry or {}

local SkillTooltip = Tooltips.Skill or {}
Tooltips.Skill = SkillTooltip

local function ensureString(value, fallback)
    if value == nil or value == "" then
        return fallback or ""
    end

    return tostring(value)
end

function SkillTooltip:Build(detail, owner)
    if type(detail) ~= "table" then
        return nil
    end

    return {
        type = "game",
        lines = {
            {
                left = ensureString(detail.name, "Skill"),
                right = ("+%d"):format(math.max(0, tonumber(detail.value) or 0)),
                r = 1,
                g = 1,
                b = 1,
                rightR = 1,
                rightG = 1,
                rightB = 1,
                wrap = false,
            },
            {
                text = "<Left-click to roll.>",
                r = 0.82,
                g = 0.84,
                b = 0.88,
                wrap = false,
            },
        },
    }
end

return SkillTooltip
