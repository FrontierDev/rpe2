local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Internal = Addon.Internal or {}
Addon.Utils = Addon.Utils or {}

local Client = Addon.Client
local Comms = Addon.Internal.Comms or {}
local Operations = Comms.Operations or {}
local Common = Addon.Utils.Common or {}
local Event = Addon.Internal
    and Addon.Internal.Database
    and Addon.Internal.Database.Classes
    and Addon.Internal.Database.Classes.Event
    or nil

local NPC_SPEECH_OPCODE = Operations.GetOpcode and Operations:GetOpcode("NPC_SPEECH") or nil
local MAX_SPEECH_TEXT_LENGTH = 500
local MAX_SPEECH_ID_LENGTH = 96
local NPC_SPEECH_CHAT_COLOR = { r = 1, g = 1, b = 0x9F / 0xFF }
local generatedSpeechSequence = 0

local function normalizeName(value)
    if type(Common.NormalizeName) == "function" then
        return Common.NormalizeName(value)
    end
    return string.lower(tostring(value or ""))
end

local function getEventState()
    return type(Client.GetEventState) == "function" and Client:GetEventState() or Client.EventState
end

local function normalizeSpeakerEventId(value)
    local number = tonumber(value)
    if number == nil
        or number <= 0
        or number == math.huge
        or number == -math.huge
        or number ~= number
        or number ~= math.floor(number)
    then
        return nil
    end
    return number
end

local function normalizeSpeechId(value)
    if type(value) ~= "string" then
        return nil
    end

    local speechId = value:match("^%s*(.-)%s*$")
    if speechId == "" or #speechId > MAX_SPEECH_ID_LENGTH or not speechId:match("^[%w%._:%-]+$") then
        return nil
    end

    return speechId
end

local function normalizeSpeechText(value)
    if type(value) ~= "string" then
        return nil
    end

    local text = value:gsub("\r\n?", "\n")
    text = text:gsub("[%z\1-\8\11\12\14-\31\127]", "")
    text = text:match("^%s*(.-)%s*$") or ""
    if text == "" or #text > MAX_SPEECH_TEXT_LENGTH then
        return nil
    end

    return text
end

local function findSpeaker(eventState, speakerEventId)
    local wantedId = normalizeSpeakerEventId(speakerEventId)
    if not wantedId then
        return nil
    end

    for index = 1, #(eventState and eventState.units or {}) do
        local speaker = eventState.units[index]
        if tonumber(speaker and speaker.eventID) == wantedId then
            if speaker.isPlayer == true then
                return nil
            end
            return speaker
        end
    end

    return nil
end

local function normalizeSpeechEntry(entry, eventState)
    if type(entry) ~= "table" or type(eventState) ~= "table" or eventState.active ~= true or eventState.ending == true then
        return nil
    end

    local eventId = tostring(entry.eventId or "")
    local speechId = normalizeSpeechId(entry.speechId)
    local speakerEventId = normalizeSpeakerEventId(entry.speakerEventId)
    local text = normalizeSpeechText(entry.text)
    if eventId == ""
        or eventId ~= tostring(eventState.id or "")
        or not speechId
        or not speakerEventId
        or not text
        or not findSpeaker(eventState, speakerEventId)
    then
        return nil
    end

    return {
        eventId = eventId,
        speechId = speechId,
        speakerEventId = speakerEventId,
        text = text,
    }
end

local function buildSpeechArguments(entry)
    return {
        entry.eventId,
        entry.speechId,
        entry.speakerEventId,
        entry.text,
    }
end

local function resolveSendMetadata(opcode)
    local spellcasting = Client.Spellcasting
    if type(spellcasting) == "table" and type(spellcasting.BuildSendMetadata) == "function" then
        return spellcasting.BuildSendMetadata(opcode)
    end

    return {
        opcode = opcode,
        scope = "client",
    }
end

local function nextSpeechId()
    generatedSpeechSequence = generatedSpeechSequence + 1
    local timestamp = type(time) == "function" and time() or math.floor(os and os.time and os.time() or 0)
    return ("s%d-%d"):format(tonumber(timestamp) or 0, generatedSpeechSequence)
end

local function escapeChatMarkup(value)
    return tostring(value or ""):gsub("|", "||")
end

local function colorizeTeamName(name, eventState, speaker)
    local color = type(Event) == "table" and type(Event.GetTeamColor) == "function"
        and Event.GetTeamColor(eventState, tonumber(speaker and speaker.team) or 0)
        or nil
    if type(color) ~= "table" then
        return name
    end

    local red = math.floor(math.max(0, math.min(1, tonumber(color.r) or 1)) * 255 + 0.5)
    local green = math.floor(math.max(0, math.min(1, tonumber(color.g) or 1)) * 255 + 0.5)
    local blue = math.floor(math.max(0, math.min(1, tonumber(color.b) or 1)) * 255 + 0.5)
    return ("|cFF%02X%02X%02X%s|r"):format(red, green, blue, name)
end

