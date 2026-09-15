local _, Addon = ...

Addon.Server = Addon.Server or {}
Addon.Internal = Addon.Internal or {}
Addon.Internal.Comms = Addon.Internal.Comms or {}

local Server = Addon.Server
local Event = Addon.Internal.Database
    and Addon.Internal.Database.Classes
    and Addon.Internal.Database.Classes.Event
    or nil
local Comms = Addon.Internal.Comms or {}
local Operations = Comms.Operations or {}

local EVENT_STATE_OPCODE = type(Operations.GetOpcode) == "function"
    and Operations:GetOpcode("EVENT_STATE")
    or nil

local function refreshEventManagePage()
    local eventManage = Server.UI and Server.UI.EventManage or nil
    if type(eventManage) == "table" and type(eventManage.RefreshActivePage) == "function" then
        eventManage:RefreshActivePage()
    end
end

local function normalizeEventMode(value)
    if type(Event) == "table" and type(Event.NormalizeEventMode) == "function" then
        return Event.NormalizeEventMode(value)
    end
    return string.lower(tostring(value or "")) == "npc" and "npc" or "combat"
end

local function resolveEventChannelId(server, eventState)
    local sessionState = type(server.GetState) == "function" and server:GetState() or nil
    local channelId = type(sessionState) == "table" and sessionState.channelId or nil
    if (channelId == nil or channelId == "")
        and type(Comms.ResolveChannelId) == "function"
        and type(eventState) == "table"
        and tostring(eventState.channelName or "") ~= ""
    then
        channelId = Comms:ResolveChannelId(eventState.channelName)
    end
    if type(sessionState) == "table" and channelId ~= nil and channelId ~= "" then
        sessionState.channelId = channelId
    end
    return channelId
end

local function buildEventStateSendMetadata(eventState)
    local metadata = {
        opcode = EVENT_STATE_OPCODE,
        scope = "server",
    }
    local eventId = tostring(type(eventState) == "table" and eventState.id or "")
    if eventId ~= "" then
        metadata.replaceKey = ("event-state:%s:%d:%d"):format(
            eventId,
            math.max(0, math.floor(tonumber(eventState.turnNumber) or 0)),
            math.max(0, math.floor(tonumber(eventState.tickNumber) or 0))
        )
    end
    return metadata
end

-- NPC Mode is presentation state. EventUnit presentation flags are synchronized
-- when the unit roster/upsert is sent, so changing modes only needs EVENT_STATE.
function Server:SetEventMode(mode)
    local eventState = type(self.GetEditableEventState) == "function" and self:GetEditableEventState() or nil
    if type(eventState) ~= "table" then
        return false
    end

    local nextMode = normalizeEventMode(mode)
    eventState.eventMode = normalizeEventMode(eventState.eventMode)
    if eventState.eventMode == nextMode then
        return true
    end

    eventState.eventMode = nextMode
    if eventState.active == true then
        if type(self.CopyLiveEventToDraftState) == "function" then
            self:CopyLiveEventToDraftState()
        elseif type(self.EventDraftState) == "table" then
            self.EventDraftState.eventMode = nextMode
        end

        local channelId = resolveEventChannelId(self, eventState)
        if channelId ~= nil
            and channelId ~= ""
            and EVENT_STATE_OPCODE ~= nil
            and type(Comms.SendToChannel) == "function"
        then
            local arguments = type(eventState.ToStateArguments) == "function"
                and eventState:ToStateArguments()
                or {
                    eventState.channelName,
                    eventState.id,
                    tonumber(eventState.turnNumber) or 0,
                    tonumber(eventState.tickNumber) or 0,
                    tonumber(eventState.totalTicks) or 0,
                    nextMode,
                }
            Comms:SendToChannel(
                channelId,
                EVENT_STATE_OPCODE,
                arguments,
                buildEventStateSendMetadata(eventState)
            )
        end
    end

    refreshEventManagePage()
    return true
end
