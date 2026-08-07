local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Utils = Addon.Utils or {}
Addon.Internal = Addon.Internal or {}

local Client = Addon.Client
local Debug = Addon.Debug
local Common = Addon.Utils.Common
local Comms = Addon.Internal.Comms
local Operations = Comms.Operations
local Registry = Addon.Internal.Registry or {}
local NativeJoinChannel = Comms and Comms.JoinChannel or nil
local NativeResolveChannelId = Comms and Comms.ResolveChannelId or nil

local CLIENT_CONNECT_OPCODE = Operations:GetOpcode("CLIENT_CONNECT")
local CLIENT_DISCONNECT_OPCODE = Operations:GetOpcode("CLIENT_DISCONNECT")
local SERVER_QUERY_OPCODE = Operations:GetOpcode("SERVER_QUERY")
local CHANNEL_RESOLVE_RETRY_DELAY = 1.5

Client.State = Client.State or nil
Client.LastStopReason = Client.LastStopReason or nil
Client.ServerQueryQueued = Client.ServerQueryQueued or false
Client.ClientConnectRefreshQueued = Client.ClientConnectRefreshQueued or false
Client.LocalConfigurationRefreshQueued = Client.LocalConfigurationRefreshQueued or false
Client.PendingLocalConfigurationRefreshReason = Client.PendingLocalConfigurationRefreshReason or nil

local LOCAL_ONLY_CONFIGURATION_REASONS = {
    ["profile-action-bar-mode"] = true,
    ["profile-action-bar"] = true,
    ["profile-skill-action-bar"] = true,
    ["profile-action-bar-anchor"] = true,
    ["profile-widgets-unlocked"] = true,
}

local function getTasks()
    return Addon.Internal and Addon.Internal.Tasks or nil
end

local function normalizeConfigurationChangeReason(reason)
    if type(reason) == "string" and reason ~= "" then
        return reason
    end

    return "configuration-changed"
end

local function ConfigurationChangeQueuesResourceSync(reason)
    return LOCAL_ONLY_CONFIGURATION_REASONS[normalizeConfigurationChangeReason(reason)] ~= true
end

local function ConfigurationChangeQueuesClientConnectRefresh(reason)
    return LOCAL_ONLY_CONFIGURATION_REASONS[normalizeConfigurationChangeReason(reason)] ~= true
end

local function captureDeferredInvoker()
    local tasks = getTasks()
    if tasks and tasks.Enqueue then
        local enqueue = tasks.Enqueue
        return function(fn, ...)
            enqueue(tasks, fn, ...)
        end
    end

    if C_Timer and C_Timer.After then
        return function(fn, ...)
            local args = { ... }
            local argCount = select("#", ...)
            C_Timer.After(CHANNEL_RESOLVE_RETRY_DELAY, function()
                fn(unpack(args, 1, argCount))
            end)
        end
    end

    return function(fn, ...)
        fn(...)
    end
end

local function defer(fn, ...)
    captureDeferredInvoker()(fn, ...)
end

local function enqueueClientWork(fn, ...)
    local tasks = getTasks()
    if tasks and tasks.Enqueue then
        tasks:Enqueue(fn, ...)
        return
    end

    if C_Timer and C_Timer.After then
        local args = { ... }
        local argCount = select("#", ...)
        C_Timer.After(0, function()
            fn(unpack(args, 1, argCount))
        end)
        return
    end

    fn(...)
end

local function queueLocalConfigurationRefresh(reason)
    if type(Client.QueueLocalConfigurationRefresh) == "function" then
        return Client:QueueLocalConfigurationRefresh(reason)
    end

    if type(Client.HandleLocalConfigurationChanged) ~= "function" then
        return false
    end

    enqueueClientWork(function(targetClient, refreshReason)
        if type(targetClient) ~= "table" or type(targetClient.HandleLocalConfigurationChanged) ~= "function" then
            return
        end

        targetClient:HandleLocalConfigurationChanged(refreshReason or "player-entering-world")
    end, Client, reason or "player-entering-world")

    return true
end

