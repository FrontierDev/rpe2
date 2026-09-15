local _, Addon = ...

Addon.Internal = Addon.Internal or {}
Addon.Internal.Database = Addon.Internal.Database or {}
Addon.Internal.Database.Classes = Addon.Internal.Database.Classes or {}
Addon.Utils = Addon.Utils or {}

local Classes = Addon.Internal.Database.Classes
local Event = Classes.Event
local EventUnit = Classes.EventUnit
local Common = Addon.Utils.Common or {}

if type(Event) ~= "table" or type(EventUnit) ~= "table" or Event._variantSpellEquipmentNetworkInstalled == true then
    return
end

local UNIT_RECORD_SEPARATOR = string.char(30)
local UNIT_FIELD_SEPARATOR = string.char(29)
local UNIT_DELTA_RECORD_SEPARATOR = string.char(23)
local UNIT_DELTA_FIELD_SEPARATOR = string.char(22)

local PRESET_INDEX_FIELD = 24
local APPEARANCE_INDEX_FIELD = 25
local MAIN_HAND_FIELD = 26
local OFF_HAND_FIELD = 27
local RANGED_FIELD = 28
local SHIELD_FIELD = 29
-- PrimaryResourceSync owns fields 30-31 and wraps this serializer later.
-- Keep NPC-mode visibility after those fields so neither extension overwrites the other.
local SHOW_IN_NPC_MODE_FIELD = 32
local FINAL_FIELD_COUNT = 32

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

local function normalizeIndex(value)
    if type(EventUnit.NormalizeVariantIndex) == "function" then
        return EventUnit.NormalizeVariantIndex(value)
    end
    local numeric = tonumber(value)
    if not numeric then
        return 0
    end
    return math.max(0, math.floor(numeric))
end

local function normalizeRef(value)
    local ref = tostring(value or ""):gsub("^%s+", ""):gsub("%s+$", "")
    return ref ~= "" and ref or nil
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

local function resolveRuntimeSource(sourceUnit)
    if type(sourceUnit) ~= "table" then
        return nil
    end
    return findRuntimeUnit(sourceUnit.eventID) or sourceUnit
end

