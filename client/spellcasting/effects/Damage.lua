local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Client.Spellcasting = Addon.Client.Spellcasting or {}

local Spellcasting = Addon.Client.Spellcasting
local AuraManager = Spellcasting.AuraManager or {}
local Common = Addon.Utils and Addon.Utils.Common or {}
local Debug = Addon.Debug or {}

local function getCombat()
    return Addon.Client and Addon.Client.Combat or nil
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

        return applied, result
    end,
})

return true
