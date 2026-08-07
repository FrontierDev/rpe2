local _, Addon = ...

local UI = Addon.UI or {}
Addon.UI = UI
local BaseElement = UI.BaseElement
local Image = UI.Image
local Text = UI.Text
local Constants = UI.Constants or {}

UI.SpellbookEntry = UI.SpellbookEntry or {}
local SpellbookEntry = UI.SpellbookEntry
SpellbookEntry.__index = SpellbookEntry
setmetatable(SpellbookEntry, { __index = BaseElement })

local DEFAULT_ICON = "Interface\\Icons\\INV_Misc_QuestionMark"

function SpellbookEntry:New(options)
    local instance = BaseElement.New(self, options)
    instance.options.border = false
    instance.enabled = options == nil or options.enabled ~= false
    instance.iconFrame = nil
    instance.iconElement = nil
    instance.iconTexture = nil
    instance.nameElement = nil
    instance.nameRegion = nil
    instance.hoverTexture = nil
    instance.iconBorderTop = nil
    instance.iconBorderBottom = nil
    instance.iconBorderLeft = nil
    instance.iconBorderRight = nil
    return instance
end

function SpellbookEntry:SetIcon(texturePath)
    self:SetOption("iconTexture", texturePath)
    if self.iconElement and self.iconElement.SetTexture then
        self.iconElement:SetTexture(texturePath or DEFAULT_ICON)
    elseif self.iconTexture and self.iconTexture.SetTexture then
        self.iconTexture:SetTexture(texturePath or DEFAULT_ICON)
    end
end

function SpellbookEntry:SetSpellName(spellName)
    self:SetOption("spellName", spellName)
    if self.nameElement and self.nameElement.SetText then
        self.nameElement:SetText(spellName or "")
    elseif self.nameRegion and self.nameRegion.SetText then
        self.nameRegion:SetText(spellName or "")
    end
end

function SpellbookEntry:SetBorderColor(r, g, b, a)
    local textures = {
        self.iconBorderTop,
        self.iconBorderBottom,
        self.iconBorderLeft,
        self.iconBorderRight,
    }
    for index = 1, #textures do
        local texture = textures[index]
        if texture and texture.SetColorTexture then
            texture:SetColorTexture(r or 1, g or 1, b or 1, a or 1)
        end
    end
end

local function createBorderTexture(frame, pointA, pointB, size, isVertical)
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

local function applyBorderColor(texture, color)
    if not texture or not texture.SetColorTexture then
        return
    end

    texture:SetColorTexture(color.r or 1, color.g or 1, color.b or 1, color.a or 1)
end

function SpellbookEntry:SetLayoutMetrics(width, height)
    local defaults = (Constants.Prefabs and Constants.Prefabs.SpellbookEntry) or {}
    local resolvedWidth = width or self.options.width or defaults.Width or 160
    local resolvedHeight = height or self.options.height or defaults.Height or 34
    local iconSize = self.options.iconSize or defaults.IconSize or 26
    local iconGap = self.options.iconGap or defaults.IconGap or 8
    local nameWidth = math.max(0, resolvedWidth - iconSize - iconGap)

    self.options.width = resolvedWidth
    self.options.height = resolvedHeight

    if self.frame and self.frame.SetSize then
        self.frame:SetSize(resolvedWidth, resolvedHeight)
    end
    if self.iconFrame and self.iconFrame.SetSize then
        self.iconFrame:SetSize(iconSize, iconSize)
    end

    local nameFrame = self.nameElement and self.nameElement.GetFrame and self.nameElement:GetFrame() or nil
    if nameFrame and nameFrame.SetSize then
        nameFrame:SetSize(nameWidth, resolvedHeight)
    end
end

function SpellbookEntry:RefreshVisualState()
    local enabled = self.enabled ~= false
    local brightness = enabled and 1 or 0.5
    local alpha = enabled and 1 or 0.7

    if self.iconTexture and self.iconTexture.SetDesaturated then
        self.iconTexture:SetDesaturated(not enabled)
    end
    if self.iconTexture and self.iconTexture.SetVertexColor then
        self.iconTexture:SetVertexColor(brightness, brightness, brightness, 1)
    end

    if self.nameRegion and self.nameRegion.SetAlpha then
        self.nameRegion:SetAlpha(alpha)
    end
    if self.frame and self.frame.SetAlpha then
        self.frame:SetAlpha(enabled and 1 or 0.85)
    end
end

function SpellbookEntry:SetEnabled(enabled)
    self.enabled = enabled ~= false
    if self.frame and self.frame.EnableMouse then
        self.frame:EnableMouse(self.enabled)
    end
    self:RefreshVisualState()
    return self.enabled
end

