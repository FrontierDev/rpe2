local _, Addon = ...

Addon.Internal = Addon.Internal or {}
Addon.Internal.Comms = Addon.Internal.Comms or {}
Addon.Client = Addon.Client or {}
Addon.Server = Addon.Server or {}
Addon.Utils = Addon.Utils or {}

local Comms = Addon.Internal.Comms
local Operations = Comms.Operations or {}
local Client = Addon.Client
local Server = Addon.Server
local Common = Addon.Utils.Common or {}
local Profile = Addon.Internal.Profile or {}
local Classes = Addon.Internal.Database and Addon.Internal.Database.Classes or {}
local Event = Classes.Event
local EventUnit = Classes.EventUnit

local PRIMARY_RESOURCE_METADATA_OPCODE = 32
local UNIT_RECORD_SEPARATOR = string.char(30)
local UNIT_FIELD_SEPARATOR = string.char(29)
local UNIT_DELTA_RECORD_SEPARATOR = string.char(23)
local UNIT_DELTA_FIELD_SEPARATOR = string.char(22)
local PRIMARY_KNOWN_FIELD = 30
local PRIMARY_REF_FIELD = 31

local function normalizeName(value)
    if type(Common.NormalizeName) == "function" then
        return Common.NormalizeName(value)
    end
    return tostring(value or "")
end

local function normalizeRef(value)
    local ref = type(value) == "string" and value or ""
    return ref ~= "" and ref or nil
end

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

local function getLocalPrimaryMetadata()
    local bootstrapReady = type(Profile.IsBootstrapResolvedStateReady) ~= "function"
        or Profile.IsBootstrapResolvedStateReady() == true
    if not bootstrapReady or type(Profile.GetPrimaryResourceRef) ~= "function" then
        return false, nil
    end
    return true, normalizeRef(Profile.GetPrimaryResourceRef())
end

local function findPlayerUnitByName(units, playerName)
    local normalizedPlayerName = normalizeName(playerName)
    if normalizedPlayerName == "" then
        return nil
    end
    for index = 1, #(units or {}) do
        local unit = units[index]
        if type(unit) == "table" and unit.isPlayer == true then
            local candidate = normalizeName(unit.ownerID or unit.controllerID or unit.name)
            if candidate == normalizedPlayerName then
                return unit
            end
        end
    end
    return nil
end

local function setUnitMetadata(unit, known, primaryRef)
    if type(unit) ~= "table" or unit.isPlayer ~= true then
        return false
    end
    local normalizedRef = known == true and normalizeRef(primaryRef) or nil
    local changed = unit.primaryResourceKnown ~= (known == true)
        or normalizeRef(unit.primaryResourceRef) ~= normalizedRef
    unit.primaryResourceKnown = known == true
    unit.primaryResourceRef = normalizedRef
    return changed
end

local function resolveClientMetadata(playerName)
    local state = type(Server.GetState) == "function" and Server:GetState() or Server.State
    local clientState = type(state) == "table"
        and type(state.clientsByName) == "table"
        and state.clientsByName[normalizeName(playerName)]
        or nil
    if type(clientState) == "table" and clientState.primaryResourceKnown ~= nil then
        return clientState.primaryResourceKnown == true, normalizeRef(clientState.primaryResourceRef)
    end

    if normalizeName(playerName) == normalizeName(Common.GetPlayerName and Common.GetPlayerName() or nil) then
        return getLocalPrimaryMetadata()
    end
    return false, nil
end

local function applyServerMetadata(playerName, known, primaryRef, broadcast)
    local normalizedPlayerName = normalizeName(playerName)
    if normalizedPlayerName == "" then
        return false
    end

    local state = type(Server.GetState) == "function" and Server:GetState() or Server.State
    local clientState = type(state) == "table"
        and type(state.clientsByName) == "table"
        and state.clientsByName[normalizedPlayerName]
        or nil
    if type(clientState) ~= "table" then
        Server.PendingPrimaryResourceMetadataByName = Server.PendingPrimaryResourceMetadataByName or {}
        Server.PendingPrimaryResourceMetadataByName[normalizedPlayerName] = {
            known = known == true,
            primaryResourceRef = known == true and normalizeRef(primaryRef) or nil,
        }
        return false
    end

    clientState.primaryResourceKnown = known == true
    clientState.primaryResourceRef = known == true and normalizeRef(primaryRef) or nil

    local liveState = Server.EventState
    local liveUnit = type(liveState) == "table" and findPlayerUnitByName(liveState.units, normalizedPlayerName) or nil
    local liveChanged = setUnitMetadata(liveUnit, known, primaryRef)

    local draftState = Server.EventDraftState
    local draftUnit = type(draftState) == "table" and findPlayerUnitByName(draftState.units, normalizedPlayerName) or nil
    setUnitMetadata(draftUnit, known, primaryRef)

    if broadcast == true
        and liveChanged
        and type(liveState) == "table"
        and liveState.active == true
        and type(Server.BroadcastEventDeltaBatch) == "function"
    then
        Server:BroadcastEventDeltaBatch({
            {
                operation = "upsert",
                eventID = liveUnit.eventID,
                unit = liveUnit,
            },
        }, false)
    end

    return true
