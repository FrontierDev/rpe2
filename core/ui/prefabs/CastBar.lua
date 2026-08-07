local _, Addon = ...

local UI = Addon.UI or {}
Addon.UI = UI
local ResourceBar = UI.ResourceBar

UI.CastBar = UI.CastBar or {}
local CastBar = UI.CastBar
CastBar.__index = CastBar
setmetatable(CastBar, { __index = ResourceBar })

function CastBar:New(options)
    local instance = ResourceBar.New(self, options)
    instance.options.progressFontSize = instance.options.progressFontSize or 12
    return instance
end

function CastBar:Create()
    if self.options then
        self.options.progressFontSize = self.options.progressFontSize or 12
    end

    return ResourceBar.Create(self)
end

return CastBar
