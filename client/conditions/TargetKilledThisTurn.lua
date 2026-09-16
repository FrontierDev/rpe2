local _, Addon = ...

local Conditions = Addon.Client and Addon.Client.Conditions or {}

Conditions:RegisterCondition("target_killed_this_turn", {
    CreateDefaults = function()
        return Conditions:CreateConditionDefaults("target_killed_this_turn")
    end,
    Normalize = function(_, condition)
        return Conditions:NormalizeCondition(condition)
    end,
    Evaluate = function(context, condition)
        local target = context and context.targetUnit
        local eventState = context and context.eventState
        local passed = Addon.Client
            and type(Addon.Client.WasUnitKilledThisTurn) == "function"
            and Addon.Client:WasUnitKilledThisTurn(eventState, target and target.eventID)
            or false
        return {
            passed = passed == true,
            failureText = Conditions:ResolveConditionText(condition, context),
        }
    end,
    BuildTooltipLine = function()
        return "Requires the target to have been killed this turn"
    end,
})
