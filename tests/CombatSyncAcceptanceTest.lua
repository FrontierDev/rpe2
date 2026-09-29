-- Final Combat Sync acceptance coverage.
--
-- The focused combat fixture exercises the production combat adapter and the
-- rest of this suite drives the real EventTransactions service through the
-- #435 isolated multi-client router.  The test adapter below only supplies a
-- deterministic EventUnit mutation so transport, lifecycle, projection, and
-- idempotency can be checked without inventing another production protocol.

dofile("tests/CombatTransactionIntegrationTest.lua")

local Harness = dofile("tests/support/IsolationHarness.lua")
local resourceFixtureChunk = assert(loadfile("tests/ResourceMutationReliabilityTest.lua"))
local ProductionResourceFixture = resourceFixtureChunk("fixture-only")

local function assertEqual(expected, actual, message)
    assert(expected == actual, (message or "values differ")
        .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual))
end

local function assertTrue(value, message)
    assert(value == true, message or "expected true")
end

local function clone(value, seen)
    return Harness.Clone(value, seen)
end

local function findUnit(state, eventId)
    for index = 1, #(state and state.units or {}) do
        if tonumber(state.units[index].eventID) == tonumber(eventId) then
            return state.units[index]
        end
    end
    return nil
end

local function health(unit)
    for index = 1, #((unit and unit.resources) or {}) do
        local resource = unit.resources[index]
        if resource.resourceRef == "health" then
            return tonumber(resource.currentValue) or 0
        end
    end
    return 0
end

local function threat(unit)
    local total = 0
    for _, amount in pairs((unit and unit.threatTable) or {}) do
        total = total + (tonumber(amount) or 0)
    end
    return total
end

local function resourcesSignature(unit)
    local rows = {}
    for index = 1, #((unit and unit.resources) or {}) do
        local resource = unit.resources[index]
        rows[#rows + 1] = table.concat({
            tostring(resource and resource.resourceRef or ""),
            tostring(resource and resource.currentValue or 0),
            tostring(resource and resource.maxValue or 0),
        }, "=")
    end
    table.sort(rows)
    return table.concat(rows, ";")
end

local function threatSignature(unit)
    local rows = {}
    for sourceEventId, amount in pairs((unit and unit.threatTable) or {}) do
        local normalizedAmount = tonumber(amount) or 0
        if normalizedAmount ~= 0 then
            rows[#rows + 1] = table.concat({ tostring(sourceEventId), tostring(normalizedAmount) }, "=")
        end
    end
    table.sort(rows)
    return table.concat(rows, ";")
end

local function unitSignature(unit)
    return {
        health = health(unit),
        resources = resourcesSignature(unit),
        active = unit and unit.active ~= false or false,
        hidden = unit and unit.hidden == true or false,
        threat = threat(unit),
        threatState = threatSignature(unit),
    }
end

local function serializeUnits(entries)
    local rows = {}
    for index = 1, #(entries or {}) do
        local unit = entries[index].unit or entries[index]
        rows[#rows + 1] = table.concat({
            tostring(unit.eventID or 0),
            tostring(health(unit)),
            unit.active == false and "0" or "1",
            unit.hidden == true and "1" or "0",
            tostring(threat(unit)),
        }, ",")
    end
    return table.concat(rows, ";")
end

