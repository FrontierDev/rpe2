local _, Addon = ...

local UI = Addon.UI or {}
Addon.UI = UI
local BaseElement = UI.BaseElement
local Debug = Addon.Debug or {}

UI.LayoutGroupBase = UI.LayoutGroupBase or {}
local LayoutGroupBase = UI.LayoutGroupBase
LayoutGroupBase.__index = LayoutGroupBase
setmetatable(LayoutGroupBase, { __index = BaseElement })

local function NormalizeOptions(name, parent, options)
    if type(name) == "table" and parent == nil and options == nil then
        return name
    end

    local normalized = options or {}

    if type(name) == "string" then
        normalized.name = normalized.name or name
    end

    if parent ~= nil then
        normalized.parent = normalized.parent or parent
    end

    return normalized
end

function LayoutGroupBase:New(name, parent, options)
    options = NormalizeOptions(name, parent, options)
    local instance = BaseElement.New(self, options)
    if options.parent ~= nil then
        instance.parent = options.parent
    end
    instance.layoutDirty = true
    return instance
end

function LayoutGroupBase:SetLayoutDirty(isDirty)
    self.layoutDirty = isDirty ~= false
    return self.layoutDirty
end

function LayoutGroupBase:RefreshLayout()
    if not self.frame then
        self.layoutDirty = true
        return
    end

    self.layoutDirty = false

    if self.LayoutChildren then
        self:LayoutChildren()
    end
end

function LayoutGroupBase:AddChild(child)
    local added = BaseElement.AddChild(self, child)
    self:RefreshLayout()
    return added
end

function LayoutGroupBase:AddElement(element)
    return self:AddChild(element)
end

function LayoutGroupBase:AddPanel(panel)
    return self:AddChild(panel)
end

function LayoutGroupBase:Create()
    if self.frame then
        return self.frame
    end

    local frame = CreateFrame("Frame", self.name, self:GetParentFrame(), self.options.template)
    self:SetFrame(frame)
    self:CreateChildren(frame)
    self:RefreshLayout()
    return self.frame
end

function LayoutGroupBase:LayoutChildren()
    if Debug.Internal then
        Debug.Internal("Addon.UI.LayoutGroupBase:LayoutChildren() must be implemented by a concrete layout group.")
    end

    error("Addon.UI.LayoutGroupBase:LayoutChildren() must be implemented by a concrete layout group.", 2)
end
