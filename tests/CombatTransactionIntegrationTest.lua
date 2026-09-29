local Harness = dofile("tests/support/IsolationHarness.lua")

local function assertEqual(expected, actual, message)
    assert(expected == actual, (message or "values differ")
        .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual))
end

local function assertTrue(value, message)
    assert(value == true, message or "expected true")
end

local function clone(value, seen)
    if type(value) ~= "table" then
        return value
    end
    seen = seen or {}
    if seen[value] then
        return seen[value]
    end
    local result = {}
    seen[value] = result
    for key, child in pairs(value) do
        result[clone(key, seen)] = clone(child, seen)
    end
    return result
end

local function health(unit)
    for index = 1, #((unit and unit.resources) or {}) do
        if unit.resources[index].resourceRef == "health" then
            return tonumber(unit.resources[index].currentValue) or 0
        end
    end
    return 0
end

local function threat(unit)
    return tonumber(unit and unit.threatTable and unit.threatTable[1]) or 0
end

local function findUnit(state, eventId)
    for index = 1, #(state and state.units or {}) do
        if tonumber(state.units[index].eventID) == tonumber(eventId) then
            return state.units[index]
        end
    end
    return nil
end

local function installEventProjection(node)
    local eventClass = {
        SerializeUnitDeltaBatchForNetwork = function(entries)
            local records = {}
            for index = 1, #(entries or {}) do
                local entry = entries[index]
                local unit = entry and entry.unit or nil
                records[#records + 1] = table.concat({
                    tostring(entry and entry.eventID or 0),
                    tostring(health(unit)),
                    tostring(threat(unit)),
                }, ",")
            end
            return table.concat(records, ";")
        end,
    }
    node.Addon.Internal.Database = { Classes = { Event = eventClass } }
    node.Addon.Client.GetState = function()
        return node.SessionState
    end
    node.Addon.Client.HandleEventUnitDeltaBatch = function(_, arguments)
        local serialized = tostring(arguments and arguments[3] or "")
        for record in string.gmatch(serialized, "[^;]+") do
            local eventId, nextHealth, nextThreat = string.match(record, "([^,]+),([^,]+),([^,]+)")
            local unit = findUnit(node.EventState, tonumber(eventId))
            if unit then
                for index = 1, #(unit.resources or {}) do
                    if unit.resources[index].resourceRef == "health" then
                        unit.resources[index].currentValue = tonumber(nextHealth) or 0
                    end
                end
                unit.threatTable = unit.threatTable or {}
                unit.threatTable[1] = tonumber(nextThreat) or 0
            end
        end
        node.EventState.liveUnitRevision = tonumber(arguments and arguments[4]) or node.EventState.liveUnitRevision
        return true
    end
end

local function makeCombat(node, stats)
    local combat = {}
    function combat:CloneValue(value)
        return clone(value)
    end
    function combat:IsUnitDead(unit)
        return health(unit) <= 0
    end
    function combat:ResolveSpellComponent()
        return nil, nil, { effect = { type = "damage" } }
    end
    function combat:ApplyResolvedDamage(entry)
        stats.executions = stats.executions + 1
        local current = health(entry.defenderUnit)
        local amount = math.min(stats.damage, current)
        return true, {
            applied = true,
            amount = amount,
            appliedDelta = -amount,
            healthResourceRef = "health",
            resourceDeltas = {
                {
                    resourceRef = "health",
                    delta = -amount,
                    maxValue = 100,
                    currentValue = current - amount,
                },
            },
            threatUpdate = {
                targetEventId = entry.defenderEventId,
                sourceEventId = entry.attackerEventId,
                amount = amount,
            },
            hitType = "ability",
            wasCritical = false,
        }
    end
    node.Addon.Client.Combat = combat
end

