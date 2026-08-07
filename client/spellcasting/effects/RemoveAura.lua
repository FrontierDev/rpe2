local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Client.Spellcasting = Addon.Client.Spellcasting or {}

local Spellcasting = Addon.Client.Spellcasting
local AuraManager = Spellcasting.AuraManager or {}
local Debug = Addon.Debug or {}

local function sameAuraRef(left, right)
    local leftRef = type(left) == "string" and left or nil
    local rightRef = type(right) == "string" and right or nil
    if not leftRef or leftRef == "" or not rightRef or rightRef == "" then
        return false
    end
    if leftRef == rightRef then
        return true
    end

    local leftDatasetId, leftId = string.match(leftRef, "^([^:]+):(.+)$")
    local rightDatasetId, rightId = string.match(rightRef, "^([^:]+):(.+)$")
    if leftDatasetId and rightDatasetId then
        return false
    end

    leftId = leftId or leftRef
    rightId = rightId or rightRef
    return leftId == rightId
end

AuraManager:RegisterEffect({
    type = "remove_aura",
    Execute = function(self, context, effect)
        local targetUnit = type(context) == "table" and context.targetUnit or nil
        if type(targetUnit) ~= "table" or type(AuraManager.RemoveAuraStacksFromContext) ~= "function" then
            return false, nil
        end

        local currentAura = type(context) == "table" and context.aura or nil
        local auraRef = effect and effect.auraRef or nil
        if type(auraRef) ~= "string" or auraRef == "" then
            auraRef = currentAura and currentAura.auraRef or nil
        end
        local resolvedAuraRef = auraRef
        if currentAura and type(AuraManager.ResolveAuraDefinition) == "function" then
            local _, _, qualifiedAuraRef = AuraManager:ResolveAuraDefinition(auraRef, {
                dataset = type(context) == "table" and context.dataset or nil,
                datasetId = type(context) == "table" and (context.datasetId or currentAura.datasetId) or currentAura.datasetId,
                sourceDatasetId = type(context) == "table" and context.sourceDatasetId or nil,
                spellDatasetId = type(context) == "table" and context.spellDatasetId or nil,
            })
            if type(qualifiedAuraRef) == "string" and qualifiedAuraRef ~= "" then
                resolvedAuraRef = qualifiedAuraRef
            end
        end
        local casterEventId = nil
        local targetEventId = tonumber(targetUnit.eventID) or 0
        if currentAura and sameAuraRef(resolvedAuraRef, currentAura.auraRef) then
            auraRef = currentAura.auraRef
            casterEventId = tonumber(currentAura.casterEventId) or nil
            targetEventId = tonumber(currentAura.targetEventId) or targetEventId
        end

        local removedStacks = math.max(1, math.floor(tonumber(effect and effect.stacks) or 1))
        if type(Debug.Internal) == "function" then
            local auraEvent = type(context) == "table" and context.auraEvent or nil
            Debug.Internal(
                "Aura remove_aura effect: event=%s effectIndex=%s authoredAuraRef=%s resolvedAuraRef=%s casterEventId=%s targetEventId=%s remove=%s.",
                tostring(auraEvent and auraEvent.combatEventId or "unknown"),
                tostring(type(context) == "table" and context.effectIndex or "unknown"),
                tostring(effect and effect.auraRef or "nil"),
                tostring(auraRef or "nil"),
                tostring(casterEventId or "nil"),
                tostring(targetEventId or 0),
                tostring(removedStacks)
            )
        end
        local applied, auraEntry = AuraManager:RemoveAuraStacksFromContext(
            Addon.Client,
            context,
            auraRef,
            removedStacks,
            casterEventId,
            targetEventId
        )
        if type(Debug.Internal) == "function" then
            Debug.Internal(
                "Aura remove_aura effect result: resolvedAuraRef=%s casterEventId=%s targetEventId=%s applied=%s stacksAfter=%s.",
                tostring(auraRef or "nil"),
                tostring(casterEventId or "nil"),
                tostring(targetEventId or 0),
                tostring(applied == true),
                tostring(auraEntry and auraEntry.stacks or "nil")
            )
        end
        return applied, {
            effectType = "remove_aura",
            applied = applied,
            auraEntry = auraEntry,
            stacks = removedStacks,
            auraRef = auraRef,
            casterEventId = casterEventId,
            targetEventId = targetEventId,
        }
    end,
})

return true
