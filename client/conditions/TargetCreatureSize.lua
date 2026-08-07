local _, Addon = ...

local Conditions = Addon.Client and Addon.Client.Conditions or {}

Conditions:RegisterCondition("target_creature_size", {
    CreateDefaults = function()
        return Conditions:CreateConditionDefaults("target_creature_size")
    end,
    Normalize = function(_, condition)
        return Conditions:NormalizeCondition(condition)
    end,
    Evaluate = function(context, condition)
        local targetUnit = context and context.targetUnit or nil
        local creatureSize = string.lower(tostring(targetUnit and targetUnit.creatureSize or ""))
        local passed = false
        for index = 1, #(condition.creatureSizes or {}) do
            if creatureSize == tostring(condition.creatureSizes[index]) then
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
        return ("Target size must be: %s"):format(table.concat(condition.creatureSizes or {}, ", "))
    end,
})