function SpellbookEntry:Create()
    if self.frame then
        return self.frame
    end

    local parentFrame = self:GetParentFrame()
    if not parentFrame then
        error("A spellbook entry prefab requires a parent frame before Create().", 2)
    end

    local defaults = (Constants.Prefabs and Constants.Prefabs.SpellbookEntry) or {}
    local width = self.options.width or defaults.Width or 160
    local height = self.options.height or defaults.Height or 34
    local iconSize = self.options.iconSize or defaults.IconSize or 26
    local iconGap = self.options.iconGap or defaults.IconGap or 8
    local nameWidth = math.max(0, width - iconSize - iconGap)

    local frame = CreateFrame("Button", self.name, parentFrame, self.options.template)
    self:SetFrame(frame)
    frame:RegisterForClicks("AnyUp")
    frame:SetSize(width, height)
    frame:EnableMouse(true)

    self.hoverTexture = frame:CreateTexture(nil, "BACKGROUND")
    self.hoverTexture:SetAllPoints(frame)
    self.hoverTexture:SetColorTexture(1, 1, 1, 0.05)
    self.hoverTexture:Hide()

    self.iconFrame = CreateFrame("Frame", (self.name or "SpellbookEntry") .. "IconFrame", frame)
    self.iconFrame:SetPoint("LEFT", frame, "LEFT", 0, 0)
    self.iconFrame:SetSize(iconSize, iconSize)
    local borderSize = self.options.iconBorderSize or 1
    local borderColor = UI.ResolveColor(self.options.iconBorderColor, "panel.border")
    self.iconBorderTop = createBorderTexture(self.iconFrame, "TOPLEFT", "TOPRIGHT", borderSize, false)
    self.iconBorderBottom = createBorderTexture(self.iconFrame, "BOTTOMLEFT", "BOTTOMRIGHT", borderSize, false)
    self.iconBorderLeft = createBorderTexture(self.iconFrame, "TOPLEFT", "BOTTOMLEFT", borderSize, true)
    self.iconBorderRight = createBorderTexture(self.iconFrame, "TOPRIGHT", "BOTTOMRIGHT", borderSize, true)
    applyBorderColor(self.iconBorderTop, borderColor)
    applyBorderColor(self.iconBorderBottom, borderColor)
    applyBorderColor(self.iconBorderLeft, borderColor)
    applyBorderColor(self.iconBorderRight, borderColor)

    self.iconElement = Image:New({
        name = (self.name or "SpellbookEntry") .. "Icon",
        width = iconSize,
        height = iconSize,
        textureInsetLeft = 1,
        textureInsetTop = 1,
        textureInsetRight = 1,
        textureInsetBottom = 1,
        border = false,
        texture = self.options.iconTexture or defaults.IconTexture or DEFAULT_ICON,
        texCoord = self.options.iconTexCoord or defaults.IconTexCoord or {
            left = 0.08,
            right = 0.92,
            top = 0.08,
            bottom = 0.92,
        },
    })
    self.iconElement:SetParent(self.iconFrame)
    self.iconElement:Create()
    local iconElementFrame = self.iconElement:GetFrame()
    if iconElementFrame and iconElementFrame.SetAllPoints then
        iconElementFrame:ClearAllPoints()
        iconElementFrame:SetAllPoints(self.iconFrame)
    end
    self.iconTexture = self.iconElement.textureRegion

    self.nameElement = Text:New({
        name = (self.name or "SpellbookEntry") .. "Name",
        width = nameWidth,
        height = height,
        text = self.options.spellName or defaults.SpellName or "Spell",
        justifyH = "LEFT",
        justifyV = "MIDDLE",
        wordWrap = true,
        textColor = UI.ResolveColor(self.options.textColor, "text.primary"),
        border = false,
        textInsetLeft = 0,
        textInsetTop = 0,
        textInsetRight = 0,
        textInsetBottom = 0,
        fontSize = self.options.fontSize or defaults.FontSize or ((Constants.FontSizes and Constants.FontSizes.Body) or 10),
    })
    self.nameElement:SetParent(frame)
    self.nameElement:Create()
    self.nameElement:GetFrame():SetPoint("LEFT", self.iconFrame, "RIGHT", iconGap, 0)
    self.nameRegion = self.nameElement.textRegion

    frame:HookScript("OnEnter", function()
        if self.hoverTexture and self.hoverTexture.Show then
            self.hoverTexture:Show()
        end
    end)
    frame:HookScript("OnLeave", function()
        if self.hoverTexture and self.hoverTexture.Hide then
            self.hoverTexture:Hide()
        end
    end)

    self:SetIcon(self.options.iconTexture or defaults.IconTexture or DEFAULT_ICON)
    self:SetSpellName(self.options.spellName or defaults.SpellName or "Spell")
    self:SetLayoutMetrics(width, height)
    self:SetEnabled(self.enabled)

    return self.frame
end

return SpellbookEntry
