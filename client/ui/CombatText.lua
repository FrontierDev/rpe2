local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Client.UI = Addon.Client.UI or {}

local ClientUI = Addon.Client.UI

ClientUI.CombatText = ClientUI.CombatText or {}
local CombatText = ClientUI.CombatText
CombatText.__index = CombatText

local function createInstance()
    return setmetatable({
        rootPanel = nil,
        rootFrame = nil,
        slots = {},
        queue = {},
        activeCount = 0,
        activationElapsed = 0,
        disabled = true,
    }, CombatText)
end

function CombatText:Get()
    if self.Instance then
        return self.Instance
    end

    self.Instance = createInstance()
    return self.Instance
end

function CombatText:Build()
    return nil
end

function CombatText:Clear()
    self.queue = {}
    self.activeCount = 0
    self.activationElapsed = 0
    return true
end

function CombatText:HasQueuedEntries()
    return false
end

function CombatText:GetQueueLength()
    return 0
end

function CombatText:Enqueue(_entry)
    return false
end

function CombatText:ActivateNextEntry()
    return false
end

function CombatText:OnUpdate(_elapsed)
    return 0
end

return CombatText
