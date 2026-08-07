local _, Addon = ...

local UI = Addon.UI or {}
Addon.UI = UI
local Debug = Addon.Debug or {}
local function ResolveSizeValue(value, reference)
    if UI.ResolveSizeValue then
        return UI.ResolveSizeValue(value, reference)
    end

    return value
end

local function ResolveFrameSize(reference)
    if UI.ResolveFrameSize then
        return UI.ResolveFrameSize(reference)
    end

    return nil, nil
end

local function ResolveFrameReference(reference)
    if type(reference) ~= "table" then
        return reference
    end

    if reference.GetFrame then
        return reference:GetFrame() or reference.frame
    end

    return reference.frame or reference
end

UI.BaseElement = UI.BaseElement or {}
local BaseElement = UI.BaseElement
BaseElement.__index = BaseElement

local function GetDebugBorderState()
    UI.DebugBorderState = UI.DebugBorderState or {
        enabled = UI.DebugBordersEnabled == true,
        elements = setmetatable({}, { __mode = "k" }),
    }

    return UI.DebugBorderState
end

function UI.GetDebugBordersEnabled()
    return GetDebugBorderState().enabled == true
end

function UI.SetDebugBorders(enabled)
    local state = GetDebugBorderState()
    state.enabled = enabled ~= false
    UI.DebugBordersEnabled = state.enabled

    for element in pairs(state.elements) do
        if element and element.UpdateDebugBorders then
            element:UpdateDebugBorders()
        end
    end

    return state.enabled
end

function BaseElement:RegisterDebugBorder()
    local state = GetDebugBorderState()
    state.elements[self] = true
    return self
end

function BaseElement:UpdateDebugBorders()
    local showBorders = UI.GetDebugBordersEnabled() and self.options and self.options.border ~= false

    for _, texture in pairs(self.borderTextures or {}) do
        if texture and texture.Show and texture.Hide then
            if showBorders then
                texture:Show()
            else
                texture:Hide()
            end
        end
    end

    return showBorders
end

function BaseElement:New(options)
    return setmetatable({
        options = options or {},
        children = {},
        points = {},
        borderTextures = {},
        frame = nil,
        parent = nil,
        name = options and options.name or nil,
        tooltip = options and options.tooltip or nil,
        _fadeTicker = nil,
        _tooltipHandlersApplied = false,
    }, self)
end

function BaseElement:SetTooltip(tooltip)
    if type(tooltip) == "string" then
        tooltip = { text = tooltip }
    end

    if type(tooltip) == "table" and tooltip.type == nil then
        tooltip.type = "custom"
    end

    self.tooltip = tooltip or nil
    self:SetOption("tooltip", self.tooltip)

    if self.frame then
        self:ApplyTooltipHandlers()
    end

    return self.tooltip
end

function BaseElement:GetTooltip()
    return self.tooltip or self.options.tooltip
end

function BaseElement:SetGameTooltip(tooltip)
    local spec = tooltip or {}

    if type(spec) == "string" then
        spec = { text = spec }
    end

    spec.type = "game"
    return self:SetTooltip(spec)
end

function BaseElement:HideTooltip()
    if UI.Tooltip and UI.Tooltip.Hide then
        UI.Tooltip:Hide()
    end
end

function BaseElement:ShowTooltip()
    local spec = self:GetTooltip()
    if not spec or not UI.Tooltip then
        return nil
    end

    return UI.Tooltip:ShowForElement(self.frame or self, spec)
end

function BaseElement:ApplyTooltipHandlers(frame)
    local target = frame or self.frame
    if not target or self._tooltipHandlersApplied then
        return
    end

    local spec = self:GetTooltip()
    if not spec then
        return
    end

    local onEnter = function()
        self:ShowTooltip()
    end

    local onLeave = function()
        self:HideTooltip()
    end

    if target.HookScript then
        target:HookScript("OnEnter", onEnter)
        target:HookScript("OnLeave", onLeave)
        target:HookScript("OnHide", onLeave)
    else
        if not (self.scripts and self.scripts.OnEnter) and target.SetScript then
            target:SetScript("OnEnter", onEnter)
        end

        if not (self.scripts and self.scripts.OnLeave) and target.SetScript then
            target:SetScript("OnLeave", onLeave)
        end
    end

    self._tooltipHandlersApplied = true
end

