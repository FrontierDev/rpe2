local _, Addon = ...

local UI = Addon.UI or {}
Addon.UI = UI

local BaseElement = UI.BaseElement
local Image = UI.Image
local Text = UI.Text
local ProgressBar = UI.ProgressBar
local Constants = UI.Constants or {}

UI.AchievementEntry = UI.AchievementEntry or {}
local AchievementEntry = UI.AchievementEntry
AchievementEntry.__index = AchievementEntry
setmetatable(AchievementEntry, { __index = BaseElement })

local DEFAULT_ICON = "Interface\\Icons\\INV_Misc_QuestionMark"
local DEFAULT_WIDTH = 324
local DEFAULT_HEIGHT = 78
local DEFAULT_ICON_SIZE = 44
local DEFAULT_ICON_GAP = 8
local DEFAULT_PADDING = 5
local DEFAULT_NAME_HEIGHT = 15
local DEFAULT_DESCRIPTION_HEIGHT = 22
local DEFAULT_PROGRESS_HEIGHT = 14
local DEFAULT_STATUS_HEIGHT = 13
local DEFAULT_SPACING = 1

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

local function showElement(element, shown)
    local frame = element and element.GetFrame and element:GetFrame() or nil
    if not frame then
        return
    end

    if shown then
        frame:Show()
    else
        frame:Hide()
    end
end

local function setTextColor(element, color)
    if element and element.SetTextColor and color then
        element:SetTextColor(color.r or 1, color.g or 1, color.b or 1, color.a or 1)
    end
end

local function setTextMaxLines(element, maxLines, wordWrap)
    local region = element and element.textRegion or nil
    if not region then
        return
    end

    if region.SetMaxLines then
        region:SetMaxLines(maxLines)
    end
    if region.SetWordWrap then
        region:SetWordWrap(wordWrap == true)
    end
end

function AchievementEntry:New(options)
    local instance = BaseElement.New(self, options)
    instance.options.border = false
    instance.cardBackground = nil
    instance.iconFrame = nil
    instance.iconElement = nil
    instance.iconTexture = nil
    instance.nameElement = nil
    instance.descriptionElement = nil
    instance.progressBar = nil
    instance.criterionElement = nil
    instance.completionElement = nil
    instance.rewardElement = nil
    instance.iconBorderTop = nil
    instance.iconBorderBottom = nil
    instance.iconBorderLeft = nil
    instance.iconBorderRight = nil
    instance.hoverTexture = nil
    instance.onClick = nil
    instance.completed = false
    return instance
end

function AchievementEntry:SetIcon(texturePath)
    local texture = texturePath or DEFAULT_ICON
    if self.iconElement and self.iconElement.SetTexture then
        self.iconElement:SetTexture(texture)
    elseif self.iconTexture and self.iconTexture.SetTexture then
        self.iconTexture:SetTexture(texture)
    end

    return texture
end

function AchievementEntry:SetAchievementName(name)
    local value = tostring(name or "")
    if self.nameElement and self.nameElement.SetText then
        self.nameElement:SetText(value)
    end

    return value
end

function AchievementEntry:SetDescription(description)
    local value = tostring(description or "")
    if self.descriptionElement and self.descriptionElement.SetText then
        self.descriptionElement:SetText(value)
    end

    return value
end

function AchievementEntry:SetProgressPresentation(presentation)
    local progress = type(presentation) == "table" and presentation or {}
    local kind = progress.kind

    if self.progressBar then
        if kind == "bar" then
            local goal = math.max(1, math.floor(tonumber(progress.goal) or 1))
            local current = math.max(0, math.floor(tonumber(progress.current) or 0))
            self.progressBar:SetMinMax(0, goal)
            self.progressBar:SetValue(current)
            self.progressBar:SetText(tostring(progress.text or ("%d / %d"):format(current, goal)))
            showElement(self.progressBar, true)
        else
            showElement(self.progressBar, false)
        end
    end

    if self.criterionElement then
        if kind == "summary" then
            self.criterionElement:SetText(tostring(progress.text or ""))
            showElement(self.criterionElement, true)
        else
            self.criterionElement:SetText("")
            showElement(self.criterionElement, false)
        end
    end