local function setup(options)
    options = options or {}
    local world = Harness.New()
    local host = world:AddHost("Host")
    local playerA = world:AddClient("PlayerA")
    local playerB = world:AddClient("PlayerB")
    local nodes = { host, playerA, playerB }
    local stats = {
        damage = options.damage or 30,
        executions = 0,
        reactions = 0,
        presentations = { Host = 0, PlayerA = 0, PlayerB = 0 },
        terminals = { Host = 0, PlayerA = 0, PlayerB = 0 },
        broadcasts = 0,
    }
    local fixture = {
        id = options.eventId or "combat-event",
        active = true,
        hostName = "Host",
        channelName = "RPE-COMBAT",
        channelId = 17,
        turnNumber = 2,
        tickNumber = 3,
        liveUnitRevision = 0,
        healthResourceRef = "health",
        units = {
            {
                eventID = 1, name = "Goblin", active = true, isPlayer = false,
                controllerID = 0, resources = { { resourceRef = "health", currentValue = 100, maxValue = 100 } },
                threatTable = {},
            },
            {
                eventID = 2, name = "PlayerA", active = true, isPlayer = true,
                ownerID = "PlayerA", resources = { { resourceRef = "health", currentValue = 100, maxValue = 100 } },
                threatTable = {},
            },
            {
                eventID = 3, name = "PlayerB", active = true, isPlayer = true,
                ownerID = "PlayerB", resources = { { resourceRef = "health", currentValue = options.defenderHealth or 100, maxValue = 100 } },
                threatTable = {},
            },
        },
    }

    world:StartEvent(fixture)
    for _, node in ipairs(nodes) do
        installEventProjection(node)
        makeCombat(node, stats)
        node.Addon.Client.HandleEventTransactionRequest = function(_, record)
            if tostring(record.envelope.operation or "") ~= "combat-hit" then
                return true
            end
            stats.reactions = stats.reactions + 1
            record.options.onTerminal = function(envelope)
                stats.terminals[node.Name] = stats.terminals[node.Name] + 1
                if envelope.state == "committed" then
                    stats.presentations[node.Name] = stats.presentations[node.Name] + 1
                end
            end
            return true
        end
        node.Addon.Client.HandleEventTransactionProjection = function(_, envelope)
            stats.terminals[node.Name] = stats.terminals[node.Name] + 1
            if envelope.state == "committed" then
                stats.presentations[node.Name] = stats.presentations[node.Name] + 1
            end
            return true
        end
    end

    local server = host.Addon.Server
    host.Addon.Internal.Comms.ResourceSync = {
        ApplyResourceDeltasToEventUnitByEventID = function(units, eventId, deltas)
            local unit = findUnit({ units = units }, eventId)
            if not unit then
                return false
            end
            local changed = false
            for deltaIndex = 1, #(deltas or {}) do
                local delta = deltas[deltaIndex]
                for resourceIndex = 1, #(unit.resources or {}) do
                    local resource = unit.resources[resourceIndex]
                    if resource.resourceRef == delta.resourceRef then
                        local nextValue = math.max(0, (tonumber(resource.currentValue) or 0) + (tonumber(delta.delta) or 0))
                        changed = changed or nextValue ~= resource.currentValue
                        resource.currentValue = nextValue
                    end
                end
            end
            return changed
        end,
    }
    server.BroadcastEventDeltaBatch = function(_, entries)
        stats.broadcasts = stats.broadcasts + 1
        server.EventState.liveUnitRevision = (tonumber(server.EventState.liveUnitRevision) or 0) + 1
        local eventClass = host.Addon.Internal.Database
            and host.Addon.Internal.Database.Classes
            and host.Addon.Internal.Database.Classes.Event
        local serialized = eventClass
            and eventClass.SerializeUnitDeltaBatchForNetwork
            and eventClass.SerializeUnitDeltaBatchForNetwork(entries)
            or ""
        local opcode = host.Addon.Internal.Comms.Operations:GetOpcode("EVENT_UNIT_DELTA_BATCH")
        assertTrue(type(opcode) == "number", "EVENT_UNIT_DELTA_BATCH opcode unavailable")
        assertTrue(serialized ~= "", "authoritative delta serialization failed")
        return host.Comms:SendToChannel(
            server.EventState.channelId,
            opcode,
            {
                server.EventState.channelName,
                server.EventState.id,
                serialized,
                server.EventState.liveUnitRevision,
            },
            { opcode = opcode, scope = "server" }
        )
    end
    host:LoadFile("server/server_CombatTransactions.lua")
    assertTrue(type(host.Addon.Server.EventTransactions.handlers["combat-hit"]) == "function",
        "combat-hit transaction handler was not registered")
    return world, host, playerA, playerB, stats
end

