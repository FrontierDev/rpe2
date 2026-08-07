local _, Addon = ...

local UI = Addon.UI or {}
Addon.UI = UI
local BaseElement = UI.BaseElement
local Image = UI.Image
local Text = UI.Text
local Font = UI.Font or {}
local Utils = UI.Utils or {}
local Constants = UI.Constants or {}

UI.StatEntry = UI.StatEntry or {}
local StatEntry = UI.StatEntry
StatEntry.__index = StatEntry
setmetatable(StatEntry, { __index = BaseElement })

local DEFAULT_ICON = "Interface\\Icons\\INV_Misc_QuestionMark"

function StatEntry:New(options)
    local instance = BaseElement.New(self, options)
    instance.options.border = false
    if instance.options.enableMouse == nil then
        instance.options.enableMouse = true
    end
    instance.iconElement = nil
    instance.nameElement = nil
    instance.valueElement = nil
    instance.iconTexture = nil
    instance.nameRegion = nil
    instance.valueRegion = nil
    return instance
end

function StatEntry:SetIcon(texturePath)
    self:SetOption("iconTexture", texturePath)

    if self.iconElement and self.iconElement.SetTexture then
        self.iconElement:SetTexture(texturePath)
    elseif self.iconTexture and self.iconTexture.SetTexture then
        self.iconTexture:SetTexture(texturePath)
    end
end

function StatEntry:SetStatName(statName)
    self:SetOption("statName", statName)

    if self.nameElement and self.nameElement.SetText then
        self.nameElement:SetText(statName or "")
    elseif self.nameRegion and self.nameRegion.SetText then
        self.nameRegion:SetText(statName or "")
    end
end

function StatEntry:SetStatValue(statValue)
    self:SetOption("statValue", statValue)

    if self.valueElement and self.valueElement.SetText then
        self.valueElement:SetText(statValue or "")
    elseif self.valueRegion and self.valueRegion.SetText then
        self.valueRegion:SetText(statValue or "")
    end
end

function StatEntry:SetLayoutMetrics(width, valueWidth)
    local defaults = (Constants.Prefabs and Constants.Prefabs.StatEntry) or {}
    local resolvedWidth = width or self.options.width or defaults.Width or 180
    local resolvedValueWidth = valueWidth or self.options.valueWidth or defaults.ValueWidth or 52
    local iconSize = self.options.iconSize or defaults.IconSize or 8
    local iconSpacing = self.options.iconToNameSpacing or defaults.IconToNameSpacing or 6
    local textGap = self.options.valueSpacing or 4
    local nameWidth = math.max(0, resolvedWidth - iconSize - iconSpacing - resolvedValueWidth - textGap)

    self.options.width = resolvedWidth
    self.options.valueWidth = resolvedValueWidth

    if self.frame and self.frame.SetWidth then
        self.frame:SetWidth(resolvedWidth)
    end

    local valueFrame = self.valueElement and self.valueElement.GetFrame and self.valueElement:GetFrame() or nil
    if valueFrame and valueFrame.SetWidth then
        valueFrame:SetWidth(resolvedValueWidth)
    end

    local nameFrame = self.nameElement and self.nameElement.GetFrame and self.nameElement:GetFrame() or nil
    if nameFrame and nameFrame.SetWidth then
        nameFrame:SetWidth(nameWidth)
    end
end