end

function AchievementEntry:SetCompletionDate(completionDate, completed)
    if not self.completionElement then
        return
    end

    if completed and tostring(completionDate or "") ~= "" then
        self.completionElement:SetText("Completed: " .. tostring(completionDate))
    elseif completed then
        self.completionElement:SetText("Completed")
    else
        self.completionElement:SetText("Incomplete")
    end
end

function AchievementEntry:SetRewardStatus(status)
    if self.rewardElement then
        self.rewardElement:SetText(tostring(status or ""))
    end
end

function AchievementEntry:SetOnClick(handler)
    self.onClick = type(handler) == "function" and handler or nil
    if self.frame and self.frame.SetScript then
        self.frame:SetScript("OnMouseUp", function(_, button)
            if self.onClick then
                self.onClick(self, button)
            end
        end)
    end
end

function AchievementEntry:SetCompleted(completed)
    self.completed = completed == true

    local background = self.completed
        and UI.ResolveColor(nil, "panel.background")
        or UI.ResolveColor(nil, "list.rowBackground")
    local border = self.completed
        and UI.ResolveColor(nil, "warning")
        or UI.ResolveColor(nil, "panel.border")
    local nameColor = self.completed
        and UI.ResolveColor(nil, "warning")
        or UI.ResolveColor(nil, "text.primary")
    local descriptionColor = UI.ResolveColor(nil, "text.secondary")
    local statusColor = self.completed
        and UI.ResolveColor(nil, "warning")
        or UI.ResolveColor(nil, "text.muted")

    if self.cardBackground and self.cardBackground.SetColorTexture then
        self.cardBackground:SetColorTexture(background.r or 0, background.g or 0, background.b or 0, background.a or 1)
    end
    if self.frame then
        self:ApplyThinBorder(self.frame, { borderColor = border, borderSize = 1 })
    end

    setTextColor(self.nameElement, nameColor)
    setTextColor(self.descriptionElement, descriptionColor)
    setTextColor(self.criterionElement, descriptionColor)
    setTextColor(self.completionElement, statusColor)
    setTextColor(self.rewardElement, statusColor)

    if self.iconTexture then
        if self.iconTexture.SetDesaturated then
            self.iconTexture:SetDesaturated(not self.completed)
        end
        if self.iconTexture.SetVertexColor then
            local brightness = self.completed and 1 or 0.72
            self.iconTexture:SetVertexColor(brightness, brightness, brightness, 1)
        end
    end
end

function AchievementEntry:SetAchievementData(data)
    local value = type(data) == "table" and data or {}
    if self.hoverTexture then
        self.hoverTexture:Hide()
    end
    self:SetIcon(value.icon)
    self:SetAchievementName(value.name)
    self:SetDescription(value.description)
    self:SetProgressPresentation(value.progress)
    self:SetCompletionDate(value.completionDate, value.completed == true)
    self:SetRewardStatus(value.rewardStatus)
    self:SetCompleted(value.completed == true)
end