function BaseElement:ApplyThinBorder(frame, options)
    local target = frame or self.frame
    if not target or not target.CreateTexture then
        return
    end

    local borderSize = (options and options.borderSize) or self.options.borderSize or 1
    local borderColor = UI.ResolveColor(
        (options and options.borderColor) or self.options.borderColor,
        "panel.border",
        { r = 0.16, g = 0.18, b = 0.22, a = 1 }
    )
    local borders = self.borderTextures or {}
    self.borderTextures = borders

    if not borders.top then
        borders.top = target:CreateTexture(nil, "ARTWORK")
    end
    if not borders.bottom then
        borders.bottom = target:CreateTexture(nil, "ARTWORK")
    end
    if not borders.left then
        borders.left = target:CreateTexture(nil, "ARTWORK")
    end
    if not borders.right then
        borders.right = target:CreateTexture(nil, "ARTWORK")
    end

    borders.top:ClearAllPoints()
    borders.top:SetPoint("TOPLEFT", target, "TOPLEFT", 0, 0)
    borders.top:SetPoint("TOPRIGHT", target, "TOPRIGHT", 0, 0)
    borders.top:SetHeight(borderSize)
    borders.top:SetColorTexture(borderColor.r or 0, borderColor.g or 0, borderColor.b or 0, borderColor.a or 1)

    borders.bottom:ClearAllPoints()
    borders.bottom:SetPoint("BOTTOMLEFT", target, "BOTTOMLEFT", 0, 0)
    borders.bottom:SetPoint("BOTTOMRIGHT", target, "BOTTOMRIGHT", 0, 0)
    borders.bottom:SetHeight(borderSize)
    borders.bottom:SetColorTexture(borderColor.r or 0, borderColor.g or 0, borderColor.b or 0, borderColor.a or 1)

    borders.left:ClearAllPoints()
    borders.left:SetPoint("TOPLEFT", target, "TOPLEFT", 0, 0)
    borders.left:SetPoint("BOTTOMLEFT", target, "BOTTOMLEFT", 0, 0)
    borders.left:SetWidth(borderSize)
    borders.left:SetColorTexture(borderColor.r or 0, borderColor.g or 0, borderColor.b or 0, borderColor.a or 1)

    borders.right:ClearAllPoints()
    borders.right:SetPoint("TOPRIGHT", target, "TOPRIGHT", 0, 0)
    borders.right:SetPoint("BOTTOMRIGHT", target, "BOTTOMRIGHT", 0, 0)
    borders.right:SetWidth(borderSize)
    borders.right:SetColorTexture(borderColor.r or 0, borderColor.g or 0, borderColor.b or 0, borderColor.a or 1)

    self:RegisterDebugBorder()
    self:UpdateDebugBorders()
end

function BaseElement:StopFade()
    if self._fadeTicker and self._fadeTicker.Cancel then
        self._fadeTicker:Cancel()
    end

    self._fadeTicker = nil
end

function BaseElement:FadeTo(targetAlpha, duration, onFinished, shouldShow)
    local frame = self.frame
    if not frame or not frame.SetAlpha then
        if shouldShow ~= false and frame and frame.Show then
            frame:Show()
        elseif shouldShow == false and frame and frame.Hide then
            frame:Hide()
        end

        if onFinished then
            onFinished()
        end

        return
    end

    local fromAlpha = frame:GetAlpha() or 1
    duration = tonumber(duration) or 0

    self:StopFade()

    if shouldShow ~= false and frame.Show then
        frame:Show()
    end

    if duration <= 0 then
        frame:SetAlpha(targetAlpha)

        if shouldShow == false and frame.Hide then
            frame:Hide()
        end

        if onFinished then
            onFinished()
        end

        return
    end

    local elapsed = 0
    local step = 0.03

    if frame.SetAlpha then
        frame:SetAlpha(fromAlpha)
    end

    if C_Timer and C_Timer.NewTicker then
        self._fadeTicker = C_Timer.NewTicker(step, function(ticker)
            elapsed = elapsed + step
            local progress = math.min(1, elapsed / duration)
            local alpha = fromAlpha + ((targetAlpha - fromAlpha) * progress)

            if frame and frame.SetAlpha then
                frame:SetAlpha(alpha)
            end

            if progress >= 1 then
                ticker:Cancel()
                self._fadeTicker = nil

                if shouldShow == false and frame and frame.Hide then
                    frame:Hide()
                end

                if onFinished then
                    onFinished()
                end
            end
        end)
    else
        frame:SetAlpha(targetAlpha)

        if shouldShow == false and frame.Hide then
            frame:Hide()
        end

        if onFinished then
            onFinished()
        end
    end
