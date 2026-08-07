local _, Addon = ...

Addon.Internal = Addon.Internal or {}
Addon.Internal.Database = Addon.Internal.Database or {}
Addon.Internal.Database.Classes = Addon.Internal.Database.Classes or {}

local ItemSlot = {}
ItemSlot.__index = ItemSlot

local function ensureString(value)
    if value == nil then
        return ""
    end

    return tostring(value)
end

local function normalizeSlotType(value)
    local normalized = string.lower(ensureString(value))
    if normalized == "mount" or normalized == "pet" then
        return normalized
    end

    return "character"
end

function ItemSlot:New(data)
    return setmetatable({
        id = nil,
        name = "",
        icon = "",
        panelSide = "left",
        priority = 0,
        slotType = "character",
    }, ItemSlot):Merge(data)
end

function ItemSlot:Merge(data)
    if type(data) ~= "table" then
        return self
    end

    for key, value in pairs(data) do
        self[key] = value
    end

    self.id = self.id ~= nil and tostring(self.id) or nil
    self.name = ensureString(self.name)
    self.icon = ensureString(self.icon)
    self.panelSide = ensureString(self.panelSide ~= "" and self.panelSide or "left")
    self.priority = tonumber(self.priority) or 0
    self.slotType = normalizeSlotType(self.slotType)

    return self
end

function ItemSlot:ToTable()
    return {
        id = self.id,
        name = self.name,
        icon = self.icon,
        panelSide = self.panelSide,
        priority = self.priority,
        slotType = self.slotType,
    }
end

function ItemSlot.FromTable(data)
    return ItemSlot:New(data)
end

Addon.Internal.Database.Classes.ItemSlot = ItemSlot
