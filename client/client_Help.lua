local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Client.Help = Addon.Client.Help or {}

local Help = Addon.Client.Help
local Database = Addon.Internal and Addon.Internal.Database or {}
local Commands = Addon.Commands or {}

local HELP_SETTING_KEY = "help"
local HELP_SCHEMA = 1
local HELP_SYSTEM_NAME = "RPE First Run"

Help.Definitions = Help.Definitions or {}
Help.ActiveTipId = Help.ActiveTipId or nil
Help._memoryState = Help._memoryState or {
    schema = HELP_SCHEMA,
    acknowledged = {},
}
Help._suppressNativeAcknowledge = false

local function copyTable(value)
    if type(value) ~= "table" then
        return value
    end

    local copy = {}
    for key, nestedValue in pairs(value) do
        copy[key] = copyTable(nestedValue)
    end
    return copy
end

local function normalizeId(id)
    local value = tostring(id or "")
    if value == "" then
        return nil
    end
    return value
end

local function normalizeState(value)
    local state = type(value) == "table" and copyTable(value) or {}
    state.schema = HELP_SCHEMA

    local acknowledged = type(state.acknowledged) == "table" and state.acknowledged or {}
    local normalizedAcknowledged = {}
    for id, isAcknowledged in pairs(acknowledged) do
        local normalizedId = normalizeId(id)
        if normalizedId and isAcknowledged == true then
            normalizedAcknowledged[normalizedId] = true
        end
    end
    state.acknowledged = normalizedAcknowledged

    return state
end

local function loadState()
    if type(Database.GetGlobalSetting) == "function" then
        local stored = Database.GetGlobalSetting(HELP_SETTING_KEY, nil)
        if stored ~= nil then
            local normalized = normalizeState(stored)
            Help._memoryState = copyTable(normalized)
            return normalized
        end
    end

    local normalized = normalizeState(Help._memoryState)
    Help._memoryState = copyTable(normalized)
    return normalized
end

local function saveState(state)
    local normalized = normalizeState(state)
    Help._memoryState = copyTable(normalized)

    if type(Database.SetGlobalSetting) == "function" then
        Database.SetGlobalSetting(HELP_SETTING_KEY, normalized)
    end

    return copyTable(normalized)
end

local function resolveFrame(target)
    if target == nil then
        return nil
    end

    if type(target) == "table" and type(target.GetFrame) == "function" then
        local ok, frame = pcall(target.GetFrame, target)
        if not ok or frame == nil then
            return nil
        end
        target = frame
    end

    if target == nil then
        return nil
    end

    local isShown = target.IsShown
    if type(isShown) == "function" then
        local ok, shown = pcall(isShown, target)
        if not ok or shown ~= true then
            return nil
        end
        return target
    end

    local isVisible = target.IsVisible
    if type(isVisible) == "function" then
        local ok, visible = pcall(isVisible, target)
        if not ok or visible ~= true then
            return nil
        end
        return target
    end

    return nil
end

local function getHelpTipApi()
    local api = rawget(_G or {}, "HelpTip")
    if type(api) ~= "table" then
        return nil
    end
    if type(api.Show) ~= "function" or type(api.HideAllSystem) ~= "function" then
        return nil
    end
    return api
end

local function resolveButtonStyle(api, value)
    if value ~= nil then
        return value
    end
    return type(api.ButtonStyle) == "table" and api.ButtonStyle.Close or nil
end

local function resolveTargetPoint(api, value)
    if type(value) == "string" and type(api.Point) == "table" then
        return api.Point[value]
    end
    if value ~= nil then
        return value
    end
    return type(api.Point) == "table" and api.Point.RightEdgeCenter or nil
end

