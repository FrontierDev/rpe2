local _, Addon = ...

local Combat = Addon.Client and Addon.Client.Combat or nil
local Spellcasting = Addon.Client and Addon.Client.Spellcasting or nil
if not Combat then
    return
end

function Combat:ExecuteRemoveAuraEffect(context, effect, component)
    local target = type(context) == "table" and (context.targetUnit or context.target) or nil
    local auraManager = Spellcasting and Spellcasting.AuraManager or nil
    if type(target) ~= "table" then
        return false, {
            effectType = "remove_aura",
            resultType = "invalid",
            amount = 0,
        }
    end

    local match = string.lower(tostring(effect and effect.match or "aura"))
    if not auraManager
        or type(auraManager.RemoveAuraStacksFromContext) ~= "function"
        or (match == "tag" and type(auraManager.RemoveAurasByTagFromContext) ~= "function")
    then
        return false, {
            effectType = "remove_aura",
            resultType = "invalid",
            amount = 0,
        }
    end

    local applied, auraEntry, removedEntries, removedCount
    local removedStacks = math.max(1, math.floor(tonumber(effect and effect.stacks) or 1))
    if match == "tag" then
        applied, removedEntries, removedCount = auraManager:RemoveAurasByTagFromContext(
            Addon.Client,
            context,
            effect and effect.tag or nil,
            effect and effect.maxAuras or nil
        )
        auraEntry = removedEntries and removedEntries[1] or nil
    else
        applied, auraEntry = auraManager:RemoveAuraStacksFromContext(
            Addon.Client,
            context,
            effect and effect.auraRef or nil,
            removedStacks,
            nil,
            tonumber(target.eventID) or 0
        )
        removedCount = applied and 1 or 0
    end
    return applied, {
        effectType = "remove_aura",
        resultType = applied and "applied" or "noop",
        applied = applied,
        auraEntry = auraEntry,
        auraEntries = removedEntries,
        removedCount = removedCount or 0,
        stacks = match == "tag" and nil or removedStacks,
        component = component,
    }
end

local RemoveAuraEffect = Combat:CreateEffectContract({
    type = "remove_aura",
    label = "Remove Aura",
    description = "Removes aura stacks from a target or removes auras by tag.",
    defaults = {
        type = "remove_aura",
        match = "aura",
        auraRef = nil,
        stacks = 1,
        tag = nil,
        maxAuras = nil,
        targetEvents = {},
    },
    fields = {
        "match",
        "auraRef",
        "stacks",
        "tag",
        "maxAuras",
        "targetEvents",
    },
    Execute = function(self, context, effect, component)
        return Combat:ExecuteRemoveAuraEffect(context, effect or self.defaults, component)
    end,
})

local RemoveAuraByTagEffect = Combat:CreateEffectContract({
    type = "remove_aura_by_tag",
    label = "Remove Aura by Tag",
    description = "Removes all aura effects with any of the selected tags from a target.",
    defaults = {
        type = "remove_aura_by_tag",
        tags = {},
        maxAuras = nil,
        targetEvents = {},
    },
    fields = {
        "tags",
        "maxAuras",
        "targetEvents",
    },
    Execute = function(self, context, effect, component)
        local target = type(context) == "table" and (context.targetUnit or context.target) or nil
        local auraManager = Spellcasting and Spellcasting.AuraManager or nil
        if type(target) ~= "table"
            or not auraManager
            or type(auraManager.RemoveAurasByTagsFromContext) ~= "function"
        then
            return false, {
                effectType = "remove_aura_by_tag",
                resultType = "invalid",
                amount = 0,
            }
        end

        local applied, removedEntries, removedCount = auraManager:RemoveAurasByTagsFromContext(
            Addon.Client,
            context,
            effect and (effect.tags or effect.tag) or nil,
            effect and effect.maxAuras or nil
        )
        return applied, {
            effectType = "remove_aura_by_tag",
            resultType = applied and "applied" or "noop",
            applied = applied,
            auraEntries = removedEntries,
            removedCount = removedCount or 0,
            component = component,
        }
    end,
})

return RemoveAuraEffect
