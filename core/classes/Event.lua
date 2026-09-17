local _, Addon = ...

Addon.Internal = Addon.Internal or {}
Addon.Internal.Database = Addon.Internal.Database or {}
Addon.Internal.Database.Classes = Addon.Internal.Database.Classes or {}
Addon.Utils = Addon.Utils or {}

local Event = {}
Event.__index = Event
local EventUnit = Addon.Internal.Database.Classes.EventUnit
local Common = Addon.Utils.Common or {}
local splitPreservingEmpty = Common.SplitPreservingEmpty

local UNIT_RECORD_SEPARATOR = string.char(30)
local UNIT_FIELD_SEPARATOR = string.char(29)
local TEAM_RECORD_SEPARATOR = string.char(25)
local TEAM_FIELD_SEPARATOR = string.char(24)
local LEGACY_TEAM_RECORD_SEPARATOR = string.char(31)
local LEGACY_TEAM_FIELD_SEPARATOR = string.char(28)
local UNIT_DELTA_RECORD_SEPARATOR = string.char(23)
local UNIT_DELTA_FIELD_SEPARATOR = string.char(22)
local TEAM_SCHEMA_RECORD_SEPARATOR = string.char(21)
local TEAM_SCHEMA_FIELD_SEPARATOR = string.char(20)
local REF_RECORD_SEPARATOR = string.char(19)
local EVENT_AURA_RECORD_SEPARATOR = string.char(18)
local EVENT_AURA_FIELD_SEPARATOR = string.char(17)
local EVENT_AURA_TEAM_SEPARATOR = ","

local DEFAULT_TEAM_COLORS = {
    [1] = { r = 0.35, g = 0.65, b = 1.00, a = 1.00 },
    [2] = { r = 1.00, g = 0.40, b = 0.35, a = 1.00 },
    [3] = { r = 0.40, g = 0.90, b = 0.45, a = 1.00 },
    [4] = { r = 0.75, g = 0.55, b = 1.00, a = 1.00 },
}
local DEFAULT_EVENT_DIFFICULTY = "normal"
local EVENT_DIFFICULTY_ORDER = { "normal", "heroic", "mythic" }

local function coerceUnitBoolean(value, defaultValue)
    if EventUnit and EventUnit.CoerceBoolean then
        return EventUnit.CoerceBoolean(value, defaultValue)
    end

    if value == nil then
        return defaultValue == true
    end

    if value == true or value == false then
        return value
    end

    local numericValue = tonumber(value)
    if numericValue ~= nil then
        return numericValue ~= 0
    end

    if type(value) == "string" then
        local normalized = string.lower(value)
        if normalized == "true" or normalized == "yes" or normalized == "on" then
            return true
        end
        if normalized == "false" or normalized == "no" or normalized == "off" then
            return false
        end
    end

    return defaultValue == true
end

local function normalizeCounter(value, fallback)
    local numericValue = tonumber(value)
    if not numericValue then
        return fallback
    end

    numericValue = math.floor(numericValue)
    if numericValue < 0 then
        numericValue = 0
    end

    return numericValue
end

local function normalizeLevel(value, fallback)
    local numericValue = tonumber(value)
    if not numericValue then
        numericValue = tonumber(fallback) or 1
    end

    numericValue = math.floor(numericValue)
    if numericValue < 1 then
        numericValue = 1
    end

    return numericValue
end

local function cloneColor(color)
    if type(color) ~= "table" then
        return nil
    end

    return {
        r = tonumber(color.r) or 0,
        g = tonumber(color.g) or 0,
        b = tonumber(color.b) or 0,
        a = tonumber(color.a) or 1,
    }
end

local function normalizeTeamColors(teamColors)
    local normalized = {}

    for team = 1, 4 do
        normalized[team] = cloneColor(teamColors and teamColors[team]) or cloneColor(DEFAULT_TEAM_COLORS[team])
    end

    return normalized
end

