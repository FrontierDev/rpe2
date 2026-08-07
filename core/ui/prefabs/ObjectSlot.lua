local _, Addon = ...

local UI = Addon.UI or {}
Addon.UI = UI
local ImageButton = UI.ImageButton
local Font = UI.Font or {}
local Constants = UI.Constants or {}

UI.ObjectSlot = UI.ObjectSlot or {}
local ObjectSlot = UI.ObjectSlot
ObjectSlot.__index = ObjectSlot
setmetatable(ObjectSlot, { __index = ImageButton })

local DEFAULT_ICON = "Interface\\Icons\\INV_Misc_QuestionMark"

local function ApplyBorderTexture(texture, r, g, b, a)
    if texture and texture.SetColorTexture then
        texture:SetColorTexture(r or 1, g or 1, b or 1, a or 1)
    end
end

local function ResolveObjectSlotDefaults(options)
    local defaults = (Constants.Prefabs and Constants.Prefabs.ObjectSlot) or {}
    local size = options.size or options.width or defaults.Size or 36
    local height = options.height or size
    local borderSize = options.slotBorderSize or defaults.BorderSize or 2
    local iconTexture = options.iconTexture or defaults.IconTexture or DEFAULT_ICON
    local texCoord = options.iconTexCoord or defaults.IconTexCoord
    local backgroundColor = UI.ResolveColor(options.backgroundColor or defaults.BackgroundColor, "panel.background")
    local borderColor = options.slotBorderColor or defaults.BorderColor or { r = 0.42, g = 0.46, b = 0.52, a = 1 }
    local countFontSize = options.countFontSize or defaults.CountFontSize or (Constants.FontSizes and Constants.FontSizes.Body) or 8
    local countInsetX = options.countInsetX or defaults.CountInsetX or 3
    local countInsetY = options.countInsetY or defaults.CountInsetY or 3
    local overlayFontSize = options.overlayFontSize or defaults.OverlayFontSize or (Constants.FontSizes and Constants.FontSizes.Body) or 12

    return {
        backgroundColor = backgroundColor,
        borderColor = borderColor,
        borderSize = borderSize,
        countFontSize = countFontSize,
        countInsetX = countInsetX,
        countInsetY = countInsetY,
        height = height,
        iconTexture = iconTexture,
        overlayFontSize = overlayFontSize,
        size = size,
        texCoord = texCoord,
    }
end

local function ApplyIconTexture(texture, texturePath, texCoord)
    if not texture then
        return
    end

    if texture.ClearAllPoints then
        texture:ClearAllPoints()
    end
    if texture.SetAllPoints then
        texture:SetAllPoints(texture:GetParent())
    end
    if texture.SetDrawLayer then
        texture:SetDrawLayer("ARTWORK")
    end
    if texture.SetTexture then
        texture:SetTexture(texturePath or DEFAULT_ICON)
    end

    if texCoord and texture.SetTexCoord then
        texture:SetTexCoord(
            texCoord.left or texCoord[1] or 0.03,
            texCoord.right or texCoord[2] or 0.97,
            texCoord.top or texCoord[3] or 0.03,
            texCoord.bottom or texCoord[4] or 0.97
        )
    end
end

local function CreateBorderTexture(frame, pointA, pointB, size, isVertical)
    local texture = frame:CreateTexture(nil, "OVERLAY")
    texture:SetPoint(pointA, frame, pointA, 0, 0)
    texture:SetPoint(pointB, frame, pointB, 0, 0)
    if isVertical then
        texture:SetWidth(size)
    else
        texture:SetHeight(size)
    end
    return texture
end

local function InstallStateScripts(self, frame)
    local onEnter = function()
        self.isHovered = true
        self:RefreshVisualState()
    end
    local onLeave = function()
        self.isHovered = false
        self.isPressed = false
        self:RefreshVisualState()
    end
    local onMouseDown = function()
        self.isPressed = true
        self:RefreshVisualState()
    end
    local onMouseUp = function()
        self.isPressed = false
        self:RefreshVisualState()
    end

    if frame.HookScript then
        frame:HookScript("OnEnter", onEnter)
        frame:HookScript("OnLeave", onLeave)
        frame:HookScript("OnMouseDown", onMouseDown)
        frame:HookScript("OnMouseUp", onMouseUp)
        return
    end

    frame:SetScript("OnEnter", onEnter)
    frame:SetScript("OnLeave", onLeave)
    frame:SetScript("OnMouseDown", onMouseDown)
    frame:SetScript("OnMouseUp", onMouseUp)
end

function ObjectSlot:New(options)
    local instance = ImageButton.New(self, options)
    instance.options.border = false
    instance.options.suppressHighlight = true
    instance.iconTexture = nil
    instance.background = nil
    instance.countRegion = nil
    instance.overlayRegion = nil
    instance.borderTop = nil
    instance.borderBottom = nil
    instance.borderLeft = nil
    instance.borderRight = nil
    instance.enabled = options == nil or options.enabled ~= false
    instance.isHovered = false
    instance.isPressed = false
    return instance
end

function ObjectSlot:SetIcon(texturePath)
    self:SetNormalTexture(texturePath)
end

function ObjectSlot:SetTexCoord(left, right, top, bottom)
    self:SetOption("iconTexCoord", { left = left, right = right, top = top, bottom = bottom })
    ApplyIconTexture(self.iconTexture, self.options.iconTexture, self.options.iconTexCoord)
