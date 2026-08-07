local _, Addon = ...

local UI = Addon.UI or {}
Addon.UI = UI
local BaseElement = UI.BaseElement
local Debug = Addon.Debug or {}

UI.Image = UI.Image or {}
local Image = UI.Image
Image.__index = Image
setmetatable(Image, { __index = BaseElement })

function Image:New(options)
    local instance = BaseElement.New(self, options)
    instance.texture = options and options.texture or nil
    instance.textureRegion = nil
    return instance
end

function Image:SetTexture(texture)
    self.texture = texture

    if self.textureRegion and self.textureRegion.SetTexture then
        self.textureRegion:SetTexture(texture)
    elseif self.frame and self.frame.SetTexture then
        self.frame:SetTexture(texture)
    end
end

function Image:SetTexCoord(left, right, top, bottom)
    self:SetOption("texCoord", { left = left, right = right, top = top, bottom = bottom })

    if self.textureRegion and self.textureRegion.SetTexCoord then
        self.textureRegion:SetTexCoord(left, right, top, bottom)
    elseif self.frame and self.frame.SetTexCoord then
        self.frame:SetTexCoord(left, right, top, bottom)
    end
end

function Image:SetVertexColor(r, g, b, a)
    self:SetOption("vertexColor", { r = r, g = g, b = b, a = a })

    if self.textureRegion and self.textureRegion.SetVertexColor then
        self.textureRegion:SetVertexColor(r, g, b, a)
    elseif self.frame and self.frame.SetVertexColor then
        self.frame:SetVertexColor(r, g, b, a)
    end
end

function Image:Create()
    if self.frame then
        return self.frame
    end

    local parentFrame = self:GetParentFrame()
    if not parentFrame then
        if Debug.Internal then
            Debug.Internal("Addon.UI.Image requires a parent frame before Create().")
        end

        error("An image element requires a parent frame before Create().", 2)
    end

    local frame = CreateFrame("Frame", self.name, parentFrame, self.options.template)
    self:SetFrame(frame)

    local texture = frame:CreateTexture(nil, self.options.layer or "ARTWORK", self.options.template)
    self.textureRegion = texture
    texture:SetPoint("TOPLEFT", frame, "TOPLEFT", self.options.textureInsetLeft or 2, -(self.options.textureInsetTop or 2))
    texture:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -(self.options.textureInsetRight or 2), self.options.textureInsetBottom or 2)

    if self.texture then
        texture:SetTexture(self.texture)
    end

    if self.options.texCoord and texture.SetTexCoord then
        local c = self.options.texCoord
        texture:SetTexCoord(c.left, c.right, c.top, c.bottom)
    end

    if self.options.vertexColor and texture.SetVertexColor then
        local c = self.options.vertexColor
        texture:SetVertexColor(c.r or 1, c.g or 1, c.b or 1, c.a or 1)
    end

    return self.frame
end