end

function Server:HandlePrimaryResourceMetadata(arguments, sender)
    local state = type(self.GetState) == "function" and self:GetState() or self.State
    if type(state) ~= "table" or state.active ~= true then
        return false
    end
    if tostring(arguments and arguments[1] or "") ~= tostring(state.channelName or "") then
        return false
    end

    local playerName = normalizeName(sender)
    if playerName == "" then
        return false
    end

    local known = tostring(arguments and arguments[2] or "0") == "1"
    local primaryRef = known and normalizeRef(arguments and arguments[3] or nil) or nil
    return applyServerMetadata(playerName, known, primaryRef, true)
end

local function installOperation()
    local existingByKey = type(Operations.GetOpcode) == "function"
        and Operations:GetOpcode("PRIMARY_RESOURCE_METADATA")
        or nil
    if existingByKey then
        return existingByKey
    end

    local existing = type(Operations.Get) == "function" and Operations:Get(PRIMARY_RESOURCE_METADATA_OPCODE) or nil
    if type(existing) == "table" and tostring(existing.key or "") ~= "" then
        error(("PRIMARY_RESOURCE_METADATA opcode collision: %d is already registered as %s."):format(
            PRIMARY_RESOURCE_METADATA_OPCODE,
            tostring(existing.key)
        ))
    end

    local definition = {
        opcode = PRIMARY_RESOURCE_METADATA_OPCODE,
        key = "PRIMARY_RESOURCE_METADATA",
        name = "primary-resource-metadata",
        ["function"] = function(arguments, sender, distribution, target, message)
            return Server:HandlePrimaryResourceMetadata(arguments, sender, distribution, target, message)
        end,
    }

    Operations.Opcodes = Operations.Opcodes or {}
    Operations.Registry = Operations.Registry or {}
    Operations.KeyIndex = Operations.KeyIndex or {}
    Operations.Opcodes[PRIMARY_RESOURCE_METADATA_OPCODE] = definition
    Operations.KeyIndex.PRIMARY_RESOURCE_METADATA = PRIMARY_RESOURCE_METADATA_OPCODE
    if type(Operations.Register) == "function" then
        local operation = Operations:Register(PRIMARY_RESOURCE_METADATA_OPCODE, definition["function"], definition.name)
        if type(operation) == "table" then
            operation.key = definition.key
        end
    else
        Operations.Registry[PRIMARY_RESOURCE_METADATA_OPCODE] = definition
    end
    return PRIMARY_RESOURCE_METADATA_OPCODE
end

local PRIMARY_RESOURCE_OPCODE = installOperation()

function Client:SendPrimaryResourceMetadata(state)
    if type(state) ~= "table"
        or state.active ~= true
        or tostring(state.channelName or "") == ""
        or not PRIMARY_RESOURCE_OPCODE
        or type(Comms.SendToChannel) ~= "function"
    then
        return false
    end

    local known, primaryRef = getLocalPrimaryMetadata()
    local signature = (known and "1" or "0") .. "\31" .. tostring(primaryRef or "")
    if state.lastPrimaryResourceMetadataSignature == signature then
        return true
    end

    local channelId = state.channelId
    if (channelId == nil or channelId == "") and type(Comms.ResolveChannelId) == "function" then
        channelId = Comms:ResolveChannelId(state.channelName)
    end
    if channelId == nil or channelId == "" then
        return false
    end
    state.channelId = channelId

    local sent = Comms:SendToChannel(channelId, PRIMARY_RESOURCE_OPCODE, {
        state.channelName,
        known and "1" or "0",
        primaryRef or "",
    }, {
        opcode = PRIMARY_RESOURCE_OPCODE,
        scope = "client",
        onDelivered = function()
            if Client.State == state then
                state.lastPrimaryResourceMetadataSignature = signature
            end
        end,
    })
    return sent == true
end

if Client.PrimaryResourceConnectWrapped ~= true and type(Client.SendClientConnect) == "function" then
    Client.PrimaryResourceConnectWrapped = true
    local nativeSendClientConnect = Client.SendClientConnect
    function Client:SendClientConnect(state, reason)
        local sent = nativeSendClientConnect(self, state, reason)
        if sent == true then
            self:SendPrimaryResourceMetadata(state)
        end
        return sent
    end
end

if Server.PrimaryResourceConnectWrapped ~= true and type(Server.HandleClientConnect) == "function" then
    Server.PrimaryResourceConnectWrapped = true
    local nativeHandleClientConnect = Server.HandleClientConnect
    function Server:HandleClientConnect(arguments, sender, distribution, target, message)
        local handled = nativeHandleClientConnect(self, arguments, sender, distribution, target, message)
        local playerName = normalizeName(sender)
        local pending = type(self.PendingPrimaryResourceMetadataByName) == "table"
            and self.PendingPrimaryResourceMetadataByName[playerName]
            or nil
        if type(pending) == "table" then
            self.PendingPrimaryResourceMetadataByName[playerName] = nil
            applyServerMetadata(playerName, pending.known == true, pending.primaryResourceRef, true)
        end
        return handled
    end