function Client:QueueLocalConfigurationRefresh(reason)
    if type(self.HandleLocalConfigurationChanged) ~= "function" then
        return false
    end

    self.PendingLocalConfigurationRefreshReason = reason or self.PendingLocalConfigurationRefreshReason or "configuration-changed"
    if self.LocalConfigurationRefreshQueued then
        return true
    end

    self.LocalConfigurationRefreshQueued = true
    enqueueClientWork(function(targetClient)
        if type(targetClient) ~= "table" or type(targetClient.HandleLocalConfigurationChanged) ~= "function" then
            return
        end

        targetClient.LocalConfigurationRefreshQueued = false
        local refreshReason = targetClient.PendingLocalConfigurationRefreshReason or "configuration-changed"
        targetClient.PendingLocalConfigurationRefreshReason = nil
        targetClient:HandleLocalConfigurationChanged(refreshReason)
    end, self)

    return true
end

local function setState(state)
    Client.State = state
    return state
end

local function bindStateSessionRuntime(state)
    if type(state) ~= "table" then
        return state
    end

    state._deferInvoker = state._deferInvoker or captureDeferredInvoker()
    state._sendToChannel = state._sendToChannel or (Comms and Comms.SendToChannel or nil)
    state._resolveChannelId = state._resolveChannelId or (Comms and Comms.ResolveChannelId or nil)
    state._leaveChannel = state._leaveChannel or (Comms and Comms.LeaveChannel or nil)
    state._getPlayerName = state._getPlayerName or Common.GetPlayerName
    return state
end

local function deferForState(state, fn, ...)
    bindStateSessionRuntime(state)
    local invoker = state and state._deferInvoker or nil
    if type(invoker) == "function" then
        invoker(fn, ...)
        return
    end

    defer(fn, ...)
end

local function getPlayerNameForState(state)
    bindStateSessionRuntime(state)
    local getter = state and state._getPlayerName or nil
    if type(getter) == "function" then
        return getter()
    end

    return Common.GetPlayerName and Common.GetPlayerName() or nil
end

local function sendToChannelForState(state, channelId, opcode, arguments, metadata)
    bindStateSessionRuntime(state)
    local sender = state and state._sendToChannel or nil
    if type(sender) ~= "function" then
        return false
    end

    return sender(Comms, channelId, opcode, arguments, metadata)
end

local function buildClientHashArguments()
    local datasetHash = Registry.GenerateActivatedDatasetsHash and Registry:GenerateActivatedDatasetsHash() or ""
    local rulesetHash = Registry.GenerateActiveRulesetHash and Registry:GenerateActiveRulesetHash() or ""

    return tostring(datasetHash or ""), tostring(rulesetHash or "")
end

local function getActiveGroupDistribution()
    local distribution = Common.GetGroupType and Common.GetGroupType() or nil
    if distribution == "PARTY" or distribution == "RAID" then
        return distribution
    end

    return nil
end

local function hasLiveChannelJoinApi()
    return type(JoinChannelByName) == "function"
        and Comms ~= nil
        and Comms.JoinChannel == NativeJoinChannel
end

local function resolveChannelId(state)
    if not state then
        return nil
    end

    bindStateSessionRuntime(state)
    local cachedChannelId = state.channelId
    local hasChannelApis = type(GetChannelName) == "function" or type(GetChannelList) == "function"
    if not hasChannelApis then
        return cachedChannelId
    end

    local resolver = state._resolveChannelId or (Comms and Comms.ResolveChannelId) or nil
    if type(resolver) ~= "function" then
        return cachedChannelId
    end

    local useResolvedLookup = hasLiveChannelJoinApi() or resolver ~= NativeResolveChannelId
    if not useResolvedLookup then
        return cachedChannelId
    end

    local resolvedChannelId = resolver(Comms, state.channelName)
    if resolvedChannelId ~= nil and resolvedChannelId ~= "" then
        state.channelId = resolvedChannelId
        return resolvedChannelId
    end

    if cachedChannelId ~= nil and cachedChannelId ~= "" then
        return cachedChannelId
    end

    if hasLiveChannelJoinApi() then
        state.channelId = nil
    end

    return nil
end