local function appendSpellEquipment(record, sourceUnit)
    if type(record) ~= "string" or record == "" then
        return record
    end

    local fields = splitPreservingEmpty(record, UNIT_FIELD_SEPARATOR)
    if #fields < PRESET_INDEX_FIELD then
        return record
    end

    local runtimeUnit = resolveRuntimeSource(sourceUnit)
    if type(runtimeUnit) ~= "table" then
        runtimeUnit = sourceUnit
    end

    local presetIndex = normalizeIndex(fields[PRESET_INDEX_FIELD])
    if presetIndex > 0 and type(runtimeUnit) == "table"
        and type(EventUnit.SerializeSpellRefsForNetwork) == "function"
    then
        -- Preset mechanics are host materialized. Always make the spell list
        -- explicit for a Preset, including an intentional empty {} override.
        fields[14] = EventUnit.SerializeSpellRefsForNetwork(runtimeUnit.spells or {})
        fields[19] = ""
    end

    while #fields < APPEARANCE_INDEX_FIELD do
        fields[#fields + 1] = ""
    end

    if type(runtimeUnit) == "table" and runtimeUnit.isPlayer ~= true then
        fields[MAIN_HAND_FIELD] = tostring(runtimeUnit.mainHandWeapon or "")
        fields[OFF_HAND_FIELD] = tostring(runtimeUnit.offHandWeapon or "")
        fields[RANGED_FIELD] = tostring(runtimeUnit.rangedWeapon or "")
        fields[SHIELD_FIELD] = tostring(runtimeUnit.shield or "")
    else
        fields[MAIN_HAND_FIELD] = ""
        fields[OFF_HAND_FIELD] = ""
        fields[RANGED_FIELD] = ""
        fields[SHIELD_FIELD] = ""
    end

    local showInNpcMode = false
    if type(runtimeUnit) == "table" then
        if type(EventUnit.IsShownInNpcMode) == "function" then
            showInNpcMode = EventUnit.IsShownInNpcMode(runtimeUnit)
        else
            showInNpcMode = runtimeUnit.showInNpcMode == true
        end
    end
    while #fields < SHOW_IN_NPC_MODE_FIELD - 1 do
        fields[#fields + 1] = ""
    end
    fields[SHOW_IN_NPC_MODE_FIELD] = showInNpcMode and "1" or "0"

    return table.concat(fields, UNIT_FIELD_SEPARATOR)
end

local function applySpellEquipment(unit, record)
    if type(unit) ~= "table" or type(record) ~= "string" or record == "" then
        return unit
    end

    local fields = splitPreservingEmpty(record, UNIT_FIELD_SEPARATOR)
    if #fields < MAIN_HAND_FIELD then
        return unit
    end

    unit.mainHandWeapon = normalizeRef(fields[MAIN_HAND_FIELD])
    unit.offHandWeapon = normalizeRef(fields[OFF_HAND_FIELD])
    unit.rangedWeapon = normalizeRef(fields[RANGED_FIELD])
    unit.shield = normalizeRef(fields[SHIELD_FIELD])
    unit.showInNpcMode = tostring(fields[SHOW_IN_NPC_MODE_FIELD] or "") == "1"
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
    local serialized = type(baseSerializeUnitsForNetwork) == "function" and baseSerializeUnitsForNetwork(self) or ""
    if serialized == "" then
        return serialized
    end

    local records = splitPreservingEmpty(serialized, UNIT_RECORD_SEPARATOR)
    local unitIndex = 0
    for index = 1, #records do
        if records[index] ~= "" then
            unitIndex = unitIndex + 1
            records[index] = appendSpellEquipment(records[index], self.units and self.units[unitIndex] or nil)
        end
    end
    return table.concat(records, UNIT_RECORD_SEPARATOR)
end

local baseDeserializeUnitsFromNetwork = Event.DeserializeUnitsFromNetwork
function Event.DeserializeUnitsFromNetwork(unitsText)
    local units = type(baseDeserializeUnitsFromNetwork) == "function" and baseDeserializeUnitsFromNetwork(unitsText) or {}
    if type(unitsText) ~= "string" or unitsText == "" then
        return units
    end

    local records = splitPreservingEmpty(unitsText, UNIT_RECORD_SEPARATOR)
    local unitIndex = 0
    for index = 1, #records do
        if records[index] ~= "" then
            unitIndex = unitIndex + 1
            applySpellEquipment(units[unitIndex], records[index])
        end
    end
    return units
end

local baseSerializeUnitDeltaBatchForNetwork = Event.SerializeUnitDeltaBatchForNetwork
function Event.SerializeUnitDeltaBatchForNetwork(entries)
    local serialized = type(baseSerializeUnitDeltaBatchForNetwork) == "function"
        and baseSerializeUnitDeltaBatchForNetwork(entries)
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
                fields[3] = appendSpellEquipment(fields[3], sourceUnit)
                records[index] = table.concat(fields, UNIT_DELTA_FIELD_SEPARATOR)
            end
        end
    end
    return table.concat(records, UNIT_DELTA_RECORD_SEPARATOR)
end

local baseDeserializeUnitDeltaBatchFromNetwork = Event.DeserializeUnitDeltaBatchFromNetwork
function Event.DeserializeUnitDeltaBatchFromNetwork(batchText)
    local entries = type(baseDeserializeUnitDeltaBatchFromNetwork) == "function"
        and baseDeserializeUnitDeltaBatchFromNetwork(batchText)
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
                    applySpellEquipment(entry.unit, fields[3])
                end
            end
        end
    end
    return entries
end

Event.VariantEquipmentNetworkFieldCount = FINAL_FIELD_COUNT
Event._variantSpellEquipmentNetworkInstalled = true
