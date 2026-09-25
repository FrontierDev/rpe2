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

local function assertRow(rows, index, kind, eventId, message)
    local row = rows[index]
    assertTrue(type(row) == "table", message .. " exists")
    assertEqual(row.kind, kind, message .. " kind")
    if eventId ~= nil then
        assertEqual(row.eventID, eventId, message .. " event id")
    end
    return row
end

local Addon = {
    Client = {
        HasUnitAttackedTargetOnTurn = function(_, eventState, attackerEventId, targetEventId, turnNumber)
            return tonumber(eventState and eventState.attackHistoryTurn) == tonumber(turnNumber)
                and tonumber(attackerEventId) == 5
                and tonumber(targetEventId) == 4
        end,
        ResolveLocalEventUnit = function(_, eventState)
            return eventState and eventState.units and eventState.units[2]
        end,
        Spellcasting = {
            IsCasterTurnOnTick = function(eventState, eventId)
                return tonumber(eventId) == (tonumber(eventState and eventState.tickNumber) == 1 and 3 or 5)
            end,
        },
        UI = {
            EventWidget = {
                EnsureCombatLogHistoryUI = function() end,
                ShowEventUtilityWindow = function() end,
                RefreshPortraitsForEventIds = function() return true end,
                IsEventUnitActive = function(_, unit)
                    return unit and unit.active ~= false
                end,
                BuildWidgetDisplayUnit = function(_, unit)
                    if unit.hidden == true then
                        return {
                            eventID = unit.eventID,
                            team = unit.team,
                            name = "Unknown Unit",
                            hidden = true,
                            active = true,
                            raidMarker = 0,
                        }
                    end
                    return unit
                end,
                ResolveEventUnitHealthState = function(_, unit)
                    return unit.health
                end,
            },
        },
    },
    UI = {},
    Internal = {
        Database = {
            Classes = {
                Event = {
                    GetTeamName = function(_, team)
                        return ({ [1] = "Heroes", [2] = "Enemies" })[team] or ("Team " .. tostring(team))
                    end,
                    GetTeamColor = function() return { r = 1, g = 1, b = 1, a = 1 } end,
                },
            },
        },
    },
}

local function loadAddonFile(path)
    local chunk, loadError = loadfile(path)
    assert(chunk, loadError)
    chunk("RPEngine2", Addon)
end

loadAddonFile("client/ui/widgets/widget_Event_AllUnits.lua")

local EventWidget = Addon.Client.UI.EventWidget
local state = {
    active = true,
    ending = false,
    id = "all-units-test",
    turnNumber = 1,
    tickNumber = 1,
    attackHistoryTurn = 0,
    unitsReady = true,
    startupReady = true,
    teams = { { name = "Heroes" }, { name = "Enemies" } },
    units = {
        { eventID = 3, team = 1, name = "Fallen Hero", raidMarker = 0, active = true, health = { currentValue = 0, maxValue = 100 } },
        { eventID = 5, team = 1, name = "Marked Hero", raidMarker = 1, isPlayer = true, active = true, health = { currentValue = 50, maxValue = 100 } },
        { eventID = 7, team = 1, name = "Hidden Hero", raidMarker = 8, hidden = true, active = true },
        { eventID = 8, team = 1, name = "Summoned Pet", raidMarker = 3, petRef = "pet", active = true },
        { eventID = 1, team = 1, name = "Inactive", active = false },
        { eventID = 4, team = 2, name = "Enemy Two", raidMarker = 2, active = true },
        { eventID = 6, team = 2, name = "Enemy One", raidMarker = 1, active = true },
    },
}
Addon.Client.EventState = state

local rows = EventWidget:BuildAllUnitsRows(state)