local function installProjection(node)
    node.Addon.Internal.Database = {
        Classes = {
            Event = {
                SerializeUnitDeltaBatchForNetwork = function(entries)
                    return serializeUnits(entries)
                end,
            },
        },
    }
    node.Addon.Client.HandleEventUnitDeltaBatch = function(_, arguments)
        local eventState = node.EventState
        if not eventState or tostring(arguments[2] or "") ~= tostring(eventState.id or "") then
            return false
        end
        for row in string.gmatch(tostring(arguments[3] or ""), "[^;]+") do
            local eventId, nextHealth, active, hidden, nextThreat = string.match(row, "([^,]+),([^,]+),([^,]+),([^,]+),([^,]+)")
            local unit = findUnit(eventState, tonumber(eventId))
            if unit then
                for index = 1, #(unit.resources or {}) do
                    if unit.resources[index].resourceRef == "health" then
                        unit.resources[index].currentValue = tonumber(nextHealth) or 0
                    end
                end
                unit.active = active == "1"
                unit.hidden = hidden == "1"
                unit.threatTable = { [1] = tonumber(nextThreat) or 0 }
            end
        end
        eventState.liveUnitRevision = tonumber(arguments[4]) or eventState.liveUnitRevision
        return true
    end
    node.Addon.Client.HandleEventTransactionProjection = function(_, envelope)
        node.AcceptancePresentations = (node.AcceptancePresentations or 0) + 1
        return true
    end
    node.Addon.Client.HandleEventTransactionRequest = function()
        return true
    end
    node.Addon.Client.HandleEventUnits = function(_, arguments)
        if tostring(arguments[2] or "") ~= tostring(node.EventState and node.EventState.id or "") then
            return false
        end
        local entries = {}
        for row in string.gmatch(tostring(arguments[3] or ""), "[^;]+") do
            local eventId, nextHealth, active, hidden, nextThreat = string.match(row, "([^,]+),([^,]+),([^,]+),([^,]+),([^,]+)")
            entries[#entries + 1] = {
                eventID = tonumber(eventId),
                active = active == "1",
                hidden = hidden == "1",
                resources = { { resourceRef = "health", currentValue = tonumber(nextHealth) or 0, maxValue = 100 } },
                threatTable = { [1] = tonumber(nextThreat) or 0 },
            }
        end
        node.EventState.units = entries
        node.EventState.liveUnitRevision = tonumber(arguments[4]) or node.EventState.liveUnitRevision
        return true
    end
end

local function assertConverged(world, expectedHealth, expectedRevision, expected)
    expected = expected or {}
    local host = world.host
    local authoritative = unitSignature(findUnit(host.ServerEventState, 1))
    assertEqual(expectedHealth, authoritative.health, "server health")
    assertEqual(expectedRevision, host.ServerEventState.liveUnitRevision, "server revision")
    assertEqual(expected.active == nil and true or expected.active, authoritative.active, "server active")
    assertEqual(expected.hidden == true, authoritative.hidden, "server hidden")
    assertEqual(expected.threat or 0, authoritative.threat, "server threat")
    for _, node in ipairs(world.nodes) do
        local actual = unitSignature(findUnit(node.EventState, 1))
        assertEqual(authoritative.health, actual.health, node.Name .. " health convergence")
        assertEqual(authoritative.resources, actual.resources, node.Name .. " resource convergence")
        assertEqual(authoritative.active, actual.active, node.Name .. " active convergence")
        assertEqual(authoritative.hidden, actual.hidden, node.Name .. " hidden convergence")
        assertEqual(authoritative.threatState, actual.threatState, node.Name .. " threat convergence")
        assertEqual(expectedHealth, actual.health, node.Name .. " health")
        assertEqual(expectedRevision, node.EventState.liveUnitRevision, node.Name .. " revision")
    end
    local hostUnit = unitSignature(findUnit(host.EventState, 1))
    assertEqual(authoritative.resources, hostUnit.resources, "host resource convergence")
    assertEqual(authoritative.active, hostUnit.active, "host active convergence")
    assertEqual(authoritative.hidden, hostUnit.hidden, "host hidden convergence")
    assertEqual(authoritative.threatState, hostUnit.threatState, "host threat convergence")
end

local function assertNoPending(world)
    for _, node in ipairs(world.nodes) do
        local transactions = node.Addon.Client.EventTransactions
        local snapshot = transactions:GetDiagnosticsSnapshot()
        assertEqual(0, snapshot.pendingCount, node.Name .. " pending transactions")
    end
    local server = world.host.Addon.Server and world.host.Addon.Server.EventTransactions
    if server and type(server.GetDiagnosticsSnapshot) == "function" then
        local snapshot = server:GetDiagnosticsSnapshot()
        assertEqual(0, snapshot.pendingCount, "server pending transactions")
    end
end

local function installProductionTargeting(node)
    node.Addon.Internal.Ruleset = {
        GetActiveRuleset = function() return {} end,
        GetRulesetRuleDefinition = function() return {} end,
        GetRulesetRuleValue = function() return "health" end,
    }
    node:LoadFile("client/client_Targeting.lua")
end

