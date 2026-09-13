local _, Addon = ...

Addon.Client = Addon.Client or {}

local Client = Addon.Client
local Profile = Addon.Internal and Addon.Internal.Profile or {}
local Ruleset = Addon.Internal and Addon.Internal.Ruleset or {}

local function positiveInteger(value, fallback)
    local numeric = tonumber(value)
    if not numeric or numeric ~= numeric or numeric == math.huge or numeric == -math.huge then
        return fallback or 0
    end
    return math.max(0, math.floor(numeric))
end

function Client:GetConfiguredEventCurrencyRewardAmount(ruleKey, fallback)
    local activeRuleset = type(Ruleset.GetActiveRuleset) == "function" and Ruleset.GetActiveRuleset() or nil
    local value = type(Ruleset.GetRulesetRuleValueByKey) == "function"
        and Ruleset.GetRulesetRuleValueByKey(activeRuleset, "event", ruleKey, tostring(fallback))
        or fallback
    return positiveInteger(value, fallback)
end

function Client:GrantConfiguredEventCurrency(currencyKey, ruleKey, fallback, eventState, grantKey)
    local amount = self:GetConfiguredEventCurrencyRewardAmount(ruleKey, fallback)
    if amount <= 0 or type(Profile.AddCurrencyAmount) ~= "function" then
        return false
    end

    local grants = type(eventState) == "table" and eventState.currencyRewardGrants or nil
    if type(eventState) == "table" then
        grants = type(grants) == "table" and grants or {}
        eventState.currencyRewardGrants = grants
        if grants[grantKey] == true then
            return false
        end
        grants[grantKey] = true
    end

    local result = Profile.AddCurrencyAmount(currencyKey, amount)
    return result ~= nil
end

local baseHandleEventEnd = Client.HandleEventEnd
if type(baseHandleEventEnd) == "function" then
    function Client:HandleEventEnd(...)
        local endingState = self.EventState
        local arguments = select(1, ...)
        local distributeEndRewards = type(arguments) ~= "table" or arguments[4] ~= false
        local result = baseHandleEventEnd(self, ...)
        if result == true and distributeEndRewards and type(endingState) == "table" then
            self:GrantConfiguredEventCurrency("justice", "event_end_justice_currency", 100, endingState, "event-end-justice")
        end
        return result
    end
end