end

function BaseElement:FadeIn(duration, onFinished)
    if self.frame and self.frame.SetAlpha then
        self.frame:SetAlpha(0)
    end

    self:FadeTo(self.options.alpha or 1, duration or self.options.fadeInDuration or 0.2, onFinished, true)
end

function BaseElement:FadeOut(duration, onFinished)
    self:FadeTo(0, duration or self.options.fadeOutDuration or 0.2, onFinished, false)
end

function BaseElement:SetName(name)
    self.name = name
    return self.name
end

function BaseElement:GetName()
    return self.name
end

function BaseElement:SetChildren(children)
    self.children = children or {}
    return self.children
end

function BaseElement:ClearChildren()
    self.children = {}
    return self.children
end

function BaseElement:RemoveChild(child)
    if not self.children then
        return nil
    end

    for index, item in ipairs(self.children) do
        if item == child then
            table.remove(self.children, index)
            break
        end
    end

    return child
end

function BaseElement:SetParent(parent)
    self.parent = parent

    local parentFrame = ResolveFrameReference(parent)
    if self.frame and self.frame.SetParent then
        self.frame:SetParent(parentFrame)
    end
end

function BaseElement:GetParent()
    return self.parent
end

function BaseElement:GetParentFrame()
    local parentFrame = ResolveFrameReference(self.parent)
    if not parentFrame and self.options and self.options.showWhenUIHidden ~= false then
        return WorldFrame or UIParent
    end

    return parentFrame
end

function BaseElement:SetFrame(frame)
    self.frame = frame

    local parentFrame = self:GetParentFrame()
    if parentFrame and self.frame and self.frame.SetParent then
        self.frame:SetParent(parentFrame)
    end

    self:ApplyFrameOptions()
    if self.options.border ~= false then
        self:ApplyThinBorder(self.frame)
    end
    self:ApplyTooltipHandlers(self.frame)
    return self.frame
end

function BaseElement:GetFrame()
    return self.frame
end

function BaseElement:SetOptions(options)
    self.options = options or {}
    return self.options
end

function BaseElement:GetOptions()
    return self.options
end

function BaseElement:SetOption(key, value)
    self.options = self.options or {}
    self.options[key] = value
    return value
end

function BaseElement:GetOption(key, defaultValue)
    if self.options and self.options[key] ~= nil then
        return self.options[key]
    end

    return defaultValue
end

function BaseElement:SetPoint(point, relativeTo, relativePoint, x, y)
    local anchor = {
        point = point,
        relativeTo = relativeTo,
        relativePoint = relativePoint,
        x = x,
        y = y,
    }

    table.insert(self.points, anchor)

    if self.frame and self.frame.SetPoint then
        self.frame:SetPoint(point, ResolveFrameReference(relativeTo), relativePoint, x, y)
    end

    return anchor
end

function BaseElement:ClearAllPoints()
    self.points = {}

    if self.frame and self.frame.ClearAllPoints then
        self.frame:ClearAllPoints()
    end
end

function BaseElement:SetSize(width, height)
    self.options = self.options or {}
    self.options.width = width
    self.options.height = height

    if self.frame and self.frame.SetSize then
        local parentWidth, parentHeight = ResolveFrameSize(self:GetParentFrame() or self.parent or self.frame:GetParent())
        self.frame:SetSize(
            ResolveSizeValue(width, parentWidth),
            ResolveSizeValue(height, parentHeight)
        )
    end
end

function BaseElement:SetWidth(width)
    self.options = self.options or {}
    self.options.width = width

    if self.frame and self.frame.SetWidth then
        local parentWidth = ResolveFrameSize(self:GetParentFrame() or self.parent or self.frame:GetParent())
        self.frame:SetWidth(ResolveSizeValue(width, parentWidth))
    end
end

function BaseElement:SetHeight(height)
    self.options = self.options or {}
    self.options.height = height

    if self.frame and self.frame.SetHeight then
        local _, parentHeight = ResolveFrameSize(self:GetParentFrame() or self.parent or self.frame:GetParent())
        self.frame:SetHeight(ResolveSizeValue(height, parentHeight))
    end