end

if type(EventUnit) == "table" and EventUnit.PrimaryResourceToTableWrapped ~= true and type(EventUnit.ToTable) == "function" then
    EventUnit.PrimaryResourceToTableWrapped = true
    local nativeToTable = EventUnit.ToTable
    function EventUnit:ToTable()
        local data = nativeToTable(self)
        data.primaryResourceKnown = self.primaryResourceKnown == true
        data.primaryResourceRef = self.primaryResourceKnown == true and normalizeRef(self.primaryResourceRef) or nil
        return data
    end
end

local function resolveUnitMetadata(unit)
    if type(unit) ~= "table" or unit.isPlayer ~= true then
        return false, nil
    end
    if unit.primaryResourceKnown == true then
        return true, normalizeRef(unit.primaryResourceRef)
    end
    return resolveClientMetadata(unit.ownerID or unit.controllerID or unit.name)
end

local function appendPrimaryMetadata(record, sourceUnit)
    if type(record) ~= "string" or record == "" then
        return record
    end
    local fields = splitPreservingEmpty(record, UNIT_FIELD_SEPARATOR)
    if #fields < 9 then
        return record
    end
    while #fields < PRIMARY_KNOWN_FIELD - 1 do
        fields[#fields + 1] = ""
    end
    local known, primaryRef = resolveUnitMetadata(sourceUnit)
    if type(sourceUnit) == "table" and sourceUnit.isPlayer == true then
        setUnitMetadata(sourceUnit, known, primaryRef)
    end
    fields[PRIMARY_KNOWN_FIELD] = known and "1" or "0"
    fields[PRIMARY_REF_FIELD] = known and tostring(primaryRef or "") or ""
    return table.concat(fields, UNIT_FIELD_SEPARATOR)
end

local function applyPrimaryMetadata(unit, record)
    if type(unit) ~= "table" or type(record) ~= "string" or record == "" then
        return unit
    end
    local fields = splitPreservingEmpty(record, UNIT_FIELD_SEPARATOR)
    if #fields < PRIMARY_KNOWN_FIELD then
        unit.primaryResourceKnown = false
        unit.primaryResourceRef = nil
        return unit
    end
    unit.primaryResourceKnown = tostring(fields[PRIMARY_KNOWN_FIELD] or "") == "1"
    unit.primaryResourceRef = unit.primaryResourceKnown and normalizeRef(fields[PRIMARY_REF_FIELD]) or nil
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

if type(Event) == "table" and Event.PrimaryResourceNetworkWrapped ~= true then
    Event.PrimaryResourceNetworkWrapped = true

    local nativeSerializeUnits = Event.SerializeUnitsForNetwork
    function Event:SerializeUnitsForNetwork()
        local serialized = type(nativeSerializeUnits) == "function" and nativeSerializeUnits(self) or ""
        if serialized == "" then
            return serialized
        end
        local records = splitPreservingEmpty(serialized, UNIT_RECORD_SEPARATOR)
        local unitIndex = 0
        for index = 1, #records do
            if records[index] ~= "" then
                unitIndex = unitIndex + 1
                records[index] = appendPrimaryMetadata(records[index], self.units and self.units[unitIndex] or nil)
            end
        end
        return table.concat(records, UNIT_RECORD_SEPARATOR)
    end

    local nativeDeserializeUnits = Event.DeserializeUnitsFromNetwork
    function Event.DeserializeUnitsFromNetwork(unitsText)
        local units = type(nativeDeserializeUnits) == "function" and nativeDeserializeUnits(unitsText) or {}
        if type(unitsText) ~= "string" or unitsText == "" then
            return units
        end
        local records = splitPreservingEmpty(unitsText, UNIT_RECORD_SEPARATOR)
        local unitIndex = 0
        for index = 1, #records do
            if records[index] ~= "" then
                unitIndex = unitIndex + 1
                applyPrimaryMetadata(units[unitIndex], records[index])
            end
        end
        return units
    end

    local nativeSerializeDelta = Event.SerializeUnitDeltaBatchForNetwork
    function Event.SerializeUnitDeltaBatchForNetwork(entries)
        local serialized = type(nativeSerializeDelta) == "function" and nativeSerializeDelta(entries) or ""
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
                    fields[3] = appendPrimaryMetadata(fields[3], sourceUnit)
                    records[index] = table.concat(fields, UNIT_DELTA_FIELD_SEPARATOR)
                end
            end
        end
        return table.concat(records, UNIT_DELTA_RECORD_SEPARATOR)
    end

    local nativeDeserializeDelta = Event.DeserializeUnitDeltaBatchFromNetwork
    function Event.DeserializeUnitDeltaBatchFromNetwork(batchText)
        local entries = type(nativeDeserializeDelta) == "function" and nativeDeserializeDelta(batchText) or {}
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
                        applyPrimaryMetadata(entry.unit, fields[3])
                    end
                end
            end
        end
        return entries
    end
end
