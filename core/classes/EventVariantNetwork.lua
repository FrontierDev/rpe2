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

local function cloneNetworkUnit(unit)
    if type(unit) ~= "table" or type(EventUnit.FromTable) ~= "function" then
        return nil
    end

    if type(unit.ToTable) == "function" then
        return EventUnit.FromTable(unit:ToTable())
    end
    return EventUnit.FromTable(unit)
end

local function countPlayerUnits(units)
    local count = 0
    for index = 1, #(units or {}) do
        if units[index] and units[index].isPlayer == true then
            count = count + 1
        end
    end
    return count
end

local function normalizeResourceRows(resources)
    if type(EventUnit.SerializeResourcesForNetwork) ~= "function"
        or type(EventUnit.DeserializeResourcesFromNetwork) ~= "function"
    then
        return nil
    end
    return EventUnit.DeserializeResourcesFromNetwork(EventUnit.SerializeResourcesForNetwork(resources or {}))
end

local function normalizeStatRows(stats)
    if type(EventUnit.SerializeStatsForNetwork) ~= "function"
        or type(EventUnit.DeserializeStatsFromNetwork) ~= "function"
    then
        return nil
    end
    return EventUnit.DeserializeStatsFromNetwork(EventUnit.SerializeStatsForNetwork(stats or {}))
end

local function normalizeSpellRefs(spells)
    if type(EventUnit.SerializeSpellRefsForNetwork) ~= "function"
        or type(EventUnit.DeserializeSpellRefsFromNetwork) ~= "function"
    then
        return nil
    end
    return EventUnit.DeserializeSpellRefsFromNetwork(EventUnit.SerializeSpellRefsForNetwork(spells or {}))
end

local function resourceRowsEqual(left, right)
    local normalizedLeft = normalizeResourceRows(left)
    local normalizedRight = normalizeResourceRows(right)
    if type(normalizedLeft) ~= "table" or type(normalizedRight) ~= "table" or #normalizedLeft ~= #normalizedRight then
        return false
    end

    for index = 1, #normalizedLeft do
        local leftEntry = normalizedLeft[index]
        local rightEntry = normalizedRight[index]
        if tostring(leftEntry and leftEntry.resourceRef or "") ~= tostring(rightEntry and rightEntry.resourceRef or "")
            or tonumber(leftEntry and leftEntry.currentValue) ~= tonumber(rightEntry and rightEntry.currentValue)
            or tonumber(leftEntry and leftEntry.maxValue) ~= tonumber(rightEntry and rightEntry.maxValue)
        then
            return false
        end
    end
    return true
end

local function statRowsEqual(left, right)
    local normalizedLeft = normalizeStatRows(left)
    local normalizedRight = normalizeStatRows(right)
    if type(normalizedLeft) ~= "table" or type(normalizedRight) ~= "table" or #normalizedLeft ~= #normalizedRight then
        return false
    end

    for index = 1, #normalizedLeft do
        local leftEntry = normalizedLeft[index]
        local rightEntry = normalizedRight[index]
        if tostring(leftEntry and leftEntry.statRef or "") ~= tostring(rightEntry and rightEntry.statRef or "")
            or tonumber(leftEntry and leftEntry.value) ~= tonumber(rightEntry and rightEntry.value)
            or tonumber(leftEntry and leftEntry.currentValue) ~= tonumber(rightEntry and rightEntry.currentValue)
        then
            return false
        end
    end
    return true
end

local function spellRefsEqual(left, right)
    local normalizedLeft = normalizeSpellRefs(left)
    local normalizedRight = normalizeSpellRefs(right)
    if type(normalizedLeft) ~= "table" or type(normalizedRight) ~= "table" or #normalizedLeft ~= #normalizedRight then
        return false
    end

    for index = 1, #normalizedLeft do
        if tostring(normalizedLeft[index] or "") ~= tostring(normalizedRight[index] or "") then
            return false
        end
    end
    return true
end

local function resolveReceiverBaseResources(unit, playerCount)
    if type(EventUnit.BuildResolvedResources) ~= "function" then
        return nil
    end
    local probe = cloneNetworkUnit(unit)
    if not probe then
        return nil
    end
    probe.resources = {}
    probe._networkResourceMode = nil
    local ok, resources = pcall(EventUnit.BuildResolvedResources, probe, playerCount)
    return ok and type(resources) == "table" and resources or nil
end

local function resolveReceiverBaseStats(unit)
    if type(EventUnit.BuildResolvedStats) ~= "function" then
        return nil
    end
    local probe = cloneNetworkUnit(unit)
    if not probe then
        return nil
    end
    probe.stats = {}
    probe._networkStatMode = nil
    local ok, stats = pcall(EventUnit.BuildResolvedStats, probe)
    return ok and type(stats) == "table" and stats or nil
