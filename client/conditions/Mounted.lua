local _, Addon = ...

local Conditions = Addon.Client and Addon.Client.Conditions or {}

Conditions:RegisterCondition("mounted", {
    CreateDefaults = function()
        return Conditions:CreateConditionDefaults("mounted")
    end,
    Normalize = function(_, condition)
        return Conditions:NormalizeCondition(condition)
    end,
    Evaluate = function(context, condition)
        return {
            passed = Conditions:IsMounted(context, condition.unit),
            failureText = Conditions:ResolveConditionText(condition, context),
        }
    end,
    BuildTooltipLine = function(_, condition)
        return condition.unit == "target" and "Target must be mounted" or "Caster must be mounted"
    end,
})
