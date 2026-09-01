local _, Addon = ...

Addon.Internal = Addon.Internal or {}
Addon.Internal.Database = Addon.Internal.Database or {}
Addon.Internal.Database.Classes = Addon.Internal.Database.Classes or {}

local Event = Addon.Internal.Database.Classes.Event
local Autopilot = Addon.Internal.Autopilot or {}

if type(Event) ~= "table" then
    return
end

local DEFAULT_TURN_STEP_CAPACITY = 5

local function normalizeTurnMode(value)
    if type(Autopilot.NormalizeTurnMode) == "function" then
        return Autopilot.NormalizeTurnMode(value)
    end
    return tostring(value or "") == "autopilot" and "autopilot" or "manual"
end

local function normalizeStepCapacity(value)
    local numericValue = math.floor(tonumber(value) or DEFAULT_TURN_STEP_CAPACITY)
    if numericValue <= 0 then
        return DEFAULT_TURN_STEP_CAPACITY
    end
    return numericValue
end

local function compareUnits(left, right)
    local leftInitiative = tonumber(left and left.initiative) or 0
    local rightInitiative = tonumber(right and right.initiative) or 0
    if leftInitiative ~= rightInitiative then
        return leftInitiative > rightInitiative
    end

    local leftEventId = tonumber(left and left.eventID) or 0
    local rightEventId = tonumber(right and right.eventID) or 0
    if leftEventId ~= rightEventId then
        return leftEventId < rightEventId
    end

    local leftName = tostring(left and left.name or "")
    local rightName = tostring(right and right.name or "")
    if leftName ~= rightName then
        return leftName < rightName
    end

    return tostring(left and left.registryID or "") < tostring(right and right.registryID or "")
end

local function isUnitActive(unit)
    if type(Event.IsUnitActive) == "function" then
        return Event.IsUnitActive(unit) == true
    end
    return type(unit) == "table" and (unit.isPlayer == true or unit.active == true)
end

local function isPlayerSharedTurnPet(units, unit)
    return type(Event.IsPlayerSharedTurnPet) == "function"
        and Event.IsPlayerSharedTurnPet(units, unit) == true
end

local function resolveSharedTurnOwnerEventId(units, eventId)
    local numericEventId = tonumber(eventId) or 0
    if numericEventId <= 0 then
        return nil
    end

    for index = 1, #(units or {}) do
        local unit = units[index]
        if tonumber(unit and unit.eventID) == numericEventId then
            if isPlayerSharedTurnPet(units, unit) then
                local ownerEventId = tonumber(unit.summonedByEventID) or tonumber(unit.controllerID) or 0
                if ownerEventId > 0 then
                    return ownerEventId
                end
            end
            return numericEventId
        end
    end

    return numericEventId
end

local function finalizeActor(actor)
    table.sort(actor.units, compareUnits)

    actor.unitEventIds = {}
    actor.initiative = 0
    for index = 1, #actor.units do
        local unit = actor.units[index]
        actor.unitEventIds[index] = tonumber(unit and unit.eventID) or 0
        actor.initiative = math.max(actor.initiative, tonumber(unit and unit.initiative) or 0)
    end

    actor.unitCount = #actor.units
    actor.firstEventId = actor.unitEventIds[1] or 0
    return actor
end

local function compareActors(left, right)
    local leftInitiative = tonumber(left and left.initiative) or 0
    local rightInitiative = tonumber(right and right.initiative) or 0
    if leftInitiative ~= rightInitiative then
        return leftInitiative > rightInitiative
    end

    local leftUnit = left and left.units and left.units[1] or nil
    local rightUnit = right and right.units and right.units[1] or nil
    if leftUnit ~= rightUnit then
        if compareUnits(leftUnit, rightUnit) then
            return true
        end
        if compareUnits(rightUnit, leftUnit) then
            return false
        end
    end

    return tostring(left and left.key or "") < tostring(right and right.key or "")
end