local function beginAttack(world, host, playerB, stats)
    local serverTransactions = host.Addon.Server.EventTransactions
    local record = assert(serverTransactions:BeginAwaitingInput({
        operation = "combat-hit",
        originName = "Host",
        inputRecipient = "PlayerB",
        actorEventId = 1,
        targetEventIds = { 3 },
        turnNumber = 2,
        tickNumber = 3,
        stepSensitive = true,
        input = {
            request = {
                spellRef = "test:spell",
                componentKey = "damage",
                attackType = "spell",
                defenceSystem = "simple",
                attackerTotal = 10,
                rawDamage = stats.damage,
                resultType = "hit",
                healthResourceRef = "health",
            },
        },
    }))
    world:DeliverAll()
    local defenderRecord = playerB.Addon.Client.EventTransactions:GetPending(record.id, "combat-event")
    return record, defenderRecord
end

local function submitAttack(playerB, record, resultToken)
    local input = {
        request = clone(record.envelope.input.request),
        reaction = {
            resultToken = resultToken or "pass",
            successfullyDefended = false,
            defenceStatRef = nil,
        },
    }
    assertTrue(playerB.Addon.Client.EventTransactions:SubmitInput(record, input), "defender input submitted")
end

local function assertConverged(host, playerA, playerB, expectedHealth)
    assertEqual(expectedHealth, health(findUnit(host.EventState, 3)), "host health")
    assertEqual(expectedHealth, health(findUnit(playerA.EventState, 3)), "PlayerA health")
    assertEqual(expectedHealth, health(findUnit(playerB.EventState, 3)), "PlayerB health")
end

local function assertThreatConverged(host, playerA, playerB, expectedThreat)
    assertEqual(expectedThreat, threat(findUnit(host.EventState, 3)), "host threat")
    assertEqual(expectedThreat, threat(findUnit(playerA.EventState, 3)), "PlayerA threat")
    assertEqual(expectedThreat, threat(findUnit(playerB.EventState, 3)), "PlayerB threat")
end

do
    local world, host, playerA, playerB, stats = setup()
    local serverRecord, defenderRecord = beginAttack(world, host, playerB, stats)
    assertTrue(defenderRecord ~= nil, "normal request reached defender")
    submitAttack(playerB, defenderRecord)
    world:DeliverAll()
    assertEqual(1, stats.executions, "normal server execution")
    assertConverged(host, playerA, playerB, 70)
    assertThreatConverged(host, playerA, playerB, 30)
    assertEqual(1, stats.broadcasts, "normal authoritative delta")
    assertEqual(1, stats.presentations.Host, "host presentation")
    assertEqual(1, stats.presentations.PlayerA, "PlayerA presentation")
    assertEqual(1, stats.presentations.PlayerB, "PlayerB presentation")
    assertEqual("committed", serverRecord.state, "normal terminal state")
end

do
    local world, host, playerA, playerB, stats = setup()
    local requestOpcode = host.Addon.Internal.Comms.EventTransactions.Opcodes.EVENT_TX_REQUEST
    world:DropNext("Host", "PlayerB", requestOpcode)
    local serverRecord = assert(host.Addon.Server.EventTransactions:BeginAwaitingInput({
        operation = "combat-hit", originName = "Host", inputRecipient = "PlayerB",
        actorEventId = 1, targetEventIds = { 3 }, turnNumber = 2, tickNumber = 3,
        stepSensitive = true, input = { request = { rawDamage = stats.damage, healthResourceRef = "health" } },
    }))
    world:DeliverAll()
    assertEqual(0, stats.reactions, "dropped request created a reaction")
    world:AdvanceTime(1500)
    world:DeliverAll()
    local defenderRecord = playerB.Addon.Client.EventTransactions:GetPending(serverRecord.id, "combat-event")
    assertTrue(defenderRecord ~= nil, "request retry reached defender")
    assertEqual(1, stats.reactions, "request retry created one reaction")
    submitAttack(playerB, defenderRecord)
    world:DeliverAll()
    assertEqual(1, stats.executions, "request retry executed once")
    assertConverged(host, playerA, playerB, 70)
end

do
    local world, host, playerA, playerB, stats = setup()
    local requestOpcode = host.Addon.Internal.Comms.EventTransactions.Opcodes.EVENT_TX_REQUEST
    world:DuplicateNext("Host", "PlayerB", requestOpcode)
    local serverRecord, defenderRecord = beginAttack(world, host, playerB, stats)
    assertTrue(defenderRecord ~= nil, "duplicate request reached defender")
    assertEqual(1, stats.reactions, "duplicate request created one reaction")
    submitAttack(playerB, defenderRecord)
    world:DeliverAll()
    assertEqual(1, stats.executions, "duplicate request executed once")
    assertEqual("committed", serverRecord.state, "duplicate request terminal")
