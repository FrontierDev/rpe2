local _, Addon = ...

Addon.Client = Addon.Client or {}

local Client = Addon.Client

if Client._combatLogTurnIdentityExtensionInstalled == true
    or type(Client.NormalizeCombatLogEntry) ~= "function"
    or type(Client.BuildCombatLogArguments) ~= "function"
    or type(Client.HandleCombatLog) ~= "function"
then
    return true
end

local baseNormalizeCombatLogEntry = Client.NormalizeCombatLogEntry
local baseBuildCombatLogArguments = Client.BuildCombatLogArguments

local function normalizeTurnNumber(value)
    local turnNumber = math.floor(tonumber(value) or 0)
    return turnNumber > 0 and turnNumber or nil
end

local function resolveTurnNumber(client, eventId, explicitTurnNumber)
    local explicit = normalizeTurnNumber(explicitTurnNumber)
    if explicit then
        return explicit
    end

    local eventState = type(client) == "table"
        and type(client.GetEventState) == "function"
        and client:GetEventState()
        or (type(client) == "table" and client.EventState or nil)
    if type(eventState) ~= "table"
        or eventState.active ~= true
        or tostring(eventState.id or "") ~= tostring(eventId or "")
    then
        return nil
    end

    return normalizeTurnNumber(eventState.turnNumber)
end

function Client:NormalizeCombatLogEntry(entry)
    local normalized = baseNormalizeCombatLogEntry(self, entry)
    if type(normalized) ~= "table" then
        return nil
    end

    normalized.turnNumber = resolveTurnNumber(self, normalized.eventId, type(entry) == "table" and entry.turnNumber or nil)
    return normalized
end

function Client:BuildCombatLogArguments(entry)
    local normalized = self:NormalizeCombatLogEntry(entry)
    if type(normalized) ~= "table" then
        return nil
    end

    local arguments = baseBuildCombatLogArguments(self, normalized)
    if type(arguments) ~= "table" then
        return nil
    end

    arguments[15] = normalized.turnNumber or ""
    return arguments
end

function Client:HandleCombatLog(arguments, sender, distribution, target, message)
    local eventState = type(self.GetEventState) == "function" and self:GetEventState() or self.EventState
    if type(eventState) ~= "table" or eventState.active ~= true then
        return false
    end

    local normalized = self:NormalizeCombatLogEntry({
        eventId = arguments and arguments[1],
        entryType = arguments and arguments[2],
        casterDisplayName = arguments and arguments[3],
        targetDisplayName = arguments and arguments[4],
        targetCount = arguments and arguments[5],
        amountMin = arguments and arguments[6],
        amountMax = arguments and arguments[7],
        iconTexture = arguments and arguments[8],
        labelText = arguments and arguments[9],
        spellIconTexture = arguments and arguments[10],
        accentColor = arguments and arguments[11],
        casterColor = arguments and arguments[12],
        targetColor = arguments and arguments[13],
        detailText = arguments and arguments[14],
        turnNumber = arguments and arguments[15],
    })
    if type(normalized) ~= "table" or normalized.eventId ~= tostring(eventState.id or "") then
        return false
    end

    return type(self.QueueCombatLogEntry) == "function" and self:QueueCombatLogEntry(normalized) == true
end

Client._combatLogTurnIdentityExtensionInstalled = true
return true
