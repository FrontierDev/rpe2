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

function ImageButton:EnsureSelectionBorder()
    if self.selectionBorder or not self.frame or not self.frame.CreateTexture then
        return self.selectionBorder
    end

    local color = self.options.selectionBorderColor or { r = 1, g = 0.78, b = 0.16, a = 1 }
    local thickness = math.max(1, math.floor(tonumber(self.options.selectionBorderSize) or 2))
    local frame = self.frame
    local border = {
        top = frame:CreateTexture(nil, "OVERLAY"),
        bottom = frame:CreateTexture(nil, "OVERLAY"),
        left = frame:CreateTexture(nil, "OVERLAY"),
        right = frame:CreateTexture(nil, "OVERLAY"),
    }

    border.top:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
    border.top:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
    border.top:SetHeight(thickness)
    border.bottom:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 0)
    border.bottom:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
    border.bottom:SetHeight(thickness)
    border.left:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
    border.left:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 0)
    border.left:SetWidth(thickness)
    border.right:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
    border.right:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
    border.right:SetWidth(thickness)

    for _, texture in pairs(border) do
        texture:SetColorTexture(color.r or 1, color.g or 0.78, color.b or 0.16, color.a or 1)
        texture:Hide()
    end

    self.selectionBorder = border
    return border
end

function ImageButton:SetSelected(selected)
    self.selected = selected == true
    local border = self.selected and self:EnsureSelectionBorder() or self.selectionBorder
    for _, texture in pairs(border or {}) do
        if self.selected then
            texture:Show()
        else
            texture:Hide()
        end
    end
    if self.RefreshInteractionAlpha then
        self:RefreshInteractionAlpha()
    end
    return self.selected
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

    if self.options.selected ~= nil then
        self:SetSelected(self.options.selected == true)
    end

    return self.frame
end