local function cloneStringList(values)
    local cloned = {}

    for index = 1, #(values or {}) do
        local value = tostring(values[index] or "")
        if value ~= "" then
            cloned[#cloned + 1] = value
        end
    end

    return cloned
end

local function cloneTeamIndexList(values)
    local cloned = {}
    local seen = {}

    for index = 1, #(values or {}) do
        local numericValue = math.floor(tonumber(values[index]) or 0)
        if numericValue > 0 and not seen[numericValue] then
            seen[numericValue] = true
            cloned[#cloned + 1] = numericValue
        end
    end

    table.sort(cloned)
    return cloned
end

local function normalizeDifficulty(value, fallback)
    local normalized = string.lower(tostring(value or fallback or DEFAULT_EVENT_DIFFICULTY))
    for index = 1, #EVENT_DIFFICULTY_ORDER do
        if normalized == EVENT_DIFFICULTY_ORDER[index] then
            return normalized
        end
    end

    return normalizeDifficulty(fallback or DEFAULT_EVENT_DIFFICULTY, DEFAULT_EVENT_DIFFICULTY)
end

local function buildDefaultTeam(index, color)
    local numericIndex = math.max(1, math.floor(tonumber(index) or 1))
    return {
        id = ("team%d"):format(numericIndex),
        name = ("Team %d"):format(numericIndex),
        color = cloneColor(color) or cloneColor(DEFAULT_TEAM_COLORS[((numericIndex - 1) % #DEFAULT_TEAM_COLORS) + 1]),
    }
end

local function cloneTeam(team, index)
    local defaultTeam = buildDefaultTeam(index, type(team) == "table" and team.color or nil)
    return {
        id = type(team) == "table" and tostring(team.id or "") ~= "" and tostring(team.id) or defaultTeam.id,
        name = type(team) == "table" and tostring(team.name or "") ~= "" and tostring(team.name) or defaultTeam.name,
        color = cloneColor(type(team) == "table" and (team.color or team.colour) or nil) or defaultTeam.color,
    }
end

local function normalizeTeams(teams, legacyTeamColors)
    local normalized = {}

    if type(teams) == "table" and #teams > 0 then
        for index = 1, #teams do
            normalized[#normalized + 1] = cloneTeam(teams[index], index)
        end
    else
        local colors = normalizeTeamColors(legacyTeamColors)
        for index = 1, #colors do
            normalized[#normalized + 1] = buildDefaultTeam(index, colors[index])
        end
    end

    if #normalized == 0 then
        normalized[1] = buildDefaultTeam(1, DEFAULT_TEAM_COLORS[1])
    end

    return normalized
end

local function deriveTeamColors(teams)
    local colors = {}

    for index = 1, #(teams or {}) do
        colors[index] = cloneColor(teams[index] and teams[index].color) or cloneColor(DEFAULT_TEAM_COLORS[((index - 1) % #DEFAULT_TEAM_COLORS) + 1])
    end

    if #colors == 0 then
        colors[1] = cloneColor(DEFAULT_TEAM_COLORS[1])
    end

    return colors
end

local function cloneTeams(teams)
    local clones = {}

    for index = 1, #(teams or {}) do
        clones[index] = cloneTeam(teams[index], index)
    end

    return clones
end

local function cloneEventAura(entry)
    local auraRef = type(entry) == "table" and tostring(entry.auraRef or entry.ref or "") or ""
    if auraRef == "" then
        return nil
    end

    return {
        auraRef = auraRef,
        teamIndices = cloneTeamIndexList(type(entry) == "table" and (entry.teamIndices or entry.teams) or nil),
    }
end

local function normalizeEventAuras(values, teamCount)
    local normalized = {}

    for index = 1, #(values or {}) do
        local cloned = cloneEventAura(values[index])
        if cloned then
            if tonumber(teamCount) and teamCount > 0 then
                local filtered = {}
                for teamIndex = 1, #cloned.teamIndices do
                    local numericValue = cloned.teamIndices[teamIndex]
                    if numericValue >= 1 and numericValue <= teamCount then
                        filtered[#filtered + 1] = numericValue
                    end
                end
                cloned.teamIndices = filtered
            end
            normalized[#normalized + 1] = cloned
        end
    end

    return normalized
end

local function cloneEventAuras(values)
    return normalizeEventAuras(values)
end

local function serializeTeams(teams)
    local records = {}
    local normalized = normalizeTeams(teams)

    for index = 1, #normalized do
        local team = normalized[index]
        local color = team.color or DEFAULT_TEAM_COLORS[((index - 1) % #DEFAULT_TEAM_COLORS) + 1]
        records[#records + 1] = table.concat({
            tostring(index),
            tostring(team.id or ""),
            tostring(team.name or ""),
            tostring(color.r or 0),
            tostring(color.g or 0),
            tostring(color.b or 0),
            tostring(color.a or 1),
        }, TEAM_SCHEMA_FIELD_SEPARATOR)
    end

    return table.concat(records, TEAM_SCHEMA_RECORD_SEPARATOR)
end

local function deserializeTeams(teamsText, legacyTeamColors)
    if type(teamsText) ~= "string" or teamsText == "" then
        return normalizeTeams(nil, legacyTeamColors)
    end

    local records = splitPreservingEmpty and splitPreservingEmpty(teamsText, TEAM_SCHEMA_RECORD_SEPARATOR) or {}
    local teams = {}
    for index = 1, #records do
        local values = splitPreservingEmpty and splitPreservingEmpty(records[index], TEAM_SCHEMA_FIELD_SEPARATOR) or {}
        local teamIndex = tonumber(values[1]) or (#teams + 1)
        teams[teamIndex] = {
            id = values[2],
            name = values[3],
            color = {
                r = tonumber(values[4]) or nil,
                g = tonumber(values[5]) or nil,
                b = tonumber(values[6]) or nil,
                a = tonumber(values[7]) or nil,
            },
        }
    end

    return normalizeTeams(teams, legacyTeamColors)
end

local function serializeEventAuras(values)
    local records = {}
    local normalized = normalizeEventAuras(values)

    for index = 1, #normalized do
        local entry = normalized[index]
        records[#records + 1] = table.concat({
            tostring(entry.auraRef or ""),
            table.concat(cloneTeamIndexList(entry.teamIndices), EVENT_AURA_TEAM_SEPARATOR),
        }, EVENT_AURA_FIELD_SEPARATOR)
    end

    return table.concat(records, EVENT_AURA_RECORD_SEPARATOR)
end

local function deserializeEventAuras(text)
    if type(text) ~= "string" or text == "" then
        return {}
    end

    local records = splitPreservingEmpty and splitPreservingEmpty(text, EVENT_AURA_RECORD_SEPARATOR) or {}
    local values = {}
    for index = 1, #records do
        local fields = splitPreservingEmpty and splitPreservingEmpty(records[index], EVENT_AURA_FIELD_SEPARATOR) or {}
        local teams = {}
        local teamTokens = splitPreservingEmpty and splitPreservingEmpty(fields[2] or "", EVENT_AURA_TEAM_SEPARATOR) or {}
        for teamIndex = 1, #teamTokens do
            teams[#teams + 1] = tonumber(teamTokens[teamIndex]) or 0
        end
        values[#values + 1] = {
            auraRef = fields[1] or "",
            teamIndices = teams,
        }
    end

    return normalizeEventAuras(values)
end

local function serializeRefList(values)
    return table.concat(cloneStringList(values), REF_RECORD_SEPARATOR)
end

local function deserializeRefList(text)
    if type(text) ~= "string" or text == "" then
        return {}
    end

    local values = splitPreservingEmpty and splitPreservingEmpty(text, REF_RECORD_SEPARATOR) or {}
    return cloneStringList(values)
end

local function getTeamByIndex(eventState, teamIndex)
    local normalizedIndex = math.floor(tonumber(teamIndex) or 0)
    if normalizedIndex <= 0 then
        return nil
    end

    local teams = type(eventState) == "table" and eventState.teams or nil
    return type(teams) == "table" and teams[normalizedIndex] or nil
end

local function getTeamName(eventState, teamIndex)
    local team = getTeamByIndex(eventState, teamIndex)
    if type(team) == "table" and tostring(team.name or "") ~= "" then
        return tostring(team.name)
    end

    local normalizedIndex = math.floor(tonumber(teamIndex) or 0)
    if normalizedIndex > 0 then
        return ("Team %d"):format(normalizedIndex)
    end

    return "Unassigned Team"
end

local function getTeamColor(eventState, teamIndex)
    local team = getTeamByIndex(eventState, teamIndex)
    if type(team) == "table" and type(team.color) == "table" then
        return cloneColor(team.color)
    end

    local teamColors = type(eventState) == "table" and eventState.teamColors or nil
    local fallback = type(teamColors) == "table" and teamColors[math.floor(tonumber(teamIndex) or 0)] or nil
    return cloneColor(fallback)
end

local function normalizeUnit(unitData)
    if EventUnit and EventUnit.FromTable then
        return EventUnit.FromTable(unitData)
    end

    return unitData
end

local function normalizeUnits(units)
    local normalized = {}

    for index = 1, #(units or {}) do
        normalized[#normalized + 1] = normalizeUnit(units[index])
    end

    return normalized
end

local function isUnitActive(unit)
    if EventUnit and EventUnit.IsActive then
        return EventUnit.IsActive(unit)
    end

    return type(unit) == "table" and (unit.isPlayer == true or coerceUnitBoolean(unit.active, true))
end

local function findUnitByEventId(units, eventId)
    local numericEventId = tonumber(eventId) or 0
    if numericEventId <= 0 then
        return nil
    end

    for index = 1, #(units or {}) do
        local unit = units[index]
        if tonumber(unit and unit.eventID) == numericEventId then
            return unit, index
        end
    end

    return nil
end

local function isPlayerSharedTurnPet(units, unit)
    if type(unit) ~= "table" or unit.isPlayer == true or tostring(unit.petRef or "") == "" then
        return false
    end

    local summoner = findUnitByEventId(units, unit.summonedByEventID)
    if type(summoner) == "table" and summoner.isPlayer == true then
        return true
    end

    local controllerId = tonumber(unit.controllerID) or 0
    if controllerId > 0 then
        local controllerUnit = findUnitByEventId(units, controllerId)
        if type(controllerUnit) == "table" and controllerUnit.isPlayer == true then
            return true
        end
    end

    return false
end

local function toNetworkBoolean(value)
    return value == true and "1" or "0"
end

local function fromNetworkBoolean(value)
    return tostring(value or "") == "1"
end

local function serializeUnit(unit)
    local resourceMode = tostring(unit and unit._networkResourceMode or "")
    local spellMode = tostring(unit and unit._networkSpellMode or "")
    local statMode = tostring(unit and unit._networkStatMode or "")
    return table.concat({
        tostring(unit and unit.eventID or ""),
        toNetworkBoolean(unit and unit.isPlayer == true),
        tostring(unit and unit.registryID or ""),
        tostring(unit and unit.raidMarker or 0),
        tostring(unit and unit.team or 0),
        tostring(unit and unit.ownerID or ""),
        tostring(unit and unit.controllerID or ""),
        tostring(unit and unit.name or ""),
        tostring(unit and unit.description or ""),
        tostring(unit and unit.initiative or ""),
        resourceMode == "inherit"
                and ""
            or (EventUnit and EventUnit.SerializeResourcesForNetwork and EventUnit.SerializeResourcesForNetwork(unit and unit.resources or nil) or ""),
        toNetworkBoolean(isUnitActive(unit)),
        toNetworkBoolean(EventUnit and EventUnit.IsHidden and EventUnit.IsHidden(unit) or coerceUnitBoolean(unit and unit.hidden, false)),
        spellMode == "inherit"
                and ""
            or (EventUnit and EventUnit.SerializeSpellRefsForNetwork and EventUnit.SerializeSpellRefsForNetwork(unit and unit.spells or nil) or ""),
        (statMode == "inherit" or statMode == "merge" or statMode == "bonus")
                and ""
            or (EventUnit and EventUnit.SerializeStatsForNetwork and EventUnit.SerializeStatsForNetwork(unit and unit.stats or nil) or ""),
        tostring(unit and unit.petRef or ""),
        tostring(unit and unit.summonedByEventID or ""),
        resourceMode,
        spellMode,
        statMode,
        (statMode == "merge" or statMode == "bonus")
                and (EventUnit and EventUnit.SerializeStatsForNetwork and EventUnit.SerializeStatsForNetwork(unit and unit.stats or nil) or "")
            or "",
        toNetworkBoolean(EventUnit and EventUnit.IsBoss and EventUnit.IsBoss(unit) or coerceUnitBoolean(unit and unit.boss, false)),
        EventUnit and EventUnit.SerializeThreatTableForNetwork and EventUnit.SerializeThreatTableForNetwork(unit and unit.threatTable or nil) or "",
        EventUnit and EventUnit.SerializeTauntStateForNetwork and EventUnit.SerializeTauntStateForNetwork(unit and unit.tauntState or nil) or "",
    }, UNIT_FIELD_SEPARATOR)
end

local function deserializeUnit(record)
    local values = splitPreservingEmpty and splitPreservingEmpty(record or "", UNIT_FIELD_SEPARATOR) or {}
    local usesLegacyLayout = #values > 0 and #values < 9

    if usesLegacyLayout then
        return normalizeUnit({
            eventID = tonumber(values[1]) or 0,
            isPlayer = fromNetworkBoolean(values[2]),
            registryID = values[3] ~= "" and values[3] or nil,
            raidMarker = 0,
            team = 1,
            ownerID = values[4] ~= "" and values[4] or nil,
            controllerID = values[5] ~= "" and values[5] or nil,
            name = values[6] or "",
            description = values[7] or "",
        })
    end

    local active = true
    local hidden = false
    if #values >= 13 then
        active = fromNetworkBoolean(values[12])
        hidden = fromNetworkBoolean(values[13])
    end

    return normalizeUnit({
        eventID = tonumber(values[1]) or 0,
        isPlayer = fromNetworkBoolean(values[2]),
        registryID = values[3] ~= "" and values[3] or nil,
        raidMarker = tonumber(values[4]) or 0,
        team = tonumber(values[5]) or 0,
        ownerID = values[6] ~= "" and values[6] or nil,
        controllerID = values[7] ~= "" and values[7] or nil,
        name = values[8] or "",
        description = values[9] or "",
        initiative = #values >= 11 and tonumber(values[10]) or nil,
        resources = EventUnit and EventUnit.DeserializeResourcesFromNetwork and EventUnit.DeserializeResourcesFromNetwork(values[#values >= 11 and 11 or 10] or "") or {},
        active = active,
        hidden = hidden,
        spells = #values >= 14 and EventUnit and EventUnit.DeserializeSpellRefsFromNetwork and EventUnit.DeserializeSpellRefsFromNetwork(values[14] or "") or {},
        stats = #values >= 21 and (values[20] == "merge" or values[20] == "bonus")
                and EventUnit
                and EventUnit.DeserializeStatsFromNetwork
                and EventUnit.DeserializeStatsFromNetwork(values[21] or "")
            or (#values >= 15 and EventUnit and EventUnit.DeserializeStatsFromNetwork and EventUnit.DeserializeStatsFromNetwork(values[15] or "") or {}),
        petRef = #values >= 16 and values[16] ~= "" and values[16] or nil,
        summonedByEventID = #values >= 17 and tonumber(values[17]) or nil,
        _networkResourceMode = #values >= 18 and values[18] ~= "" and values[18] or nil,
        _networkSpellMode = #values >= 19 and values[19] ~= "" and values[19] or nil,
        _networkStatMode = #values >= 20 and values[20] ~= "" and values[20] or nil,
        boss = #values >= 22 and fromNetworkBoolean(values[22]) or false,
        threatTable = #values >= 23 and EventUnit and EventUnit.DeserializeThreatTableFromNetwork and EventUnit.DeserializeThreatTableFromNetwork(values[23] or "") or {},
        tauntState = #values >= 24 and EventUnit and EventUnit.DeserializeTauntStateFromNetwork and EventUnit.DeserializeTauntStateFromNetwork(values[24] or "") or nil,
    })
end

local function serializeUnitDeltaEntry(entry)
    local operation = type(entry) == "table" and tostring(entry.operation or "") or ""
    local numericEventId = tonumber(type(entry) == "table" and (entry.eventID or entry.eventId or entry.unit and entry.unit.eventID) or nil) or 0
    local unitRecord = ""

    if operation == "upsert" then
        unitRecord = serializeUnit(type(entry) == "table" and (entry.unit or entry))
    end

    return table.concat({
        operation,
        numericEventId > 0 and tostring(numericEventId) or "",
        unitRecord,
    }, UNIT_DELTA_FIELD_SEPARATOR)
end

local function deserializeUnitDeltaEntry(record)
    local values = splitPreservingEmpty and splitPreservingEmpty(record or "", UNIT_DELTA_FIELD_SEPARATOR) or {}
    local operation = tostring(values[1] or "")
    if operation ~= "upsert" and operation ~= "remove" then
        return nil
    end

    local eventID = tonumber(values[2]) or 0
    local unit = nil
    if operation == "upsert" and values[3] ~= nil and values[3] ~= "" then
        unit = deserializeUnit(values[3])
        eventID = tonumber(unit and unit.eventID) or eventID
    end

    if eventID <= 0 then
        return nil
    end

    return {
        operation = operation,
        eventID = eventID,
        unit = unit,
    }
end

local function compareUnitsByInitiative(left, right)
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

local function sortUnitsByInitiative(units)
    table.sort(units or {}, compareUnitsByInitiative)
    return units
end

local function countActiveUnits(units)
    local count = 0
    for index = 1, #(units or {}) do
        if isUnitActive(units[index]) and not isPlayerSharedTurnPet(units, units[index]) then
            count = count + 1
        end
    end
    return count
end

local function buildActiveUnits(units)
    local activeUnits = {}
    for index = 1, #(units or {}) do
        local unit = units[index]
        if isUnitActive(unit) and not isPlayerSharedTurnPet(units, unit) then
            activeUnits[#activeUnits + 1] = unit
        end
    end
    return activeUnits
end

local function getUnitPageIndex(units, eventId, pageSize)
    local normalizedEventId = tonumber(eventId) or 0
    local normalizedPageSize = math.max(1, math.floor(tonumber(pageSize) or 1))
    if normalizedEventId <= 0 then
        return nil
    end

    local activeIndex = 0
    for index = 1, #(units or {}) do
        local unit = units[index]
        if isUnitActive(unit) and not isPlayerSharedTurnPet(units, unit) then
            activeIndex = activeIndex + 1
            if tonumber(unit and unit.eventID) == normalizedEventId then
                return math.max(1, math.ceil(activeIndex / normalizedPageSize))
            end
        end
    end

    return nil
end

local function getUnitsForPage(units, pageNumber, pageSize)
    local normalizedPageNumber = math.max(1, math.floor(tonumber(pageNumber) or 1))
    local normalizedPageSize = math.max(1, math.floor(tonumber(pageSize) or 1))
    local startIndex = ((normalizedPageNumber - 1) * normalizedPageSize) + 1
    local activeIndex = 0
    local pageUnits = {}

    for index = 1, #(units or {}) do
        local unit = units[index]
        if isUnitActive(unit) and not isPlayerSharedTurnPet(units, unit) then
            activeIndex = activeIndex + 1
            if activeIndex >= startIndex and #pageUnits < normalizedPageSize then
                pageUnits[#pageUnits + 1] = unit
            elseif #pageUnits >= normalizedPageSize then
                break
            end
        end
    end

    return pageUnits
end

local function serializeTeamColors(teamColors)
    local records = {}
    local normalized = normalizeTeamColors(teamColors)

    for team = 1, 4 do
        local color = normalized[team]
        records[#records + 1] = table.concat({
            tostring(team),
            tostring(color.r or 0),
            tostring(color.g or 0),
            tostring(color.b or 0),
            tostring(color.a or 1),
        }, TEAM_FIELD_SEPARATOR)
    end

    return table.concat(records, TEAM_RECORD_SEPARATOR)
end

local function deserializeTeamColors(teamColorsText)
    if type(teamColorsText) ~= "string" or teamColorsText == "" then
        return normalizeTeamColors(nil)
    end

    local normalized = normalizeTeamColors(nil)
    local records = splitPreservingEmpty and splitPreservingEmpty(teamColorsText, TEAM_RECORD_SEPARATOR) or {}
    if #records <= 1 then
        records = splitPreservingEmpty and splitPreservingEmpty(teamColorsText, LEGACY_TEAM_RECORD_SEPARATOR) or records
    end

    for index = 1, #records do
        local values = splitPreservingEmpty and splitPreservingEmpty(records[index], TEAM_FIELD_SEPARATOR) or {}
        if #values <= 1 then
            values = splitPreservingEmpty and splitPreservingEmpty(records[index], LEGACY_TEAM_FIELD_SEPARATOR) or values
        end
        local team = tonumber(values[1]) or 0
        if team >= 1 and team <= 4 then
            normalized[team] = {
                r = tonumber(values[2]) or normalized[team].r,
                g = tonumber(values[3]) or normalized[team].g,
                b = tonumber(values[4]) or normalized[team].b,
                a = tonumber(values[5]) or normalized[team].a,
            }
        end
    end

    return normalized
end

function Event:New(data)
    return setmetatable({
        id = nil,
        name = "",
        subtext = "",
        description = "",
        hostName = "",
        channelName = "",
        startedAt = 0,
        endedAt = 0,
        active = false,
        difficulty = DEFAULT_EVENT_DIFFICULTY,
        level = 1,
        turnNumber = 0,
        tickNumber = 0,
        totalTicks = 0,
        rosterReady = false,
        unitsReady = false,
        resourcesReady = false,
        unitsChunkExpected = 0,
        unitsChunkReceived = 0,
        healthResourcesExpected = 0,
        healthResourcesReceived = 0,
        readyProgressExpected = 0,
        readyProgressReceived = 0,
        units = {},
        teams = normalizeTeams(nil, nil),
        eventAuras = {},
        lootRefs = {},
        teamColors = normalizeTeamColors(nil),
    }, Event):Merge(data)
end

function Event:Merge(data)
    if type(data) ~= "table" then
        return self
    end

    local mergedTeams = nil
    local mergedTeamColors = nil

    for key, value in pairs(data) do
        if key == "units" then
            self.units = normalizeUnits(value)
        elseif key == "teams" then
            mergedTeams = value
        elseif key == "teamColors" then
            mergedTeamColors = value
        elseif key == "turnNumber" or key == "tickNumber" or key == "totalTicks" then
            self[key] = normalizeCounter(value, self[key] or 0)
        elseif key == "difficulty" then
            self.difficulty = normalizeDifficulty(value, self.difficulty or DEFAULT_EVENT_DIFFICULTY)
        elseif key == "level" then
            self.level = normalizeLevel(value, self.level or 1)
        elseif key == "eventAuras" then
            self.eventAuras = cloneEventAuras(value)
        elseif key == "lootRefs" then
            self[key] = cloneStringList(value)
        else
            self[key] = value
        end
    end

    self.units = normalizeUnits(self.units)
    self.teams = normalizeTeams(mergedTeams or self.teams, mergedTeamColors or self.teamColors)
    self.teamColors = deriveTeamColors(self.teams)
    self.difficulty = normalizeDifficulty(self.difficulty, DEFAULT_EVENT_DIFFICULTY)
    self.level = normalizeLevel(self.level, 1)
    self.eventAuras = normalizeEventAuras(self.eventAuras, #(self.teams or {}))
    self.lootRefs = cloneStringList(self.lootRefs)
    return self
end

function Event:ToTable()
    local units = {}

    for index = 1, #(self.units or {}) do
        local unit = self.units[index]
        units[#units + 1] = unit and unit.ToTable and unit:ToTable() or unit
    end

    return {
        id = self.id,
        name = self.name,
        subtext = self.subtext,
        description = self.description,
        hostName = self.hostName,
        channelName = self.channelName,
        startedAt = self.startedAt,
        endedAt = self.endedAt,
        active = self.active,
        difficulty = normalizeDifficulty(self.difficulty, DEFAULT_EVENT_DIFFICULTY),
        level = normalizeLevel(self.level, 1),
        turnNumber = normalizeCounter(self.turnNumber, 0),
        tickNumber = normalizeCounter(self.tickNumber, 0),
        totalTicks = normalizeCounter(self.totalTicks, 0),
        rosterReady = self.rosterReady == true,
        unitsReady = self.unitsReady == true,
        resourcesReady = self.resourcesReady == true,
        unitsChunkExpected = normalizeCounter(self.unitsChunkExpected, 0),
        unitsChunkReceived = normalizeCounter(self.unitsChunkReceived, 0),
        healthResourcesExpected = normalizeCounter(self.healthResourcesExpected, 0),
        healthResourcesReceived = normalizeCounter(self.healthResourcesReceived, 0),
        readyProgressExpected = normalizeCounter(self.readyProgressExpected, 0),
        readyProgressReceived = normalizeCounter(self.readyProgressReceived, 0),
        units = units,
        teams = cloneTeams(self.teams),
        eventAuras = cloneEventAuras(self.eventAuras),
        lootRefs = cloneStringList(self.lootRefs),
        teamColors = deriveTeamColors(self.teams),
    }
end

function Event:SerializeUnitsForNetwork()
    local records = {}

    for index = 1, #(self.units or {}) do
        records[#records + 1] = serializeUnit(self.units[index])
    end

    return table.concat(records, UNIT_RECORD_SEPARATOR)
end

function Event.SerializeUnitDeltaBatchForNetwork(entries)
    local records = {}

    for index = 1, #(entries or {}) do
        local record = serializeUnitDeltaEntry(entries[index])
        if record ~= "" then
            records[#records + 1] = record
        end
    end

    return table.concat(records, UNIT_DELTA_RECORD_SEPARATOR)
end

function Event:ToStartArguments(includeUnits)
    local unitsText = ""
    if includeUnits ~= false then
        unitsText = self:SerializeUnitsForNetwork()
    end

    return {
        self.channelName,
        self.id,
        self.name,
        self.description,
        self.hostName,
        self.startedAt,
        unitsText,
        self.subtext,
        serializeTeamColors(self.teamColors),
        normalizeDifficulty(self.difficulty, DEFAULT_EVENT_DIFFICULTY),
        serializeTeams(self.teams),
        serializeEventAuras(self.eventAuras),
        serializeRefList(self.lootRefs),
        normalizeLevel(self.level, 1),
        normalizeCounter(self.turnNumber, 0),
        normalizeCounter(self.tickNumber, 0),
        normalizeCounter(self.totalTicks, 0),
    }
end

function Event:ToStateArguments()
    return {
        self.channelName,
        self.id,
        normalizeCounter(self.turnNumber, 0),
        normalizeCounter(self.tickNumber, 0),
        normalizeCounter(self.totalTicks, 0),
    }
end

function Event:ToEndArguments(reason)
    return {
        self.channelName,
        self.id,
        tostring(reason or ""),
        self.distributeEndRewards ~= false,
    }
end

function Event.FromTable(data)
    return Event:New(data)
end

function Event.DeserializeUnitsFromNetwork(unitsText)
    local units = {}

    if type(unitsText) ~= "string" or unitsText == "" then
        return units
    end

    local records = splitPreservingEmpty and splitPreservingEmpty(unitsText, UNIT_RECORD_SEPARATOR) or {}
    for index = 1, #records do
        if records[index] ~= "" then
            units[#units + 1] = deserializeUnit(records[index])
        end
    end

    return units
end

function Event.DeserializeUnitDeltaBatchFromNetwork(batchText)
    local entries = {}
    if type(batchText) ~= "string" or batchText == "" then
        return entries
    end

    local records = splitPreservingEmpty and splitPreservingEmpty(batchText, UNIT_DELTA_RECORD_SEPARATOR) or {}
    for index = 1, #records do
        if records[index] ~= "" then
            local entry = deserializeUnitDeltaEntry(records[index])
            if entry then
                entries[#entries + 1] = entry
            end
        end
    end

    return entries
end

function Event.FromStartArguments(arguments)
    local argumentCount = #((arguments) or {})
    local usesExtendedLayout = argumentCount >= 17
    local legacyTeamColors = deserializeTeamColors(arguments and arguments[9] or "")
    local teams = usesExtendedLayout and deserializeTeams(arguments and arguments[11] or "", legacyTeamColors) or normalizeTeams(nil, legacyTeamColors)

    return Event:New({
        channelName = arguments and arguments[1] or "",
        id = arguments and arguments[2] or nil,
        name = arguments and arguments[3] or "",
        description = arguments and arguments[4] or "",
        hostName = arguments and arguments[5] or "",
        startedAt = tonumber(arguments and arguments[6]) or 0,
        active = true,
        units = Event.DeserializeUnitsFromNetwork(arguments and arguments[7] or ""),
        subtext = arguments and arguments[8] or "",
        difficulty = usesExtendedLayout and normalizeDifficulty(arguments and arguments[10], DEFAULT_EVENT_DIFFICULTY) or DEFAULT_EVENT_DIFFICULTY,
        teams = teams,
        eventAuras = usesExtendedLayout and deserializeEventAuras(arguments and arguments[12] or "") or {},
        lootRefs = usesExtendedLayout and deserializeRefList(arguments and arguments[13] or "") or {},
        teamColors = legacyTeamColors,
        level = usesExtendedLayout and normalizeLevel(arguments and arguments[14], 1) or argumentCount >= 13 and normalizeLevel(arguments and arguments[10], 1) or 1,
        turnNumber = normalizeCounter(arguments and arguments[usesExtendedLayout and 15 or argumentCount >= 13 and 11 or 10], 0),
        tickNumber = normalizeCounter(arguments and arguments[usesExtendedLayout and 16 or argumentCount >= 13 and 12 or 11], 0),
        totalTicks = normalizeCounter(arguments and arguments[usesExtendedLayout and 17 or argumentCount >= 13 and 13 or 12], 0),
    })
end

function Event.ApplyStateArguments(eventState, arguments)
    if not eventState or type(arguments) ~= "table" then
        return eventState
    end

    local usesLevelField = #arguments >= 6
    if usesLevelField then
        eventState.level = normalizeLevel(arguments[3], eventState.level or 1)
    end
    eventState.turnNumber = normalizeCounter(arguments[usesLevelField and 4 or 3], eventState.turnNumber or 0)
    eventState.tickNumber = normalizeCounter(arguments[usesLevelField and 5 or 4], eventState.tickNumber or 0)
    eventState.totalTicks = normalizeCounter(arguments[usesLevelField and 6 or 5], eventState.totalTicks or 0)
    return eventState
end

Event.SerializeTeamColorsForNetwork = serializeTeamColors
Event.DeserializeTeamColorsFromNetwork = deserializeTeamColors
Event.GetDefaultTeamColors = normalizeTeamColors
Event.SerializeTeamsForNetwork = serializeTeams
Event.DeserializeTeamsFromNetwork = deserializeTeams
Event.SerializeEventAurasForNetwork = serializeEventAuras
Event.DeserializeEventAurasFromNetwork = deserializeEventAuras
Event.SerializeRefListForNetwork = serializeRefList
Event.DeserializeRefListFromNetwork = deserializeRefList
Event.GetTeamByIndex = getTeamByIndex
Event.GetTeamName = getTeamName
Event.GetTeamColor = getTeamColor
Event.IsUnitActive = isUnitActive
Event.IsPlayerSharedTurnPet = isPlayerSharedTurnPet
Event.CountActiveUnits = countActiveUnits
Event.BuildActiveUnits = buildActiveUnits
Event.GetUnitPageIndex = getUnitPageIndex
Event.GetUnitsForPage = getUnitsForPage
Event.SortUnitsByInitiative = sortUnitsByInitiative

function Event:GetActiveUnits()
    return buildActiveUnits(self.units)
end

function Event:GetTeamByIndex(teamIndex)
    return getTeamByIndex(self, teamIndex)
end

function Event:GetTeamName(teamIndex)
    return getTeamName(self, teamIndex)
end

function Event:GetTeamColor(teamIndex)
    return getTeamColor(self, teamIndex)
end

Addon.Internal.Database.Classes.Event = Event
