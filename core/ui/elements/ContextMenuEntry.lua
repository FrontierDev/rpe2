local _, Addon = ...

local UI = Addon.UI or {}
Addon.UI = UI
local ButtonBase = UI.ButtonBase
local Constants = UI.Constants or {}
local Font = UI.Font or {}

UI.ContextMenuEntry = UI.ContextMenuEntry or {}
local ContextMenuEntry = UI.ContextMenuEntry
ContextMenuEntry.__index = ContextMenuEntry
setmetatable(ContextMenuEntry, { __index = ButtonBase })

function ContextMenuEntry:New(options)
    local instance = ButtonBase.New(self, options)
    instance.options.suppressHighlight = true
    instance.item = nil
    instance.ownerMenu = nil
    instance.depth = 1
    instance.absoluteIndex = 0
    instance.highlighted = false
    instance.selected = false
    instance.selectionHighlighted = false
    instance.iconTexture = nil
    instance.iconPath = nil
    instance.label = nil
    instance.checkRegion = nil
    instance.arrowRegion = nil
    instance.background = nil
    return instance
end

function ContextMenuEntry:SetHighlighted(isHighlighted)
    self.highlighted = isHighlighted == true
    self:RefreshVisualState()
end

function ContextMenuEntry:SetSelected(isSelected)
    self.selected = isSelected == true
    self:RefreshVisualState()
end

function ContextMenuEntry:SetSelectionHighlighted(isHighlighted)
    self.selectionHighlighted = isHighlighted == true
    self:RefreshVisualState()
end

function ContextMenuEntry:SetItem(item, ownerMenu, depth, absoluteIndex)
    self.item = item
    self.ownerMenu = ownerMenu
    self.depth = depth or 1
    self.absoluteIndex = absoluteIndex or 0

    local frame = self:GetFrame()
    if frame then
        if item then
            frame:Show()
            frame:EnableMouse(item.enabled ~= false)
        else
            frame:Hide()
            return
        end
    end

    if self.label and self.label.SetText then
        self.label:SetText(item.label or "")
    end

    if self.iconTexture then
        if item.icon then
            self.iconPath = item.icon
            self.iconTexture:SetTexture(item.icon)
            if item.iconCoords and self.iconTexture.SetTexCoord then
                local coords = item.iconCoords
                self.iconTexture:SetTexCoord(
                    coords.left or coords[1] or 0,
                    coords.right or coords[2] or 1,
                    coords.top or coords[3] or 0,
                    coords.bottom or coords[4] or 1
                )
            elseif self.iconTexture.SetTexCoord then
                self.iconTexture:SetTexCoord(0, 1, 0, 1)
            end

            self.iconTexture:Show()
        else
            self.iconPath = nil
            self.iconTexture:SetTexture(nil)
            self.iconTexture:Hide()
        end
    end

    if self.checkRegion and self.checkRegion.SetText then
        self.checkRegion:SetText("")
    end

    if self.arrowRegion and self.arrowRegion.SetText then
        self.arrowRegion:SetText(item.hasArrow and ">" or "")
    end

    if item.tooltipTitle or item.tooltipText then
        self:SetTooltip({
            type = item.tooltipType or "custom",
            title = item.tooltipTitle or item.label or "",
            text = item.tooltipText or "",
            lines = item.tooltipLines,
        })
    else
        self:SetTooltip(nil)
    end

    self:RefreshVisualState()
end