end

function ObjectSlot:SetCount(countText)
    self:SetOption("countText", countText)
    if self.countRegion and self.countRegion.SetText then
        self.countRegion:SetText(countText or "")
    end
end

function ObjectSlot:SetBorderColor(r, g, b, a)
    ApplyBorderTexture(self.borderTop, r, g, b, a)
    ApplyBorderTexture(self.borderBottom, r, g, b, a)
    ApplyBorderTexture(self.borderLeft, r, g, b, a)
    ApplyBorderTexture(self.borderRight, r, g, b, a)
end

function ObjectSlot:SetOverlayText(overlayText)
    self:SetOption("overlayText", overlayText)
    if self.overlayRegion and self.overlayRegion.SetText then
        local text = tostring(overlayText or "")
        self.overlayRegion:SetText(text)
        if text ~= "" and self.overlayRegion.Show then
            self.overlayRegion:Show()
        elseif text == "" and self.overlayRegion.Hide then
            self.overlayRegion:Hide()
        end
    end
end

function ObjectSlot:RefreshVisualState()
    ---@type Texture?
    local texture = self.iconTexture
    if not texture then
        return
    end

    local enabled = self.enabled ~= false
    if texture.SetDesaturated then
        texture:SetDesaturated(not enabled)
    end

    local brightness = 0.9
    if not enabled then
        brightness = 0.45
    elseif self.isPressed then
        brightness = 0.82
    elseif self.isHovered then
        brightness = 1
    end

    if texture.SetVertexColor then
        texture:SetVertexColor(brightness, brightness, brightness, 1)
    end

    if self.countRegion and self.countRegion.SetAlpha then
        self.countRegion:SetAlpha(enabled and 1 or 0.65)
    end
    if self.overlayRegion and self.overlayRegion.SetAlpha then
        self.overlayRegion:SetAlpha(0.95)
    end
end

function ObjectSlot:SetEnabled(enabled)
    ImageButton.SetEnabled(self, enabled)
    self:RefreshVisualState()
    return self.enabled
end

function ObjectSlot:Create()
    if self.frame then
        return self.frame
    end

    local resolved = ResolveObjectSlotDefaults(self.options)
    self:SetNormalTexture(resolved.iconTexture)
    local frame = ImageButton.Create(self)
    frame:SetSize(resolved.size, resolved.height)

    self.background = frame:CreateTexture(nil, "BACKGROUND")
    self.background:SetAllPoints(frame)
    self.background:SetColorTexture(
        resolved.backgroundColor.r or 0.07,
        resolved.backgroundColor.g or 0.08,
        resolved.backgroundColor.b or 0.1,
        resolved.backgroundColor.a or 0.95
    )

    self.iconTexture = frame.GetNormalTexture and frame:GetNormalTexture() or nil
    ApplyIconTexture(self.iconTexture, resolved.iconTexture, resolved.texCoord)

    self.borderTop = CreateBorderTexture(frame, "TOPLEFT", "TOPRIGHT", resolved.borderSize, false)
    self.borderBottom = CreateBorderTexture(frame, "BOTTOMLEFT", "BOTTOMRIGHT", resolved.borderSize, false)
    self.borderLeft = CreateBorderTexture(frame, "TOPLEFT", "BOTTOMLEFT", resolved.borderSize, true)
    self.borderRight = CreateBorderTexture(frame, "TOPRIGHT", "BOTTOMRIGHT", resolved.borderSize, true)
    self:SetBorderColor(
        resolved.borderColor.r,
        resolved.borderColor.g,
        resolved.borderColor.b,
        resolved.borderColor.a
    )

    self.countRegion = frame:CreateFontString(nil, "OVERLAY")
    self.countRegion:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -resolved.countInsetX, resolved.countInsetY)
    self.countRegion:SetJustifyH("RIGHT")
    self.countRegion:SetJustifyV("BOTTOM")
    Font:Apply(self.countRegion, self.options, {
        fontSize = resolved.countFontSize,
    })
    local countColor = UI.ResolveColor(self.options.countTextColor, "text.primary")
    self.countRegion:SetTextColor(countColor.r or 1, countColor.g or 1, countColor.b or 1, countColor.a or 1)
    self.countRegion:SetText(self.options.countText or "")

    self.overlayRegion = frame:CreateFontString(nil, "OVERLAY")
    self.overlayRegion:SetPoint("CENTER", frame, "CENTER", 0, 0)
    self.overlayRegion:SetJustifyH("CENTER")
    self.overlayRegion:SetJustifyV("MIDDLE")
    Font:Apply(self.overlayRegion, self.options, {
        fontSize = resolved.overlayFontSize,
        fontFlags = "OUTLINE",
    })
    local overlayColor = UI.ResolveColor(self.options.overlayTextColor, "text.primary")
    self.overlayRegion:SetTextColor(overlayColor.r or 1, overlayColor.g or 1, overlayColor.b or 1, overlayColor.a or 1)
    if self.overlayRegion.SetShadowOffset then
        self.overlayRegion:SetShadowOffset(1, -1)
    end
    if self.overlayRegion.SetShadowColor then
        self.overlayRegion:SetShadowColor(0, 0, 0, 1)
    end
    self:SetOverlayText(self.options.overlayText or "")

    InstallStateScripts(self, frame)

    self:SetEnabled(self.enabled)

    return self.frame
end

return ObjectSlot