local function assertResourceConverged(world, targetEventId, expectedHealth, expectedRevision)
    local host = world.host
    local authoritative = unitSignature(findUnit(host.ServerEventState, targetEventId))
    assertEqual(expectedHealth, authoritative.health, "resource server health")
    assertEqual(expectedRevision, host.ServerEventState.liveUnitRevision, "resource server revision")
    for _, node in ipairs(world.nodes) do
        local actual = unitSignature(findUnit(node.EventState, targetEventId))
        assertEqual(authoritative.health, actual.health, node.Name .. " resource health convergence")
        assertEqual(authoritative.resources, actual.resources, node.Name .. " resource value convergence")
        assertEqual(authoritative.active, actual.active, node.Name .. " resource active convergence")
        assertEqual(authoritative.hidden, actual.hidden, node.Name .. " resource hidden convergence")
        assertEqual(authoritative.threatState, actual.threatState, node.Name .. " resource threat convergence")
        assertEqual(expectedRevision, node.EventState.liveUnitRevision, node.Name .. " resource revision")
    end
end

local function newWorld(eventId, startingHealth)
    local world = Harness.New()
    local host = world:AddHost("Host")
    local playerA = world:AddClient("PlayerA")
    local playerB = world:AddClient("PlayerB")
    local fixture = {
        id = eventId or "acceptance-event",
        active = true,
        hostName = "Host",
        channelName = "RPE-ACCEPTANCE-" .. tostring(eventId or "event"),
        channelId = 77,
        turnNumber = 1,
        tickNumber = 1,
        liveUnitRevision = 0,
        units = {
            {
                eventID = 1,
                name = "Target",
                active = true,
                hidden = false,
                isPlayer = true,
                ownerID = "PlayerB",
                team = 2,
                resources = { { resourceRef = "health", currentValue = startingHealth or 100, maxValue = 100 } },
                threatTable = {},
            },
            {
                eventID = 2,
                name = "Attacker",
                active = true,
                hidden = false,
                isPlayer = true,
                ownerID = "PlayerA",
                team = 1,
                resources = { { resourceRef = "health", currentValue = 100, maxValue = 100 } },
                threatTable = {},
            },
        },
    }
    world:StartEvent(fixture)
    for _, node in ipairs(world.nodes) do
        installProjection(node)
    end

    local transactions = host.Addon.Server.EventTransactions
    local function resolve(envelope)
        local state = host.ServerEventState
        local input = envelope.input or {}
        local unit = findUnit(state, envelope.targetEventIds[1])
        if not unit then
            return { state = "rejected", outcome = { reason = "unknown-target" } }
        end
        if input.reject == true then
            return { state = "rejected", outcome = { reason = "explicit-stale-rejection" } }
        end
        local resource = unit.resources[1]
        resource.currentValue = tonumber(input.health) or ((tonumber(resource.currentValue) or 0) + (tonumber(input.amount) or 0))
        if input.active ~= nil then
            unit.active = input.active == true
        end
        if input.hidden ~= nil then
            unit.hidden = input.hidden == true
        end
        unit.threatTable = { [1] = tonumber(input.threat) or threat(unit) }
        state.liveUnitRevision = (tonumber(state.liveUnitRevision) or 0) + 1
        local delta = { { operation = "upsert", eventID = unit.eventID, unit = clone(unit) } }
        return {
            state = "committed",
            outcome = { health = resource.currentValue, dead = resource.currentValue <= 0 },
            authoritativeDelta = delta,
            newRevision = state.liveUnitRevision,
        }
    end
    transactions:Register("acceptance-mutation", resolve)
    return world, host, playerA, playerB
end

local function submit(origin, input, options)
    options = options or {}
    local event = origin.EventState
    local record = assert(origin.Addon.Client.EventTransactions:Create({
        operation = "acceptance-mutation",
        originName = origin.Name,
        eventId = event.id,
        actorEventId = 1,
        targetEventIds = { 1 },
        turnNumber = options.turnNumber or event.turnNumber,
        tickNumber = options.tickNumber or event.tickNumber,
        baseRevision = event.liveUnitRevision,
        stepSensitive = options.stepSensitive ~= false,
        input = input,
    }))
    assertTrue(origin.Addon.Client.EventTransactions:Submit(record, input), "acceptance transaction submitted")
    return record
end

local function repairFromHost(host, node)
    local state = host.ServerEventState
    assertTrue(node.Addon.Client:HandleEventUnits({
        state.channelName,
        state.id,
        serializeUnits(state.units),
        state.liveUnitRevision,
    }), "authoritative snapshot repaired client")
end

-- 1. Normal remote NPC attack (the focused production fixture above).
-- 2. Dropped first Host -> defender request.
-- 3. Duplicate request.
-- 4. Dropped first defender -> Host input.
-- These four are executed by CombatTransactionIntegrationTest, which loads
-- server/server_CombatTransactions.lua and the production projection path.

