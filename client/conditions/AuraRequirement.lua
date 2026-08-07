local _, Addon = ...

local Conditions = Addon.Client and Addon.Client.Conditions or {}

Conditions:RegisterCondition("aura_requirement", {
    CreateDefaults = function()
        return Conditions:CreateConditionDefaults("aura_requirement")
    end,
    Normalize = function(_, condition)
        return Conditions:NormalizeCondition(condition)
    end,
    Evaluate = function(context, condition)
        local unit = Conditions:GetConditionUnit(context, condition.unit)
        return {
            passed = Conditions:UnitHasAura(context, unit, condition.auraRef),
            failureText = Conditions:ResolveConditionText(condition, context),
        }
    end,
    BuildTooltipLine = function(_, condition)
        local subject = condition.unit == "target" and "Target" or "Caster"
        return ("%s must have %s"):format(subject, Conditions:ResolveAuraName(condition.auraRef))
    end,
})
