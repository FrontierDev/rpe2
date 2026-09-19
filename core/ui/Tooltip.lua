local _, Addon = ...

local UI = Addon.UI or {}
Addon.UI = UI
local Constants = UI.Constants or {}
local Font = UI.Font or {}

UI.Tooltip = UI.Tooltip or {}
local Tooltip = UI.Tooltip

local function ResolveTooltipSpec(owner, spec)
    local resolvedSpec = spec
    if type(resolvedSpec) == "function" then
        resolvedSpec = resolvedSpec(owner)
    end

    if type(resolvedSpec) == "string" then
        resolvedSpec = {
            text = resolvedSpec,
        }
    end

    if type(resolvedSpec) == "table" and resolvedSpec.type == nil then
        resolvedSpec.type = "custom"
    end

    return resolvedSpec
end

local function ResolveOwnerFrame(owner)
    if not owner then
        return UIParent or WorldFrame
    end

    if owner.GetFrame then
        return owner:GetFrame() or owner.frame or (UIParent or WorldFrame)
    end

    if owner.frame then
        return owner.frame
    end

    return owner
end

local function IsSameOwner(left, right)
    return ResolveOwnerFrame(left) == ResolveOwnerFrame(right)
end

local function GetBodyLines(spec)
    local lines = {}

    if spec.lines then
        for index = 1, #spec.lines do
            local line = spec.lines[index]
            if type(line) == "table" then
                local text = line.text
                if (text == nil or text == "") and (line.left ~= nil or line.right ~= nil) then
                    local left = tostring(line.left or "")
                    local right = tostring(line.right or "")
                    if left ~= "" and right ~= "" then
                        text = ("%s  %s"):format(left, right)
                    else
                        text = left ~= "" and left or right
                    end
                end

                if text ~= nil and text ~= "" then
                    lines[#lines + 1] = tostring(text)
                end
            elseif line ~= nil and line ~= "" then
                lines[#lines + 1] = tostring(line)
            end
        end
    end

    if spec.text and spec.text ~= "" then
        lines[#lines + 1] = tostring(spec.text)
    end

    if spec.description and spec.description ~= "" then
        lines[#lines + 1] = tostring(spec.description)
    end

    return lines
end

local function GetBodyEntries(spec)
    local entries = {}

    if spec.lines then
        for index = 1, #spec.lines do
            local line = spec.lines[index]
            if type(line) == "table" then
                entries[#entries + 1] = {
                    text = line.text ~= nil and tostring(line.text) or nil,
                    left = line.left ~= nil and tostring(line.left) or nil,
                    right = line.right ~= nil and tostring(line.right) or nil,
                    icon = line.icon ~= nil and tostring(line.icon) or nil,
                    justifyH = line.justifyH ~= nil and tostring(line.justifyH) or nil,
                    colorToken = line.colorToken,
                    rightColorToken = line.rightColorToken,
                    r = line.r,
                    g = line.g,
                    b = line.b,
                    a = line.a,
                    rightR = line.rightR,
                    rightG = line.rightG,
                    rightB = line.rightB,
                    rightA = line.rightA,
                }
            elseif line ~= nil and line ~= "" then
                entries[#entries + 1] = {
                    text = tostring(line),
                }
            end
        end
    end

    if spec.text and spec.text ~= "" then
        entries[#entries + 1] = {
            text = tostring(spec.text),
        }
    end

    if spec.description and spec.description ~= "" then
        entries[#entries + 1] = {
            text = tostring(spec.description),
        }
    end

    return entries
end

local function EnsureBodyRow(frame, index)
    frame.bodyRows = frame.bodyRows or {}
    local row = frame.bodyRows[index]
    if row then
        return row
    end

    row = CreateFrame("Frame", nil, frame)
    row.icon = row:CreateTexture(nil, "ARTWORK")
    row.icon:SetSize(14, 14)

    row.leftText = row:CreateFontString(nil, "OVERLAY")
    row.leftText:SetJustifyH("LEFT")
    row.leftText:SetJustifyV("MIDDLE")
    row.leftText:SetWordWrap(true)
    Font:Apply(row.leftText, {
        fontFile = UI.Constants and UI.Constants.FontFiles and UI.Constants.FontFiles.Default,
    }, {
        fontSize = (Constants.FontSizes and Constants.FontSizes.ScrollDetail) or 8,
    })

    row.rightText = row:CreateFontString(nil, "OVERLAY")
    row.rightText:SetJustifyH("RIGHT")
    row.rightText:SetJustifyV("MIDDLE")
    row.rightText:SetWordWrap(false)
    Font:Apply(row.rightText, {
        fontFile = UI.Constants and UI.Constants.FontFiles and UI.Constants.FontFiles.Default,
    }, {
        fontSize = (Constants.FontSizes and Constants.FontSizes.ScrollDetail) or 8,
    })

    local bodyColor = UI.ResolveColor(nil, "text.secondary")
    if row.leftText.SetTextColor then
        row.leftText:SetTextColor(bodyColor.r or 0.8, bodyColor.g or 0.8, bodyColor.b or 0.8, bodyColor.a or 1)
    end
    if row.rightText.SetTextColor then
        row.rightText:SetTextColor(bodyColor.r or 0.8, bodyColor.g or 0.8, bodyColor.b or 0.8, bodyColor.a or 1)
    end

    frame.bodyRows[index] = row
    return row
end

local function HideBodyRows(frame)
    for index = 1, #((frame and frame.bodyRows) or {}) do
        local row = frame.bodyRows[index]
        if row and row.Hide then
            row:Hide()
        end
    end
end

function Tooltip:EnsureCustomTooltip()
    if self.customTooltip then
        return self.customTooltip
    end

    local parent = UIParent or WorldFrame
    local frame = CreateFrame("Frame", "RPEngineCustomTooltip", parent, "BackdropTemplate")
    frame:SetFrameStrata("TOOLTIP")
    if frame.SetToplevel then
        frame:SetToplevel(true)
    end
    if frame.SetFrameLevel then
        frame:SetFrameLevel(10000)
    end
    frame:SetClampedToScreen(true)
    if frame.EnableMouse then
        frame:EnableMouse(false)
    end
    frame:Hide()
    if frame.SetBackdrop then
        frame:SetBackdrop({
            bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = false,
            tileSize = 0,
            edgeSize = 12,
            insets = { left = 3, right = 3, top = 3, bottom = 3 },
        })
    end

    local bg = UI.ResolveColor(nil, "tooltip.background", { r = 0.05, g = 0.06, b = 0.08, a = 0.96 })
    if frame.SetBackdropColor then
        frame:SetBackdropColor(bg.r or 0.05, bg.g or 0.06, bg.b or 0.08, bg.a or 0.96)
    end

    if frame.SetBackdropBorderColor then
        local border = UI.ResolveColor(nil, "tooltip.border", { r = 0.18, g = 0.2, b = 0.24, a = 1 })
        frame:SetBackdropBorderColor(border.r or 0.18, border.g or 0.2, border.b or 0.24, border.a or 1)
    end

    frame.titleRegion = frame:CreateFontString(nil, "OVERLAY")
    frame.titleRegion:SetPoint("TOPLEFT", frame, "TOPLEFT", 8, -8)
    frame.titleRegion:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -8, -8)
    Font:Apply(frame.titleRegion, {
        fontFile = UI.Constants and UI.Constants.FontFiles and UI.Constants.FontFiles.Default,
    }, {
        fontSize = (Constants.FontSizes and Constants.FontSizes.ScrollStatus) or 10,
    })
    if frame.titleRegion.SetTextColor then
        local titleColor = UI.ResolveColor(nil, "text.primary")
        frame.titleRegion:SetTextColor(titleColor.r or 1, titleColor.g or 1, titleColor.b or 1, titleColor.a or 1)
    end

    frame.titleRightRegion = frame:CreateFontString(nil, "OVERLAY")
    frame.titleRightRegion:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -8, -8)
    frame.titleRightRegion:SetJustifyH("RIGHT")
    frame.titleRightRegion:SetJustifyV("TOP")
    frame.titleRightRegion:SetWordWrap(false)
    Font:Apply(frame.titleRightRegion, {
        fontFile = UI.Constants and UI.Constants.FontFiles and UI.Constants.FontFiles.Default,
    }, {
        fontSize = (Constants.FontSizes and Constants.FontSizes.ScrollDetail) or 8,
    })
    if frame.titleRightRegion.SetTextColor then
        local titleRightColor = UI.ResolveColor(nil, "text.secondary")
        frame.titleRightRegion:SetTextColor(titleRightColor.r or 0.8, titleRightColor.g or 0.8, titleRightColor.b or 0.8, titleRightColor.a or 1)
    end

    frame.bodyRegion = frame:CreateFontString(nil, "OVERLAY")
    frame.bodyRegion:SetPoint("TOPLEFT", frame.titleRegion, "BOTTOMLEFT", 0, -4)
    frame.bodyRegion:SetPoint("TOPRIGHT", frame.titleRegion, "BOTTOMRIGHT", 0, 0)
    frame.bodyRegion:SetJustifyH("LEFT")
    frame.bodyRegion:SetJustifyV("TOP")
    frame.bodyRegion:SetWordWrap(true)
    Font:Apply(frame.bodyRegion, {
        fontFile = UI.Constants and UI.Constants.FontFiles and UI.Constants.FontFiles.Default,
    }, {
        fontSize = (Constants.FontSizes and Constants.FontSizes.ScrollDetail) or 8,
    })
    if frame.bodyRegion.SetTextColor then
        local bodyColor = UI.ResolveColor(nil, "text.secondary")
        frame.bodyRegion:SetTextColor(bodyColor.r or 0.8, bodyColor.g or 0.8, bodyColor.b or 0.8, bodyColor.a or 1)
    end

    self.customTooltip = frame
    return self.customTooltip
end

function Tooltip:ShowCustomTooltip(owner, spec, resolvedSpec)
    local tooltip = self:EnsureCustomTooltip()
    local ownerFrame = ResolveOwnerFrame(owner)
    local rawSpec = spec or {}
    spec = resolvedSpec or ResolveTooltipSpec(owner, rawSpec)
    if type(spec) ~= "table" then
        return nil
    end
    self.activeGameTooltip = false
    self.currentOwnerFrame = ownerFrame
    self.currentSpec = rawSpec
    self.currentMode = "custom"

    local width = math.max(180, tonumber(spec.width) or 240)
    local title = spec.title or spec.header or ""
    local lines = GetBodyLines(spec)
    local entries = GetBodyEntries(spec)
    local titleColor = spec.titleColor or UI.ResolveColor(nil, "text.primary")
    local titleJustifyH = tostring(spec.titleJustifyH or "LEFT"):upper()
    local titleRight = tostring(spec.titleRight or "")
    local titleRightColor = spec.titleRightColor or UI.ResolveColor(nil, "text.secondary")

    if tooltip.titleRegion and tooltip.titleRegion.SetText then
        tooltip.titleRegion:SetText(title)
    end
    if tooltip.titleRegion and tooltip.titleRegion.SetJustifyH then
        tooltip.titleRegion:SetJustifyH(titleJustifyH)
    end
    if tooltip.titleRegion then
        Font:Apply(tooltip.titleRegion, {
            fontFile = UI.Constants and UI.Constants.FontFiles and UI.Constants.FontFiles.Default,
            fontSize = tonumber(spec.titleFontSize) or (Constants.FontSizes and Constants.FontSizes.ScrollStatus) or 10,
            fontFlags = spec.titleFontFlags,
        }, {
            fontSize = (Constants.FontSizes and Constants.FontSizes.ScrollStatus) or 10,
        })
    end

    if tooltip.titleRightRegion then
        tooltip.titleRightRegion:ClearAllPoints()
        tooltip.titleRightRegion:SetPoint("TOPRIGHT", tooltip, "TOPRIGHT", -8, -8)
        Font:Apply(tooltip.titleRightRegion, {
            fontFile = UI.Constants and UI.Constants.FontFiles and UI.Constants.FontFiles.Default,
            fontSize = tonumber(spec.titleRightFontSize) or (Constants.FontSizes and Constants.FontSizes.ScrollDetail) or 8,
            fontFlags = spec.titleRightFontFlags,
        }, {
            fontSize = (Constants.FontSizes and Constants.FontSizes.ScrollDetail) or 8,
        })
        if titleRight ~= "" then
            tooltip.titleRightRegion:SetText(titleRight)
            if tooltip.titleRightRegion.SetTextColor then
                tooltip.titleRightRegion:SetTextColor(
                    titleRightColor.r or titleRightColor[1] or 0.8,
                    titleRightColor.g or titleRightColor[2] or 0.8,
                    titleRightColor.b or titleRightColor[3] or 0.8,
                    titleRightColor.a or titleRightColor[4] or 1
                )
            end
            tooltip.titleRightRegion:Show()
        else
            tooltip.titleRightRegion:SetText("")
            tooltip.titleRightRegion:Hide()
        end
    end

    if tooltip.titleRegion and tooltip.titleRegion.SetTextColor then
        tooltip.titleRegion:SetTextColor(
            titleColor.r or titleColor[1] or 1,
            titleColor.g or titleColor[2] or 1,
            titleColor.b or titleColor[3] or 1,
            titleColor.a or titleColor[4] or 1
        )
    end

    if tooltip.titleRegion then
        tooltip.titleRegion:ClearAllPoints()
        tooltip.titleRegion:SetPoint("TOPLEFT", tooltip, "TOPLEFT", 8, -8)
        if titleRight ~= "" and tooltip.titleRightRegion then
            tooltip.titleRegion:SetPoint("TOPRIGHT", tooltip.titleRightRegion, "TOPLEFT", -8, 0)
        else
            tooltip.titleRegion:SetPoint("TOPRIGHT", tooltip, "TOPRIGHT", -8, -8)
        end
    end

    local titleHeight = tooltip.titleRegion and tooltip.titleRegion.GetStringHeight and tooltip.titleRegion:GetStringHeight() or 0
    local titleRightHeight = tooltip.titleRightRegion and tooltip.titleRightRegion.IsShown and tooltip.titleRightRegion:IsShown() and tooltip.titleRightRegion.GetStringHeight and tooltip.titleRightRegion:GetStringHeight() or 0
    titleHeight = math.max(titleHeight, titleRightHeight)
    local bodyHeight = 0
    local contentWidth = width - 16

    HideBodyRows(tooltip)

    if tooltip.bodyRegion then
        tooltip.bodyRegion:SetText("")
        tooltip.bodyRegion:Hide()
    end

    for index = 1, #entries do
        local entry = entries[index]
        local row = EnsureBodyRow(tooltip, index)
        local leftText = entry.left or entry.text or ""
        local rightText = entry.right or ""
        local hasRightText = rightText ~= ""
        local hasIcon = type(entry.icon) == "string" and entry.icon ~= ""
        local justifyH = tostring(entry.justifyH or "LEFT"):upper()
        local iconOffset = hasIcon and 20 or 0
        local rightWidth = hasRightText and 64 or 0
        local leftColor = UI.ResolveColor(nil, entry.colorToken, {
            r = entry.r or 0.8,
            g = entry.g or 0.8,
            b = entry.b or 0.8,
            a = entry.a or 1,
        })
        local rightColor = UI.ResolveColor(nil, entry.rightColorToken or entry.colorToken, {
            r = entry.rightR or entry.r or 0.8,
            g = entry.rightG or entry.g or 0.8,
            b = entry.rightB or entry.b or 0.8,
            a = entry.rightA or entry.a or 1,
        })

        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", tooltip, "TOPLEFT", 8, -8 - titleHeight - 4 - bodyHeight)
        row:SetWidth(contentWidth)

        if hasIcon then
            row.icon:SetTexture(entry.icon)
            row.icon:ClearAllPoints()
            row.icon:SetPoint("LEFT", row, "LEFT", 0, 0)
            row.icon:Show()
        else
            row.icon:Hide()
        end

        if hasRightText then
            row.rightText:ClearAllPoints()
            row.rightText:SetPoint("RIGHT", row, "RIGHT", 0, 0)
            row.rightText:SetWidth(rightWidth)
            row.rightText:SetText(rightText)
            row.rightText:SetTextColor(rightColor.r or 1, rightColor.g or 1, rightColor.b or 1, rightColor.a or 1)
            row.rightText:Show()
        else
            row.rightText:SetText("")
            row.rightText:Hide()
        end

        row.leftText:ClearAllPoints()
        row.leftText:SetJustifyH(justifyH == "CENTER" and "LEFT" or justifyH)
        row.leftText:SetText(leftText)
        row.leftText:SetTextColor(leftColor.r or 1, leftColor.g or 1, leftColor.b or 1, leftColor.a or 1)
        row.leftText:Show()

        if justifyH == "CENTER" and not hasRightText then
            local textWidth = row.leftText.GetStringWidth and row.leftText:GetStringWidth() or 0
            local centeredGroupWidth = textWidth + (hasIcon and 18 or 0)
            local startX = math.max(0, math.floor((contentWidth - centeredGroupWidth) * 0.5))
            if hasIcon then
                row.icon:ClearAllPoints()
                row.icon:SetPoint("LEFT", row, "LEFT", startX, 0)
            end
            row.leftText:SetPoint("LEFT", row, "LEFT", startX + (hasIcon and 18 or 0), 0)
            row.leftText:SetWidth(math.max(24, textWidth + 4))
        else
            row.leftText:SetPoint("LEFT", row, "LEFT", iconOffset, 0)
            row.leftText:SetWidth(math.max(24, contentWidth - iconOffset - rightWidth - (hasRightText and 8 or 0)))
        end

        local leftHeight = row.leftText.GetStringHeight and row.leftText:GetStringHeight() or 0
        local rightHeight = row.rightText.IsShown and row.rightText:IsShown() and row.rightText.GetStringHeight and row.rightText:GetStringHeight() or 0
        local rowHeight = math.max(hasIcon and 16 or 0, leftHeight, rightHeight, 12)
        row:SetHeight(rowHeight)
        row:Show()
        bodyHeight = bodyHeight + rowHeight + 2
    end

    if #entries == 0 and tooltip.bodyRegion and tooltip.bodyRegion.SetText then
        tooltip.bodyRegion:SetText(table.concat(lines, "\n"))
        tooltip.bodyRegion:Show()
        bodyHeight = tooltip.bodyRegion.GetStringHeight and tooltip.bodyRegion:GetStringHeight() or 0
    end

    local height = 24 + titleHeight + bodyHeight
    if tooltip.SetSize then
        tooltip:SetSize(width, math.max(height, 28))
    end

    if tooltip.SetFrameStrata then
        tooltip:SetFrameStrata("TOOLTIP")
    end
    if tooltip.SetFrameLevel then
        tooltip:SetFrameLevel(10000)
    end
    tooltip:ClearAllPoints()
    tooltip:SetPoint(spec.anchorPoint or "TOPLEFT", ownerFrame, spec.relativePoint or "TOPRIGHT", spec.offsetX or 8, spec.offsetY or 0)
    if tooltip.Raise then
        tooltip:Raise()
    end
    tooltip:Show()
    return tooltip
end

function Tooltip:ShowGameTooltip(owner, spec, resolvedSpec)
    local tooltip = _G.GameTooltip
    if not tooltip then
        return nil
    end

    local ownerFrame = ResolveOwnerFrame(owner)
    local rawSpec = spec or {}
    spec = resolvedSpec or ResolveTooltipSpec(owner, rawSpec)
    if type(spec) ~= "table" then
        return nil
    end
    self.activeGameTooltip = true
    self.currentOwnerFrame = ownerFrame
    self.currentSpec = rawSpec
    self.currentMode = "game"

    if tooltip.SetFrameStrata then
        tooltip:SetFrameStrata("TOOLTIP")
    end
    if tooltip.SetFrameLevel then
        tooltip:SetFrameLevel(10000)
    end
    tooltip:SetOwner(ownerFrame, spec.anchor or "ANCHOR_RIGHT")
    tooltip:ClearLines()

    if spec.link and tooltip.SetHyperlink then
        tooltip:SetHyperlink(spec.link)
        tooltip:Show()
        return tooltip
    end

    if spec.itemLink and tooltip.SetHyperlink then
        tooltip:SetHyperlink(spec.itemLink)
        tooltip:Show()
        return tooltip
    end

    if spec.unit and tooltip.SetUnit then
        tooltip:SetUnit(spec.unit)
        tooltip:Show()
        return tooltip
    end

    if spec.spellID and tooltip.AddSpellByID then
        tooltip:AddSpellByID(spec.spellID)
        tooltip:Show()
        return tooltip
    end

    local title = spec.title or spec.header or ""
    local titleColor = spec.titleColor or {}
    local titleRight = tostring(spec.titleRight or "")
    local titleRightColor = spec.titleRightColor or {}
    if title ~= "" then
        if titleRight ~= "" and tooltip.AddDoubleLine then
            tooltip:AddDoubleLine(
                title,
                titleRight,
                titleColor.r or titleColor[1] or 1,
                titleColor.g or titleColor[2] or 1,
                titleColor.b or titleColor[3] or 1,
                titleRightColor.r or titleRightColor[1] or 0.8,
                titleRightColor.g or titleRightColor[2] or 0.8,
                titleRightColor.b or titleRightColor[3] or 0.8
            )
        else
            tooltip:AddLine(
                title,
                titleColor.r or titleColor[1] or 1,
                titleColor.g or titleColor[2] or 1,
                titleColor.b or titleColor[3] or 1,
                true
            )
        end
    end

    if spec.lines then
        for index = 1, #spec.lines do
            local line = spec.lines[index]
            if type(line) == "table" then
                local colorR = line.r or 0.82
                local colorG = line.g or 0.84
                local colorB = line.b or 0.88
                local allowWrap = line.wrap ~= false

                if (line.left ~= nil or line.right ~= nil) and tooltip.AddDoubleLine then
                    tooltip:AddDoubleLine(
                        tostring(line.left or ""),
                        tostring(line.right or ""),
                        colorR,
                        colorG,
                        colorB,
                        line.rightR or colorR,
                        line.rightG or colorG,
                        line.rightB or colorB
                    )
                else
                    local text = line.text
                    if text ~= nil then
                        tooltip:AddLine(
                            text == "" and " " or tostring(text),
                            colorR,
                            colorG,
                            colorB,
                            allowWrap
                        )
                    end
                end
            elseif line ~= nil and line ~= "" then
                tooltip:AddLine(tostring(line), 0.82, 0.84, 0.88, true)
            end
        end
    else
        local lines = GetBodyLines(spec)
        for index = 1, #lines do
            tooltip:AddLine(lines[index], 0.82, 0.84, 0.88, true)
        end
    end

    local lines = GetBodyLines(spec)
    if #lines == 0 and title == "" and spec.text then
        tooltip:AddLine(tostring(spec.text), 0.82, 0.84, 0.88, true)
    end

    tooltip:Show()
    if tooltip.Raise then
        tooltip:Raise()
    end
    return tooltip
end

function Tooltip:Hide()
    if self.customTooltip and self.customTooltip.Hide then
        self.customTooltip:Hide()
    end

    if self.activeGameTooltip and _G.GameTooltip and _G.GameTooltip.Hide then
        _G.GameTooltip:Hide()
    end

    self.activeGameTooltip = false
    self.currentOwnerFrame = nil
    self.currentSpec = nil
    self.currentMode = nil
end

function Tooltip:ShowForElement(owner, spec)
    local resolvedSpec = ResolveTooltipSpec(owner, spec or {})
    if type(resolvedSpec) ~= "table" then
        return nil
    end

    if resolvedSpec.type == "game" or resolvedSpec.gameTooltip == true or resolvedSpec.useGameTooltip == true then
        return self:ShowGameTooltip(owner, spec, resolvedSpec)
    end

    return self:ShowCustomTooltip(owner, spec, resolvedSpec)
end

function Tooltip:RefreshForElement(owner, spec, resolvedSpec)
    local ownerFrame = ResolveOwnerFrame(owner)
    local rawSpec = spec or self.currentSpec or nil
    resolvedSpec = resolvedSpec or ResolveTooltipSpec(owner, rawSpec)
    if ownerFrame == nil or resolvedSpec == nil then
        return false
    end

    if self.currentMode == "custom" then
        local tooltip = self.customTooltip
        if not (tooltip and tooltip.IsShown and tooltip:IsShown() == true) then
            return false
        end
        if not IsSameOwner(ownerFrame, self.currentOwnerFrame) then
            return false
        end

        self:ShowCustomTooltip(ownerFrame, rawSpec, resolvedSpec)
        return true
    end

    if self.currentMode == "game" then
        local tooltip = _G.GameTooltip
        if not (tooltip and tooltip.IsShown and tooltip:IsShown() == true) then
            return false
        end
        if not IsSameOwner(ownerFrame, self.currentOwnerFrame) then
            return false
        end

        self:ShowGameTooltip(ownerFrame, rawSpec, resolvedSpec)
        return true
    end

    return false
end

function Tooltip:RefreshVisibleSpellTooltip()
    if self.currentMode ~= "custom" and self.currentMode ~= "game" then
        return false
    end

    local tooltip = self.currentMode == "custom" and self.customTooltip or _G.GameTooltip
    if not (tooltip and tooltip.IsShown and tooltip:IsShown() == true) then
        return false
    end

    local ownerFrame = self.currentOwnerFrame
    local rawSpec = self.currentSpec
    if self.currentMode == "game"
        and tooltip.GetOwner
        and tooltip:GetOwner() ~= ownerFrame
    then
        return false
    end

    local resolvedSpec = ResolveTooltipSpec(ownerFrame, rawSpec)
    if type(resolvedSpec) ~= "table" or resolvedSpec.rpeTooltipKind ~= "spell" then
        return false
    end

    return self:RefreshForElement(ownerFrame, rawSpec, resolvedSpec)
end

local function isShiftModifierKey(key)
    local normalizedKey = string.upper(tostring(key or ""))
    return normalizedKey == "LSHIFT" or normalizedKey == "RSHIFT" or normalizedKey == "SHIFT"
end

if type(CreateFrame) == "function" then
    local modifierRefreshFrame = CreateFrame("Frame")
    modifierRefreshFrame:RegisterEvent("MODIFIER_STATE_CHANGED")
    Tooltip._lastShiftDown = type(IsShiftKeyDown) == "function" and IsShiftKeyDown() == true or false
    modifierRefreshFrame:SetScript("OnEvent", function(_, event, key)
        if event ~= "MODIFIER_STATE_CHANGED" or not isShiftModifierKey(key) then
            return
        end

        local shiftDown = type(IsShiftKeyDown) == "function" and IsShiftKeyDown() == true or false
        if shiftDown == Tooltip._lastShiftDown then
            return
        end

        Tooltip._lastShiftDown = shiftDown
        Tooltip:RefreshVisibleSpellTooltip()
    end)
    Tooltip._modifierRefreshFrame = modifierRefreshFrame
end

UI.Tooltip = Tooltip

return Tooltip
