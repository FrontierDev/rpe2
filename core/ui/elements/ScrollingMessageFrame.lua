local _, Addon = ...

local UI = Addon.UI or {}
Addon.UI = UI
local BaseElement = UI.BaseElement
local Font = UI.Font or {}
local Debug = Addon.Debug or {}

UI.ScrollingMessageFrame = UI.ScrollingMessageFrame or {}
local ScrollingMessageFrame = UI.ScrollingMessageFrame
ScrollingMessageFrame.__index = ScrollingMessageFrame
setmetatable(ScrollingMessageFrame, { __index = BaseElement })

local function normalizeInsertMode(value)
    local mode = string.lower(tostring(value or "bottom"))
    if mode ~= "top" then
        mode = "bottom"
    end
    return mode
end

function ScrollingMessageFrame:New(options)
    local instance = BaseElement.New(self, options)
    instance.defaultTextColor = nil
    return instance
end

function ScrollingMessageFrame:SetDefaultTextColor(color)
    local resolved = UI.ResolveColor(color, "text.primary")
    self.defaultTextColor = {
        r = tonumber(resolved and resolved.r) or 1,
        g = tonumber(resolved and resolved.g) or 1,
        b = tonumber(resolved and resolved.b) or 1,
        a = tonumber(resolved and resolved.a) or 1,
    }
    return self.defaultTextColor
end

function ScrollingMessageFrame:AddMessage(text, color)
    local frame = self.frame
    if not frame or not frame.AddMessage then
        return false
    end

    local resolved = UI.ResolveColor(color, nil, self.defaultTextColor or UI.ResolveColor(nil, "text.primary"))
    frame:AddMessage(
        tostring(text or ""),
        tonumber(resolved and resolved.r) or 1,
        tonumber(resolved and resolved.g) or 1,
        tonumber(resolved and resolved.b) or 1
    )
    return true
end

function ScrollingMessageFrame:ClearMessages()
    if self.frame and self.frame.Clear then
        self.frame:Clear()
        return true
    end

    return false
end

function ScrollingMessageFrame:Create()
    if self.frame then
        return self.frame
    end

    local parentFrame = self:GetParentFrame()
    if not parentFrame then
        if Debug.Internal then
            Debug.Internal("Addon.UI.ScrollingMessageFrame requires a parent frame before Create().")
        end

        error("A scrolling message frame requires a parent frame before Create().", 2)
    end

    local frame = CreateFrame("ScrollingMessageFrame", self.name, parentFrame, self.options.template)
    self:SetFrame(frame)

    Font:Apply(frame, self.options, {
        fontSize = 12,
    })

    self:SetDefaultTextColor(self.options.textColor)

    if frame.SetJustifyH and self.options.justifyH then
        frame:SetJustifyH(self.options.justifyH)
    end
    if frame.SetJustifyV and self.options.justifyV then
        frame:SetJustifyV(self.options.justifyV)
    end
    if frame.SetIndentedWordWrap then
        frame:SetIndentedWordWrap(self.options.indentedWordWrap == true)
    end
    if frame.SetWordWrap then
        frame:SetWordWrap(self.options.wordWrap == true)
    end
    if frame.SetMaxLines then
        frame:SetMaxLines(math.max(1, math.floor(tonumber(self.options.maxLines) or 32)))
    end
    if frame.SetSpacing then
        frame:SetSpacing(tonumber(self.options.spacing) or 0)
    end
    if frame.SetFading then
        frame:SetFading(self.options.fading ~= false)
    end
    if frame.SetFadeDuration then
        frame:SetFadeDuration(math.max(0, tonumber(self.options.fadeDuration) or 0.2))
    end
    if frame.SetTimeVisible then
        frame:SetTimeVisible(math.max(0, tonumber(self.options.timeVisible) or 1))
    end
    if frame.SetScrollTime then
        frame:SetScrollTime(math.max(0, tonumber(self.options.scrollTime) or 0))
    end
    if frame.SetInsertMode then
        frame:SetInsertMode(normalizeInsertMode(self.options.insertMode))
    end

    return self.frame
end

return ScrollingMessageFrame
