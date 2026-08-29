local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Client.UI = Addon.Client.UI or {}

local Client = Addon.Client
local ClientUI = Addon.Client.UI
local EventWidget = ClientUI.EventWidget

if type(EventWidget) ~= "table" or EventWidget._portraitReadinessExtensionInstalled == true then
    return true
end

local function getFrame(element)
    if type(element) == "table" and type(element.GetFrame) == "function" then
        return element:GetFrame()
    end

    return element
end

local function getEventState()
    if type(Client.GetEventState) == "function" then
        return Client:GetEventState()
    end

    return Client.EventState
end

local function arePortraitsReady(state)
    return type(state) == "table"
        and state.active == true
        and state.unitsReady == true
        and state.startupReady == true
end

function EventWidget:ApplyPortraitStartupVisibility(state, context)
    local ready = arePortraitsReady(state)
    local portraitHostFrame = getFrame(self.portraitPanel)
    local bossHostFrame = getFrame(self.bossPortraitPanel)
    local initiativeHostFrame = getFrame(self.initiativePortraitPanel)

    if not ready then
        if portraitHostFrame and portraitHostFrame.Hide then
            portraitHostFrame:Hide()
        end
        if bossHostFrame and bossHostFrame.Hide then
            bossHostFrame:Hide()
        end
        if initiativeHostFrame and initiativeHostFrame.Hide then
            initiativeHostFrame:Hide()
        end
        return false
    end

    if portraitHostFrame and portraitHostFrame.Show then
        portraitHostFrame:Show()
    end
    if initiativeHostFrame and initiativeHostFrame.Show then
        initiativeHostFrame:Show()
    end

    local bossUnits = type(context) == "table" and context.bossUnits or nil
    local hasBossUnits = type(bossUnits) == "table" and #bossUnits > 0
    if bossHostFrame then
        if hasBossUnits and bossHostFrame.Show then
            bossHostFrame:Show()
        elseif not hasBossUnits and bossHostFrame.Hide then
            bossHostFrame:Hide()
        end
    end

    return true
end

local originalBuildPortraitRefreshContext = EventWidget.BuildPortraitRefreshContext
local originalRefreshPortraitSlot = EventWidget.RefreshPortraitSlot
local originalRefreshPortraitsForEventIds = EventWidget.RefreshPortraitsForEventIds
local originalRefresh = EventWidget.Refresh

function EventWidget:BuildPortraitRefreshContext(state)
    local context = originalBuildPortraitRefreshContext(self, state)
    if type(context) == "table" then
        context.portraitsReady = arePortraitsReady(state)
    end
    return context
end

function EventWidget:RefreshPortraitSlot(index, eventUnit, state, context, options)
    context = type(context) == "table" and context or self:BuildPortraitRefreshContext(state)
    local portraitsReady = type(context) == "table" and context.portraitsReady == true

    if not portraitsReady then
        eventUnit = nil
    end

    return originalRefreshPortraitSlot(self, index, eventUnit, state, context, options)
end

function EventWidget:RefreshPortraitsForEventIds(eventIds, reason)
    local result = originalRefreshPortraitsForEventIds(self, eventIds, reason)
    local state = getEventState()
    local context = type(state) == "table" and self:BuildPortraitRefreshContext(state) or nil
    self:ApplyPortraitStartupVisibility(state, context)
    return result
end

function EventWidget:Refresh(...)
    local result = originalRefresh(self, ...)
    local state = getEventState()
    local context = type(state) == "table" and self:BuildPortraitRefreshContext(state) or nil
    self:ApplyPortraitStartupVisibility(state, context)
    return result
end

EventWidget._portraitReadinessExtensionInstalled = true
return true