end

local function resolveReceiverBaseSpells(unit)
    if type(EventUnit.BuildResolvedSpellRefs) ~= "function" then
        return nil
    end
    local probe = cloneNetworkUnit(unit)
    if not probe then
        return nil
    end
    probe.spells = {}
    probe._networkSpellMode = nil
    local ok, spells = pcall(EventUnit.BuildResolvedSpellRefs, probe)
    return ok and type(spells) == "table" and spells or nil
end

local function compactSnapshotUnit(unit, playerCount)
    if type(unit) ~= "table" or unit.isPlayer == true or tostring(unit.registryID or "") == "" then
        return unit
    end
    local resolvedUnit = type(unit.GetResolvedUnit) == "function" and unit:GetResolvedUnit() or nil
    if type(resolvedUnit) ~= "table" then
        return unit
    end

    local compact = cloneNetworkUnit(unit)
    if not compact then
        return unit
    end

    compact._networkResourceMode = nil
    if type(EventUnit.BuildResourceDeltas) == "function" and type(EventUnit.ApplyResourceDeltas) == "function" then
        local baseResources = resolveReceiverBaseResources(compact, playerCount)
        if type(baseResources) == "table" then
            local resourceDeltas = EventUnit.BuildResourceDeltas(baseResources, unit.resources or {})
            local reconstructed = EventUnit.ApplyResourceDeltas(baseResources, resourceDeltas)
            if resourceRowsEqual(reconstructed, unit.resources or {}) then
                compact.resources = resourceDeltas
                compact._networkResourceMode = "delta"
            end
        end
    end

    local presetIndex = normalizeVariantIndex(unit.presetIndex)
    compact._networkSpellMode = nil
    compact._networkStatMode = nil
    if presetIndex == 0 then
        local baseSpells = resolveReceiverBaseSpells(compact)
        if type(baseSpells) == "table" and spellRefsEqual(baseSpells, unit.spells or {}) then
            compact.spells = {}
            compact._networkSpellMode = "inherit"
        end

        local baseStats = resolveReceiverBaseStats(compact)
        if type(baseStats) == "table" and statRowsEqual(baseStats, unit.stats or {}) then
            compact.stats = {}
            compact._networkStatMode = "inherit"
        end
    end

    return compact
end

local function buildSnapshotSerializationEvent(eventState)
    local server = Addon.Server
    if type(eventState) ~= "table"
        or type(server) ~= "table"
        or server.EventState ~= eventState
        or eventState.active ~= true
    then
        return eventState
    end

    local compactUnits = {}
    local playerCount = countPlayerUnits(eventState.units)
    for index = 1, #((eventState.units) or {}) do
        compactUnits[index] = compactSnapshotUnit(eventState.units[index], playerCount)
    end

    return {
        units = compactUnits,
    }
end

local function makePresetMechanicsExplicit(fields, sourceUnit, presetIndex)
    if type(fields) ~= "table" or type(sourceUnit) ~= "table" then
        return fields
    end

    local runtimeUnit = findRuntimeUnit(sourceUnit.eventID) or sourceUnit
    if type(runtimeUnit) ~= "table" then
        return fields
    end

    -- Ordinary serialization keeps resources host-materialized. A snapshot
    -- compaction copy explicitly marked as resource delta has already proved
    -- lossless receiver reconstruction and must retain that mode.
    if tostring(sourceUnit._networkResourceMode or "") ~= "delta"
        and type(EventUnit.SerializeResourcesForNetwork) == "function"
    then
        fields[11] = EventUnit.SerializeResourcesForNetwork(runtimeUnit.resources or {})
        fields[18] = ""
    end

    if presetIndex > 0 then
        if type(EventUnit.SerializeStatsForNetwork) == "function" then
            fields[15] = EventUnit.SerializeStatsForNetwork(runtimeUnit.stats or {})
        end

        -- Preset stats are host-materialized. Do not let compact bonus mode
        -- reconstruct Base-only mechanics on the receiver.
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
    local serializationEvent = buildSnapshotSerializationEvent(self)
    local serialized = baseSerializeUnitsForNetwork and baseSerializeUnitsForNetwork(serializationEvent) or ""
    if serialized == "" then
        return serialized
    end

    local records = splitPreservingEmpty(serialized, UNIT_RECORD_SEPARATOR)
    for index = 1, #records do
        if records[index] ~= "" then
            records[index] = appendVariantIdentity(records[index], serializationEvent.units and serializationEvent.units[index] or nil)
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

    if type(EventUnit.HydrateNetworkUnit) == "function" then
        local playerCount = countPlayerUnits(units)
        for index = 1, #units do
            units[index] = EventUnit.HydrateNetworkUnit(units[index], {
                playerCount = playerCount,
            })
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