local function buildNPCSpeechChatSpeakerLabel(entry, eventState)
    local speaker = findSpeaker(eventState, entry and entry.speakerEventId)
    local eventUnitId = math.max(1, math.floor(tonumber(speaker and speaker.eventID) or tonumber(entry and entry.speakerEventId) or 1))
    local name = colorizeTeamName(escapeChatMarkup(speaker and speaker.name or "Unknown NPC"), eventState, speaker)
    local marker = math.floor(tonumber(speaker and speaker.raidMarker) or 0)
    local inline = Addon.UI and Addon.UI.Inline or nil
    local markerIcon = marker >= 1 and marker <= 8 and type(inline) == "table" and type(inline.RaidMarker) == "function"
        and inline:RaidMarker(marker, 14, 14)
        or ""
    return (markerIcon ~= "" and (markerIcon .. " ") or "") .. name .. (" |cff9d9d9d[#%d]|r"):format(eventUnitId)
end

local function emitNPCSpeechChatMessage(entry, eventState)
    if not (DEFAULT_CHAT_FRAME and type(DEFAULT_CHAT_FRAME.AddMessage) == "function") then
        return false
    end

    local text = tostring(entry and entry.text or "")
    DEFAULT_CHAT_FRAME:AddMessage(
        ("%s: %s"):format(buildNPCSpeechChatSpeakerLabel(entry, eventState), escapeChatMarkup(text)),
        NPC_SPEECH_CHAT_COLOR.r,
        NPC_SPEECH_CHAT_COLOR.g,
        NPC_SPEECH_CHAT_COLOR.b
    )
    return true
end

function Client:ClearNPCSpeechState()
    self.NPCSpeechSeenIds = {}
    return true
end

function Client:QueueNPCSpeech(entry)
    local eventState = getEventState()
    local normalized = normalizeSpeechEntry(entry, eventState)
    if not normalized then
        return false
    end

    self.NPCSpeechSeenIds = self.NPCSpeechSeenIds or {}
    local duplicateKey = normalized.eventId .. "\31" .. normalized.speechId
    if self.NPCSpeechSeenIds[duplicateKey] then
        return false
    end

    local widgetNamespace = self.UI and self.UI.EventWidget or nil
    local widget = widgetNamespace and widgetNamespace.Get and widgetNamespace:Get() or nil
    if type(widget) ~= "table" or type(widget.QueueNPCSpeech) ~= "function" then
        return false
    end

    if widget:QueueNPCSpeech(normalized) ~= true then
        return false
    end

    self.NPCSpeechSeenIds[duplicateKey] = true
    emitNPCSpeechChatMessage(normalized, eventState)
    return true
end

function Client:HandleNPCSpeech(arguments, sender, distribution, target, message)
    local eventState = getEventState()
    if type(eventState) ~= "table" or eventState.active ~= true or eventState.ending == true then
        return false
    end

    local normalizedSender = normalizeName(sender)
    local localPlayerName = normalizeName(Common.GetPlayerName and Common.GetPlayerName() or "")
    local eventHostName = normalizeName(eventState.hostName)
    if normalizedSender == "" or eventHostName == "" or normalizedSender ~= eventHostName then
        return false
    end

    if (distribution == "PARTY" or distribution == "RAID")
        and localPlayerName ~= ""
        and normalizedSender == localPlayerName
    then
        -- Host-local emission queues before broadcast; suppress the transport echo.
        return true
    end

    if distribution ~= "PARTY" and distribution ~= "RAID" then
        return false
    end

    local normalized = normalizeSpeechEntry({
        eventId = arguments and arguments[1],
        speechId = arguments and arguments[2],
        speakerEventId = arguments and arguments[3],
        text = arguments and arguments[4],
    }, eventState)
    if not normalized then
        return false
    end

    return self:QueueNPCSpeech(normalized)
end

function Client:EmitNPCSpeech(speakerEventId, text, options)
    local eventState = getEventState()
    if type(eventState) ~= "table"
        or eventState.active ~= true
        or eventState.ending == true
        or type(self.IsLocalEventHost) ~= "function"
        or self:IsLocalEventHost(eventState) ~= true
    then
        return false
    end

    local speechId = nil
    if type(options) == "table" and options.speechId ~= nil then
        speechId = normalizeSpeechId(options.speechId)
        if not speechId then
            return false
        end
    else
        speechId = nextSpeechId()
    end
    local normalized = normalizeSpeechEntry({
        eventId = eventState.id,
        speechId = speechId,
        speakerEventId = speakerEventId,
        text = text,
    }, eventState)
    if not normalized then
        return false
    end

    local queuedLocally = self:QueueNPCSpeech(normalized)
    if not queuedLocally then
        return false
    end

    local distribution = Common.GetGroupType and Common.GetGroupType() or nil
    if (distribution ~= "PARTY" and distribution ~= "RAID")
        or type(Comms.SendMessage) ~= "function"
        or not NPC_SPEECH_OPCODE
    then
        return true
    end

    Comms:SendMessage(distribution, NPC_SPEECH_OPCODE, buildSpeechArguments(normalized), nil, resolveSendMetadata(NPC_SPEECH_OPCODE))
    return true
end

return true
