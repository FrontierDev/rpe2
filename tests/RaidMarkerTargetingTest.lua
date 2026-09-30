local function assertEqual(actual, expected, message)
    if actual ~= expected then
        error(("%s: expected %s, got %s"):format(message, tostring(expected), tostring(actual)), 2)
    end
end

local function assertTrue(value, message)
    if value ~= true then
        error(message, 2)
    end
end

local function assertFalse(value, message)
    if value == true then
        error(message, 2)
    end
end

local function loadAddonFile(path, addon)
    local chunk, loadError = loadfile(path)
    assert(chunk, loadError)
    chunk(nil, addon)
end

local function position(x, y)
    return {
        available = true,
        x = x,
        y = y,
        instanceID = "instance",
    }
end

local function findCandidate(candidates, eventId)
    for index = 1, #(candidates or {}) do
        if tonumber(candidates[index] and candidates[index].eventID) == eventId then
            return candidates[index]
        end
    end
    return nil
end

local Common = {
    NormalizeName = function(name) return tostring(name or "") end,
    GetPlayerName = function() return "Alice" end,
}
local Addon = {
    Client = {
        AutopilotSpellEvaluator = {},
        Spellcasting = {},
    },
    Internal = {
        Database = { Classes = {} },
        Tasks = {},
        Profile = {},
        Ruleset = {},
    },
    Utils = {
        Common = Common,
        Lookup = {},
    },
}

local Client = Addon.Client
loadAddonFile("client/autopilot/Spatial.lua", Addon)
loadAddonFile("client/autopilot/TargetSelector.lua", Addon)

local Spatial = Client.AutopilotSpatial
local TargetSelector = Client.AutopilotTargetSelector
assertEqual(Spatial.RAID_MARKER_NPC_AOE_RADIUS_YARDS, 8, "NPC raid-marker AoE radius")

local caster = { eventID = 900, isPlayer = false, active = true, team = 1, threatTable = { [101] = 100 } }
local targetA = { eventID = 101, isPlayer = true, active = true, team = 2, name = "A", raidMarker = 1 }
local targetB = { eventID = 102, isPlayer = true, active = true, team = 2, name = "B", raidMarker = 2 }
local targetC = { eventID = 103, isPlayer = true, active = true, team = 2, name = "C", raidMarker = 0 }
local targetD = { eventID = 104, isPlayer = true, active = true, team = 2, name = "D", raidMarker = 3 }
local targetE = { eventID = 105, isPlayer = true, active = true, team = 2, name = "E", raidMarker = 1 }
local targetF = { eventID = 106, isPlayer = true, active = true, team = 2, name = "F", raidMarker = 4 }
local targetG = { eventID = 107, isPlayer = true, active = true, team = 2, name = "G", raidMarker = 5 }
local targetH = { eventID = 108, isPlayer = true, active = true, team = 2, name = "H", raidMarker = 6 }
local candidates = { targetA, targetB, targetC, targetD, targetE }
local eventState = {
    id = "raid-marker-test",
    active = true,
    units = { caster, targetA, targetB, targetC, targetD, targetE },
}
local spatialRuntime = {
    status = "ready",
    positionByActorKey = { ["unit:900"] = position(0, 0) },
    playerPositionByEventId = {
        [101] = position(0, 0),
        [102] = position(3, 0),
        [103] = position(7, 0),
        [104] = position(9, 0),
        [105] = position(20, 0),
        [106] = position(4, 0),
        [107] = position(5, 0),
        [108] = position(6, 0),
    },
}

local function selectNpcTargets(targetList, minTargets, maxTargets, runtime)
    local snapshot = {
        canCast = true,
        casterUnit = caster,
        eventState = eventState,
        policy = {
            type = "raid_marker",
            targetDisposition = "enemy",
            minTargets = minTargets,
            maxTargets = maxTargets,
        },
        targetCandidates = targetList,
    }
    local state, reason = TargetSelector.CreateState(snapshot, {
        intent = "hostile",
        spatialRuntime = runtime,
    })
    assertTrue(state ~= nil, "NPC raid-marker selector creates a state: " .. tostring(reason))
    assertTrue(TargetSelector.Step(state), "NPC raid-marker selector completes")
    return TargetSelector.CopyResult(state)
end

