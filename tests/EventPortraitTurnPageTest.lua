local function assertEqual(actual, expected, message)
    if actual ~= expected then
        error(("%s: expected %s, got %s"):format(message, tostring(expected), tostring(actual)), 2)
    end
end

local function assertUnitIds(units, expectedIds, message)
    assertEqual(#units, #expectedIds, message .. " count")
    for index = 1, #expectedIds do
        assertEqual(units[index].eventID, expectedIds[index], message .. " unit " .. index)
    end
end

local TestSupport = dofile("tests/support/RuntimeStubs.lua")
local Addon = {
    Client = { UI = {} },
    UI = {},
    Utils = {},
    Internal = {
        Database = {
            Classes = {
                EventUnit = {
                    IsActive = function(unit)
                        return type(unit) == "table" and unit.active ~= false
                    end,
                    IsBoss = function(unit)
                        return type(unit) == "table" and unit.boss == true
                    end,
                    CoerceBoolean = function(value, fallback)
                        if value == nil then return fallback == true end
                        return value == true
                    end,
                },
            },
        },
        Ruleset = {
            GetActiveRuleset = function() return {} end,
            GetRulesetRuleDefinition = function() return {} end,
            GetRulesetRuleValue = function() return 5 end,
        },
    },
}

TestSupport.LoadAddonFile("core/classes/Event.lua", Addon)
TestSupport.LoadAddonFile("core/classes/EventAutopilotMode.lua", Addon)
TestSupport.LoadAddonFile("client/ui/widgets/widget_Event.lua", Addon)
TestSupport.LoadAddonFile("client/ui/widgets/widget_EventAutopilotSchedule.lua", Addon)

local EventWidget = Addon.Client.UI.EventWidget
local Event = Addon.Internal.Database.Classes.Event

local function unit(eventID, options)
    local record = {
        eventID = eventID,
        active = true,
        initiative = 100 - eventID,
        raidMarker = 0,
    }
    for key, value in pairs(options or {}) do
        record[key] = value
    end
    return record
end

local function contextFor(state, tickNumber)
    state.tickNumber = tickNumber
    return EventWidget:BuildPortraitRefreshContext(state)
end

-- The first five active units form the turn page INCLUDING the boss.
-- Excluding the boss before pagination used to introduce unit 6 prematurely.
local state = {
    id = "portrait-turn-test",
    active = true,
    turnMode = "manual",
    units = {
        unit(1, { boss = true }),
        unit(2), unit(3), unit(4), unit(5), unit(6),
    },
}
local first = contextFor(state, 1)
assertUnitIds(Event.GetUnitsForPage(state.units, 1, 5), { 1, 2, 3, 4, 5 }, "authoritative first page")
assertUnitIds(first.pageUnits, { 2, 3, 4, 5 }, "boss consumes a first-page slot")
assertUnitIds(first.bossUnits, { 1 }, "boss retains dedicated row")
assertEqual(first.portraitSlotCount, 5, "portrait capacity is unchanged")

local second = contextFor(state, 2)
assertUnitIds(second.pageUnits, { 6 }, "next-turn unit appears only on its own turn")
assertUnitIds(second.bossUnits, { 1 }, "boss row persists across turn pages")

-- A boss in the middle of a page must not change the five-unit turn boundary.
state.units = {
    unit(2), unit(3), unit(1, { boss = true }), unit(4), unit(5), unit(6),
}
assertUnitIds(contextFor(state, 1).pageUnits, { 2, 3, 4, 5 }, "middle boss does not shift page")
assertUnitIds(contextFor(state, 2).pageUnits, { 6 }, "middle boss leaves next page untouched")

-- If only a boss has the turn, the ordinary row must be empty.
state.units = {
    unit(2), unit(3), unit(4), unit(5), unit(6), unit(1, { boss = true }),
}
local bossOnlyStep = contextFor(state, 2)
assertUnitIds(bossOnlyStep.pageUnits, {}, "boss-only page leaves ordinary row empty")
assertUnitIds(bossOnlyStep.bossUnits, { 1 }, "boss-only page keeps boss portrait")

-- Inactive units and player-owned pets do not consume standalone turn slots.
state.units = {
    unit(1, { boss = true }),
    unit(9, { active = false }),
    unit(10, { isPet = true, summonedByEventID = 2 }),
    unit(2, { isPlayer = true }),
    unit(3), unit(4), unit(5), unit(6),
}
assertUnitIds(contextFor(state, 1).pageUnits, { 2, 3, 4, 5 }, "inactive and shared-turn pet omitted")
assertUnitIds(contextFor(state, 2).pageUnits, { 6 }, "shared-turn pet does not shift next page")

-- Normal encounters still show up to five ordinary actors per turn page.
state.units = { unit(2), unit(3), unit(4), unit(5), unit(6), unit(7) }
assertUnitIds(contextFor(state, 1).pageUnits, { 2, 3, 4, 5, 6 }, "no-boss first page")
assertUnitIds(contextFor(state, 2).pageUnits, { 7 }, "no-boss second page")
assertUnitIds(contextFor(state, 1).bossUnits, {}, "no-boss encounter has no boss row")

-- Autopilot uses its own actor schedule; it must retain the same separation.
state.turnMode = "autopilot"
state.units = { unit(1, { boss = true }), unit(2), unit(3), unit(4), unit(5), unit(6) }
assertUnitIds(contextFor(state, 1).pageUnits, { 2, 3, 4, 5 }, "autopilot first step")
assertUnitIds(contextFor(state, 2).pageUnits, { 6 }, "autopilot second step")

print("EventPortraitTurnPageTest passed")
