local _, Addon = ...

Addon.Server = Addon.Server or {}
Addon.Internal = Addon.Internal or {}
Addon.Internal.Database = Addon.Internal.Database or {}
Addon.Internal.Database.Classes = Addon.Internal.Database.Classes or {}

local Server = Addon.Server
local Event = Addon.Internal.Database.Classes.Event

if type(Server) ~= "table" or type(Event) ~= "table" or Server._eventEndLootIntegrationInstalled == true then
    return
end

local function cloneGrants(values)
    if type(Event.CloneEndLootGrants) == "function" then
        return Event.CloneEndLootGrants(values)
    end

    local cloned = {}
    for index = 1, #(type(values) == "table" and values or {}) do
        local source = values[index]
        if type(source) == "table" then
            local copy = {
                sourceType = source.sourceType,
                distribution = source.distribution,
                lootRef = source.lootRef,
            }
            if type(source.reward) == "table" then
                copy.reward = {
                    type = source.reward.type,
                    ref = source.reward.ref,
                    amount = source.reward.amount,
                }
            end
            cloned[#cloned + 1] = copy
        end
    end
    return cloned
end

local function deriveLegacy(values)
    if type(Event.BuildEndLootGrantsFromLegacyRefs) == "function" then
        return Event.BuildEndLootGrantsFromLegacyRefs(values)
    end
    return {}
end

local function chooseStartGrants(server, data)
    local values = type(data) == "table" and data or {}
    if values.endLootGrants ~= nil then
        return cloneGrants(values.endLootGrants)
    end
    if values.lootRefs ~= nil then
        return deriveLegacy(values.lootRefs)
    end

    local draft = server.EventDraftState
    if type(draft) == "table" then
        if draft.endLootGrants ~= nil then
            return cloneGrants(draft.endLootGrants)
        end
        return deriveLegacy(draft.lootRefs)
    end
    return {}
end

local function applyGrants(eventState, grants)
    if type(eventState) ~= "table" then
        return false
    end
    if type(eventState.Merge) == "function" then
        eventState:Merge({ endLootGrants = cloneGrants(grants) })
    else
        eventState.endLootGrants = cloneGrants(grants)
        if type(Event.BuildLegacyLootRefsFromEndLootGrants) == "function" then
            eventState.lootRefs = Event.BuildLegacyLootRefsFromEndLootGrants(eventState.endLootGrants)
        end
    end
    return true
end

function Server:SyncEndLootGrantsToDraft(eventStateOverride)
    local liveState = eventStateOverride or self.EventState
    local draftState = self.EventDraftState
    if type(liveState) ~= "table" or type(draftState) ~= "table" then
        return false
    end
    return applyGrants(draftState, liveState.endLootGrants)
end

local baseCopyLiveEventToDraftState = Server.CopyLiveEventToDraftState
if type(baseCopyLiveEventToDraftState) == "function" then
    function Server:CopyLiveEventToDraftState(...)
        local result = baseCopyLiveEventToDraftState(self, ...)
        if result == true then
            self:SyncEndLootGrantsToDraft(self.EventState)
        end
        return result
    end
end

local baseStartEvent = Server.StartEvent
if type(baseStartEvent) == "function" then
    function Server:StartEvent(data, ...)
        local grants = chooseStartGrants(self, data)
        local previousContext = nil
        if type(Event.PushEndLootConstructionContext) == "function" then
            previousContext = Event.PushEndLootConstructionContext(grants)
        end

        local results = { pcall(baseStartEvent, self, data, ...) }
        local resultCount = #results

        if type(Event.PopEndLootConstructionContext) == "function" then
            Event.PopEndLootConstructionContext(previousContext)
        end

        if results[1] ~= true then
            error(results[2], 0)
        end

        local eventState = results[2]
        if type(eventState) == "table" then
            applyGrants(eventState, grants)
            if type(self.EventDraftState) == "table" then
                applyGrants(self.EventDraftState, grants)
            end
        end

        return unpack(results, 2, resultCount)
    end
end

Server._eventEndLootIntegrationInstalled = true
