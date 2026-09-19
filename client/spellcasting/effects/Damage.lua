local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Client.Spellcasting = Addon.Client.Spellcasting or {}

local Spellcasting = Addon.Client.Spellcasting
local AuraManager = Spellcasting.AuraManager or {}
local Common = Addon.Utils and Addon.Utils.Common or {}
local Lookup = Addon.Utils and Addon.Utils.Lookup or {}
local Debug = Addon.Debug or {}

local function getCombat()
    return Addon.Client and Addon.Client.Combat or nil
end

local function resolveDamageSchoolRef(Combat, effect)
    for index = 1, #(effect and effect.damageSchoolRefs or {}) do
        local candidate = tostring(effect.damageSchoolRefs[index] or "")
        if candidate ~= "" then
            if type(Combat.ResolveDamageSchoolReference) ~= "function" then
                return candidate
            end

            local _, damageSchool = Combat:ResolveDamageSchoolReference(candidate)
            if type(damageSchool) == "table" then
                return candidate
            end
        end
    end

    return nil
end

local function roundValue(value)
    local numericValue = tonumber(value) or 0
    if type(Common.Round) == "function" then
        return Common.Round(numericValue)
    end
    return math.floor(numericValue + 0.5)
end

local function buildPeriodicThreatUpdate(Combat, context, effect, targetUnit, appliedDelta)
    if type(effect) ~= "table" or effect.threatCoefficient == nil then
        return nil
    end
    if type(targetUnit) ~= "table" or targetUnit.isPlayer == true then
        return nil
    end

    local casterUnit = type(context) == "table" and context.casterUnit or nil
    local sourceEventId = math.floor(tonumber(casterUnit and casterUnit.eventID) or 0)
    local targetEventId = math.floor(tonumber(targetUnit.eventID) or 0)
    local appliedDamage = math.max(0, -(tonumber(appliedDelta) or 0))
    local threatCoefficient = math.max(0, tonumber(effect.threatCoefficient) or 0)
    if sourceEventId <= 0 or targetEventId <= 0 or appliedDamage <= 0 or threatCoefficient <= 0 then
        return nil
    end

    local threatAmount = math.max(0, roundValue(appliedDamage * threatCoefficient))
    local threatGeneratedStatRef = type(Combat.GetCombatRule) == "function"
        and tostring(Combat:GetCombatRule("threat_generated_stat", "") or "")
        or ""
    if threatAmount > 0 and threatGeneratedStatRef ~= "" then
        local threatGeneratedPercent = tonumber(
            type(Lookup.GetStatValue) == "function"
                and Lookup.GetStatValue(casterUnit, threatGeneratedStatRef, 0)
                or 0
        ) or 0
        threatAmount = math.max(0, roundValue(threatAmount * (1 + (threatGeneratedPercent / 100))))
    end
    if threatAmount <= 0 then
        return nil
    end

    targetUnit.threatTable = type(targetUnit.threatTable) == "table" and targetUnit.threatTable or {}
    targetUnit.threatTable[sourceEventId] = (tonumber(targetUnit.threatTable[sourceEventId]) or 0) + threatAmount

    return {
        targetEventId = targetEventId,
        sourceEventId = sourceEventId,
        amount = threatAmount,
    }
end

AuraManager:RegisterEffect({
    type = "damage",
    Execute = function(self, context, effect)
        local targetUnit = type(context) == "table" and context.targetUnit or nil
        local healthResourceRef = type(context) == "table" and context.healthResourceRef or nil
        local Combat = getCombat()
        if type(targetUnit) == "table" and (type(healthResourceRef) ~= "string" or healthResourceRef == "") then
            local resources = targetUnit.resources
            for index = 1, #(resources or {}) do
                local entry = resources[index]
                if type(entry) == "table" and type(entry.resourceRef) == "string" and entry.resourceRef ~= "" then
                    healthResourceRef = entry.resourceRef
                    break
                end
            end
        end

        if type(targetUnit) ~= "table" or type(healthResourceRef) ~= "string" or healthResourceRef == "" or not Combat then
            if Debug.AuraTracing == true and type(Debug.Info) == "function" then
                Debug.Info(
                    "Aura damage skipped: target=%s healthResourceRef=%s combat=%s.",
                    tostring(targetUnit and targetUnit.name or "unknown"),
                    tostring(healthResourceRef or "nil"),
                    tostring(Combat ~= nil)
                )
            end
            return false, nil
        end

        local amount = AuraManager:ResolveEffectAmount(context, effect, "baseDamage")
        amount = math.max(0, type(Common.Round) == "function" and Common.Round(amount) or math.floor(amount + 0.5))
        if amount <= 0 then
            return false, {
                effectType = "damage",
                resourceDeltas = {},
            }
        end

        local applied, resourceEntry, appliedDelta = Combat:ApplyResourceDelta(targetUnit, healthResourceRef, -amount, context)
        if not applied and Debug.AuraTracing == true and type(Debug.Info) == "function" then
            Debug.Info(
                "Aura damage applied no delta: target=%s healthResourceRef=%s amount=%d resourceFound=%s.",
                tostring(targetUnit and targetUnit.name or "unknown"),
                tostring(healthResourceRef or "nil"),
                amount,
                tostring(resourceEntry ~= nil)
            )
        end
        local result = {
            effectType = "damage",
            amount = amount,
            applied = applied,
            appliedDelta = appliedDelta,
            resourceEntry = resourceEntry,
            hitType = "ability",
            damageSchoolRef = resolveDamageSchoolRef(Combat, effect),
            resourceDeltas = {},
        }

        if applied and resourceEntry then
            result.resourceDeltas[1] = {
                resourceRef = healthResourceRef,
                delta = appliedDelta,
                currentValue = tonumber(resourceEntry.currentValue) or 0,
                maxValue = tonumber(resourceEntry.maxValue) or 0,
            }
        end

        local threatUpdate = applied and buildPeriodicThreatUpdate(Combat, context, effect, targetUnit, appliedDelta) or nil
        if type(threatUpdate) == "table" then
            result.threatGenerated = threatUpdate.amount
            result.threatUpdate = threatUpdate
        end

        return applied, result
    end,
})

return true
