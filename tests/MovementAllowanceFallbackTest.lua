local function assertEqual(actual, expected, message)
    if actual ~= expected then
        error(("%s: expected %s, got %s"):format(message, tostring(expected), tostring(actual)), 2)
    end
end

local function assertTrue(value, message)
    if value ~= true then error(message, 2) end
end

local function loadAddonFile(path, addon)
    local chunk, loadError = loadfile(path)
    assert(chunk, loadError)
    chunk("RPEngine2", addon)
end

local movementStatRef = "test:movement"
local controlOverride = nil
local Addon = {
    Client = {
        Spellcasting = {
            AuraManager = {
                BuildControlState = function()
                    return controlOverride == nil and {} or { movementRangeOverride = controlOverride }
                end,
            },
        },
    },
    Internal = {
        Profile = {
            GetMovementRangeStatRef = function() return movementStatRef end,
        },
    },
    Utils = {
        Lookup = {
            GetStatEntry = function(unit)
                return unit.hasMovementStat == true and {} or nil
            end,
            GetStatValue = function(unit)
                return unit.movementValue
            end,
        },
    },
}

RPE = { Core = { Movement = {} } }
loadAddonFile("client/autopilot/MovementAllowance.lua", Addon)

local Movement = RPE.Core.Movement
local eventState = { id = "movement-fallback" }
local function resolve(unit)
    return Movement:ResolveEventUnitMovementAllowance(eventState, unit)
end

local allowance, details = resolve({ eventID = 1, hasMovementStat = true, movementValue = 40 })
assertEqual(allowance, 40, "resolved movement stat is used")
assertEqual(details.baseStatFound, true, "resolved stat remains identified")

allowance, details = resolve({ eventID = 2, hasMovementStat = true, movementValue = 0 })
assertEqual(allowance, 0, "explicit zero movement stat remains zero")
assertEqual(details.usedMissingStatFallback, false, "explicit zero is not the missing-stat fallback")

allowance, details = resolve({ eventID = 3, hasMovementStat = false })
assertEqual(allowance, 30, "missing movement stat receives the runtime fallback")
assertEqual(details.baseStatFound, false, "missing stat remains identifiable")
assertEqual(details.usedMissingStatFallback, true, "fallback provenance is recorded")

controlOverride = 12
allowance, details = resolve({ eventID = 4, hasMovementStat = false })
assertEqual(allowance, 12, "control override takes priority over fallback")
assertEqual(details.usedMissingStatFallback, false, "override is not classified as fallback")

controlOverride = 0
allowance = resolve({ eventID = 5, hasMovementStat = true, movementValue = 40 })
assertEqual(allowance, 0, "zero control override remains zero")
controlOverride = nil

local firstMissing = resolve({ eventID = 6, hasMovementStat = false })
local secondMissing = resolve({ eventID = 7, hasMovementStat = false })
assertEqual(math.min(firstMissing, secondMissing), 30, "missing-stat cohort allowance does not collapse to zero")

loadAddonFile("client/autopilot/MovementAllowanceFrozen.lua", Addon)
local frozenUnit = {
    eventID = 8,
    __autopilotMovementSnapshot = {
        available = true,
        reason = "movement-range-stat-missing",
        statRef = movementStatRef,
        baseStatFound = false,
        usedMissingStatFallback = true,
        missingStatFallbackValue = 30,
        effectiveValue = 30,
    },
}
allowance, details = resolve(frozenUnit)
assertEqual(allowance, 30, "frozen fallback allowance is preserved")
assertTrue(details.frozen, "frozen allowance is identified")
assertEqual(details.usedMissingStatFallback, true, "frozen fallback provenance is preserved")

print("MovementAllowanceFallbackTest passed")
