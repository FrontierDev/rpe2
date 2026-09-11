local _, Addon = ...

Addon.Server = Addon.Server or {}
Addon.Client = Addon.Client or {}
Addon.Utils = Addon.Utils or {}

local Server = Addon.Server
local Client = Addon.Client
local Common = Addon.Utils.Common or {}
local Debug = Addon.Debug or {}
local Loot = Server.Loot or {}
Server.Loot = Loot

if Loot._recentEventManagerContextInstalled == true then
    return
end

local function trim(value)
    return tostring(value or ""):gsub("^%s+", ""):gsub("%s+$", "")
end

local function normalizeName(value)
    local text = trim(value)
    if text == "" then
        return ""
    end
    if type(Common.NormalizeName) == "function" then
        text = trim(Common.NormalizeName(text))
    end
    return text
end

local function getNow()
    return type(Common.GetNow) == "function"
        and math.max(0, math.floor(tonumber(Common.GetNow()) or 0))
        or 0
end

local function deepCopy(value, seen)
    if type(value) ~= "table" then
        return value
    end
    seen = seen or {}
    if seen[value] then
        return seen[value]
    end
    local copy = {}
    seen[value] = copy
    for key, child in pairs(value) do
        copy[key] = deepCopy(child, seen)
    end
    return copy
end

local function localPlayerName()
    return normalizeName(type(Common.GetPlayerName) == "function" and Common.GetPlayerName() or "")
end

local function isServerActive()
    if type(Server.IsActive) == "function" then
        return Server:IsActive() == true
    end
    local state = type(Server.GetState) == "function" and Server:GetState() or Server.State
    return type(state) == "table" and state.active == true
end

local function buildEligibilityState(players)
    local units = {}
    for index = 1, #(players or {}) do
        local player = normalizeName(players[index])
        if player ~= "" then
            units[#units + 1] = {
                isPlayer = true,
                ownerID = player,
                controllerID = player,
                name = player,
            }
        end
    end
    return { units = units }
end

local function copyPlayers(players)
    local copied = {}
    local seen = {}
    for index = 1, #(players or {}) do
        local player = normalizeName(players[index])
        if player ~= "" and not seen[player] then
            seen[player] = true
            copied[#copied + 1] = player
        end
    end
    return copied
end

local function resolveClientAuthority(eventSessionId)
    if type(Client.ResolveLootEventAuthority) ~= "function" then
        return nil, "event-authority-unavailable"
    end
    local ok, authority, reason = pcall(Client.ResolveLootEventAuthority, Client, eventSessionId)
    if not ok or type(authority) ~= "table" then
        return nil, reason or "unknown-event-session"
    end
    return authority
end

function Loot:CaptureEndedEventManagerContext(eventState)
    if type(eventState) ~= "table" or eventState.active ~= true then
        return nil, "event-inactive"
    end

    local eventSessionId = trim(eventState.id)
    local hostName = normalizeName(eventState.hostName)
    if eventSessionId == "" or hostName == "" then
        return nil, "event-state-mismatch"
    end

    local players, reason, detail = self:GetEligiblePlayers(eventState)
    if not players then
        if reason == "empty-eligibility" then
            players = {}
        else
            return nil, reason, detail
        end
    end

    local snapshot = {
        eventSessionId = eventSessionId,
        hostName = hostName,
        eventName = trim(eventState.name),
        players = copyPlayers(players),
        endedAt = getNow(),
    }
    self.LastEndedEventManagerContext = snapshot
    return deepCopy(snapshot)
end

function Loot:GetEventManagerLootContext()
    if not isServerActive() then
        return nil, "server-inactive"
    end

    local activeEvent = type(Server.GetEventState) == "function" and Server:GetEventState() or Server.EventState
    if type(activeEvent) == "table" and activeEvent.active == true then
        if type(Server.CanUseEventManagerActions) == "function" then
            local allowed, reason = Server:CanUseEventManagerActions()
            if allowed ~= true then
                return nil, reason or "event-action-blocked"
            end
        end
        local players, reason, detail = self:GetEligiblePlayers(activeEvent)
        if not players then
            return nil, reason, detail
        end
        return {
            mode = "active",
            active = true,
            eventSessionId = tostring(activeEvent.id or ""),
            hostName = normalizeName(activeEvent.hostName),
            eventName = trim(activeEvent.name),
            players = copyPlayers(players),
            endedAt = 0,
            eventState = activeEvent,
        }
    end

    local snapshot = self.LastEndedEventManagerContext
    if type(snapshot) ~= "table" then
        return nil, "event-inactive"
    end

    local clientState = type(Client.GetState) == "function" and Client:GetState() or Client.State
    if type(clientState) ~= "table" or clientState.active ~= true then
        return nil, "client-inactive"
    end

    local authority, reason = resolveClientAuthority(snapshot.eventSessionId)
    if not authority then
        self.LastEndedEventManagerContext = nil
        return nil, reason or "unknown-event-session"
    end

    local snapshotHost = normalizeName(snapshot.hostName)
    local authorityHost = normalizeName(authority.hostName)
    local localName = localPlayerName()
    if snapshotHost == "" or authorityHost == "" or authorityHost ~= snapshotHost then
        return nil, "host-mismatch"
    end
    if localName == "" or localName ~= snapshotHost then
        return nil, "not-host"
    end

    local players = copyPlayers(snapshot.players)
    return {
        mode = "recent",
        active = false,
        eventSessionId = tostring(snapshot.eventSessionId or ""),
        hostName = snapshotHost,
        eventName = trim(snapshot.eventName),
        players = players,
        endedAt = math.max(0, math.floor(tonumber(snapshot.endedAt) or 0)),
        eventState = buildEligibilityState(players),
    }
end

function Loot:ResolveRetainedEventManagerAuthority(context)
    if not isServerActive() then
        return nil, "server-inactive"
    end

    local activeEvent = type(Server.GetEventState) == "function" and Server:GetEventState() or Server.EventState
    if type(activeEvent) == "table" and activeEvent.active == true then
        return nil, "event-state-mismatch"
    end

    local retained, reason, detail = self:GetEventManagerLootContext()
    if type(retained) ~= "table" or retained.mode ~= "recent" then
        return nil, reason or "event-inactive", detail
    end

    local requestedSessionId = trim(type(context) == "table" and context.eventSessionId or nil)
    if requestedSessionId == "" or requestedSessionId ~= retained.eventSessionId then
        return nil, "event-state-mismatch"
    end

    local requestedHost = normalizeName(type(context) == "table" and context.hostName or nil)
    if requestedHost ~= "" and requestedHost ~= retained.hostName then
        return nil, "host-mismatch"
    end

    return {
        eventState = retained.eventState,
        eventSessionId = retained.eventSessionId,
        hostName = retained.hostName,
        source = "event-manager",
        rng = type(context) == "table" and context.rng or nil,
        retained = true,
    }
end

local baseEndEvent = Server.EndEvent
if type(baseEndEvent) == "function" then
    function Server:EndEvent(reason, ...)
        local eventState = self.EventState
        if type(eventState) == "table" and eventState.active == true then
            local ok, captureReason = pcall(Loot.CaptureEndedEventManagerContext, Loot, eventState)
            if not ok and type(Debug.Error) == "function" then
                Debug.Error(
                    "Failed to capture post-Event Loot context for %s: %s",
                    tostring(eventState.id or ""),
                    tostring(captureReason)
                )
            end
        end
        return baseEndEvent(self, reason, ...)
    end
end

Loot._recentEventManagerContextInstalled = true
return true