local proximityResult = selectNpcTargets(candidates, 1, 5, spatialRuntime)
assertEqual(proximityResult.selectedCount, 3, "NPC proximity selection count")
assertEqual(proximityResult.targetEventIds[1], 101, "NPC proximity primary target")
assertEqual(proximityResult.targetEventIds[2], 102, "NPC proximity selects nearest secondary")
assertEqual(proximityResult.targetEventIds[3], 103, "NPC proximity selects second nearest secondary")
assertFalse(findCandidate(proximityResult.targetUnits, 104) ~= nil, "NPC proximity excludes the 9-yard target")
assertFalse(findCandidate(proximityResult.targetUnits, 105) ~= nil, "NPC proximity excludes the 20-yard target")

local cappedResult = selectNpcTargets({ targetA, targetB, targetC, targetF, targetG, targetH }, 1, 3, spatialRuntime)
assertEqual(cappedResult.selectedCount, 3, "NPC raid-marker maxTargets cap")
assertEqual(cappedResult.targetEventIds[2], 102, "NPC maxTargets keeps the closest secondary")
assertEqual(cappedResult.targetEventIds[3], 106, "NPC maxTargets keeps the second-closest secondary")

local unavailableRuntime = {
    status = "ready",
    positionByActorKey = { ["unit:900"] = position(0, 0) },
    playerPositionByEventId = {},
}
local unavailableSingleResult = selectNpcTargets({ targetA, targetB }, 1, 5, unavailableRuntime)
assertEqual(unavailableSingleResult.selectedCount, 1, "NPC unavailable positions keep the primary")
assertTrue(unavailableSingleResult.meetsMinTargets, "NPC single-target minimum remains valid without secondary positions")
local unavailableMultiResult = selectNpcTargets({ targetA, targetB }, 2, 5, unavailableRuntime)
assertEqual(unavailableMultiResult.selectedCount, 1, "NPC unavailable positions do not invent a secondary")
assertFalse(unavailableMultiResult.meetsMinTargets, "NPC unavailable positions fail a multi-target minimum")

Client.OnSpellcastStart = function() return true end
Client.OnSpellcastComplete = function() return true end
Client.Spellcasting.QueueLocalSpellTargetSelection = function() end
loadAddonFile("client/autopilot/Execution.lua", Addon)
local Execution = Client.AutopilotExecution

local function validateSelection(casterUnit, targetList, targetIds, runtime)
    local snapshot = {
        casterUnit = casterUnit,
        eventState = eventState,
        policy = {
            type = "raid_marker",
            targetDisposition = "enemy",
            minTargets = 1,
            maxTargets = 5,
        },
        targetCandidates = targetList,
    }
    local action = {
        targetSelections = {
            default = { targetEventIds = targetIds },
        },
    }
    local selections, _, reason = Execution.BuildValidatedTargetSelection(action, snapshot, runtime)
    return selections ~= nil, reason
end

local playerCaster = { eventID = 1, isPlayer = true, active = true, team = 1 }
local markedPlayerA = { eventID = 201, isPlayer = false, active = true, team = 2, raidMarker = 1 }
local markedPlayerB = { eventID = 202, isPlayer = false, active = true, team = 2, raidMarker = 1 }
local differentMarker = { eventID = 203, isPlayer = false, active = true, team = 2, raidMarker = 2 }
local unmarkedPlayerA = { eventID = 204, isPlayer = false, active = true, team = 2, raidMarker = 0 }
local unmarkedPlayerB = { eventID = 205, isPlayer = false, active = true, team = 2, raidMarker = 0 }

local validMarkedPlayerSelection = validateSelection(
    playerCaster,
    { markedPlayerA, markedPlayerB, differentMarker },
    { 201, 202 },
    spatialRuntime
)
assertTrue(validMarkedPlayerSelection, "player marked raid-marker selection validates")
local validUnmarkedPlayerSelection = validateSelection(
    playerCaster,
    { unmarkedPlayerA, unmarkedPlayerB },
    { 204 },
    spatialRuntime
)
assertTrue(validUnmarkedPlayerSelection, "player unmarked raid-marker anchor validates")
local invalidUnmarkedPlayerSelection = validateSelection(
    playerCaster,
    { unmarkedPlayerA, unmarkedPlayerB },
    { 204, 205 },
    spatialRuntime
)
assertFalse(invalidUnmarkedPlayerSelection, "player unmarked raid-marker anchor rejects a second target")
local invalidMixedMarkerSelection = validateSelection(
    playerCaster,
    { markedPlayerA, markedPlayerB, differentMarker },
    { 201, 203 },
    spatialRuntime
)
assertFalse(invalidMixedMarkerSelection, "player marked raid-marker anchor rejects a different marker")

