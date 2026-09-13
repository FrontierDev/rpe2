from pathlib import Path

path = Path('server/server_Event.lua')
text = path.read_text(encoding='utf-8')

old_decls = '''    local seenPlayers = {}
    local playerOrder = {}
    local groupedPlayerOrder = {}
    local trackedPlayerOrder = {}
    local trackedPlayersSeen = {}
    local sourcePlayerUnitsByName = {}
    local sourceNpcUnits = {}
    local groupedPlayers = Common.GetGroupMemberNames and Common.GetGroupMemberNames() or {}
    local playerCount = 0
    local playerEventIds = {}
'''
new_decls = '''    local seenPlayers = {}
    local playerOrder = {}
    local playerOrderSeen = {}
    local sourcePlayerUnitsByName = {}
    local sourceNpcUnits = {}
    local playerCount = 0
    local playerEventIds = {}
'''
if text.count(old_decls) != 1:
    raise RuntimeError('buildEventUnits declaration block changed unexpectedly')
text = text.replace(old_decls, new_decls, 1)

old_roster = '''    for index = 1, #groupedPlayers do
        appendUniqueName(groupedPlayerOrder, seenPlayers, groupedPlayers[index])
    end

    seenPlayers = {}
    for index = 1, #((sessionState and sessionState.clientOrder) or {}) do
        appendUniqueName(trackedPlayerOrder, trackedPlayersSeen, sessionState.clientOrder[index])
    end

    for index = 1, #((sourceUnits) or {}) do
        local unit = sourceUnits[index]
        if unit and unit.isPlayer == true then
            local playerName = Common.NormalizeName(unit.ownerID or unit.controllerID or unit.name)
            if playerName ~= "" and not sourcePlayerUnitsByName[playerName] then
                sourcePlayerUnitsByName[playerName] = unit
            end
        elseif unit then
            sourceNpcUnits[#sourceNpcUnits + 1] = unit
        end
    end

    if #trackedPlayerOrder > 1 then
        for index = 1, #trackedPlayerOrder do
            playerOrder[#playerOrder + 1] = trackedPlayerOrder[index]
        end
    else
        local playerOrderSeen = {}
        for index = 1, #groupedPlayerOrder do
            appendUniqueName(playerOrder, playerOrderSeen, groupedPlayerOrder[index])
        end
        for index = 1, #trackedPlayerOrder do
            appendUniqueName(playerOrder, playerOrderSeen, trackedPlayerOrder[index])
        end
    end
'''
new_roster = '''    -- Only clients that joined the RPE session are event participants.
    -- Ordinary WoW party/raid members without the addon never enter clientOrder and are ignored.
    for index = 1, #((sessionState and sessionState.clientOrder) or {}) do
        local playerName = Common.NormalizeName(sessionState.clientOrder[index])
        local clientState = playerName ~= ""
            and sessionState
            and sessionState.clientsByName
            and sessionState.clientsByName[playerName]
            or nil
        if clientState then
            appendUniqueName(playerOrder, playerOrderSeen, playerName)
        end
    end

    for index = 1, #((sourceUnits) or {}) do
        local unit = sourceUnits[index]
        if unit and unit.isPlayer == true then
            local playerName = Common.NormalizeName(unit.ownerID or unit.controllerID or unit.name)
            if playerName ~= "" and not sourcePlayerUnitsByName[playerName] then
                sourcePlayerUnitsByName[playerName] = unit
            end
        elseif unit then
            sourceNpcUnits[#sourceNpcUnits + 1] = unit
        end
    end
'''
if text.count(old_roster) != 1:
    raise RuntimeError('buildEventUnits roster block changed unexpectedly')
text = text.replace(old_roster, new_roster, 1)

anchor = '''    if type(localClientState) ~= "table"
        or localClientState.active ~= true
        or localClientState.channelName ~= channelName
        or tonumber(localClientState.channelId) ~= channelId
    then
        return nil, "host-session-not-current"
    end

    sessionState.channelId = channelId
'''
replacement = '''    if type(localClientState) ~= "table"
        or localClientState.active ~= true
        or localClientState.channelName ~= channelName
        or tonumber(localClientState.channelId) ~= channelId
    then
        return nil, "host-session-not-current"
    end

    -- These recipients come from the RPE session, not the raw WoW group roster.
    -- Non-addon group members are absent; connected addon clients must be hash-compatible.
    if type(server.HasClientHashMismatch) == "function" and server:HasClientHashMismatch(sessionState) then
        return nil, "client-hash-mismatch"
    end

    local hostName = Common.NormalizeName(Common.GetPlayerName())
    local clientsByName = sessionState.clientsByName or {}
    for index = 1, #(recipients or {}) do
        local clientName = Common.NormalizeName(recipients[index])
        if clientName ~= "" and clientName ~= hostName then
            local clientState = clientsByName[clientName]
            if type(clientState) ~= "table" or clientState.hashesReceived ~= true then
                return nil, "client-handshake-incomplete:" .. clientName
            end
            if type(server.ClientHashesMatch) ~= "function" or server:ClientHashesMatch(clientName, sessionState) ~= true then
                return nil, "client-hash-unverified:" .. clientName
            end
        end
    end

    sessionState.channelId = channelId
'''
if text.count(anchor) != 1:
    raise RuntimeError('resolveInitialEventSnapshotChannel anchor changed unexpectedly')
text = text.replace(anchor, replacement, 1)

path.write_text(text, encoding='utf-8')

# Structural validation of the exact call paths modified.
text = path.read_text(encoding='utf-8')
start = text.index('local function buildEventUnits(')
end = text.index('\nlocal function buildLivePlayerUnit', start)
build = text[start:end]
assert 'Common.GetGroupMemberNames' not in build
assert 'groupedPlayerOrder' not in build
assert 'sessionState.clientOrder' in build
assert 'sessionState.clientsByName[playerName]' in build

start = text.index('local function resolveInitialEventSnapshotChannel(')
end = text.index('\nlocal function getEventSnapshotPacketCount', start)
resolver = text[start:end]
assert 'server:HasClientHashMismatch(sessionState)' in resolver
assert 'clientState.hashesReceived ~= true' in resolver
assert 'server:ClientHashesMatch(clientName, sessionState) ~= true' in resolver

start = text.index('function Server:StartEvent(data)')
end = text.index('\nfunction Server:EndEvent', start)
starter = text[start:end]
assert 'self:HasClientHashMismatch(sessionState)' in starter

# Deterministic participant-boundary cases.
def participants(client_order, clients_by_name, host):
    result = []
    seen = set()
    for name in client_order:
        if name and name in clients_by_name and name not in seen:
            result.append(name)
            seen.add(name)
    if host not in seen:
        result.append(host)
    return result

assert participants(['Host'], {'Host': {}}, 'Host') == ['Host']
assert participants(['Host', 'Addon'], {'Host': {}, 'Addon': {}}, 'Host') == ['Host', 'Addon']
