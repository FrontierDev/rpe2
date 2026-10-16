local _, Addon = ...

Addon.Internal = Addon.Internal or {}
Addon.Internal.Database = Addon.Internal.Database or {}
Addon.Internal.Database.Classes = Addon.Internal.Database.Classes or {}
Addon.Utils = Addon.Utils or {}

local Event = Addon.Internal.Database.Classes.Event
local EventUnit = Addon.Internal.Database.Classes.EventUnit
local Common = Addon.Utils.Common or {}

if type(Event) ~= "table" or type(EventUnit) ~= "table" or Event.DisplayNameNetworkWrapped == true then
    return
end

local UNIT_RECORD_SEPARATOR = string.char(30)
local UNIT_FIELD_SEPARATOR = string.char(29)
local UNIT_DELTA_RECORD_SEPARATOR = string.char(23)
local UNIT_DELTA_FIELD_SEPARATOR = string.char(22)
local DISPLAY_NAME_FIELD = 35
local DISPLAY_NAME_VALUE_PREFIX = "1:"
local DISPLAY_NAME_CLEAR_MARKER = "0"

local function splitPreservingEmpty(text, separator)
    if type(Common.SplitPreservingEmpty) == "function" then
        return Common.SplitPreservingEmpty(text or "", separator)
    end

    local values = {}
    local source = tostring(text or "")
    local startIndex = 1
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

local function normalizeOverride(value)
    if type(EventUnit.NormalizeDisplayNameOverride) == "function" then
        return EventUnit.NormalizeDisplayNameOverride(value)
    end
    local text = tostring(value or ""):gsub("^%s+", ""):gsub("%s+$", "")
    return text ~= "" and text or nil
end

local function serializeOverride(unit)
    if type(unit) ~= "table" or unit.isPlayer == true then
        return DISPLAY_NAME_CLEAR_MARKER
    end

    local override = normalizeOverride(unit.displayNameOverride)
    if not override then
        return DISPLAY_NAME_CLEAR_MARKER
    end

    return DISPLAY_NAME_VALUE_PREFIX .. override
end

local function appendDisplayName(record, sourceUnit)
    if type(record) ~= "string" or record == "" then
        return record
    end

    local fields = splitPreservingEmpty(record, UNIT_FIELD_SEPARATOR)
    if #fields < 9 then
        return record
    end

    while #fields < DISPLAY_NAME_FIELD - 1 do
        fields[#fields + 1] = ""
    end
    fields[DISPLAY_NAME_FIELD] = serializeOverride(sourceUnit)
    return table.concat(fields, UNIT_FIELD_SEPARATOR)
end

local function applyDisplayName(unit, record)
    if type(unit) ~= "table" or type(record) ~= "string" or record == "" then
        return unit
    end

    local fields = splitPreservingEmpty(record, UNIT_FIELD_SEPARATOR)
    if #fields < DISPLAY_NAME_FIELD then
        return unit
    end

    local encoded = tostring(fields[DISPLAY_NAME_FIELD] or "")
    if encoded == DISPLAY_NAME_CLEAR_MARKER then
        unit.displayNameOverride = nil
        unit._networkDisplayNameOverridePresent = true
    elseif string.sub(encoded, 1, #DISPLAY_NAME_VALUE_PREFIX) == DISPLAY_NAME_VALUE_PREFIX then
        local override, reason = normalizeOverride(string.sub(encoded, #DISPLAY_NAME_VALUE_PREFIX + 1))
        if override then
            unit.displayNameOverride = override
            unit._networkDisplayNameOverridePresent = true
        elseif Addon.Debug and type(Addon.Debug.Warn) == "function" then
            Addon.Debug.Warn("Rejected network Event unit display name override: %s", tostring(reason or "invalid-name"))
        end
    end

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

Event.DisplayNameNetworkWrapped = true
Event.DisplayNameNetworkField = DISPLAY_NAME_FIELD

local baseSerializeUnits = Event.SerializeUnitsForNetwork
function Event:SerializeUnitsForNetwork()
    local serialized = type(baseSerializeUnits) == "function" and baseSerializeUnits(self) or ""
    if serialized == "" then
        return serialized
    end

    local records = splitPreservingEmpty(serialized, UNIT_RECORD_SEPARATOR)
    local unitIndex = 0
    for index = 1, #records do
        if records[index] ~= "" then
            unitIndex = unitIndex + 1
            records[index] = appendDisplayName(records[index], self.units and self.units[unitIndex] or nil)
        end
    end
    return table.concat(records, UNIT_RECORD_SEPARATOR)
end

local baseDeserializeUnits = Event.DeserializeUnitsFromNetwork
function Event.DeserializeUnitsFromNetwork(unitsText, options)
    local units = type(baseDeserializeUnits) == "function" and baseDeserializeUnits(unitsText, options) or {}
    if type(unitsText) ~= "string" or unitsText == "" then
        return units
    end

    local records = splitPreservingEmpty(unitsText, UNIT_RECORD_SEPARATOR)
    local unitIndex = 0
    for index = 1, #records do
        if records[index] ~= "" then
            unitIndex = unitIndex + 1
            applyDisplayName(units[unitIndex], records[index])
        end
    end
    return units
end

local baseSerializeDelta = Event.SerializeUnitDeltaBatchForNetwork
function Event.SerializeUnitDeltaBatchForNetwork(entries, options)
    local serialized = type(baseSerializeDelta) == "function"
        and baseSerializeDelta(entries, options)
        or ""
    if serialized == "" then
        return serialized
    end

    local records = splitPreservingEmpty(serialized, UNIT_DELTA_RECORD_SEPARATOR)
    for index = 1, #records do
        if records[index] ~= "" and isAcceptedDeltaRecord(records[index]) then
            local fields = splitPreservingEmpty(records[index], UNIT_DELTA_FIELD_SEPARATOR)
            if tostring(fields[1] or "") == "upsert" and tostring(fields[3] or "") ~= "" then
                local entry = type(entries) == "table" and entries[index] or nil
                local sourceUnit = type(entry) == "table" and (entry.unit or entry) or nil
                fields[3] = appendDisplayName(fields[3], sourceUnit)
                records[index] = table.concat(fields, UNIT_DELTA_FIELD_SEPARATOR)
            end
        end
    end
    return table.concat(records, UNIT_DELTA_RECORD_SEPARATOR)
end

local baseDeserializeDelta = Event.DeserializeUnitDeltaBatchFromNetwork
function Event.DeserializeUnitDeltaBatchFromNetwork(batchText, options)
    local entries = type(baseDeserializeDelta) == "function"
        and baseDeserializeDelta(batchText, options)
        or {}
    if type(batchText) ~= "string" or batchText == "" then
        return entries
    end

    local records = splitPreservingEmpty(batchText, UNIT_DELTA_RECORD_SEPARATOR)
    local entryIndex = 0
    for index = 1, #records do
        if records[index] ~= "" and isAcceptedDeltaRecord(records[index]) then
            entryIndex = entryIndex + 1
            local fields = splitPreservingEmpty(records[index], UNIT_DELTA_FIELD_SEPARATOR)
            if tostring(fields[1] or "") == "upsert" and tostring(fields[3] or "") ~= "" then
                local entry = entries[entryIndex]
                if type(entry) == "table" then
                    applyDisplayName(entry.unit, fields[3])
                end
            end
        end
    end
    return entries
end

Event.DisplayNameNetworkFieldCount = DISPLAY_NAME_FIELD
