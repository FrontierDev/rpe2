local _, Addon = ...

Addon.Internal = Addon.Internal or {}
Addon.Internal.Database = Addon.Internal.Database or {}
Addon.Internal.Database.Classes = Addon.Internal.Database.Classes or {}

local Classes = Addon.Internal.Database.Classes
local Event = Classes.Event
local EventUnit = Classes.EventUnit
local Common = Addon.Utils and Addon.Utils.Common or {}

if type(Event) ~= "table" or type(EventUnit) ~= "table" then
    return
end

local UNIT_RECORD_SEPARATOR = string.char(30)
local UNIT_FIELD_SEPARATOR = string.char(29)
local UNIT_DELTA_RECORD_SEPARATOR = string.char(23)
local UNIT_DELTA_FIELD_SEPARATOR = string.char(22)
local CURRENT_MODERN_UNIT_FIELD_COUNT = 23
local PRESET_INDEX_FIELD = 24
local APPEARANCE_INDEX_FIELD = 25

local function splitPreservingEmpty(text, separator)
    if type(Common.SplitPreservingEmpty) == "function" then
        return Common.SplitPreservingEmpty(text or "", separator)
    end

    local values = {}
    local startIndex = 1
    local source = tostring(text or "")
    while true do
        local separatorIndex = string.find(source, separator, startIndex, true)
        if not separatorIndex then
            values[#values + 1] = string.sub(source, startIndex)
            break
        end
        values[#values + 1] = string.sub(source, startIndex, separatorIndex - 1)
        startIndex = separatorIndex + #separator
    end
    return values
end

local function normalizeVariantIndex(value)
    if type(EventUnit.NormalizeVariantIndex) == "function" then
        return EventUnit.NormalizeVariantIndex(value)
    end

    local numericValue = tonumber(value)
    if numericValue == nil or numericValue ~= numericValue or numericValue == math.huge or numericValue == -math.huge then
        return 0
    end
    return math.max(0, math.floor(numericValue))
end

local function findRuntimeUnit(eventId)
    local numericEventId = tonumber(eventId) or 0
    if numericEventId <= 0 then
        return nil
    end

    local server = Addon.Server
    local eventState = type(server) == "table" and server.EventState or nil
    for index = 1, #((eventState and eventState.units) or {}) do
        local unit = eventState.units[index]
        if tonumber(unit and unit.eventID) == numericEventId then
            return unit
        end
    end

    return nil
end

local function getPendingIdentity(unit)
    local server = Addon.Server
    local pending = type(server) == "table" and server.PendingNpcVariantMaterialization or nil
    if type(pending) ~= "table" or type(unit) ~= "table" then
        return nil
    end

    local pendingRegistryId = tostring(pending.registryID or "")
    local unitRegistryId = tostring(unit.registryID or "")
    if pendingRegistryId == "" or pendingRegistryId ~= unitRegistryId then
        return nil
    end

    return {
        presetIndex = normalizeVariantIndex(pending.presetIndex),
        appearanceIndex = normalizeVariantIndex(pending.appearanceIndex),
    }
end

local function resolveIdentity(unit)
    local pending = getPendingIdentity(unit)
    if pending then
        return pending.presetIndex, pending.appearanceIndex
    end

    local runtimeUnit = findRuntimeUnit(unit and unit.eventID)
    local identitySource = runtimeUnit or unit or {}
    return normalizeVariantIndex(identitySource.presetIndex), normalizeVariantIndex(identitySource.appearanceIndex)
end

local function makePresetMechanicsExplicit(fields, sourceUnit, presetIndex)
    if presetIndex <= 0 or type(fields) ~= "table" or type(sourceUnit) ~= "table" then
        return fields
    end

    local runtimeUnit = findRuntimeUnit(sourceUnit.eventID) or sourceUnit
    if type(runtimeUnit) ~= "table" then
        return fields
    end

    if type(EventUnit.SerializeResourcesForNetwork) == "function" then
        fields[11] = EventUnit.SerializeResourcesForNetwork(runtimeUnit.resources or {})
    end
    if type(EventUnit.SerializeStatsForNetwork) == "function" then
        fields[15] = EventUnit.SerializeStatsForNetwork(runtimeUnit.stats or {})
    end

    -- Preset resources and stats are host-materialized. Do not let compact
    -- inherit/bonus modes reconstruct Base-only mechanics on the receiver.
    fields[18] = ""
    fields[20] = ""
    fields[21] = ""

    -- Preserve the existing compact spell-inheritance contract unless the
    -- summon/runtime unit carries an explicit non-empty spell override.
    if type(runtimeUnit.spells) == "table" and #runtimeUnit.spells > 0
        and type(EventUnit.SerializeSpellRefsForNetwork) == "function"
    then
        fields[14] = EventUnit.SerializeSpellRefsForNetwork(runtimeUnit.spells)
        fields[19] = ""
    end

    return fields
end

local function appendVariantIdentity(unitRecord, sourceUnit)
    if type(unitRecord) ~= "string" or unitRecord == "" then
        return unitRecord
    end

    local fields = splitPreservingEmpty(unitRecord, UNIT_FIELD_SEPARATOR)
    if #fields < 9 then
        return unitRecord
    end

    local presetIndex, appearanceIndex = resolveIdentity(sourceUnit)
    makePresetMechanicsExplicit(fields, sourceUnit or {}, presetIndex)

    while #fields < CURRENT_MODERN_UNIT_FIELD_COUNT do
        fields[#fields + 1] = ""
    end
    fields[PRESET_INDEX_FIELD] = tostring(presetIndex)
    fields[APPEARANCE_INDEX_FIELD] = tostring(appearanceIndex)
    return table.concat(fields, UNIT_FIELD_SEPARATOR)
end

local function applyVariantIdentity(unit, unitRecord)
    if type(unit) ~= "table" or type(unitRecord) ~= "string" or unitRecord == "" then
        return unit
    end

    local fields = splitPreservingEmpty(unitRecord, UNIT_FIELD_SEPARATOR)
    local presetIndex = #fields >= PRESET_INDEX_FIELD and fields[PRESET_INDEX_FIELD] or 0
    local appearanceIndex = #fields >= APPEARANCE_INDEX_FIELD and fields[APPEARANCE_INDEX_FIELD] or 0
    unit.presetIndex = normalizeVariantIndex(presetIndex)
    unit.appearanceIndex = normalizeVariantIndex(appearanceIndex)
    return unit
end

local function isAcceptedDeltaRecord(record)
    local fields = splitPreservingEmpty(record, UNIT_DELTA_FIELD_SEPARATOR)
    local operation = tostring(fields[1] or "")
    if operation ~= "upsert" and operation ~= "remove" then
        return false
    end

    local eventId = tonumber(fields[2]) or 0
    if operation == "upsert" and tostring(fields[3] or "") ~= "" then
        local unitFields = splitPreservingEmpty(fields[3], UNIT_FIELD_SEPARATOR)
        eventId = tonumber(unitFields[1]) or eventId
    end
    return eventId > 0
end

local baseSerializeUnitsForNetwork = Event.SerializeUnitsForNetwork
function Event:SerializeUnitsForNetwork()
    local serialized = baseSerializeUnitsForNetwork and baseSerializeUnitsForNetwork(self) or ""
    if serialized == "" then
        return serialized
    end

    local records = splitPreservingEmpty(serialized, UNIT_RECORD_SEPARATOR)
    for index = 1, #records do
        if records[index] ~= "" then
            records[index] = appendVariantIdentity(records[index], self.units and self.units[index] or nil)
        end
    end
    return table.concat(records, UNIT_RECORD_SEPARATOR)
end

local baseDeserializeUnitsFromNetwork = Event.DeserializeUnitsFromNetwork
function Event.DeserializeUnitsFromNetwork(unitsText)
    local units = baseDeserializeUnitsFromNetwork and baseDeserializeUnitsFromNetwork(unitsText) or {}
    if type(unitsText) ~= "string" or unitsText == "" then
        return units
    end

    local records = splitPreservingEmpty(unitsText, UNIT_RECORD_SEPARATOR)
    local unitIndex = 0
    for index = 1, #records do
        if records[index] ~= "" then
            unitIndex = unitIndex + 1
            applyVariantIdentity(units[unitIndex], records[index])
        end
    end
    return units
end

local baseSerializeUnitDeltaBatchForNetwork = Event.SerializeUnitDeltaBatchForNetwork
function Event.SerializeUnitDeltaBatchForNetwork(entries)
    local serialized = baseSerializeUnitDeltaBatchForNetwork and baseSerializeUnitDeltaBatchForNetwork(entries) or ""
    if serialized == "" then
        return serialized
    end

    local records = splitPreservingEmpty(serialized, UNIT_DELTA_RECORD_SEPARATOR)
    for index = 1, #records do
        local fields = splitPreservingEmpty(records[index], UNIT_DELTA_FIELD_SEPARATOR)
        if tostring(fields[1] or "") == "upsert" and tostring(fields[3] or "") ~= "" then
            local entry = type(entries) == "table" and entries[index] or nil
            local sourceUnit = type(entry) == "table" and (entry.unit or entry) or nil
            fields[3] = appendVariantIdentity(fields[3], sourceUnit)
            records[index] = table.concat(fields, UNIT_DELTA_FIELD_SEPARATOR)
        end
    end
    return table.concat(records, UNIT_DELTA_RECORD_SEPARATOR)
end

local baseDeserializeUnitDeltaBatchFromNetwork = Event.DeserializeUnitDeltaBatchFromNetwork
function Event.DeserializeUnitDeltaBatchFromNetwork(batchText)
    local entries = baseDeserializeUnitDeltaBatchFromNetwork and baseDeserializeUnitDeltaBatchFromNetwork(batchText) or {}
    if type(batchText) ~= "string" or batchText == "" then
        return entries
    end

    local records = splitPreservingEmpty(batchText, UNIT_DELTA_RECORD_SEPARATOR)
    local entryIndex = 0
    for index = 1, #records do
        if records[index] ~= "" and isAcceptedDeltaRecord(records[index]) then
            entryIndex = entryIndex + 1
            local deltaFields = splitPreservingEmpty(records[index], UNIT_DELTA_FIELD_SEPARATOR)
            if tostring(deltaFields[1] or "") == "upsert" and tostring(deltaFields[3] or "") ~= "" then
                local entry = entries[entryIndex]
                if type(entry) == "table" then
                    applyVariantIdentity(entry.unit, deltaFields[3])
                end
            end
        end
    end
    return entries
end