local function addMember(state, memberName, joinedAt)
    state.membersByName = state.membersByName or {}
    state.memberOrder = state.memberOrder or {}

    if state.membersByName[memberName] then
        return false
    end

    state.memberOrder[#state.memberOrder + 1] = memberName
    state.membersByName[memberName] = {
        name = memberName,
        joinedAt = joinedAt or Common.GetNow(),
    }
    return true
end

local function removeMember(state, memberName)
    state.membersByName = state.membersByName or {}
    state.memberOrder = state.memberOrder or {}

    if not state.membersByName[memberName] then
        return false
    end

    state.membersByName[memberName] = nil
    for index = #state.memberOrder, 1, -1 do
        if state.memberOrder[index] == memberName then
            table.remove(state.memberOrder, index)
            break
        end
    end

    return true
end

function Client:GetState()
    return self.State
end

function Client:QueueServerQuery(reason)
    if self:GetState() ~= nil then
        return false
    end

    if not getActiveGroupDistribution() then
        return false
    end

    if self.ServerQueryQueued then
        return true
    end

    self.ServerQueryQueued = true
    enqueueClientWork(function(targetClient, queryReason)
        targetClient.ServerQueryQueued = false

        if targetClient:GetState() ~= nil then
            return
        end

        targetClient:SendServerQuery(queryReason)
    end, self, reason)

    return true
end

function Client:SendServerQuery(reason)
    if self:GetState() ~= nil then
        return false
    end

    local distribution = getActiveGroupDistribution()
    if not distribution then
        return false
    end

    return Comms:SendMessage(distribution, SERVER_QUERY_OPCODE, {
        Common.GetPlayerName and Common.GetPlayerName() or "",
    }, nil, {
        opcode = SERVER_QUERY_OPCODE,
        scope = "client",
    })
end

function Client:QueueClientConnectRefresh(reason)
    local state = self.State
    if not state or state.active ~= true then
        return false
    end

    if self.ClientConnectRefreshQueued then
        return true
    end

    self.ClientConnectRefreshQueued = true
    enqueueClientWork(function(targetClient, expectedState, refreshReason)
        targetClient.ClientConnectRefreshQueued = false

        if targetClient.State ~= expectedState or not expectedState or expectedState.active ~= true then
            return
        end

        targetClient:SendClientConnect(expectedState, refreshReason)
    end, self, state, reason)

    return true
end

function Client:HandleLocalConfigurationChanged(reason)
    local normalizedReason = normalizeConfigurationChangeReason(reason)
    local eventState = self.GetEventState and self:GetEventState() or nil
    local profileWindowRefreshed = false
    if self.GetTraitRuntimeState and self.SyncAutomaticTraitAuras and type(eventState) == "table" and eventState.active == true then
        local traitState = self:GetTraitRuntimeState(eventState.id, true)
        if traitState then
            traitState.automaticAurasApplied = false
            traitState.appliedEventAuras = {}
        end
        if self.ActivateEventTraits then
            self:ActivateEventTraits(eventState)
        else
            if self.RefreshTraitRuntimeEntries then
                self:RefreshTraitRuntimeEntries(eventState)
            end
            self:SyncAutomaticTraitAuras(eventState)
        end
    end
    if self.RefreshTraitResolvedState and type(eventState) == "table" and eventState.active == true then
        self:RefreshTraitResolvedState(eventState, normalizedReason)
        profileWindowRefreshed = true
    end

    local profileWindow = self.UI and self.UI.Profile and self.UI.Profile.Window or nil
    local profileWindowInstance = type(profileWindow) == "table" and profileWindow._singleton or nil
    if not profileWindowRefreshed and type(profileWindowInstance) == "table" then
        if type(profileWindowInstance.RefreshVisible) == "function" then
            profileWindowInstance:RefreshVisible()
        elseif type(profileWindowInstance.Refresh) == "function" then
            profileWindowInstance:Refresh()
        end
    end

    local inventoryWindow = self.UI and self.UI.Inventory and self.UI.Inventory.Window or nil
    local inventoryWindowInstance = type(inventoryWindow) == "table" and inventoryWindow._singleton or nil
    if type(inventoryWindowInstance) == "table" then
        if type(inventoryWindowInstance.Refresh) == "function" then
            inventoryWindowInstance:Refresh()
        end
    end

    if self.BuildActionBarWidget then
        self:BuildActionBarWidget()
    end
    if self.ShowActionBarWidget then
        self:ShowActionBarWidget()
    end
    if self.RefreshActionBarWidget then
        self:RefreshActionBarWidget(normalizedReason)
    end
    if self.QueueClientResourceSync
        and type(eventState) == "table"
        and eventState.active == true
        and ConfigurationChangeQueuesResourceSync(normalizedReason)
    then
        self:QueueClientResourceSync(normalizedReason)
    end

    if not ConfigurationChangeQueuesClientConnectRefresh(normalizedReason) then
        return true
    end

    return self:QueueClientConnectRefresh(normalizedReason)
end

function Client:HandleClientConnect(arguments, sender)
    local state = self.State
    if not state or state.active ~= true then
        return false
    end

    local channelName = arguments and arguments[1] or nil
    if channelName ~= state.channelName then
        return false
    end

    local clientName = Common.NormalizeName(sender)
    if clientName == "" then
        return false
    end

    if not addMember(state, clientName) then
        return true
    end

    Debug.Info("%s joined the server.", clientName)

    return true
end

function Client:HandleClientDisconnect(arguments, sender)
    local state = self.State
    if not state or state.active ~= true then
        return false
    end

    local channelName = arguments and arguments[1] or nil
    if channelName ~= state.channelName then
        return false
    end

    local clientName = Common.NormalizeName(sender)
    if clientName == "" or not removeMember(state, clientName) then
        return false
    end

    Debug.Info("%s left the server.", clientName)
    return true
end

function Client:SendClientConnect(state, reason)
    if not state or not state.channelName then
        return false
    end

    bindStateSessionRuntime(state)
    if state.connectPending then
        return true
    end

    local datasetHash, rulesetHash = buildClientHashArguments()
    if state.connectSent
        and state.lastAnnouncedDatasetHash == datasetHash
        and state.lastAnnouncedRulesetHash == rulesetHash
    then
        return true
    end

    local channelId = resolveChannelId(state)
    if not channelId then
        return false
    end

    state.connectPending = true
    local playerName = getPlayerNameForState(state) or "unknown"
    state.pendingDatasetHash = datasetHash
    state.pendingRulesetHash = rulesetHash
    if Debug and Debug.CommsTracing == true and Debug.Internal then
        Debug.Internal(
            "Sending CLIENT_CONNECT on channel %s (%s) using channel id %s (%s).",
            tostring(state.channelName or "unknown"),
            tostring(playerName),
            tostring(channelId),
            tostring(reason or "connect")
        )
    end

    local sent = sendToChannelForState(state, channelId, CLIENT_CONNECT_OPCODE, {
        state.channelName,
        playerName,
        datasetHash,
        rulesetHash,
    }, {
        opcode = CLIENT_CONNECT_OPCODE,
        scope = "client",
        onDelivered = function()
            if Client.State ~= state then
                return
            end

            state.connectPending = false
            state.lastAnnouncedDatasetHash = state.pendingDatasetHash
            state.lastAnnouncedRulesetHash = state.pendingRulesetHash
            state.pendingDatasetHash = nil
            state.pendingRulesetHash = nil
        end,
        onFailed = function(_, result)
            if Client.State ~= state then
                return
            end

            state.connectPending = false
            state.connectSent = false
            state.pendingDatasetHash = nil
            state.pendingRulesetHash = nil

            if Debug and Debug.CommsTracing == true and Debug.Internal then
                Debug.Internal(
                    "CLIENT_CONNECT send failed on channel %s using channel id %s: %s.",
                    tostring(state.channelName or "unknown"),
                    tostring(state.channelId or "unknown"),
                    tostring(result or "unknown")
                )
            end

            state.channelJoinReady = false
        end,
    })

    if not sent then
        state.connectPending = false
        state.connectSent = false
        state.pendingDatasetHash = nil
        state.pendingRulesetHash = nil
        if Debug and Debug.CommsTracing == true and Debug.Internal then
            Debug.Internal(
                "CLIENT_CONNECT enqueue failed on channel %s using channel id %s.",
                tostring(state.channelName or "unknown"),
                tostring(channelId or "unknown")
            )
        end
        return false
    end

    state.connectSent = true
    return true
end

function Client:SendClientDisconnect(state)
    if not state or not state.channelName then
        return false
    end

    bindStateSessionRuntime(state)
    local channelId = resolveChannelId(state)
    if not channelId then
        return false
    end

    return sendToChannelForState(state, channelId, CLIENT_DISCONNECT_OPCODE, {
        state.channelName,
        getPlayerNameForState(state) or "unknown",
    }, {
        opcode = CLIENT_DISCONNECT_OPCODE,
        scope = "client",
    })
end

local function markChannelJoinReady(state, reason)
    if not state or state.channelJoinReady == true then
        return false
    end

    bindStateSessionRuntime(state)
    state.channelJoinReady = true
    if Debug and Debug.CommsTracing == true and Debug.Internal then
        Debug.Internal(
            "Session channel %s marked ready for CLIENT_CONNECT (%s).",
            tostring(state.channelName or "unknown"),
            tostring(reason or "unknown")
        )
    end
    return true
end

local function eventMentionsJoinedChannel(state, ...)
    if not state or not state.channelName or state.channelName == "" then
        return false
    end

    local expectedChannelName = tostring(state.channelName)
    local expectedChannelId = tonumber(state.channelId)
    for index = 1, select("#", ...) do
        local value = select(index, ...)
        if type(value) == "string" and value == expectedChannelName then
            return true
        end

        if expectedChannelId ~= nil and tonumber(value) == expectedChannelId then
            return true
        end
    end

    return false
end

function Client:HandleSessionRuntimeEvent(event, ...)
    local handledDiscovery = false
    if event == "PLAYER_ENTERING_WORLD" then
        handledDiscovery = self:QueueServerQuery("player-entering-world") or handledDiscovery
        queueLocalConfigurationRefresh("player-entering-world")
    elseif event == "GROUP_ROSTER_UPDATE" then
        handledDiscovery = self:QueueServerQuery("group-roster-update") or handledDiscovery
    end

    local state = self.State
    if not state or state.active ~= true or state.channelJoinReady == true then
        return handledDiscovery
    end

    if Debug and Debug.CommsTracing == true and Debug.Internal then
        Debug.Internal(
            "Session channel runtime event %s received while waiting for %s.",
            tostring(event or "unknown"),
            tostring(state.channelName or "unknown")
        )
    end

    local shouldRecheckJoin = false
    if event == "CHANNEL_UI_UPDATE" then
        shouldRecheckJoin = true
        if resolveChannelId(state) ~= nil then
            markChannelJoinReady(state, "channel-ui-update")
        end
    elseif event == "CHAT_MSG_CHANNEL_JOIN" then
        if eventMentionsJoinedChannel(state, ...) then
            shouldRecheckJoin = true
            if resolveChannelId(state) ~= nil then
                markChannelJoinReady(state, "channel-join")
            end
        end
    elseif event == "CHAT_MSG_CHANNEL_NOTICE" or event == "CHAT_MSG_CHANNEL_NOTICE_USER" then
        local noticeType = tostring(select(1, ...) or "")
        if noticeType == "YOU_JOINED" and eventMentionsJoinedChannel(state, ...) then
            shouldRecheckJoin = true
            markChannelJoinReady(state, "channel-notice")
        end
    end

    if not shouldRecheckJoin then
        return handledDiscovery
    end

    deferForState(state, function(targetState)
        if Client.State ~= targetState or not targetState or targetState.active ~= true then
            return
        end

        Client:FinishChannelJoin(targetState, 1)
    end, state)

    return true
end

function Client:HandleChannelRuntimeEvent(event, ...)
    return self:HandleSessionRuntimeEvent(event, ...)
end

function Client:FinishChannelJoin(state, attempt)
    if not state or self.State ~= state then
        return false
    end

    local channelId = resolveChannelId(state)
    if not channelId then
        return false
    end

    if hasLiveChannelJoinApi() and state.channelJoinReady ~= true then
        return false
    end

    if not state.joinLogged then
        state.joinLogged = true
    end

    return self:SendClientConnect(state)
end

-- Resets the client session state, disconnecting from the server and clearing any session data. 
-- The `reason` parameter is a string indicating why the reset is occurring, and the `options` 
-- parameter is an optional table that can include `suppressDisconnect` and `suppressLeave` flags 
-- to control whether to send disconnect messages or leave the channel.
function Client:Reset(reason, options)
    local state = self.State
    self.LastStopReason = reason
    self.ServerQueryQueued = false
    self.ClientConnectRefreshQueued = false
    self.EventWidgetRefreshQueued = false
    self.ActionBarRefreshQueued = false
    if self.ResetResourceState then
        self:ResetResourceState()
    end
    if self.ResetSpellcastingState then
        self:ResetSpellcastingState()
    end
    if self.CancelSpellTargeting then
        self:CancelSpellTargeting("")
    end

    if self.ResetEventState then
        self:ResetEventState(reason or "session-reset")
    else
        self.EventState = nil
    end

    self.State = nil

    local suppressDisconnect = type(options) == "table" and options.suppressDisconnect == true
    local suppressLeave = type(options) == "table" and options.suppressLeave == true

    if state and not suppressDisconnect then
        self:SendClientDisconnect(state)
    end

    if state and not suppressLeave and state.channelName then
        bindStateSessionRuntime(state)
        deferForState(state, function(targetState, channelName)
            local leaveChannel = targetState and targetState._leaveChannel or nil
            if type(leaveChannel) == "function" then
                leaveChannel(Comms, channelName)
                return
            end

            Comms:LeaveChannel(channelName)
        end, state, state.channelName)
    end

    return nil
end

-- When a SERVER_START message is received from the server, this function is called to handle it.
function Client:HandleServerStart(arguments, sender)
    local channelName = arguments and arguments[1] or nil
    local announcedChannelId = tonumber(arguments and arguments[2] or nil)
    if type(channelName) ~= "string" or channelName == "" then
        return false
    end

    local state = self.State
    if state and state.channelName == channelName then
        return true
    end

    if state then
        self:Reset("replaced")
    end

    local existingChannelId = nil
    if Comms and type(Comms.ResolveChannelId) == "function" then
        existingChannelId = Comms:ResolveChannelId(channelName)
    end

    local alreadyJoinedChannel = existingChannelId ~= nil and existingChannelId ~= ""
    local joinedChannelId = existingChannelId
    if not alreadyJoinedChannel and Comms and type(Comms.JoinChannel) == "function" then
        joinedChannelId = Comms:JoinChannel(channelName)
    end

    local nextState = setState({
        active = true,
        hostName = Common.NormalizeName(sender),
        channelName = channelName,
        channelId = joinedChannelId or announcedChannelId,
        channelJoinReady = alreadyJoinedChannel or not hasLiveChannelJoinApi(),
        joinedAt = Common.GetNow(),
        membersByName = {},
        memberOrder = {},
        connectSent = false,
        connectPending = false,
        lastAnnouncedDatasetHash = nil,
        lastAnnouncedRulesetHash = nil,
        joinLogged = false,
    })
    bindStateSessionRuntime(nextState)

    if nextState.channelJoinReady then
        deferForState(nextState, function(targetState)
            Client:FinishChannelJoin(targetState, 1)
        end, nextState)
    elseif Debug and Debug.Internal then
        Debug.Internal(
            "Waiting for channel-ready event before CLIENT_CONNECT on %s.",
            tostring(channelName)
        )
    end

    return true
end

-- When a SERVER_STOP message is received from the server, this function is called to handle it.
function Client:HandleServerStop(arguments)
    local state = self.State
    if not state then
        return false
    end

    local channelName = arguments and arguments[1] or nil
    if channelName and channelName ~= "" and channelName ~= state.channelName then
        return false
    end

    self:Reset("stopped", {
        suppressDisconnect = true,
    })
    return true
end