end

function BaseElement:ApplyFrameOptions()
    local frame = self.frame
    if not frame then
        return
    end

    local options = self.options or {}

    local parentWidth, parentHeight = ResolveFrameSize(self:GetParentFrame() or self.parent or frame:GetParent())

    if options.width and options.height and frame.SetSize then
        frame:SetSize(ResolveSizeValue(options.width, parentWidth), ResolveSizeValue(options.height, parentHeight))
    elseif options.width and frame.SetWidth then
        frame:SetWidth(ResolveSizeValue(options.width, parentWidth))
    elseif options.height and frame.SetHeight then
        frame:SetHeight(ResolveSizeValue(options.height, parentHeight))
    end

    if frame.ClearAllPoints and frame.SetPoint then
        frame:ClearAllPoints()

        if #self.points > 0 then
            for _, anchor in ipairs(self.points) do
                frame:SetPoint(
                    anchor.point,
                    ResolveFrameReference(anchor.relativeTo),
                    anchor.relativePoint,
                    anchor.x,
                    anchor.y
                )
            end
        elseif options.point then
            frame:SetPoint(
                options.point,
                ResolveFrameReference(options.relativeTo),
                options.relativePoint,
                options.x,
                options.y
            )
        end
    end

    if options.alpha ~= nil and frame.SetAlpha then
        frame:SetAlpha(options.alpha)
    end

    if options.frameStrata and frame.SetFrameStrata then
        frame:SetFrameStrata(options.frameStrata)
    end

    if options.frameLevel and frame.SetFrameLevel then
        frame:SetFrameLevel(options.frameLevel)
    end

    if options.enableMouse ~= nil and frame.EnableMouse then
        frame:EnableMouse(options.enableMouse)
    end

    if options.movable ~= nil and frame.SetMovable then
        frame:SetMovable(options.movable)
    end

    if options.clampedToScreen ~= nil and frame.SetClampedToScreen then
        frame:SetClampedToScreen(options.clampedToScreen)
    end

    if options.toplevel ~= nil and frame.SetToplevel then
        frame:SetToplevel(options.toplevel)
    end

    if options.hidden ~= nil then
        if options.hidden and frame.Hide then
            frame:Hide()
        elseif not options.hidden and frame.Show then
            frame:Show()
        end
    end
end

function BaseElement:AddChild(child)
    self.children = self.children or {}
    table.insert(self.children, child)

    if child and child.SetParent then
        child:SetParent(self.frame or self)
    end

    if self.frame and child and child.Create and not child:IsCreated() then
        child:Create()
    end

    return child
end

function BaseElement:GetChildren()
    return self.children or {}
end

function BaseElement:CreateFrame(frameType, template)
    local parentFrame = self:GetParentFrame()
    local frame = CreateFrame(frameType, self.name, parentFrame, template)
    return self:SetFrame(frame)
end

function BaseElement:CreateChildren(parentFrame)
    local targetParent = parentFrame or self.frame

    for _, child in ipairs(self.children or {}) do
        if child and child.SetParent then
            child:SetParent(targetParent or self)
        end

        if child and child.Create and not child:IsCreated() then
            child:Create()
        elseif child and child.SetParent and targetParent and child.GetFrame and child:GetFrame() then
            child:GetFrame():SetParent(ResolveFrameReference(targetParent))
        end
    end
end

function BaseElement:Show()
    if self.frame and self.frame.Show then
        if self.options.fadeInDuration and self.options.fadeInDuration > 0 then
            self:FadeIn(self.options.fadeInDuration)
        else
            self.frame:Show()
        end
    end
end

function BaseElement:Hide()
    if self.frame and self.frame.Hide then
        if self.options.fadeOutDuration and self.options.fadeOutDuration > 0 then
            self:FadeOut(self.options.fadeOutDuration)
        else
            self.frame:Hide()
        end
    end
end

function BaseElement:IsCreated()
    return self.frame ~= nil
end

function BaseElement:Create()
    if Debug.Internal then
        Debug.Internal("Addon.UI.BaseElement:Create() must be implemented by a concrete UI element.")
    end

    error("Addon.UI.BaseElement:Create() must be implemented by a concrete UI element.", 2)
end
