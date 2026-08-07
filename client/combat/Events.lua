local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Client.Combat = Addon.Client.Combat or {}
Addon.Client.Spellcasting = Addon.Client.Spellcasting or {}
Addon.Utils = Addon.Utils or {}

local Combat = Addon.Client.Combat
local Spellcasting = Addon.Client.Spellcasting or {}
local Lookup = Addon.Utils.Lookup or {}

local EVENT_DEFINITIONS = {
    {
        id = "on_auto_attack_hit",
        label = "On Auto Attack Hit",
        recipientRole = "caster",
    },
    {
        id = "on_auto_attack_taken",
        label = "On Auto Attack Taken",
        recipientRole = "target",
    },
    {
        id = "on_melee_hit",
        label = "On Melee Hit",
        recipientRole = "caster",
    },
    {
        id = "on_melee_taken",
        label = "On Melee Taken",
        recipientRole = "target",
    },
    {
        id = "on_ranged_hit",
        label = "On Ranged Hit",
        recipientRole = "caster",
    },
    {
        id = "on_ranged_taken",
        label = "On Ranged Taken",
        recipientRole = "target",
    },
    {
        id = "on_spell_hit",
        label = "On Spell Hit",
        recipientRole = "caster",
    },
    {
        id = "on_spell_taken",
        label = "On Spell Taken",
        recipientRole = "target",
    },
    {
        id = "on_heal",
        label = "On Heal",
        recipientRole = "caster",
    },
    {
        id = "on_heal_taken",
        label = "On Heal Taken",
        recipientRole = "target",
    },
    {
        id = "on_critical_hit",
        label = "On Critical Hit",
        recipientRole = "caster",
    },
    {
        id = "on_critical_hit_taken",
        label = "On Critical Hit Taken",
        recipientRole = "target",
    },
    {
        id = "on_critical_heal",
        label = "On Critical Heal",
        recipientRole = "caster",
    },
    {
        id = "on_critical_heal_taken",
        label = "On Critical Heal Taken",
        recipientRole = "target",
    },
}

local EVENT_DEFINITIONS_BY_ID = {}
for index = 1, #EVENT_DEFINITIONS do
    local definition = EVENT_DEFINITIONS[index]
    EVENT_DEFINITIONS_BY_ID[definition.id] = definition
end

local Events = {}

local function normalizeId(value)
    local text = tostring(value or "")
    text = string.gsub(text, "^%s+", "")
    text = string.gsub(text, "%s+$", "")
    text = string.lower(text)
    return text ~= "" and text or nil
end

local function cloneDefinition(definition)
    if type(definition) ~= "table" then
        return nil
    end

    return {
        id = definition.id,
        label = definition.label,
        recipientRole = definition.recipientRole,
    }
end

local function findUnit(eventState, eventId)
    if type(Lookup.FindEventUnitById) == "function" then
        return Lookup.FindEventUnitById(eventState and eventState.units, eventId)
    end

    return nil
end

local function appendTarget(targets, seen, value)
    local eventId = math.floor(tonumber(value) or 0)
    if eventId <= 0 or seen[eventId] then
        return
    end

    seen[eventId] = true
    targets[#targets + 1] = eventId
end

local function normalizeTargets(context)
    local targets = {}
    local seen = {}
    local values = type(context) == "table" and (context.targetEventIds or context.targetEventId) or nil

    if type(values) == "table" then
        for index = 1, #values do
            appendTarget(targets, seen, values[index])
        end
    else
        appendTarget(targets, seen, values)
    end

    if #targets == 0 and type(context) == "table" and type(context.targetUnit) == "table" then
        appendTarget(targets, seen, context.targetUnit.eventID)
    end

    return targets
end

function Events:GetItems()
    local items = {}
    for index = 1, #EVENT_DEFINITIONS do
        items[index] = cloneDefinition(EVENT_DEFINITIONS[index])
    end

    return items
end

function Events:IsValid(id)
    return self:GetDefinition(id) ~= nil
end

function Events:GetDefinition(id)
    local eventId = normalizeId(id)
    return eventId and EVENT_DEFINITIONS_BY_ID[eventId] or nil
end

function Events:Run(client, context)
    if type(context) ~= "table" then
        return false
    end
    if context.suppressCombatEvents == true then
        return false
    end

    local eventState = type(context) == "table" and context.eventState or nil
    local definition = self:GetDefinition(type(context) == "table" and (context.hookId or context.combatEventId) or nil)
    if type(client) ~= "table" or type(eventState) ~= "table" or type(definition) ~= "table" then
        return false
    end

    local sourceEventId = math.floor(tonumber(context.sourceEventId or context.casterEventId or (context.sourceUnit and context.sourceUnit.eventID)) or 0)
    local sourceUnit = type(context.sourceUnit) == "table" and context.sourceUnit or findUnit(eventState, sourceEventId)
    local targetEventIds = normalizeTargets(context)
    if type(sourceUnit) ~= "table" or #targetEventIds == 0 then
        return false
    end

    local auraManager = client.Spellcasting and client.Spellcasting.AuraManager or Spellcasting.AuraManager or nil
    if type(auraManager) ~= "table" or type(auraManager.HandleCombatEvent) ~= "function" then
        return false
    end

    local changed = false
    for index = 1, #targetEventIds do
        local targetEventId = targetEventIds[index]
        local targetUnit = findUnit(eventState, targetEventId)
        if type(targetUnit) == "table" then
            changed = auraManager:HandleCombatEvent(client, {
                eventState = eventState,
                sessionState = context.sessionState or (type(client.GetState) == "function" and client:GetState() or nil),
                combatEventId = definition.id,
                recipientEventId = definition.recipientRole == "target" and targetEventId or sourceEventId,
                eventSourceUnit = sourceUnit,
                eventOtherUnit = targetUnit,
                casterEventId = sourceEventId,
                targetEventId = targetEventId,
                actionContext = context.actionContext,
            }) or changed
        end
    end

    return changed
end

Combat.Events = Events

return Events
