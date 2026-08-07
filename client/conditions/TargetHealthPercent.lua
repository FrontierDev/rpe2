local _, Addon = ...

local Conditions = Addon.Client and Addon.Client.Conditions or {}

local function buildText(condition, subject)
    local minimumValue = tonumber(condition.minimumValue)
    local maximumValue = tonumber(condition.maximumValue)
    if minimumValue ~= nil and maximumValue ~= nil then
        return ("%s health between %d%% and %d%%"):format(subject, minimumValue, maximumValue)
    end
    if minimumValue ~= nil then
        return ("%s health above %d%%"):format(subject, minimumValue)
    end
    return ("%s health below %d%%"):format(subject, math.floor(maximumValue or 0))
end

Conditions:RegisterCondition("target_health_percent", {
    CreateDefaults = function()
        return Conditions:CreateConditionDefaults("target_health_percent")
    end,
    Normalize = function(_, condition)
        return Conditions:NormalizeCondition(condition)
    end,
    Evaluate = function(context, condition)
        local percent = Conditions:GetUnitHealthPercent(context and context.targetUnit)
        local minimumValue = tonumber(condition.minimumValue)
        local maximumValue = tonumber(condition.maximumValue)
        local passed = percent ~= nil
            and (minimumValue == nil or percent >= minimumValue)
            and (maximumValue == nil or percent <= maximumValue)
        return {
            passed = passed,
            failureText = Conditions:ResolveConditionText(condition, context),
        }
    end,
    BuildTooltipLine = function(_, condition)
        return buildText(condition, "Target")
    end,
})