function ContextMenuEntry:RefreshVisualState()
    local item = self.item
    if not item then
        return
    end

    local backgroundToken = self.highlighted and "list.rowHover" or "list.rowBackground"
    local backgroundColor = UI.ResolveColor(nil, backgroundToken)
    if self.background and self.background.SetColorTexture then
        self.background:SetColorTexture(
            backgroundColor.r or 0.08,
            backgroundColor.g or 0.09,
            backgroundColor.b or 0.11,
            backgroundColor.a or 0.9
        )
    end

    local textToken = "text.primary"
    if item.enabled == false then
        textToken = "text.muted"
    elseif self.selectionHighlighted then
        textToken = "dropdown.selectedText"
    end

    local textColor = UI.ResolveColor(nil, textToken)
    if self.label and self.label.SetTextColor then
        self.label:SetTextColor(textColor.r or 1, textColor.g or 1, textColor.b or 1, textColor.a or 1)
    end

    local iconColor = UI.ResolveColor(nil, item.enabled == false and "text.muted" or "dropdown.categoryIcon")
    if self.iconTexture and self.iconTexture.SetVertexColor then
        self.iconTexture:SetVertexColor(iconColor.r or 1, iconColor.g or 1, iconColor.b or 1, iconColor.a or 1)
    end

    local accessoryToken = item.enabled == false and "text.muted" or (self.selectionHighlighted and "dropdown.selectedText" or "text.secondary")
    local accessoryColor = UI.ResolveColor(nil, accessoryToken)

    if self.checkRegion and self.checkRegion.SetText then
        self.checkRegion:SetText("")
        self.checkRegion:SetTextColor(accessoryColor.r or 1, accessoryColor.g or 1, accessoryColor.b or 1, accessoryColor.a or 1)
    end

    if self.arrowRegion and self.arrowRegion.SetTextColor then
        self.arrowRegion:SetTextColor(accessoryColor.r or 1, accessoryColor.g or 1, accessoryColor.b or 1, accessoryColor.a or 1)
    end

    local frame = self:GetFrame()
    if frame and frame.SetAlpha then
        frame:SetAlpha(item.enabled == false and 0.55 or 1)
    end
end

function ContextMenuEntry:Create()
    if self.frame then
        return self.frame
    end

    local frame = self:CreateButton(self.options.template)

    self.background = frame:CreateTexture(nil, "BACKGROUND")
    self.background:SetAllPoints(frame)

    self.iconTexture = frame:CreateTexture(nil, "ARTWORK")
    self.iconTexture:SetSize(self.options.iconSize or 12, self.options.iconSize or 12)
    self.iconTexture:SetPoint("LEFT", frame, "LEFT", self.options.iconInsetLeft or 6, 0)
    self.iconTexture:Hide()

    self.label = frame:CreateFontString(nil, "OVERLAY")
    self.label:SetPoint("LEFT", self.iconTexture, "RIGHT", self.options.labelInsetLeft or 6, 0)
    self.label:SetPoint("RIGHT", frame, "RIGHT", -(self.options.arrowInsetRight or 16), 0)
    self.label:SetJustifyH("LEFT")
    self.label:SetJustifyV("MIDDLE")
    Font:Apply(self.label, self.options, {
        fontSize = (Constants.FontSizes and Constants.FontSizes.Dropdown) or 8,
    })

    self.checkRegion = frame:CreateFontString(nil, "OVERLAY")
    self.checkRegion:SetPoint("RIGHT", frame, "RIGHT", -(self.options.checkInsetRight or 20), 0)
    self.checkRegion:SetJustifyH("CENTER")
    self.checkRegion:SetJustifyV("MIDDLE")
    Font:Apply(self.checkRegion, self.options, {
        fontSize = (Constants.FontSizes and Constants.FontSizes.Dropdown) or 8,
    })

    self.arrowRegion = frame:CreateFontString(nil, "OVERLAY")
    self.arrowRegion:SetPoint("RIGHT", frame, "RIGHT", -(self.options.arrowInsetRight or 8), 0)
    self.arrowRegion:SetJustifyH("RIGHT")
    self.arrowRegion:SetJustifyV("MIDDLE")
    Font:Apply(self.arrowRegion, self.options, {
        fontSize = (Constants.FontSizes and Constants.FontSizes.DropdownArrow) or 10,
    })

    frame:SetScript("OnEnter", function()
        self.highlighted = true
        self:RefreshVisualState()

        if self.ownerMenu and self.ownerMenu.HandleItemHover and self.item then
            self.ownerMenu:HandleItemHover(self.depth, self.item)
        end

        if self:GetTooltip() then
            self:ShowTooltip()
        end
    end)

    frame:SetScript("OnLeave", function()
        if self.ownerMenu then
            self.ownerMenu.hoveredItem = nil
            self.ownerMenu.hoveredDepth = nil
        end
        self.highlighted = self.ownerMenu and self.ownerMenu.activePath and self.ownerMenu.activePath[self.depth] == self.item or false
        self:RefreshVisualState()
        self:HideTooltip()
    end)

    frame:SetScript("OnClick", function()
        if self.ownerMenu and self.ownerMenu.HandleItemClick and self.item then
            self.ownerMenu:HandleItemClick(self.depth, self.item)
        end
    end)

    if self.item then
        self:SetItem(self.item, self.ownerMenu, self.depth, self.absoluteIndex)
    else
        self:RefreshVisualState()
    end

    return self.frame
end
