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
        local minimumStacks = math.max(1, math.floor(tonumber(condition.minimumValue) or 1))
        local stacks = type(Conditions.GetUnitAuraStacks) == "function"
            and Conditions:GetUnitAuraStacks(context, unit, condition.auraRef)
            or (Conditions:UnitHasAura(context, unit, condition.auraRef) and 1 or 0)
        return {
            passed = stacks >= minimumStacks,
            failureText = Conditions:ResolveConditionText(condition, context),
        }
    end,
    BuildTooltipLine = function(_, condition)
        local subject = condition.unit == "target" and "Target" or "Caster"
        local auraName = Conditions:ResolveAuraName(condition.auraRef)
        local minimumStacks = math.max(1, math.floor(tonumber(condition.minimumValue) or 1))
        if minimumStacks > 1 then
            return ("%s must have at least %d stacks of %s"):format(subject, minimumStacks, auraName)
        end
        return ("%s must have %s"):format(subject, auraName)
    end,
})