end

do
    local world, host, playerA, playerB, stats = setup()
    local inputOpcode = host.Addon.Internal.Comms.EventTransactions.Opcodes.EVENT_TX_INPUT
    local serverRecord, defenderRecord = beginAttack(world, host, playerB, stats)
    world:DropNext("PlayerB", "Host", inputOpcode)
    submitAttack(playerB, defenderRecord)
    world:DeliverAll()
    assertEqual(0, stats.executions, "dropped input executed early")
    world:AdvanceTime(1500)
    world:DeliverAll()
    assertEqual(1, stats.executions, "input retry executed once")
    assertEqual(2, defenderRecord.attempts, "input retry reused the ID")
    assertEqual("committed", serverRecord.state, "input retry terminal")
end

do
    local world, host, playerA, playerB, stats = setup()
    local serverRecord, defenderRecord = beginAttack(world, host, playerB, stats)
    submitAttack(playerB, defenderRecord)
    world:DeliverAll()
    playerB.Addon.Client.EventTransactions:ReplayInput(serverRecord.id, "combat-event")
    world:DeliverAll()
    assertEqual(1, stats.executions, "duplicate input executed twice")
    assertEqual(1, stats.presentations.PlayerB, "duplicate input presented twice")
    assertThreatConverged(host, playerA, playerB, 30)
end

do
    local world, host, playerA, playerB, stats = setup()
    local serverRecord, defenderRecord = beginAttack(world, host, playerB, stats)
    submitAttack(playerB, defenderRecord)
    world:DeliverAll()
    local inputOpcode = host.Addon.Internal.Comms.EventTransactions.Opcodes.EVENT_TX_INPUT
    world:DuplicateNext("PlayerB", "Host", inputOpcode)
    playerB.Addon.Client.EventTransactions:ReplayInput(serverRecord.id, "combat-event")
    world:DeliverAll()
    assertEqual(1, stats.executions, "duplicate commit executed twice")
    assertEqual(1, stats.presentations.Host, "duplicate commit presented twice on host")
    assertEqual(1, stats.presentations.PlayerA, "duplicate commit presented twice on PlayerA")
    assertEqual(1, stats.presentations.PlayerB, "duplicate commit presented twice on PlayerB")
    assertConverged(host, playerA, playerB, 70)
    assertThreatConverged(host, playerA, playerB, 30)
end

do
    local world, host, playerA, playerB, stats = setup({ defenderHealth = 20 })
    local _, defenderRecord = beginAttack(world, host, playerB, stats)
    submitAttack(playerB, defenderRecord)
    world:DeliverAll()
    assertConverged(host, playerA, playerB, 0)
    assertTrue(health(findUnit(host.EventState, 3)) <= 0, "host marks lethal target dead")
    assertTrue(health(findUnit(playerA.EventState, 3)) <= 0, "PlayerA marks lethal target dead")
    assertTrue(health(findUnit(playerB.EventState, 3)) <= 0, "PlayerB marks lethal target dead")
    local candidates = {}
    for index = 1, #playerA.EventState.units do
        local unit = playerA.EventState.units[index]
        if unit.isPlayer == true and unit.active ~= false and health(unit) > 0 then
            candidates[#candidates + 1] = unit.eventID
        end
    end
    for index = 1, #candidates do
        assertTrue(candidates[index] ~= 3, "lethal target remained an Autopilot candidate")
    end
end

do
    local world, host, _, playerB, stats = setup()
    local serverRecord, defenderRecord = beginAttack(world, host, playerB, stats)
    assertTrue(defenderRecord ~= nil, "pending reaction reached defender")
    world:EndEvent("event-ended")
    world:StartEvent({
        id = "replacement-event", active = true, hostName = "Host",
        channelName = "RPE-COMBAT-REPLACEMENT", channelId = 18,
        turnNumber = 1, tickNumber = 1, liveUnitRevision = 0,
        healthResourceRef = "health", units = clone(host.EventState.units),
    })
    world:AdvanceTime(20000)
    world:DeliverAll()
    assertEqual(0, stats.executions, "ended event committed after replacement")
    assertEqual("cancelled", serverRecord.state, "ended event transaction cancelled")
    assertTrue(playerB.Addon.Client.EventTransactions:GetPending(serverRecord.id, "combat-event") == nil,
        "ended event left a pending defender transaction")
end

print("CombatTransactionIntegrationTest passed")
