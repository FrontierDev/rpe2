local _, Addon = ...

Addon.Server = Addon.Server or {}
Addon.Internal = Addon.Internal or {}

local Server = Addon.Server
local Autopilot = Addon.Internal.Autopilot or {}

local baseStartEvent = Server.StartEvent
if type(baseStartEvent) ~= "function" then
    return
end

local function normalizeTurnMode(value)
    if type(Autopilot.NormalizeTurnMode) == "function" then
        return Autopilot.NormalizeTurnMode(value)
    end
    return tostring(value or "") == "autopilot" and "autopilot" or "manual"
end

function Server:GetNpcAutopilotCapability()
    if type(Autopilot.GetCoordinateCapability) ~= "function" then
        return false, "position-api-unavailable"
    end
    return Autopilot.GetCoordinateCapability()
end

function Server:GetLastEventStartError()
    return tostring(self.LastEventStartError or "")
end

function Server:StartEvent(data)
    local eventData = type(data) == "table" and data or {}
    local draftState = self.GetEventDraftState and self:GetEventDraftState() or nil
    local requestedMode = normalizeTurnMode(
        eventData.turnMode ~= nil and eventData.turnMode
            or (draftState and draftState.turnMode)
    )

    if requestedMode == "autopilot" then
        local available, reason, details = self:GetNpcAutopilotCapability()
        if available ~= true then
            local message = type(Autopilot.GetCapabilityMessage) == "function"
                and Autopilot.GetCapabilityMessage(reason, details)
                or "NPC Autopilot is unavailable. Use Manual mode."
            self.LastEventStartError = message
            return nil, message, reason
        end
    end

    self.LastEventStartError = nil
    if type(Autopilot.SetEventStartTurnModeContext) == "function" then
        Autopilot.SetEventStartTurnModeContext(requestedMode)
    end

    local ok, eventState, secondary = pcall(baseStartEvent, self, eventData)

    if type(Autopilot.SetEventStartTurnModeContext) == "function" then
        Autopilot.SetEventStartTurnModeContext(nil)
    end

    if not ok then
        error(eventState, 0)
    end

    if type(eventState) == "table" then
        eventState.turnMode = requestedMode
    end
    if type(self.EventDraftState) == "table" then
        self.EventDraftState.turnMode = requestedMode
    end

    return eventState, secondary
end
