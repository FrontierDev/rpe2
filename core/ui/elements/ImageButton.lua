local _, Addon = ...

local UI = Addon.UI or {}
Addon.UI = UI
local ButtonBase = UI.ButtonBase
local Debug = Addon.Debug or {}

UI.ImageButton = UI.ImageButton or {}
local ImageButton = UI.ImageButton
ImageButton.__index = ImageButton
setmetatable(ImageButton, { __index = ButtonBase })

function ImageButton:New(options)
    local instance = ButtonBase.New(self, options)
    return instance
end

function ImageButton:SetNormalTexture(texture)
    self:SetOption("normalTexture", texture)

    if self.frame and self.frame.SetNormalTexture then
        self.frame:SetNormalTexture(texture)
    end
end

function ImageButton:SetHighlightTexture(texture)
    self:SetOption("highlightTexture", texture)

    if self.frame and self.frame.SetHighlightTexture then
        self.frame:SetHighlightTexture(texture)
    end
end

function ImageButton:SetPushedTexture(texture)
    self:SetOption("pushedTexture", texture)

    if self.frame and self.frame.SetPushedTexture then
        self.frame:SetPushedTexture(texture)
    end
end

function ImageButton:SetDisabledTexture(texture)
    self:SetOption("disabledTexture", texture)

    if self.frame and self.frame.SetDisabledTexture then
        self.frame:SetDisabledTexture(texture)
    end
end

function ImageButton:Create()
    if self.frame then
        return self.frame
    end

    local frame = self:CreateButton(self.options.template)

    if self.options.normalTexture and frame.SetNormalTexture then
        frame:SetNormalTexture(self.options.normalTexture)
    end

    if self.options.highlightTexture and frame.SetHighlightTexture then
        frame:SetHighlightTexture(self.options.highlightTexture)
    end

    if self.options.pushedTexture and frame.SetPushedTexture then
        frame:SetPushedTexture(self.options.pushedTexture)
    end

    if self.options.disabledTexture and frame.SetDisabledTexture then
        frame:SetDisabledTexture(self.options.disabledTexture)
    end

    return self.frame
end