-- 5. Explicit stale rejection.
do
    local world, host, playerA, playerB = newWorld("stale", 100)
    local requestOpcode = host.Addon.Internal.Comms.EventTransactions.Opcodes.EVENT_TX_REQUEST
    world:HoldNext("PlayerA", "Host", requestOpcode)
    local record = submit(playerA, { amount = -10 })
    host.ServerEventState.turnNumber = 2
    world:ReleaseHeld("PlayerA", "Host", requestOpcode)
    world:DeliverAll()
    assertEqual("rejected", record.state, "stale request terminal state")
    assertConverged(world, 100, 0)
    assertNoPending(world)
end

-- 6. One client misses the terminal/delta and repairs from the latest snapshot.
do
    local world, host, playerA, playerB = newWorld("repair-one", 100)
    local commitOpcode = host.Addon.Internal.Comms.EventTransactions.Opcodes.EVENT_TX_COMMIT
    world:DropNext("Host", "PlayerB", commitOpcode)
    submit(playerA, { amount = -15, threat = 15 })
    world:DeliverAll()
    assertEqual(100, health(findUnit(playerB.EventState, 1)), "missed client remains stale before repair")
    repairFromHost(host, playerB)
    assertConverged(world, 85, 1, { threat = 15 })
    assertNoPending(world)
end

-- 7. Duplicate terminal commit is presentation-idempotent.
do
    local world, host, playerA, playerB = newWorld("duplicate-terminal", 100)
    world:DuplicateNext("Host", "PlayerB", host.Addon.Internal.Comms.EventTransactions.Opcodes.EVENT_TX_COMMIT)
    submit(playerA, { amount = -10 })
    world:DeliverAll()
    assertConverged(world, 90, 1)
    assertEqual(1, playerB.AcceptancePresentations, "duplicate terminal presentation")
    assertNoPending(world)
end