local validNpcSelection = validateSelection(caster, { targetA, targetC }, { 101, 103 }, spatialRuntime)
assertTrue(validNpcSelection, "NPC raid-marker secondary within 8 yards validates")
local invalidNpcSelection = validateSelection(caster, { targetA, targetD }, { 101, 104 }, spatialRuntime)
assertFalse(invalidNpcSelection, "NPC raid-marker secondary beyond 8 yards rejects")

loadAddonFile("client/client_Targeting.lua", Addon)
local targetingPolicy = {
    type = "raid_marker",
    targetDisposition = "enemy",
    requiresTarget = true,
    minTargets = 1,
    maxTargets = 5,
}
local manualCaster = { eventID = 300, isPlayer = true, active = true, team = 1, name = "Alice" }
local manualSkullA = { eventID = 301, isPlayer = false, active = true, team = 2, name = "Skull A", raidMarker = 1 }
local manualSkullB = { eventID = 302, isPlayer = false, active = true, team = 2, name = "Skull B", raidMarker = 1 }
local manualCross = { eventID = 303, isPlayer = false, active = true, team = 2, name = "Cross", raidMarker = 2 }
local manualUnmarkedA = { eventID = 304, isPlayer = false, active = true, team = 2, name = "Unmarked A", raidMarker = 0 }
local manualUnmarkedB = { eventID = 305, isPlayer = false, active = true, team = 2, name = "Unmarked B", raidMarker = 0 }
eventState.units = {
    manualCaster,
    manualSkullA,
    manualSkullB,
    manualCross,
    manualUnmarkedA,
    manualUnmarkedB,
}
function Client:GetEventState() return eventState end

local function beginManualTargeting(anchorEventId)
    Client.PendingSpellTargeting = {
        eventId = eventState.id,
        casterEventId = manualCaster.eventID,
        spellRef = "test:raid-marker",
        groups = {
            {
                key = "default",
                label = "Targets",
                policy = targetingPolicy,
                selectedTargetEventIds = {},
                focusedTargetEventId = 0,
            },
        },
        activeGroupKey = "default",
    }
    Client:InvalidatePendingSpellTargetingDisplayState()
    assertTrue(Client:TogglePendingSpellTarget(anchorEventId), "manual raid-marker anchor selection succeeds")
    return Client:GetPendingSpellTargetingDisplayState().groups[1]
end

local markedGroup = beginManualTargeting(manualSkullA.eventID)
assertEqual(markedGroup.selectedCount, 2, "manual marked anchor selects the same-marker group")
assertTrue(markedGroup.selectedTargetEventIds[manualSkullA.eventID], "manual marked anchor remains selected")
assertTrue(markedGroup.selectedTargetEventIds[manualSkullB.eventID], "manual same-marker target is selected")
assertFalse(markedGroup.selectedTargetEventIds[manualCross.eventID] == true, "manual different-marker target is not selected")
assertFalse(Client:TogglePendingSpellTarget(manualCross.eventID), "manual marked selection does not accept another target")

local unmarkedGroup = beginManualTargeting(manualUnmarkedA.eventID)
assertEqual(unmarkedGroup.selectedCount, 1, "manual unmarked anchor selects exactly one target")
assertEqual(unmarkedGroup.maxTargets, 1, "manual unmarked anchor caps the displayed selection at one")
assertTrue(unmarkedGroup.selectedTargetEventIds[manualUnmarkedA.eventID], "manual unmarked anchor remains selected")
assertFalse(unmarkedGroup.selectedTargetEventIds[manualUnmarkedB.eventID] == true, "manual unmarked target is not auto-grouped")
assertTrue(unmarkedGroup.canConfirm, "manual unmarked anchor remains a valid cast")
assertFalse(Client:TogglePendingSpellTarget(manualUnmarkedB.eventID), "manual unmarked selection rejects an additional target")

print("Raid marker targeting tests passed")
