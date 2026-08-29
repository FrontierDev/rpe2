local _, Addon = ...

Addon.Server = Addon.Server or {}
Addon.Internal = Addon.Internal or {}
Addon.Internal.Database = Addon.Internal.Database or {}
Addon.Internal.Database.Classes = Addon.Internal.Database.Classes or {}

local Server = Addon.Server
local EventUnit = Addon.Internal.Database.Classes.EventUnit

if type(Server) ~= "table" or type(EventUnit) ~= "table" then
    return
end

local function deepCopy(value)
    if type(value) ~= "table" then
        return value
    end

    local copy = {}
    for key, nestedValue in pairs(value) do
        copy[key] = deepCopy(nestedValue)
    end
    return copy
end

local function countPlayerUnits(units)
    local count = 0
    for index = 1, #((units) or {}) do
        if units[index] and units[index].isPlayer == true then
            count = count + 1
        end
    end
    return count
end

local function getCurrentEventContext(server)
    local live = type(server.EventState) == "table" and server.EventState.active == true and server.EventState or nil
    local state = live or server.EventDraftState
    return state, countPlayerUnits(state and state.units or {})
end

local function buildResourceOptions(options, difficulty)
    local source = type(options) == "table" and options or {}
    return {
        difficulty = source.difficulty ~= nil and source.difficulty or difficulty,
        playerScalingChallengeLevels = source.playerScalingChallengeLevels,
        applyPerPlayerScaling = source.applyPerPlayerScaling,
        healthResourceRef = source.healthResourceRef,
        healthPercent = source.healthPercent,
        difficultyModifiers = source.difficultyModifiers,
    }
end

if Server._unitResourceVariantIntegrationInstalled ~= true then
    local baseBuildResolvedNpcVariant = Server.BuildResolvedNpcVariant

    function Server:BuildResolvedNpcVariant(registryId, options)
        local variant = type(baseBuildResolvedNpcVariant) == "function"
            and baseBuildResolvedNpcVariant(self, registryId, options)
            or nil
        if type(variant) ~= "table" or type(variant.baseUnit) ~= "table"
            or type(EventUnit.BuildUnitDerivedResources) ~= "function"
        then
            return variant
        end

        local contextState = type(self.EventState) == "table" and self.EventState.active == true and self.EventState
            or self.EventDraftState
        local difficulty = type(options) == "table" and options.difficulty or nil
        if difficulty == nil then
            difficulty = contextState and contextState.difficulty or "normal"
        end

        local playerCount = type(options) == "table" and options.playerCount or nil
        if playerCount == nil then
            playerCount = variant.playerCount
        end

        local resources, policy = EventUnit.BuildUnitDerivedResources(
            variant.baseUnit,
            variant.presetIndex,
            playerCount,
            buildResourceOptions(options, difficulty)
        )
        variant.resources = deepCopy(resources)
        variant.resourcePolicy = deepCopy(policy)
        variant.playerCount = policy and policy.playerCount or variant.playerCount
        return variant
    end

    Server._unitResourceVariantIntegrationInstalled = true
end

local function materializeMissingRuntimeResources(server, unit, playerCount, difficulty)
    if type(unit) ~= "table" or unit.isPlayer == true or tostring(unit.registryID or "") == "" then
        return false
    end
    if type(EventUnit.HasExplicitRuntimeResources) == "function" and EventUnit.HasExplicitRuntimeResources(unit) then
        return false
    end

    local variant = server:BuildResolvedNpcVariant(unit.registryID, {
        presetIndex = unit.presetIndex,
        playerCount = playerCount,
        difficulty = difficulty,
        selectRandomAppearance = false,
    })
    if type(variant) ~= "table" then
        return false
    end

    unit.resources = deepCopy(variant.resources or {})
    return true
end

if Server._unitResourceDirectAddIntegrationInstalled ~= true then
    local baseAddEventNpcUnit = Server.AddEventNpcUnit

    function Server:AddEventNpcUnit(data)
        local prepared = type(data) == "table" and data or nil
        if prepared and prepared.isPlayer ~= true and tostring(prepared.registryID or "") ~= "" then
            local hasExplicit = type(EventUnit.HasExplicitRuntimeResources) == "function"
                and EventUnit.HasExplicitRuntimeResources(prepared)
                or false
            if not hasExplicit then
                local state, playerCount = getCurrentEventContext(self)
                local variant = self:BuildResolvedNpcVariant(prepared.registryID, {
                    presetIndex = prepared.presetIndex,
                    playerCount = playerCount,
                    difficulty = state and state.difficulty or "normal",
                    selectRandomAppearance = false,
                })
                if variant then
                    prepared = deepCopy(prepared)
                    prepared.resources = deepCopy(variant.resources or {})
                end
            end
        end

        return type(baseAddEventNpcUnit) == "function" and baseAddEventNpcUnit(self, prepared) or nil
    end

    Server._unitResourceDirectAddIntegrationInstalled = true
end

if Server._unitResourceDraftIntegrationInstalled ~= true then
    local baseGetEventDraftState = Server.GetEventDraftState

    function Server:GetEventDraftState()
        local existing = self.EventDraftState
        if type(existing) == "table" and type(existing.units) == "table" then
            local playerCount = countPlayerUnits(existing.units)
            local difficulty = existing.difficulty or "normal"
            for index = 1, #existing.units do
                materializeMissingRuntimeResources(self, existing.units[index], playerCount, difficulty)
            end
        end

        return type(baseGetEventDraftState) == "function" and baseGetEventDraftState(self) or existing
    end

    Server._unitResourceDraftIntegrationInstalled = true
end