local function buildInfo(api, definition, overrides, id)
    local info = {}
    local source = type(definition) == "table" and definition or {}
    local extra = type(overrides) == "table" and overrides or {}

    for key, value in pairs(source) do
        if key ~= "target" and key ~= "id" then
            info[key] = value
        end
    end
    for key, value in pairs(extra) do
        if key ~= "target" and key ~= "id" then
            info[key] = value
        end
    end

    info.text = tostring(info.text or "")
    if info.text == "" then
        return nil
    end

    info.system = HELP_SYSTEM_NAME
    info.buttonStyle = resolveButtonStyle(api, info.buttonStyle)
    info.targetPoint = resolveTargetPoint(api, info.targetPoint)

    local externalAcknowledge = info.onAcknowledgeCallback
    info.onAcknowledgeCallback = function(...)
        if Help._suppressNativeAcknowledge == true then
            return
        end
        Help:Acknowledge(id)
        if type(externalAcknowledge) == "function" then
            externalAcknowledge(...)
        end
    end

    return info
end

function Help:GetSystemName()
    return HELP_SYSTEM_NAME
end

function Help:IsAvailable()
    return getHelpTipApi() ~= nil
end

function Help:Register(id, definition)
    local normalizedId = normalizeId(id)
    if not normalizedId or type(definition) ~= "table" then
        return false
    end

    self.Definitions[normalizedId] = copyTable(definition)
    return true
end

function Help:GetDefinition(id)
    local normalizedId = normalizeId(id)
    if not normalizedId then
        return nil
    end

    local definition = self.Definitions[normalizedId]
    return type(definition) == "table" and copyTable(definition) or nil
end

function Help:IsAcknowledged(id)
    local normalizedId = normalizeId(id)
    if not normalizedId then
        return false
    end

    local state = loadState()
    return state.acknowledged[normalizedId] == true
end

function Help:HideAll()
    local api = getHelpTipApi()
    self.ActiveTipId = nil
    if not api then
        return false
    end

    self._suppressNativeAcknowledge = true
    local ok = pcall(api.HideAllSystem, api, HELP_SYSTEM_NAME)
    self._suppressNativeAcknowledge = false
    return ok
end

function Help:Hide(id)
    local normalizedId = normalizeId(id)
    if normalizedId and self.ActiveTipId ~= normalizedId then
        return false
    end
    return self:HideAll()
end

function Help:Acknowledge(id)
    local normalizedId = normalizeId(id)
    if not normalizedId then
        return false
    end

    local state = loadState()
    if state.acknowledged[normalizedId] ~= true then
        state.acknowledged[normalizedId] = true
        saveState(state)
    end

    if self.ActiveTipId == normalizedId then
        self:Hide(normalizedId)
    end

    return true
end

function Help:Show(id, target, overrides)
    local normalizedId = normalizeId(id)
    if not normalizedId or self:IsAcknowledged(normalizedId) then
        return false
    end

    local api = getHelpTipApi()
    if not api then
        return false
    end

    local definition = self.Definitions[normalizedId]
    local resolvedTarget = target
    if resolvedTarget == nil and type(definition) == "table" then
        resolvedTarget = definition.target
        if type(resolvedTarget) == "function" then
            local ok, value = pcall(resolvedTarget)
            resolvedTarget = ok and value or nil
        end
    end

    resolvedTarget = resolveFrame(resolvedTarget)
    if resolvedTarget == nil then
        return false
    end

    local info = buildInfo(api, definition, overrides, normalizedId)
    if not info then
        return false
    end

    if self.ActiveTipId ~= nil then
        self:HideAll()
    end

    local parent = rawget(_G or {}, "UIParent")
    if parent == nil then
        return false
    end

    local ok, result = pcall(api.Show, api, parent, info, resolvedTarget)
    if not ok or result == false then
        self.ActiveTipId = nil
        return false
    end

    self.ActiveTipId = normalizedId
    return true
end

function Help:Reset()
    local state = loadState()
    state.acknowledged = {}
    saveState(state)
    self:HideAll()
    return true
end

if type(Commands.RegisterCommand) == "function" then
    Commands:RegisterCommand({ "help", "reset" }, function(context)
        Help:Reset()
        if context and context.router and type(context.router.Print) == "function" then
            context.router:Print("RPE first-run help has been reset.")
        end
        return true
    end, {
        description = "Reset first-run RPE HelpTips so they can be shown again.",
    })
end

return Help
