local _, Addon = ...

local Conditions = Addon.Client and Addon.Client.Conditions or {}

Conditions:RegisterCondition("caster_killed_this_turn", {
    CreateDefaults = function()
        return Conditions:CreateConditionDefaults("caster_killed_this_turn")
    end,
    Normalize = function(_, condition)
        return Conditions:NormalizeCondition(condition)
    end,
    Evaluate = function(context, condition)
        local caster = context and context.casterUnit
        local eventState = context and context.eventState
        local passed = Addon.Client
            and type(Addon.Client.WasUnitKilledThisTurn) == "function"
            and Addon.Client:WasUnitKilledThisTurn(eventState, caster and caster.eventID)
            or false
        return {
            passed = passed == true,
            failureText = Conditions:ResolveConditionText(condition, context),
        }
    end,
    BuildTooltipLine = function()
        return "Requires the caster to have been killed this turn"
    end,
})