assertEqual(rows[1].kind, "team", "first team heading")
assertEqual(rows[1].name, "Heroes", "configured first team name")
assertRow(rows, 2, "unit", 5, "marked hero sorts first")
assertRow(rows, 3, "unit", 8, "marked pet remains in marker order")
assertRow(rows, 4, "unit", 3, "unmarked dead unit remains")
assertEqual(rows[4].healthState.currentValue, 0, "dead unit health remains visible to the view")
assertRow(rows, 5, "unit", 7, "hidden unit remains")
local hiddenRow = rows[5]
assertEqual(hiddenRow.unit.name, "Unknown Unit", "hidden unit name is masked")
assertEqual(hiddenRow.unit.raidMarker, 0, "hidden unit marker is masked")
assertEqual(hiddenRow.healthState, nil, "hidden unit health is masked")
assertTrue(hiddenRow.currentTurn ~= true, "hidden unit does not expose current-turn metadata")
assertEqual(rows[6].kind, "team", "second team heading follows first group")
assertEqual(rows[6].name, "Enemies", "configured second team name")
assertRow(rows, 7, "unit", 6, "second team marker one sorts first")
assertRow(rows, 8, "unit", 4, "second team marker two sorts second")
assertTrue(rows[4].currentTurn == true, "current turn uses existing caster-turn semantics")
assertTrue(rows[8].attackedLastTurn ~= true, "attack highlight is not shown before the previous turn has attack history")

state.turnNumber = 2
state.attackHistoryTurn = 1
rows = EventWidget:BuildAllUnitsRows(state)
assertTrue(rows[8].attackedLastTurn == true, "local player's previous-turn target is marked")
assertTrue(rows[4].attackedLastTurn ~= true, "unattacked units are not marked")
state.turnNumber = 1
state.attackHistoryTurn = 0

local utilityFrame = {
    shown = true,
    Show = function(self) self.shown = true end,
    Hide = function(self) self.shown = false end,
    IsShown = function(self) return self.shown end,
}
EventWidget.eventUtilityMode = "all-units"
EventWidget.eventUtilityWindow = { GetFrame = function() return utilityFrame end }
EventWidget.allUnitsPanel = { GetFrame = function() return utilityFrame end }
EventWidget.allUnitsEmptyText = { GetFrame = function() return { Show = function() end, Hide = function() end } end }
EventWidget.allUnitsButton = {
    SetEnabled = function(self, enabled) self.enabled = enabled end,
}
EventWidget.allUnitsScroll = {
    updates = 0,
    items = {},
    SetItems = function(self, items)
        self.updates = self.updates + 1
        self.items = items
    end,
}

assertTrue(EventWidget:RefreshAllUnitsAvailability(state), "ready state enables availability during Build")
assertTrue(EventWidget.allUnitsButton.enabled, "Build-time availability enables the All Units button")
assertTrue(EventWidget:RefreshAllUnitsPanel(state, true), "ready state refreshes the visible panel")
assertEqual(EventWidget.allUnitsScroll.updates, 1, "initial refresh updates rows")
assertTrue(EventWidget.allUnitsButton.enabled, "ready state enables the All Units button")
assertTrue(not EventWidget:RefreshAllUnitsPanel(state), "unchanged presentation signature skips refresh")
assertEqual(EventWidget.allUnitsScroll.updates, 1, "skipped refresh does not rebuild rows")

state.units[1].health.currentValue = 25
assertTrue(EventWidget:RefreshPortraitsForEventIds({ [3] = true }, "resource-delta"), "targeted refresh route remains callable")
assertEqual(EventWidget.allUnitsScroll.updates, 2, "health change refreshes the visible panel")

state.units[3].hidden = false
assertTrue(EventWidget:RefreshAllUnitsPanel(state), "hidden-state change invalidates the presentation")
assertEqual(EventWidget.allUnitsScroll.items[4].unit.name, "Hidden Hero", "unhidden unit restores its details")

state.tickNumber = 2
assertTrue(EventWidget:RefreshAllUnitsPanel(state), "turn-step change invalidates the presentation")
assertTrue(EventWidget.allUnitsScroll.items[2].currentTurn == true, "current-turn indicator moves to the next unit")
assertTrue(EventWidget.allUnitsScroll.items[5].currentTurn ~= true, "previous current-turn indicator clears")

local startupState = {
    active = true,
    ending = false,
    id = "starting",
    unitsReady = true,
    startupReady = false,
    teams = state.teams,
    units = state.units,
}
assertTrue(not EventWidget:RefreshAllUnitsPanel(startupState), "startup state is not presented as authoritative")
assertTrue(not EventWidget.allUnitsButton.enabled, "startup state disables the All Units button")
assertTrue(not utilityFrame:IsShown(), "startup transition hides the utility window")

assertTrue(not EventWidget:RefreshAllUnitsPanel({ active = false, ending = true }, true), "event end clears the view")
assertEqual(#EventWidget.allUnitsScroll.items, 0, "event end removes stale rows")

print("EventAllUnitsTest passed")
