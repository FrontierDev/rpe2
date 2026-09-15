local _, Addon = ...

Addon.Server = Addon.Server or {}

local Server = Addon.Server

local function getPopup()
    return Addon.UI and Addon.UI.Popup or nil
end

local baseEndEvent = Server.EndEvent
if type(baseEndEvent) ~= "function" or Server._eventEndDistributionConfirmationInstalled == true then
    return
end

local function finishEvent(server, eventState, reason, distributeEndRewards)
    if server.EventState ~= eventState or eventState.active ~= true then
        return false
    end

    server.PendingEventEndDistribution = nil
    eventState.distributeEndRewards = distributeEndRewards == true
    return baseEndEvent(server, reason)
end

function Server:EndEvent(reason, ...)
    local eventState = self.EventState
    if type(eventState) ~= "table" or eventState.active ~= true then
        return baseEndEvent(self, reason, ...)
    end

    if self.PendingEventEndDistribution and self.PendingEventEndDistribution.eventState == eventState then
        return true
    end

    local popup = getPopup()
    if not (popup and type(popup.ShowConfirmation) == "function") then
        return false
    end

    self.PendingEventEndDistribution = {
        eventState = eventState,
        reason = reason,
    }

    popup:ShowConfirmation({
        title = "End Event",
        message = "Distribute this event's loot and end-of-event currencies?",
        confirmText = "Distribute",
        cancelText = "Skip Distribution",
        onConfirm = function()
            finishEvent(self, eventState, reason, true)
        end,
        onCancel = function()
            finishEvent(self, eventState, reason, false)
        end,
    })
    return true
end

Server._eventEndDistributionConfirmationInstalled = true
