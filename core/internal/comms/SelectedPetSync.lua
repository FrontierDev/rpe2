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
local Runtime = Addon.Internal.Runtime or {}
local Classes = Addon.Internal.Database and Addon.Internal.Database.Classes or {}
local Event = Classes.Event
local EventUnit = Classes.EventUnit

local UNIT_RECORD_SEPARATOR = string.char(30)
local UNIT_FIELD_SEPARATOR = string.char(29)
local UNIT_DELTA_RECORD_SEPARATOR = string.char(23)
local UNIT_DELTA_FIELD_SEPARATOR = string.char(22)
-- Fields 24-32 belong to the existing variant, equipment, NPC-mode, and
-- primary-resource extensions. Keep selected-pet runtime stats after them.
local PET_STATS_FIELD = 33

local function normalizeName(value)
    if type(Common.NormalizeName) == "function" then
        return Common.NormalizeName(value)
    end
    return tostring(value or "")
end

local function normalizeRef(value)
    local ref = tostring(value or "")
    return ref ~= "" and ref or nil
end

local function normalizePetStats(value)
    if type(value) ~= "table" then
        return {}
    end
    if type(EventUnit) == "table" and type(EventUnit.New) == "function" then
        return EventUnit:New({ petStats = value }).petStats or {}
    end
    return value
end

local function clone(value)
    if type(value) ~= "table" then
        return value
    end
    local copy = {}
    for key, nestedValue in pairs(value) do
        copy[key] = clone(nestedValue)
    end
    return copy
end

local function serializeStats(stats)
    if type(EventUnit) == "table" and type(EventUnit.SerializeStatsForNetwork) == "function" then
        return EventUnit.SerializeStatsForNetwork(stats or {})
    end
    return ""
end

local function deserializeStats(payload)
    if type(EventUnit) == "table" and type(EventUnit.DeserializeStatsFromNetwork) == "function" then
        return EventUnit.DeserializeStatsFromNetwork(payload or "")
    end
    return {}
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

