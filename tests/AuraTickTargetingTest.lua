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

local function loadAddonFile(path, addon)
    local chunk, loadError = loadfile(path)
    assert(chunk, loadError)
    chunk(nil, addon)
end

local function position(x, y, instanceID)
    return {
        available = true,
        x = x,
        y = y,
        instanceID = instanceID or "instance-a",
    }
end

local Addon = {
    Client = {
        Spellcasting = {
            GetLocalPlayerName = function() return "Alice" end,
            NormalizeName = function(value) return tostring(value or "") end,
            GetUnitPageIndex = function() return 1 end,
        },
    },
    Internal = {
        Comms = {
            Operations = {
                GetOpcode = function() return nil end,
            },
        },
        Database = {
            Classes = {
                Event = {
                    IsUnitActive = function(unit)
                        return type(unit) == "table" and unit.active ~= false
                    end,
                },
            },
            Dependecies = {},
            Profile = {},
        },
        Profile = {},
        Registry = {},
    },
    Utils = {
        Common = {},
        Lookup = {
            FindEventUnitById = function(units, eventId)
                for index = 1, #(units or {}) do
                    if tonumber(units[index] and units[index].eventID) == tonumber(eventId) then
                        return units[index]
                    end
                end
                return nil
            end,
        },
    },
}

local Client = Addon.Client
function Client:GetAutopilotSpatialRuntime()
    return self.testSpatialRuntime
end

function Client:GetEventState()
    return self.testEventState
end

function Client:GetState()
    return { active = true }
end

loadAddonFile("core/classes/Aura.lua", Addon)
loadAddonFile("client/autopilot/Spatial.lua", Addon)
loadAddonFile("client/spellcasting/AuraManager.lua", Addon)

local AuraClass = Addon.Internal.Database.Classes.Aura
local AuraManager = Addon.Client.Spellcasting.AuraManager
local Spatial = Addon.Client.AutopilotSpatial

local anchor = { eventID = 10, isPlayer = true, active = true }
local boundary = { eventID = 20, isPlayer = true, active = true }
local inside = { eventID = 15, isPlayer = true, active = true }
local outside = { eventID = 30, isPlayer = true, active = true }
local wrongInstance = { eventID = 40, isPlayer = true, active = true }
local unavailable = { eventID = 50, isPlayer = true, active = true }
local inactive = { eventID = 60, isPlayer = true, active = false }
local npc = { eventID = 70, isPlayer = false, active = true, raidMarker = 4 }
local eventState = {
    active = true,
    id = "aura-tick-targeting",
    units = { wrongInstance, outside, anchor, inactive, npc, unavailable, boundary, inside },
}
Client.testSpatialRuntime = {
    playerPositionByEventId = {
        [10] = position(0, 0),
        [15] = position(3, 4),
        [20] = position(6, 8),
        [30] = position(10.1, 0),
        [40] = position(1, 0, "instance-b"),
        [60] = position(1, 0),
    },
    positionByActorKey = {},
}

local nearbyDefinition = AuraClass:New({
    tickTargetMode = "nearby_players",
    tickRadiusYards = 10,
})
local roundTrip = AuraClass.FromTable(nearbyDefinition:ToTable())
assertEqual(roundTrip.tickTargetMode, "nearby_players", "tick target mode round-trips")
assertEqual(roundTrip.tickRadiusYards, 10, "tick radius round-trips")
assertTrue(roundTrip:Validate().valid, "valid nearby tick configuration passes validation")

local invalidNearby = AuraClass:New({ tickTargetMode = "nearby_players", tickRadiusYards = 0 })
assertTrue(invalidNearby:Validate().valid ~= true, "invalid nearby tick radius is rejected")

