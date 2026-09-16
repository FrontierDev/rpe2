local _, Addon = ...

local UI = Addon.UI or {}
Addon.UI = UI
local BaseElement = UI.BaseElement
local Debug = Addon.Debug or {}

UI.ButtonBase = UI.ButtonBase or {}
local ButtonBase = UI.ButtonBase
ButtonBase.__index = ButtonBase
setmetatable(ButtonBase, { __index = BaseElement })

local function BuildScriptHandler(self, scriptName, handler)
    if scriptName ~= "OnClick" or type(handler) ~= "function" then
        return handler
    end

    return function(...)
        local contextMenu = UI.ContextMenu
        if self.options.suppressContextMenuClose ~= true and contextMenu and contextMenu.HideAll then
            contextMenu.HideAll()
        end

        return handler(...)
    end
end

function ButtonBase:New(options)
    local instance = BaseElement.New(self, options)
    instance.scripts = {}
    instance.label = nil
    instance.isHovered = false
    instance.isPressed = false
    return instance
end

function ButtonBase:SetScript(scriptName, handler)
    self.scripts = self.scripts or {}
    self.scripts[scriptName] = handler

    if self.frame and self.frame.SetScript then
        self.frame:SetScript(scriptName, BuildScriptHandler(self, scriptName, handler))
    end
end

function ButtonBase:ApplyButtonScripts()
    if not self.frame or not self.frame.SetScript then
        return
    end

    for scriptName, handler in pairs(self.scripts or {}) do
        self.frame:SetScript(scriptName, BuildScriptHandler(self, scriptName, handler))
    end
end

function ButtonBase:GetRestingAlpha()
    if self.selected ~= nil then
        if self.selected == true then
            return 1
        end

        return tonumber(self.options.inactiveAlpha) or 0.45
    end

    if self.enabled == false then
        return tonumber(self.options.disabledAlpha) or 0.45
    end

    return 1
end

function ButtonBase:RefreshInteractionAlpha()
    local frame = self.frame
    if not frame or not frame.SetAlpha then
        return false
    end

    local alpha = self:GetRestingAlpha()
    if self.isPressed == true then
        alpha = tonumber(self.options.pressedAlpha) or 0.8
    elseif self.isHovered == true then
        alpha = tonumber(self.options.hoverAlpha) or 1
    end

    frame:SetAlpha(alpha)
    return true
end

function ButtonBase:SetEnabled(enabled)
    self.enabled = enabled ~= false

    if self.frame then
        if self.frame.Enable then
            if self.enabled then
                self.frame:Enable()
            else
                self.frame:Disable()
            end
        end

        self:RefreshInteractionAlpha()
    end

    return self.enabled
end

function ButtonBase:CreateButton(template)
    local parentFrame = self:GetParentFrame()

    if not parentFrame then
        if Debug.Internal then
            Debug.Internal("%s requires a parent frame before Create().", self.__className or "Addon.UI.ButtonBase")
        end

        error("A button element requires a parent frame before Create().", 2)
    end

    local frame = CreateFrame("Button", self.name, parentFrame, template)
    self:SetFrame(frame)
    self:ApplyButtonScripts()

    if frame.RegisterForClicks then
        frame:RegisterForClicks("AnyUp")
    end

    if frame.SetHighlightTexture and not self.options.suppressHighlight then
        if self.options.highlightTexture then
            frame:SetHighlightTexture(self.options.highlightTexture)
        else
            frame:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight")
        end
    end

    if frame.GetHighlightTexture and not self.options.suppressHighlight then
        local highlight = frame:GetHighlightTexture()
        if highlight and highlight.SetBlendMode then
            highlight:SetBlendMode("ADD")
        end
    end

    if not (self.scripts and self.scripts.OnEnter) then
        frame:SetScript("OnEnter", function()
            self.isHovered = true
            self:RefreshInteractionAlpha()
        end)
    end

    if not (self.scripts and self.scripts.OnLeave) then
        frame:SetScript("OnLeave", function()
            self.isHovered = false
            self.isPressed = false
            self:RefreshInteractionAlpha()
        end)
    end

    if not (self.scripts and self.scripts.OnMouseDown) then
        frame:SetScript("OnMouseDown", function()
            self.isPressed = true
            self:RefreshInteractionAlpha()
        end)
    end

    if not (self.scripts and self.scripts.OnMouseUp) then
        frame:SetScript("OnMouseUp", function()
            self.isPressed = false
            self:RefreshInteractionAlpha()
        end)
    end
    return frame
end