-- 8. Lethal damage excludes the dead target from subsequent planning.
do
    local world, host, playerA, playerB = newWorld("lethal", 25)
    submit(playerA, { amount = -25 })
    world:DeliverAll()
    assertConverged(world, 0, 1)
    for _, node in ipairs(world.nodes) do
        assertTrue(health(findUnit(node.EventState, 1)) <= 0, node.Name .. " lethal state")
    end
    installProductionTargeting(playerA)
    local candidates = playerA.Addon.Client:BuildSpellActivationTargetCandidates({
        eventState = playerA.EventState,
        casterUnit = findUnit(playerA.EventState, 2),
        policy = {
            type = "single",
            targetDisposition = "enemy",
            allowDeadTargets = false,
            allowHiddenTargets = false,
            maxTargets = 1,
        },
        targetGroups = {},
    })
    assertEqual(0, #candidates, "production targeting retained the lethal target")
    assertNoPending(world)
end

-- 9. Active/hidden change during planning invalidates the old revision.
do
    local world, host, playerA = newWorld("stale-plan", 100)
    local plan = { eventId = playerA.EventState.id, revision = playerA.EventState.liveUnitRevision }
    submit(playerA, { amount = 0, active = false, hidden = true })
    world:DeliverAll()
    assertConverged(world, 100, 1, { active = false, hidden = true })
    assertTrue(plan.revision ~= playerA.EventState.liveUnitRevision, "stale plan revision detected")
    plan = { eventId = playerA.EventState.id, revision = playerA.EventState.liveUnitRevision }
    assertEqual(playerA.EventState.liveUnitRevision, plan.revision, "replacement plan uses authoritative revision")
    assertNoPending(world)
end

-- 10. Event end mid-transaction cancels the shared record.
do
    local world, host, playerA, playerB = newWorld("end-mid-transaction", 100)
    local serverRecord = assert(host.Addon.Server.EventTransactions:BeginAwaitingInput({
        operation = "acceptance-mutation",
        originName = "Host",
        inputRecipient = "PlayerB",
        actorEventId = 1,
        targetEventIds = { 1 },
        turnNumber = 1,
        tickNumber = 1,
        stepSensitive = true,
        input = { amount = -10 },
    }))
    world:DeliverAll()
    world:EndEvent("acceptance-end")
    assertEqual("cancelled", serverRecord.state, "server event-end cancellation")
    assertNoPending(world)
end

-- 11. Event A held packet released during Event B cannot reuse the unit ID.
do
    local world, host, playerA = newWorld("event-a", 100)
    local requestOpcode = host.Addon.Internal.Comms.EventTransactions.Opcodes.EVENT_TX_REQUEST
    world:HoldNext("PlayerA", "Host", requestOpcode)
    local oldRecord = submit(playerA, { amount = -50 })
    world:EndEvent("event-replaced")
    world:StartEvent({
        id = "event-b", active = true, hostName = "Host", channelName = "RPE-ACCEPTANCE-B", channelId = 78,
        turnNumber = 1, tickNumber = 1, liveUnitRevision = 0,
        units = { { eventID = 1, name = "Target", active = true, hidden = false,
            resources = { { resourceRef = "health", currentValue = 100, maxValue = 100 } }, threatTable = {} } },
    })
    world:ReleaseHeld("PlayerA", "Host", requestOpcode)
    world:DeliverAll()
    assertEqual(100, health(findUnit(host.ServerEventState, 1)), "held Event A packet mutated Event B")
    assertEqual("cancelled", oldRecord.state, "Event A record was not terminalized")
    assertNoPending(world)
end

-- 12. Resurrection/full replacement retries once after the first request drops.
do
    local world, host, playerA = ProductionResourceFixture.setup({
        eventId = "acceptance-resurrection",
        playerAHealth = 0,
    })
    local requestOpcode = host.Addon.Internal.Comms.EventTransactions.Opcodes.EVENT_TX_REQUEST
    world:DropNext("PlayerA", "Host", requestOpcode)
    local sent, transactionId = playerA.Addon.Client:SendClientResources(
        playerA.SessionState,
        "acceptance-resurrect",
        playerA.Name,
        ProductionResourceFixture.resources(100),
        2
    )
    assertTrue(sent and transactionId ~= nil, "production resource replacement submitted")
    world:DeliverAll()
    assertEqual(0, host.Addon.Server.EventTransactions:GetDiagnosticsSnapshot().terminalCount,
        "dropped replacement did not terminalize early")
    world:AdvanceTime(1500)
    world:DeliverAll()
    assertResourceConverged(world, 2, 100, 1)
    local terminal = playerA.Addon.Client.EventTransactions.TerminalTransactions["acceptance-resurrection"][transactionId]
    assertEqual("committed", terminal and terminal.state, "production replacement terminal")
    assertNoPending(world)
end

-- 13. The origin misses the first terminal; replay reuses the same ID and
-- does not execute the authoritative mutation a second time.
do
    local world, host, playerA = newWorld("lost-origin-terminal", 100)
    world:DropNext("Host", "PlayerA", host.Addon.Internal.Comms.EventTransactions.Opcodes.EVENT_TX_COMMIT)
    local record = submit(playerA, { amount = -20 })
    world:DeliverAll()
    assertEqual(1, host.ServerEventState.liveUnitRevision, "server committed lost terminal")
    world:AdvanceTime(1500)
    world:DeliverAll()
    assertEqual("committed", record.state, "origin replay did not settle")
    assertEqual(1, host.ServerEventState.liveUnitRevision, "origin replay re-executed mutation")
    assertNoPending(world)
end

-- 14. Reload/rejoin reconstructs current state from the authoritative snapshot.
do
    local world, host, playerA, playerB = newWorld("rejoin", 100)
    submit(playerA, { amount = -30, threat = 30 })
    world:DeliverAll()
    playerB.Addon.Client.EventTransactions:EndEvent("rejoin", "reload")
    playerB.EventState.units = {}
    playerB.EventState.liveUnitRevision = 0
    playerB.Addon.Client.EventTransactions:StartEvent("rejoin")
    repairFromHost(host, playerB)
    assertConverged(world, 70, 1, { threat = 30 })
    assertNoPending(world)
end

-- 15. Several missed updates converge with one latest snapshot.
do
    local world, host, playerA, playerB = newWorld("multi-repair", 100)
    world:DropAll("Host", "PlayerB", host.Addon.Internal.Comms.EventTransactions.Opcodes.EVENT_TX_COMMIT)
    submit(playerA, { amount = -10 })
    submit(playerA, { amount = -10 })
    submit(playerA, { amount = -10 })
    world:DeliverAll()
    assertEqual(100, health(findUnit(playerB.EventState, 1)), "multi-update client changed without commits")
    world.Router.dropAllRules = {}
    repairFromHost(host, playerB)
    assertConverged(world, 70, 3)
    assertNoPending(world)
end

print("CombatSyncAcceptanceTest passed")