function AchievementEntry:SetLayoutMetrics(width, height)
    local resolvedWidth = math.max(1, tonumber(width) or self.options.width or DEFAULT_WIDTH)
    local resolvedHeight = math.max(1, tonumber(height) or self.options.height or DEFAULT_HEIGHT)
    local padding = math.max(2, tonumber(self.options.padding) or DEFAULT_PADDING)
    local iconGap = math.max(2, tonumber(self.options.iconGap) or DEFAULT_ICON_GAP)
    local iconSize = math.max(1, math.min(
        tonumber(self.options.iconSize) or DEFAULT_ICON_SIZE,
        resolvedHeight - (padding * 2)
    ))
    local contentLeft = padding + iconSize + iconGap
    local contentWidth = math.max(1, resolvedWidth - contentLeft - padding)
    local nameHeight = tonumber(self.options.nameHeight) or DEFAULT_NAME_HEIGHT
    local descriptionHeight = tonumber(self.options.descriptionHeight) or DEFAULT_DESCRIPTION_HEIGHT
    local progressHeight = tonumber(self.options.progressHeight) or DEFAULT_PROGRESS_HEIGHT
    local statusHeight = tonumber(self.options.statusHeight) or DEFAULT_STATUS_HEIGHT
    local spacing = tonumber(self.options.spacing) or DEFAULT_SPACING
    local statusWidth = math.max(1, math.floor(contentWidth * 0.48))
    local rewardWidth = math.max(1, contentWidth - statusWidth - spacing)
    local contentTop = padding
    local descriptionTop = contentTop + nameHeight + spacing
    local progressTop = descriptionTop + descriptionHeight + spacing
    local statusTop = progressTop + progressHeight + spacing

    self.options.width = resolvedWidth
    self.options.height = resolvedHeight

    if self.frame and self.frame.SetSize then
        self.frame:SetSize(resolvedWidth, resolvedHeight)
    end
    if self.iconFrame then
        self.iconFrame:ClearAllPoints()
        self.iconFrame:SetPoint("TOPLEFT", self.frame, "TOPLEFT", padding, -padding)
        self.iconFrame:SetSize(iconSize, iconSize)
    end

    local nameFrame = self.nameElement and self.nameElement:GetFrame() or nil
    if nameFrame then
        nameFrame:ClearAllPoints()
        nameFrame:SetPoint("TOPLEFT", self.frame, "TOPLEFT", contentLeft, -contentTop)
        self.nameElement:SetSize(contentWidth, nameHeight)
    end

    local descriptionFrame = self.descriptionElement and self.descriptionElement:GetFrame() or nil
    if descriptionFrame then
        descriptionFrame:ClearAllPoints()
        descriptionFrame:SetPoint("TOPLEFT", self.frame, "TOPLEFT", contentLeft, -descriptionTop)
        self.descriptionElement:SetSize(contentWidth, descriptionHeight)
    end

    local progressFrame = self.progressBar and self.progressBar:GetFrame() or nil
    if progressFrame then
        progressFrame:ClearAllPoints()
        progressFrame:SetPoint("TOPLEFT", self.frame, "TOPLEFT", contentLeft, -progressTop)
        self.progressBar:SetSize(contentWidth, progressHeight)
    end

    local criterionFrame = self.criterionElement and self.criterionElement:GetFrame() or nil
    if criterionFrame then
        criterionFrame:ClearAllPoints()
        criterionFrame:SetPoint("TOPLEFT", self.frame, "TOPLEFT", contentLeft, -progressTop)
        self.criterionElement:SetSize(contentWidth, progressHeight)
    end

    local completionFrame = self.completionElement and self.completionElement:GetFrame() or nil
    if completionFrame then
        completionFrame:ClearAllPoints()
        completionFrame:SetPoint("TOPLEFT", self.frame, "TOPLEFT", contentLeft, -statusTop)
        self.completionElement:SetSize(statusWidth, statusHeight)
    end

    local rewardFrame = self.rewardElement and self.rewardElement:GetFrame() or nil
    if rewardFrame then
        rewardFrame:ClearAllPoints()
        rewardFrame:SetPoint("TOPLEFT", self.frame, "TOPLEFT", contentLeft + statusWidth + spacing, -statusTop)
        self.rewardElement:SetSize(rewardWidth, statusHeight)
    end

    return resolvedWidth, resolvedHeight
end

