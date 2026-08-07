local _, Addon = ...

local Conditions = Addon.Client and Addon.Client.Conditions or {}

Conditions:RegisterCondition("target_creature_type", {
    CreateDefaults = function()
        return Conditions:CreateConditionDefaults("target_creature_type")
    end,
    Normalize = function(_, condition)
        return Conditions:NormalizeCondition(condition)
    end,
    Evaluate = function(context, condition)
        local targetUnit = context and context.targetUnit or nil
        local creatureType = string.lower(tostring(targetUnit and targetUnit.creatureType or ""))
        local passed = false
        for index = 1, #(condition.creatureTypes or {}) do
            if creatureType == tostring(condition.creatureTypes[index]) then
                passed = true
                break
            end
        end
        return {
            passed = passed,
            failureText = Conditions:ResolveConditionText(condition, context),
        }
    end,
    BuildTooltipLine = function(_, condition)
        return ("Target must be: %s"):format(table.concat(condition.creatureTypes or {}, ", "))
    end,
})