function Event.BuildTurnActors(eventState)
    local units = type(eventState) == "table" and eventState.units or nil
    local actors = {}
    local markerActors = {}

    for index = 1, #(units or {}) do
        local unit = units[index]
        if isUnitActive(unit) and not isPlayerSharedTurnPet(units, unit) then
            local eventId = tonumber(unit and unit.eventID) or 0
            if eventId > 0 then
                if unit.isPlayer == true then
                    actors[#actors + 1] = {
                        key = "player:" .. eventId,
                        kind = "player",
                        raidMarker = 0,
                        units = { unit },
                    }
                else
                    local raidMarker = math.max(0, math.floor(tonumber(unit.raidMarker) or 0))
                    if raidMarker > 0 then
                        local actorKey = "marker:" .. raidMarker
                        local actor = markerActors[actorKey]
                        if not actor then
                            actor = {
                                key = actorKey,
                                kind = "npc_marker",
                                raidMarker = raidMarker,
                                units = {},
                            }
                            markerActors[actorKey] = actor
                            actors[#actors + 1] = actor
                        end
                        actor.units[#actor.units + 1] = unit
                    else
                        actors[#actors + 1] = {
                            key = "npc:" .. eventId,
                            kind = "npc",
                            raidMarker = 0,
                            units = { unit },
                        }
                    end
                end
            end
        end
    end

    for index = 1, #actors do
        finalizeActor(actors[index])
    end
    table.sort(actors, compareActors)
    return actors
end

function Event.BuildTurnSchedule(eventState, stepCapacity)
    local capacity = normalizeStepCapacity(stepCapacity)
    local actors = Event.BuildTurnActors(eventState)
    local steps = {}
    local currentStep = nil

    local function beginStep()
        currentStep = {
            index = #steps + 1,
            actors = {},
            units = {},
            unitEventIds = {},
            unitCount = 0,
            oversized = false,
        }
        steps[#steps + 1] = currentStep
        return currentStep
    end

    local function appendActor(step, actor)
        step.actors[#step.actors + 1] = actor
        for memberIndex = 1, #(actor.units or {}) do
            step.units[#step.units + 1] = actor.units[memberIndex]
            step.unitEventIds[#step.unitEventIds + 1] = actor.unitEventIds[memberIndex]
        end
        step.unitCount = step.unitCount + (tonumber(actor.unitCount) or #(actor.units or {}))
    end

    for actorIndex = 1, #actors do
        local actor = actors[actorIndex]
        local actorSize = math.max(1, tonumber(actor.unitCount) or #(actor.units or {}))

        if actorSize > capacity then
            if currentStep and currentStep.unitCount == 0 then
                table.remove(steps, #steps)
                currentStep = nil
            end
            local oversizedStep = beginStep()
            appendActor(oversizedStep, actor)
            oversizedStep.oversized = true
            currentStep = nil
        else
            if not currentStep or currentStep.unitCount + actorSize > capacity then
                currentStep = beginStep()
            end
            appendActor(currentStep, actor)
            if currentStep.unitCount >= capacity then
                currentStep = nil
            end
        end
    end

    return steps
end

function Event.GetTurnStepCount(eventState, stepCapacity)
    return math.max(1, #Event.BuildTurnSchedule(eventState, stepCapacity))
end

function Event.GetUnitTurnStepIndex(eventState, eventId, stepCapacity)
    local units = type(eventState) == "table" and eventState.units or nil
    local resolvedEventId = resolveSharedTurnOwnerEventId(units, eventId)
    if not resolvedEventId then
        return nil
    end

    local schedule = Event.BuildTurnSchedule(eventState, stepCapacity)
    for stepIndex = 1, #schedule do
        local eventIds = schedule[stepIndex].unitEventIds or {}
        for unitIndex = 1, #eventIds do
            if tonumber(eventIds[unitIndex]) == resolvedEventId then
                return stepIndex
            end
        end
    end

    return nil
end

function Event.GetUnitsForTurnStep(eventState, tickNumber, stepCapacity)
    local normalizedTick = math.max(1, math.floor(tonumber(tickNumber) or 1))
    local schedule = Event.BuildTurnSchedule(eventState, stepCapacity)
    local step = schedule[normalizedTick]
    if not step then
        return {}
    end

    local units = {}
    for index = 1, #(step.units or {}) do
        units[index] = step.units[index]
    end
    return units
end

function Event.NormalizeTurnScheduleState(eventState, stepCapacity)
    if type(eventState) ~= "table" or normalizeTurnMode(eventState.turnMode) ~= "autopilot" then
        return eventState
    end

    local totalTicks = Event.GetTurnStepCount(eventState, stepCapacity)
    eventState.totalTicks = totalTicks

    local tickNumber = math.max(1, math.floor(tonumber(eventState.tickNumber) or 1))
    if tickNumber > totalTicks then
        tickNumber = totalTicks
    end
    eventState.tickNumber = tickNumber
    return eventState
end

Event.NormalizeTurnMode = normalizeTurnMode

local baseMerge = Event.Merge
function Event:Merge(data)
    local result = baseMerge and baseMerge(self, data) or self
    local explicitMode = type(data) == "table" and data.turnMode or nil
    local contextMode = type(Autopilot.GetEventStartTurnModeContext) == "function"
        and Autopilot.GetEventStartTurnModeContext()
        or nil

    if explicitMode ~= nil then
        self.turnMode = normalizeTurnMode(explicitMode)
    elseif self.turnMode ~= nil then
        self.turnMode = normalizeTurnMode(self.turnMode)
    elseif contextMode ~= nil then
        self.turnMode = normalizeTurnMode(contextMode)
    else
        self.turnMode = "manual"
    end

    return result
end

local baseToTable = Event.ToTable
function Event:ToTable()
    local values = baseToTable and baseToTable(self) or {}
    values.turnMode = normalizeTurnMode(self.turnMode)
    return values
end

local baseToStartArguments = Event.ToStartArguments
function Event:ToStartArguments(includeUnits)
    local arguments = baseToStartArguments and baseToStartArguments(self, includeUnits) or {}
    arguments[#arguments + 1] = normalizeTurnMode(self.turnMode)
    return arguments
end

local baseFromStartArguments = Event.FromStartArguments
function Event.FromStartArguments(arguments)
    local eventState = baseFromStartArguments and baseFromStartArguments(arguments) or Event:New({})
    if type(eventState) == "table" then
        eventState.turnMode = normalizeTurnMode(type(arguments) == "table" and arguments[18] or nil)
    end
    return eventState
end