local function appendPetStats(record, sourceUnit)
    if type(record) ~= "string" or record == "" then
        return record
    end

    local fields = splitPreservingEmpty(record, UNIT_FIELD_SEPARATOR)
    if #fields < 9 then
        return record
    end

    while #fields < PET_STATS_FIELD - 1 do
        fields[#fields + 1] = ""
    end
    fields[PET_STATS_FIELD] = serializeStats(type(sourceUnit) == "table" and sourceUnit.petStats or nil)
    return table.concat(fields, UNIT_FIELD_SEPARATOR)
end

local function applyPetStats(unit, record)
    if type(unit) ~= "table" or type(record) ~= "string" or record == "" then
        return unit
    end

    local fields = splitPreservingEmpty(record, UNIT_FIELD_SEPARATOR)
    if #fields >= PET_STATS_FIELD then
        unit.petStats = normalizePetStats(deserializeStats(fields[PET_STATS_FIELD] or ""))
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

if type(Event) == "table" and Event.SelectedPetStatsNetworkWrapped ~= true then
    Event.SelectedPetStatsNetworkWrapped = true

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
                records[index] = appendPetStats(records[index], self.units and self.units[unitIndex] or nil)
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
                applyPetStats(units[unitIndex], records[index])
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
                    fields[3] = appendPetStats(fields[3], sourceUnit)
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
                        applyPetStats(entry.unit, fields[3])
                    end
                end
            end
        end
        return entries
    end
end

local function getLocalPetState()
    local petRef = type(Profile.GetPetRef) == "function" and normalizeRef(Profile.GetPetRef()) or nil
    local stats = {}
    if petRef ~= nil
        and type(Profile.IsPetSelectionValid) == "function"
        and Profile.IsPetSelectionValid() == true
        and type(Profile.BuildSelectedPetRuntimeStats) == "function"
    then
        stats = normalizePetStats(Profile.BuildSelectedPetRuntimeStats())
    end
    return petRef, stats
end

local function findPlayerUnitByName(units, playerName)
    local normalizedName = normalizeName(playerName)
    if normalizedName == "" then
        return nil
    end

    for index = 1, #(units or {}) do
        local unit = units[index]
        if type(unit) == "table" and unit.isPlayer == true
            and normalizeName(unit.ownerID or unit.controllerID or unit.name) == normalizedName
        then
            return unit
        end
    end

    return nil
end

local function applyUnitMetadata(unit, petRef, petStats)
    if type(unit) ~= "table" or unit.isPlayer ~= true then
        return false
    end

    local normalizedRef = normalizeRef(petRef)
    local normalizedStats = normalizePetStats(petStats)
    local changed = normalizeRef(unit.petRef) ~= normalizedRef
        or serializeStats(unit.petStats) ~= serializeStats(normalizedStats)
    unit.petRef = normalizedRef
    unit.petStats = clone(normalizedStats)
    return changed
end

local function getServerState()
    return type(Server.GetState) == "function" and Server:GetState() or Server.State
end

local function applyServerMetadata(playerName, petRef, petStats, broadcast)
    local normalizedName = normalizeName(playerName)
    if normalizedName == "" then
        return false
    end

    local state = getServerState()
    local clientState = type(state) == "table"
        and type(state.clientsByName) == "table"
        and state.clientsByName[normalizedName]
        or nil
    if type(clientState) ~= "table" then
        Server.PendingSelectedPetMetadataByName = Server.PendingSelectedPetMetadataByName or {}
        Server.PendingSelectedPetMetadataByName[normalizedName] = {
            petRef = normalizeRef(petRef),
            petStats = clone(normalizePetStats(petStats)),
        }
        return false
    end

    local normalizedRef = normalizeRef(petRef)
    local normalizedStats = normalizePetStats(petStats)
    clientState.petRef = normalizedRef
    clientState.petStats = clone(normalizedStats)

    local liveState = Server.EventState
    local liveUnit = type(liveState) == "table" and findPlayerUnitByName(liveState.units, normalizedName) or nil
    local liveChanged = applyUnitMetadata(liveUnit, normalizedRef, normalizedStats)
    local draftState = Server.EventDraftState
    applyUnitMetadata(type(draftState) == "table" and findPlayerUnitByName(draftState.units, normalizedName) or nil, normalizedRef, normalizedStats)

    if broadcast == true and liveChanged
        and type(liveState) == "table" and liveState.active == true
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

local function handleMetadata(arguments, sender)
    local state = getServerState()
    if type(state) ~= "table" or state.active ~= true
        or tostring(arguments and arguments[1] or "") ~= tostring(state.channelName or "")
    then
        return false
    end

    local senderName = normalizeName(sender)
    if senderName == "" then
        return false
    end

    return applyServerMetadata(senderName, arguments and arguments[2], deserializeStats(arguments and arguments[3]), true)
end

local SELECTED_PET_OPCODE = type(Operations.Allocate) == "function"
    and Operations:Allocate("SELECTED_PET_METADATA", handleMetadata, "selected-pet-metadata")
    or nil

function Client:SendSelectedPetMetadata(state, force)
    if type(state) ~= "table" or state.active ~= true
        or tostring(state.channelName or "") == ""
        or not SELECTED_PET_OPCODE
        or type(Comms.SendToChannel) ~= "function"
    then
        return false
    end

    local petRef, petStats = getLocalPetState()
    local signature = tostring(petRef or "") .. "\31" .. serializeStats(petStats)
    if force ~= true and state.lastSelectedPetMetadataSignature == signature then
        return true
    end

    -- The local client can also host the server. Reconcile its client record
    -- immediately so an event started in the same frame includes the selected
    -- pet before the channel delivery callback runs.
    local localName = normalizeName(Common.GetPlayerName and Common.GetPlayerName() or nil)
    if localName ~= "" then
        applyServerMetadata(localName, petRef, petStats, true)
    end

    local channelId = state.channelId
    if (channelId == nil or channelId == "") and type(Comms.ResolveChannelId) == "function" then
        channelId = Comms:ResolveChannelId(state.channelName)
    end
    if channelId == nil or channelId == "" then
        return false
    end
    state.channelId = channelId

    local sent = Comms:SendToChannel(channelId, SELECTED_PET_OPCODE, {
        state.channelName,
        petRef or "",
        serializeStats(petStats),
    }, {
        opcode = SELECTED_PET_OPCODE,
        scope = "client",
        onDelivered = function()
            if Client.State == state then
                state.lastSelectedPetMetadataSignature = signature
            end
        end,
    })
    if sent == true then
        local eventState = Client.EventState
        applyUnitMetadata(type(eventState) == "table" and findPlayerUnitByName(eventState.units, localName) or nil, petRef, petStats)
    end
    return sent == true
end

function Client:QueueSelectedPetSync(reason)
    local state = self.State
    if type(state) ~= "table" or state.active ~= true then
        return false
    end
    state.lastSelectedPetMetadataReason = reason or state.lastSelectedPetMetadataReason
    return self:SendSelectedPetMetadata(state, true)
end

if Client.SelectedPetConnectWrapped ~= true and type(Client.SendClientConnect) == "function" then
    Client.SelectedPetConnectWrapped = true
    local nativeSendClientConnect = Client.SendClientConnect
    function Client:SendClientConnect(state, reason)
        -- Queue metadata before connect as well as after it. The server keeps
        -- pre-connect metadata pending, which removes the event-start race.
        self:SendSelectedPetMetadata(state)
        local sent = nativeSendClientConnect(self, state, reason)
        if sent == true then
            self:SendSelectedPetMetadata(state, true)
        end
        return sent
    end
end

if Server.SelectedPetConnectWrapped ~= true and type(Server.HandleClientConnect) == "function" then
    Server.SelectedPetConnectWrapped = true
    local nativeHandleClientConnect = Server.HandleClientConnect
    function Server:HandleClientConnect(arguments, sender, distribution, target, message)
        local handled = nativeHandleClientConnect(self, arguments, sender, distribution, target, message)
        local playerName = normalizeName(sender)
        local pending = type(self.PendingSelectedPetMetadataByName) == "table"
            and self.PendingSelectedPetMetadataByName[playerName]
            or nil
        if type(pending) == "table" then
            self.PendingSelectedPetMetadataByName[playerName] = nil
            applyServerMetadata(playerName, pending.petRef, pending.petStats, true)
        end
        return handled
    end
end

if Server.SelectedPetStartWrapped ~= true and type(Server.StartEvent) == "function" then
    Server.SelectedPetStartWrapped = true
    local nativeStartEvent = Server.StartEvent
    function Server:StartEvent(data, ...)
        local state = Client.State
        if type(state) == "table" and state.active == true and type(Client.SendSelectedPetMetadata) == "function" then
            Client:SendSelectedPetMetadata(state, true)
        end
        return nativeStartEvent(self, data, ...)
    end
end

if type(Profile.SetPetRef) == "function" and Profile.SelectedPetSyncWrapped ~= true then
    Profile.SelectedPetSyncWrapped = true
    local nativeSetPetRef = Profile.SetPetRef
    function Profile.SetPetRef(petRef)
        local result = nativeSetPetRef(petRef)
        if type(Client.QueueSelectedPetSync) == "function" then
            Client:QueueSelectedPetSync("profile-pet")
        end
        return result
    end
end

if type(Runtime) == "table"
    and type(Runtime.RegisterPostCommitListener) == "function"
    and Client._selectedPetRuntimeListenerId == nil
then
    Client._selectedPetRuntimeListenerId = Runtime:RegisterPostCommitListener(function()
        if type(Client.QueueSelectedPetSync) == "function" then
            Client:QueueSelectedPetSync("profile-runtime")
        end
    end)
end
