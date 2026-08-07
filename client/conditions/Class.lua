local _, Addon = ...

local Conditions = Addon.Client and Addon.Client.Conditions or {}

local function join(values)
    return table.concat(values, ", ")
end

Conditions:RegisterCondition("class", {
    CreateDefaults = function()
        return Conditions:CreateConditionDefaults("class")
    end,
    Normalize = function(_, condition)
        return Conditions:NormalizeCondition(condition)
    end,
    Evaluate = function(context, condition)
        local classRef = Conditions:GetProfileClassRef(context)
        local passed = false
        for index = 1, #(condition.classRefs or {}) do
            if tostring(condition.classRefs[index]) == tostring(classRef) then
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
        local labels = {}
        for index = 1, #(condition.classRefs or {}) do
            labels[#labels + 1] = Conditions:ResolveEntryName(condition.classRefs[index], "classes")
        end
        return ("Requires class: %s"):format(join(labels))
    end,
})
