local _, Addon = ...

local Conditions = Addon.Client and Addon.Client.Conditions or {}

Conditions:RegisterCondition("caster_dead", {
    CreateDefaults = function()
        return Conditions:CreateConditionDefaults("caster_dead")
    end,
    Normalize = function(_, condition)
        return Conditions:NormalizeCondition(condition)
    end,
    Evaluate = function(context, condition)
        return {
            passed = Conditions:IsUnitDead(context and context.casterUnit),
            failureText = Conditions:ResolveConditionText(condition, context),
        }
    end,
    BuildTooltipLine = function()
        return "Requires the caster to be dead"
    end,
})
