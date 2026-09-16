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
    arguments[16] = normalized.logKind or ""
    arguments[17] = normalized.spellRef or ""
    return arguments
end


Client._combatLogTurnIdentityExtensionInstalled = true
return true