function AchievementEntry:Create()
    if self.frame then
        return self.frame
    end

    local parentFrame = self:GetParentFrame()
    if not parentFrame then
        error("An achievement entry prefab requires a parent frame before Create().", 2)
    end

    local width = tonumber(self.options.width) or DEFAULT_WIDTH
    local height = tonumber(self.options.height) or DEFAULT_HEIGHT
    local fontFile = self.options.fontFile or (Constants.FontFiles and Constants.FontFiles.Default)
    local frame = CreateFrame("Frame", self.name, parentFrame, self.options.template)
    self:SetFrame(frame)
    frame:EnableMouse(true)
    if frame.SetClipsChildren then
        frame:SetClipsChildren(true)
    end

    self.cardBackground = frame:CreateTexture(nil, "BACKGROUND")
    self.cardBackground:SetAllPoints(frame)

    self.hoverTexture = frame:CreateTexture(nil, "ARTWORK")
    self.hoverTexture:SetAllPoints(frame)
    self.hoverTexture:SetColorTexture(1, 1, 1, 0.04)
    self.hoverTexture:Hide()

    self.iconFrame = CreateFrame("Frame", (self.name or "AchievementEntry") .. "IconFrame", frame)
    local iconSize = tonumber(self.options.iconSize) or DEFAULT_ICON_SIZE
    self.iconFrame:SetSize(iconSize, iconSize)
    local iconBorderSize = tonumber(self.options.iconBorderSize) or 1
    local iconBorderColor = UI.ResolveColor(nil, "panel.border")
    self.iconBorderTop = createBorderTexture(self.iconFrame, "TOPLEFT", "TOPRIGHT", iconBorderSize, false)
    self.iconBorderBottom = createBorderTexture(self.iconFrame, "BOTTOMLEFT", "BOTTOMRIGHT", iconBorderSize, false)
    self.iconBorderLeft = createBorderTexture(self.iconFrame, "TOPLEFT", "BOTTOMLEFT", iconBorderSize, true)
    self.iconBorderRight = createBorderTexture(self.iconFrame, "TOPRIGHT", "BOTTOMRIGHT", iconBorderSize, true)
    applyBorderColor(self.iconBorderTop, iconBorderColor)
    applyBorderColor(self.iconBorderBottom, iconBorderColor)
    applyBorderColor(self.iconBorderLeft, iconBorderColor)
    applyBorderColor(self.iconBorderRight, iconBorderColor)

    self.iconElement = Image:New({
        name = (self.name or "AchievementEntry") .. "Icon",
        width = iconSize,
        height = iconSize,
        border = false,
        texture = DEFAULT_ICON,
        textureInsetLeft = 1,
        textureInsetTop = 1,
        textureInsetRight = 1,
        textureInsetBottom = 1,
        texCoord = {
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
        name = (self.name or "AchievementEntry") .. "Name",
        width = width,
        height = DEFAULT_NAME_HEIGHT,
        text = "",
        fontFile = fontFile,
        fontSize = (Constants.FontSizes and Constants.FontSizes.Heading2) or 10,
        textColor = UI.ResolveColor(nil, "text.primary"),
        justifyH = "LEFT",
        justifyV = "TOP",
        wordWrap = false,
        border = false,
        textInsetLeft = 0,
        textInsetTop = 0,
        textInsetRight = 0,
        textInsetBottom = 0,
    })
    self.nameElement:SetParent(frame)
    self.nameElement:Create()
    setTextMaxLines(self.nameElement, 1, false)

    self.descriptionElement = Text:New({
        name = (self.name or "AchievementEntry") .. "Description",
        width = width,
        height = DEFAULT_DESCRIPTION_HEIGHT,
        text = "",
        fontFile = fontFile,
        fontSize = (Constants.FontSizes and Constants.FontSizes.Body) or 8,
        textColor = UI.ResolveColor(nil, "text.secondary"),
        justifyH = "LEFT",
        justifyV = "TOP",
        wordWrap = true,
        border = false,
        textInsetLeft = 0,
        textInsetTop = 0,
        textInsetRight = 0,
        textInsetBottom = 0,
    })
    self.descriptionElement:SetParent(frame)
    self.descriptionElement:Create()
    setTextMaxLines(self.descriptionElement, 2, true)

    self.progressBar = ProgressBar:New({
        name = (self.name or "AchievementEntry") .. "Progress",
        width = width,
        height = DEFAULT_PROGRESS_HEIGHT,
        border = false,
        minValue = 0,
        maxValue = 1,
        value = 0,
        text = "",
        textColor = UI.ResolveColor(nil, "progress.text"),
        primaryColor = UI.ResolveColor(nil, "progress.barPrimary"),
    })
    self.progressBar:SetParent(frame)
    self.progressBar:Create()
    showElement(self.progressBar, false)

    self.criterionElement = Text:New({
        name = (self.name or "AchievementEntry") .. "CriterionSummary",
        width = width,
        height = DEFAULT_PROGRESS_HEIGHT,
        text = "",
        fontFile = fontFile,
        fontSize = (Constants.FontSizes and Constants.FontSizes.Body) or 8,
        textColor = UI.ResolveColor(nil, "text.secondary"),
        justifyH = "LEFT",
        justifyV = "MIDDLE",
        wordWrap = false,
        border = false,
        textInsetLeft = 0,
        textInsetTop = 0,
        textInsetRight = 0,
        textInsetBottom = 0,
    })
    self.criterionElement:SetParent(frame)
    self.criterionElement:Create()
    setTextMaxLines(self.criterionElement, 1, false)
    showElement(self.criterionElement, false)

    self.completionElement = Text:New({
        name = (self.name or "AchievementEntry") .. "Completion",
        width = width,
        height = DEFAULT_STATUS_HEIGHT,
        text = "",
        fontFile = fontFile,
        fontSize = (Constants.FontSizes and Constants.FontSizes.Small) or 6,
        textColor = UI.ResolveColor(nil, "text.muted"),
        justifyH = "LEFT",
        justifyV = "MIDDLE",
        wordWrap = false,
        border = false,
        textInsetLeft = 0,
        textInsetTop = 0,
        textInsetRight = 0,
        textInsetBottom = 0,
    })
    self.completionElement:SetParent(frame)
    self.completionElement:Create()
    setTextMaxLines(self.completionElement, 1, false)

    self.rewardElement = Text:New({
        name = (self.name or "AchievementEntry") .. "RewardStatus",
        width = width,
        height = DEFAULT_STATUS_HEIGHT,
        text = "",
        fontFile = fontFile,
        fontSize = (Constants.FontSizes and Constants.FontSizes.Small) or 6,
        textColor = UI.ResolveColor(nil, "text.muted"),
        justifyH = "RIGHT",
        justifyV = "MIDDLE",
        wordWrap = false,
        border = false,
        textInsetLeft = 0,
        textInsetTop = 0,
        textInsetRight = 0,
        textInsetBottom = 0,
    })
    self.rewardElement:SetParent(frame)
    self.rewardElement:Create()
    setTextMaxLines(self.rewardElement, 1, false)

    frame:HookScript("OnEnter", function()
        if self.hoverTexture then
            self.hoverTexture:Show()
        end
    end)
    frame:HookScript("OnLeave", function()
        if self.hoverTexture then
            self.hoverTexture:Hide()
        end
    end)
    frame:SetScript("OnMouseUp", function(_, button)
        if self.onClick then
            self.onClick(self, button)
        end
    end)
    frame:SetScript("OnSizeChanged", function(_, newWidth, newHeight)
        if not self._layoutRefreshing then
            self._layoutRefreshing = true
            self:SetLayoutMetrics(newWidth, newHeight)
            self._layoutRefreshing = false
        end
    end)

    self:SetLayoutMetrics(width, height)
    self:SetAchievementData(nil)
    return self.frame
end

return AchievementEntry
