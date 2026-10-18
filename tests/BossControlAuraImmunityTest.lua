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

local auraDataset = {
    id = "boss-control-test",
    auras = {
        {
            id = "stun",
            name = "Stun",
            duration = 2,
            effects = {
                {
                    type = "control",
                    preventCasting = true,
                    movementRangeOverride = 0,
                },
            },
        },
        {
            id = "damage-over-time",
            name = "Damage over Time",
            duration = 2,
            effects = {
                {
                    type = "damage",
                    baseDamage = 10,
                    statScaling = {},
                },
            },
        },
    },
}

local caster = { eventID = 1, name = "Caster" }
local boss = { eventID = 2, name = "Boss", challengeLevel = "boss" }
local normalTarget = { eventID = 3, name = "Normal Target", challengeLevel = "normal" }
local eventState = {
    active = true,
    id = "boss-control-event",
    turnNumber = 1,
    tickNumber = 1,
    units = { caster, boss, normalTarget },
}

local Addon = {
    Client = {
        Spellcasting = {
            GetLocalPlayerName = function() return "" end,
        },
        GetEventState = function() return eventState end,
    },
    Internal = {
        Tasks = {
            Enqueue = function() return true end,
        },
        Comms = {
            Operations = {
                GetOpcode = function(_, name)
                    return ({
                        AURA_APPLY = 1,
                        AURA_DISPEL = 2,
                        AURA_APPLY_BATCH = 3,
                        AURA_DISPEL_BATCH = 4,
                        AURA_RUNTIME_UPDATE = 5,
                        AURA_RUNTIME_UPDATE_BATCH = 6,
                    })[name]
                end,
            },
        },
        Database = {
            Classes = {},
            GetDatasetByID = function(datasetId)
                return datasetId == auraDataset.id and auraDataset or nil
            end,
        },
        Registry = {},
    },
    Utils = {
        Common = {
            Round = function(value) return math.floor(value + 0.5) end,
        },
        Lookup = {
            FindEventUnitById = function(units, eventId)
                for index = 1, #(units or {}) do
                    if tonumber(units[index].eventID) == tonumber(eventId) then
                        return units[index]
                    end
                end
                return nil
            end,
        },
    },
    Debug = {
        Internal = function() end,
    },
}

local chunk, loadError = loadfile("client/spellcasting/AuraManager.lua")
assert(chunk, loadError)
chunk("RPEngine2", Addon)

local AuraManager = Addon.Client.Spellcasting.AuraManager
AuraManager.QueueAuraApply = function()
    return true
end

local function applyAura(targetUnit, auraRef)
    return AuraManager:UpsertAura(Addon.Client, {
        eventState = eventState,
        dataset = auraDataset,
        datasetId = auraDataset.id,
        auraRef = auraRef,
        casterEventId = caster.eventID,
        targetEventId = targetUnit.eventID,
        stacks = 1,
        turns = 2,
    })
end

local bossControlApplied = applyAura(boss, "boss-control-test:stun")
assertFalse(bossControlApplied, "Boss units reject control auras")

local normalControlApplied = applyAura(normalTarget, "boss-control-test:stun")
assertTrue(normalControlApplied, "Normal units accept control auras")

local bossDamageApplied = applyAura(boss, "boss-control-test:damage-over-time")
assertTrue(bossDamageApplied, "Boss units still accept non-control auras")

local bucket = AuraManager:GetEventAuraBucket(Addon.Client, eventState.id, false)
assertEqual(bucket.byKey["boss-control-test:stun\31" .. caster.eventID .. "\31" .. boss.eventID], nil,
    "Rejected boss control aura is not stored")

print("BossControlAuraImmunityTest passed")
