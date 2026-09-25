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

local function newFrame()
    return {
        shown = false,
        Show = function(self) self.shown = true end,
        Hide = function(self) self.shown = false end,
        IsShown = function(self) return self.shown end,
        Raise = function(self) self.raised = true end,
    }
end

local function newElement(frame)
    return {
        GetFrame = function() return frame end,
    }
end

local Addon = {
    Client = {
        UI = {
            EventWidget = {
                Build = function() end,
                Hide = function() end,
                Refresh = function() end,
                QueueCombatLogEntry = function() return true end,
                ClearCombatLogTicker = function() end,
            },
        },
    },
    UI = {},
}

local function loadAddonFile(path)
    local chunk, loadError = loadfile(path)
    assert(chunk, loadError)
    chunk("RPEngine2", Addon)
end

local EventWidget = Addon.Client.UI.EventWidget
local utilityFrame = newFrame()
local combatLogScrollFrame = newFrame()
local combatLogEmptyFrame = newFrame()
local metersFrame = newFrame()
local allUnitsFrame = newFrame()
local legacyHistoryFrame = newFrame()

EventWidget.eventUtilityWindow = {
    GetFrame = function() return utilityFrame end,
    SetTitle = function(self, title) self.title = title end,
}
EventWidget.combatLogUtilityScroll = newElement(combatLogScrollFrame)
EventWidget.combatLogUtilityEmptyText = newElement(combatLogEmptyFrame)
EventWidget.metersPanel = newElement(metersFrame)
EventWidget.allUnitsPanel = newElement(allUnitsFrame)
EventWidget.combatLogHistoryPanel = newElement(legacyHistoryFrame)

loadAddonFile("client/ui/widgets/widget_Event_CombatLogHistory.lua")
loadAddonFile("client/ui/widgets/widget_Event_Meters.lua")
loadAddonFile("client/ui/widgets/widget_Event_AllUnits.lua")

local function assertMode(mode, title, selectedFrames, message)
    assertEqual(EventWidget.eventUtilityMode, mode, message .. " mode")
    assertEqual(EventWidget.eventUtilityWindow.title, title, message .. " title")
    assertTrue(utilityFrame:IsShown(), message .. " window is shown")
    local selected = {}
    for _, frame in ipairs(selectedFrames) do
        selected[frame] = true
        assertTrue(frame:IsShown(), message .. " selected panel is shown")
    end
    for _, frame in ipairs({ combatLogScrollFrame, combatLogEmptyFrame, metersFrame, allUnitsFrame }) do
        if not selected[frame] then
            assertTrue(not frame:IsShown(), message .. " hides non-selected panels")
        end
    end
    assertTrue(not legacyHistoryFrame:IsShown(), message .. " hides the legacy history panel")
end

EventWidget:ShowEventUtilityWindow("combat-log")
assertMode("combat-log", "Combat Log", { combatLogScrollFrame, combatLogEmptyFrame }, "combat log opens")

EventWidget.EnsureMetersUI = function() return EventWidget.metersPanel end
EventWidget.RefreshMetersPanel = function() return true end
EventWidget:ShowMetersPanel()
assertMode("meters", "Meters", { metersFrame }, "meters opens")

EventWidget:ShowEventUtilityWindow("combat-log")
assertMode("combat-log", "Combat Log", { combatLogScrollFrame, combatLogEmptyFrame }, "switching back to combat log works")
EventWidget:HideEventUtilityWindow()
assertEqual(EventWidget.eventUtilityMode, nil, "closing combat log clears the active mode")
assertTrue(not utilityFrame:IsShown(), "closing combat log hides the utility window")

EventWidget:ShowMetersPanel()
assertMode("meters", "Meters", { metersFrame }, "meters reopens")
EventWidget:ToggleMetersPanel()
assertEqual(EventWidget.eventUtilityMode, nil, "toggling meters closes and clears the active mode")
assertTrue(not utilityFrame:IsShown(), "toggling meters closes the utility window")

EventWidget:ShowMetersPanel()
EventWidget:ToggleCombatLogHistoryPanel()
assertMode("combat-log", "Combat Log", { combatLogScrollFrame, combatLogEmptyFrame }, "combat log button switches from meters")
EventWidget:ToggleCombatLogHistoryPanel()
assertEqual(EventWidget.eventUtilityMode, nil, "toggling combat log closes and clears the active mode")
assertTrue(not utilityFrame:IsShown(), "toggling combat log closes the utility window")

EventWidget:ShowEventUtilityWindow("all-units")
assertMode("all-units", "All Units", { allUnitsFrame }, "all-units dispatch is reserved")
EventWidget:HideEventUtilityWindow()

-- Refreshing the widget while Meters is open must preserve the shared mode and
-- route the refresh back to the Meters integration.
Addon.Client.EventState = { active = true, ending = false, id = "utility-test" }
EventWidget.combatLogHistoryEventId = "utility-test"
EventWidget.EnsureCombatLogHistoryUI = function() return true end
EventWidget.RefreshCombatLogHistoryPanel = function() return true end
EventWidget:ShowMetersPanel()
EventWidget:Refresh()
assertMode("meters", "Meters", { metersFrame }, "refresh preserves the meters mode")

-- DM Helper continues to use only the legacy side panel and never claims the
-- shared utility mode.
EventWidget:ShowCombatLogHistoryPanel("dm-helper")
assertEqual(EventWidget.eventUtilityMode, nil, "DM Helper leaves the shared mode clear")
assertTrue(legacyHistoryFrame:IsShown(), "DM Helper legacy panel remains available")
assertTrue(not utilityFrame:IsShown(), "DM Helper does not show the utility window")

EventWidget:ShowCombatLogHistoryPanel("combat-log")
assertMode("combat-log", "Combat Log", { combatLogScrollFrame, combatLogEmptyFrame }, "combat log remains available after DM Helper")

print("EventUtilityWindowModeTest passed")
