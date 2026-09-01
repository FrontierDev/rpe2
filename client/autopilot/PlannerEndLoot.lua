local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Internal = Addon.Internal or {}
Addon.Internal.Database = Addon.Internal.Database or {}
Addon.Internal.Database.Classes = Addon.Internal.Database.Classes or {}

local Planner = Addon.Client.AutopilotPlanner
local Event = Addon.Internal.Database.Classes.Event

if type(Planner) ~= "table" or type(Event) ~= "table" or Planner._endLootSnapshotIntegrationInstalled == true then
    return
end

local baseCreateState = Planner.CreateState
if type(baseCreateState) == "function" then
    function Planner.CreateState(eventState, ...)
        local state = baseCreateState(eventState, ...)
        local frozenEvent = type(state) == "table"
            and type(state.snapshot) == "table"
            and state.snapshot.eventState
            or nil
        if type(frozenEvent) == "table" then
            frozenEvent.endLootGrants = type(Event.CloneEndLootGrants) == "function"
                and Event.CloneEndLootGrants(eventState and eventState.endLootGrants)
                or {}
            frozenEvent.lootRefs = type(Event.BuildLegacyLootRefsFromEndLootGrants) == "function"
                and Event.BuildLegacyLootRefsFromEndLootGrants(frozenEvent.endLootGrants)
                or frozenEvent.lootRefs
        end
        return state
    end
end

Planner._endLootSnapshotIntegrationInstalled = true