local entry = { targetEventId = anchor.eventID }
local targets = AuraManager:ResolveAuraTickTargets(Client, eventState, entry, anchor, anchor, nearbyDefinition)
assertEqual(#targets, 3, "player tick selects anchor and eligible nearby players")
assertEqual(targets[1].eventID, anchor.eventID, "player tick target order is numeric")
assertEqual(targets[2].eventID, inside.eventID, "player inside radius is selected")
assertEqual(targets[3].eventID, boundary.eventID, "player at radius boundary is selected")

local singleTargets = AuraManager:ResolveAuraTickTargets(Client, eventState, entry, anchor, anchor, AuraClass:New({}))
assertEqual(#singleTargets, 1, "legacy Aura tick remains single-target")
assertEqual(singleTargets[1].eventID, anchor.eventID, "legacy Aura tick keeps original target")

local npcAnchor = { eventID = 80, isPlayer = false, active = true, raidMarker = 4 }
local npcSameMarker = { eventID = 90, isPlayer = false, active = true, raidMarker = 4 }
local npcOtherMarker = { eventID = 100, isPlayer = false, active = true, raidMarker = 5 }
local playerWithMarker = { eventID = 110, isPlayer = true, active = true, raidMarker = 4 }
eventState.units = { npcOtherMarker, playerWithMarker, npcSameMarker, npcAnchor }
local npcTargets = AuraManager:ResolveAuraTickTargets(
    Client,
    eventState,
    { targetEventId = npcAnchor.eventID },
    npcAnchor,
    npcAnchor,
    nearbyDefinition
)
assertEqual(#npcTargets, 2, "marked NPC tick selects exactly its marker cohort")
assertEqual(npcTargets[1].eventID, npcAnchor.eventID, "marked NPC anchor is selected")
assertEqual(npcTargets[2].eventID, npcSameMarker.eventID, "same-marker NPC is selected")

local unmarkedNpc = { eventID = 120, isPlayer = false, active = true, raidMarker = 0 }
local otherUnmarkedNpc = { eventID = 130, isPlayer = false, active = true, raidMarker = 0 }
eventState.units = { otherUnmarkedNpc, unmarkedNpc }
local unmarkedTargets = AuraManager:ResolveAuraTickTargets(
    Client,
    eventState,
    { targetEventId = unmarkedNpc.eventID },
    unmarkedNpc,
    unmarkedNpc,
    nearbyDefinition
)
assertEqual(#unmarkedTargets, 1, "unmarked NPC tick remains anchored to one unit")
assertEqual(unmarkedTargets[1].eventID, unmarkedNpc.eventID, "unmarked NPC anchor is retained")

local tickCaster = { eventID = 1, isPlayer = true, active = true, name = "Alice" }
eventState.turnNumber = 2
eventState.tickNumber = 1
eventState.units = { tickCaster, anchor, boundary, inside, outside, wrongInstance, inactive, unavailable }
Client.testEventState = eventState
local tickEntry = {
    auraKey = "area-tick",
    auraRef = "test:area-tick",
    casterEventId = tickCaster.eventID,
    targetEventId = anchor.eventID,
    stacks = 1,
    turnsRemaining = 3,
    durationTurns = 3,
    stackBehavior = "refresh_duration",
    lastAdvancedOwnerTurnNumber = 1,
    definition = nearbyDefinition,
}
local bucket = AuraManager:GetEventAuraBucket(Client, eventState.id, true)
bucket.byKey[tickEntry.auraKey] = tickEntry
local executedTargets = {}
local originalTickAura = AuraManager.TickAura
AuraManager.TickAura = function(_, _, _, _, _, targetUnit)
    executedTargets[#executedTargets + 1] = targetUnit.eventID
    return false
end
assertTrue(AuraManager:AdvanceAuraEntry(Client, eventState.id, tickEntry.auraKey, 2, 1),
    "due area Aura advances through its tick")
assertEqual(#executedTargets, 3, "due area Aura executes once per selected recipient")
assertEqual(executedTargets[1], anchor.eventID, "area Aura executes on the anchor")
assertEqual(executedTargets[2], inside.eventID, "area Aura executes on the inside player")
assertEqual(executedTargets[3], boundary.eventID, "area Aura executes on the boundary player")
local executedCountAfterRefresh = #executedTargets
assertTrue(not AuraManager:AdvanceAuraEntry(Client, eventState.id, tickEntry.auraKey, 2, 1),
    "duplicate state refresh does not repeat the same owner tick")
assertEqual(#executedTargets, executedCountAfterRefresh, "duplicate state refresh does not duplicate recipients")
AuraManager.TickAura = originalTickAura

print("Aura tick targeting tests passed")
