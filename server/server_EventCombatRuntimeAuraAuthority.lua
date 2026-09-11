local _, Addon = ...

local Server = Addon.Server or {}
local Client = Addon.Client or {}
local Common = Addon.Utils and Addon.Utils.Common or {}
local Spellcasting = Client.Spellcasting or {}
local AuraManager = Spellcasting.AuraManager or (Addon.Internal and Addon.Internal.AuraManager) or nil

local function normalizeName(value)
    if type(Common.NormalizeName) == "function" then
        return Common.NormalizeName(value)
    end
    return tostring(value or "")
end

local function localPlayerName()
    if type(Spellcasting.GetLocalPlayerName) == "function" then
        return normalizeName(Spellcasting.GetLocalPlayerName())
    end
    return normalizeName(type(Common.GetPlayerName) == "function" and Common.GetPlayerName() or nil)
end

local function findEventUnit(eventState, eventId)
    local numericEventId = tonumber(eventId) or 0
    if numericEventId <= 0 then
        return nil
    end
    for index = 1, #(type(eventState) == "table" and eventState.units or {}) do
        local unit = eventState.units[index]
        if tonumber(unit and unit.eventID) == numericEventId then
            return unit
        end
    end
    return nil
end

local function expectedAuraOwner(eventState, casterUnit)
    if type(casterUnit) ~= "table" then
        return ""
    end
    if casterUnit.isPlayer == true then
        return normalizeName(casterUnit.ownerID or casterUnit.controllerID or casterUnit.name)
    end
    local controller = type(Spellcasting.ResolveControllerPlayerUnit) == "function"
        and Spellcasting.ResolveControllerPlayerUnit(eventState, casterUnit)
        or nil
    return normalizeName(controller and (controller.ownerID or controller.controllerID or controller.name) or nil)
end

local function findMatchingAuraEntry(bucket, previous)
    if type(bucket) ~= "table" or type(previous) ~= "table" then
        return nil
    end
    for _, entry in pairs(bucket.byKey or {}) do
        if type(entry) == "table"
            and tostring(entry.auraRef or "") == tostring(previous.auraRef or "")
            and tonumber(entry.casterEventId) == tonumber(previous.casterEventId)
            and tonumber(entry.targetEventId) == tonumber(previous.targetEventId)
        then
            return entry
        end
    end
    return nil
end

-- Aura duration/tick execution intentionally remains owner-executed. The base
-- AuraManager advances local copies on every client, but previously did not
-- publish the resulting duration/removal state. Only the aura owner/controller
-- now proposes the post-tick full state, so Server.EventRuntime becomes the
-- durable authority without causing every client to race the same update.
if type(AuraManager) == "table" and type(AuraManager.AdvanceAuraEntry) == "function" then
    local baseAdvanceAuraEntry = AuraManager.AdvanceAuraEntry
    function AuraManager:AdvanceAuraEntry(client, eventId, auraKey, targetTurnNumber, targetTickNumber)
        local eventState = type(client) == "table" and type(client.GetEventState) == "function" and client:GetEventState() or nil
        local bucket = type(self.GetEventAuraBucket) == "function" and self:GetEventAuraBucket(client, eventId, false) or nil
        local entry = type(bucket) == "table" and type(bucket.byKey) == "table" and bucket.byKey[auraKey] or nil
        local previous = type(entry) == "table" and {
            auraRef = entry.auraRef,
            casterEventId = tonumber(entry.casterEventId) or 0,
            targetEventId = tonumber(entry.targetEventId) or 0,
        } or nil
        local casterUnit = previous and findEventUnit(eventState, previous.casterEventId) or nil
        local expectedOwner = expectedAuraOwner(eventState, casterUnit)
        local localName = localPlayerName()
        local isOwner = expectedOwner ~= "" and expectedOwner == localName
        local isOrphanHost = expectedOwner == ""
            and type(Server.EventRuntime) == "table"
            and type(Server.EventState) == "table"
            and Server.EventState.active == true
            and tostring(Server.EventState.id or "") == tostring(eventId or "")

        local changed = baseAdvanceAuraEntry(self, client, eventId, auraKey, targetTurnNumber, targetTickNumber)
        if changed ~= true or type(previous) ~= "table" or (not isOwner and not isOrphanHost) then
            return changed
        end

        local sessionState = type(client.GetState) == "function" and client:GetState() or nil
        local currentEventState = type(client.GetEventState) == "function" and client:GetEventState() or nil
        if type(sessionState) ~= "table" or sessionState.active ~= true
            or type(currentEventState) ~= "table" or currentEventState.active ~= true
            or tostring(currentEventState.id or "") ~= tostring(eventId or "")
        then
            return changed
        end

        local currentBucket = type(self.GetEventAuraBucket) == "function" and self:GetEventAuraBucket(client, eventId, false) or nil
        local currentEntry = findMatchingAuraEntry(currentBucket, previous)
        local context = {
            sessionState = sessionState,
            eventState = currentEventState,
            immediate = true,
            pendingScope = "turn",
            scope = "turn",
        }

        if type(currentEntry) == "table" and (tonumber(currentEntry.stacks) or 0) > 0 and (tonumber(currentEntry.turnsRemaining) or 0) > 0 then
            self:QueueAuraApply(client, context, currentEntry, {
                stacks = currentEntry.stacks,
                turns = currentEntry.turnsRemaining,
                powerLevel = currentEntry.powerLevel,
                fullState = true,
            })
        else
            self:QueueAuraDispel(
                client,
                context,
                previous.auraRef,
                previous.casterEventId,
                previous.targetEventId
            )
        end

        return changed
    end
end

return AuraManager
