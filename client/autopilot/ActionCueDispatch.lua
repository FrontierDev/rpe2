local _, Addon = ...

Addon.Client = Addon.Client or {}
local Client = Addon.Client
local unpackValues = unpack or (table and table.unpack)
local Event = Addon.Internal and Addon.Internal.Database
    and Addon.Internal.Database.Classes and Addon.Internal.Database.Classes.Event or nil

local function pack(...)
    return { n = select("#", ...), ... }
end

local Dispatch = Client.AutopilotActionCueDispatch or {
    handlers = {},
    handlerKeys = {},
}
Client.AutopilotActionCueDispatch = Dispatch

function Client:RegisterAutopilotActionCueHandler(key, handlers)
    key = tostring(key or "")
    if key == "" or type(handlers) ~= "table" then return false end
    if Dispatch.handlers[key] then return true end
    Dispatch.handlers[key] = handlers
    Dispatch.handlerKeys[#Dispatch.handlerKeys + 1] = key
    return true
end

local function currentState(override)
    if type(override) == "table" then return override end
    if type(Client.GetEventState) == "function" then return Client:GetEventState() end
    return Client.EventState
end

local function isAutopilot(eventState)
    if type(Event) == "table" and type(Event.NormalizeTurnMode) == "function" then
        return Event.NormalizeTurnMode(eventState and eventState.turnMode) == "autopilot"
    end
    return tostring(eventState and eventState.turnMode or "manual") == "autopilot"
end

local function currentPlanFor(action, plan, eventState)
    if type(action) ~= "table" or type(plan) ~= "table"
        or type(eventState) ~= "table" or eventState.active ~= true or eventState.ending == true
        or not isAutopilot(eventState)
        or type(Client.IsLocalEventHost) ~= "function" or Client:IsLocalEventHost(eventState) ~= true
        or type(Client.GetAutopilotPendingPlan) ~= "function"
    then
        return false
    end
    local activePlan = Client:GetAutopilotPendingPlan(eventState)
    return activePlan == plan
        and tostring(plan.status or "") ~= "stale"
        and tostring(plan.eventId or "") == tostring(eventState.id or "")
        and tonumber(plan.turnNumber) == tonumber(eventState.turnNumber)
        and tonumber(plan.tickNumber) == tonumber(eventState.tickNumber)
        and type(plan.actionsById) == "table"
        and plan.actionsById[tostring(action.actionId or "")] == action
end

local function dispatch(kind, action, plan, eventState)
    for index = 1, #Dispatch.handlerKeys do
        local handlers = Dispatch.handlers[Dispatch.handlerKeys[index]]
        local callback = type(handlers) == "table" and handlers[kind] or nil
        if type(callback) == "function" then
            -- Presentation failures must never change authorization or movement results.
            pcall(callback, action, plan, eventState)
        end
    end
end

if Client._autopilotActionCueDispatchInstalled ~= true then
    Client._autopilotActionCueDispatchInstalled = true

    local baseAuthorized = Client.OnAutopilotPendingActionAuthorized
    if type(baseAuthorized) == "function" then
        function Client:OnAutopilotPendingActionAuthorized(action, plan, eventState, ...)
            local shouldDispatch = type(action) == "table"
                and action.actionType == "spell"
                and action.status == "authorized"
                and currentPlanFor(action, plan, eventState)
            local results = pack(baseAuthorized(self, action, plan, eventState, ...))
            if shouldDispatch and results[1] == true and currentPlanFor(action, plan, eventState) then
                -- Gameplay commits first. Presentation must never run ahead of a cast
                -- that can still fail validation, local state mutation, or comms enqueue.
                dispatch("spellAuthorized", action, plan, eventState)
            end
            return unpackValues(results, 1, results.n)
        end
    end

    local baseConfirmMovement = Client.ConfirmAutopilotPendingMovement
    if type(baseConfirmMovement) == "function" then
        function Client:ConfirmAutopilotPendingMovement(actionId, eventStateOverride, ...)
            local results = pack(baseConfirmMovement(self, actionId, eventStateOverride, ...))
            local action = results[2]
            local eventState = currentState(eventStateOverride)
            if results[1] == true and type(action) == "table" and action.actionType == "movement"
                and action.status == "confirmed"
            then
                local plan = type(self.GetAutopilotPendingPlan) == "function" and self:GetAutopilotPendingPlan(eventState) or nil
                if currentPlanFor(action, plan, eventState) then
                    dispatch("movementConfirmed", action, plan, eventState)
                end
            end
            return unpackValues(results, 1, results.n)
        end
    end
end

return Dispatch