function StatEntry:Create()
    if self.frame then
        return self.frame
    end

    local parentFrame = self:GetParentFrame()
    if not parentFrame then
        error("A stat entry prefab requires a parent frame before Create().", 2)
    end

    local defaults = (Constants.Prefabs and Constants.Prefabs.StatEntry) or {}
    local width = self.options.width or defaults.Width or 180
    local height = self.options.height or defaults.Height or 14
    local iconSize = self.options.iconSize or defaults.IconSize or 8
    local valueWidth = self.options.valueWidth or defaults.ValueWidth or 52
    local iconSpacing = self.options.iconToNameSpacing or defaults.IconToNameSpacing or 6
    local textGap = self.options.valueSpacing or 4
    local nameWidth = math.max(0, width - iconSize - iconSpacing - valueWidth - textGap)

    local frame = CreateFrame("Frame", self.name, parentFrame, self.options.template)
    self:SetFrame(frame)
    frame:SetSize(width, height)

    self.iconElement = Image:New({
        name = (self.name or "StatEntry") .. "Icon",
        width = iconSize,
        height = iconSize,
        textureInsetLeft = 0,
        textureInsetTop = 0,
        textureInsetRight = 0,
        textureInsetBottom = 0,
        border = false,
    })
    self.iconElement:SetParent(frame)
    self.iconElement:Create()
    self.iconElement:GetFrame():SetPoint("LEFT", frame, "LEFT", 0, 0)
    self.iconTexture = self.iconElement.textureRegion
    Utils.ApplyTexture(
        self.iconTexture,
        self.options.iconTexture or defaults.IconTexture or DEFAULT_ICON,
        Utils.ResolveTexCoord(self.options.iconTexCoord, defaults.IconTexCoord)
    )

    self.valueElement = Text:New({
        name = (self.name or "StatEntry") .. "Value",
        width = valueWidth,
        height = height,
        textInsetLeft = 0,
        textInsetTop = 0,
        textInsetRight = 0,
        textInsetBottom = 0,
        border = false,
    })
    self.valueElement:SetParent(frame)
    self.valueElement:Create()
    self.valueElement:GetFrame():SetPoint("RIGHT", frame, "RIGHT", 0, 0)
    self.valueRegion = self.valueElement.textRegion
    if self.valueRegion and self.valueRegion.SetJustifyH then
        self.valueRegion:SetJustifyH("RIGHT")
    end
    if self.valueRegion and self.valueRegion.SetJustifyV then
        self.valueRegion:SetJustifyV("MIDDLE")
    end
    Font:Apply(self.valueRegion, self.options, {
        fontSize = self.options.valueFontSize or defaults.ValueFontSize or self.options.fontSize or defaults.FontSize or (Constants.FontSizes and Constants.FontSizes.Body) or 10,
    })
    local valueColor = UI.ResolveColor(self.options.statValueColor, "text.primary")
    if self.valueRegion and self.valueRegion.SetTextColor then
        self.valueRegion:SetTextColor(valueColor.r or 1, valueColor.g or 1, valueColor.b or 1, valueColor.a or 1)
    end
    self:SetStatValue(self.options.statValue or defaults.StatValue or "0")

    self.nameElement = Text:New({
        name = (self.name or "StatEntry") .. "Name",
        width = nameWidth,
        height = height,
        textInsetLeft = 0,
        textInsetTop = 0,
        textInsetRight = 0,
        textInsetBottom = 0,
        border = false,
    })
    self.nameElement:SetParent(frame)
    self.nameElement:Create()
    self.nameElement:GetFrame():SetPoint("LEFT", self.iconElement:GetFrame(), "RIGHT", iconSpacing, 0)
    self.nameRegion = self.nameElement.textRegion
    if self.nameRegion and self.nameRegion.SetJustifyH then
        self.nameRegion:SetJustifyH("LEFT")
    end
    if self.nameRegion and self.nameRegion.SetJustifyV then
        self.nameRegion:SetJustifyV("MIDDLE")
    end
    Font:Apply(self.nameRegion, self.options, {
        fontSize = self.options.fontSize or defaults.FontSize or (Constants.FontSizes and Constants.FontSizes.Body) or 10,
    })
    local nameColor = UI.ResolveColor(self.options.statNameColor, "text.secondary")
    if self.nameRegion and self.nameRegion.SetTextColor then
        self.nameRegion:SetTextColor(nameColor.r or 1, nameColor.g or 1, nameColor.b or 1, nameColor.a or 1)
    end
    self:SetStatName(self.options.statName or defaults.StatName or "Statistic")
    self:SetLayoutMetrics(width, valueWidth)

    return self.frame
end

return StatEntry
