local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Client.UI = Addon.Client.UI or {}
Addon.Client.UI.Tooltips = Addon.Client.UI.Tooltips or {}

local UI = Addon.UI or {}
local Tooltips = Addon.Client.UI.Tooltips
local Profile = Addon.Internal and Addon.Internal.Profile or {}
local Registry = Addon.Internal and Addon.Internal.Registry or {}

local AchievementTooltip = Tooltips.Achievement or {}
Tooltips.Achievement = AchievementTooltip

local function ensureString(value, fallback)
    if value == nil or value == "" then
        return fallback or ""
    end

    return tostring(value)
end

local function trimText(value)
    return ensureString(value):gsub("^%s+", ""):gsub("%s+$", "")
end

local function resolveColor(token, fallback)
    if type(UI.ResolveColor) == "function" then
        return UI.ResolveColor(nil, token, fallback) or fallback
    end

    return fallback
end

local function isFiniteTimestamp(value)
    local timestamp = tonumber(value)
    if not timestamp
        or timestamp ~= timestamp
        or timestamp == math.huge
        or timestamp == -math.huge
        or timestamp < 0
    then
        return nil
    end

    return timestamp
end

local function formatDate(value)
    local timestamp = isFiniteTimestamp(value)
    if not timestamp then
        return nil
    end

    if type(date) == "function" then
        return date("%Y-%m-%d", timestamp)
    end

    return tostring(math.floor(timestamp))
end

local function getContext(detail)
    local context = type(detail) == "table" and detail or {}
    local achievement = context.achievement or context.achievementDefinition
    local achievementRef = trimText(context.achievementRef)

    if type(achievement) ~= "table" and achievementRef ~= "" and type(Registry.ResolveAchievementReference) == "function" then
        local callOk, _, resolvedAchievement = pcall(
            Registry.ResolveAchievementReference,
            Registry,
            achievementRef
        )
        if callOk then
            achievement = resolvedAchievement
        end
    end

    if type(achievement) ~= "table" then
        achievement = {}
    end

    local state = context.state or context.achievementState or context.profileAchievementState
    if type(state) ~= "table" then
        state = nil
    end

    local rewards = context.rewardDefinitions or context.rewards or achievement.rewards
    if type(rewards) ~= "table" then
        rewards = {}
    end

    return context, achievement, achievementRef, state, rewards
end

local function getAchievementName(context, achievement, achievementRef)
    local name = trimText(achievement.name)
    if name == "" then
        name = trimText(context.name)
    end
    if name == "" then
        name = trimText(achievement.id)
    end

    if name == "" and achievementRef ~= "" and type(Registry.ResolveAchievementName) == "function" then
        local callOk, resolvedName = pcall(Registry.ResolveAchievementName, Registry, achievementRef)
        if callOk then
            name = trimText(resolvedName)
        end
    end

    return name ~= "" and name or (achievementRef ~= "" and achievementRef or "Unknown Achievement")
end

local function buildCriterionLines(achievement)
    local criteria = achievement.criteria
    if type(criteria) ~= "table" or #criteria == 0 then
        return {}
    end

    local lines = {}
    local criterionCount = 0

    local criterionColor = resolveColor("text.secondary", { r = 0.8, g = 0.82, b = 0.88, a = 1 })
    for index = 1, #criteria do
        local criterion = criteria[index]
        if type(criterion) == "table" then
            criterionCount = criterionCount + 1
            local label = trimText(criterion.description)
            if label == "" then
                label = trimText(criterion.id)
            end
            if label == "" then
                label = trimText(criterion.trigger)
            end
            if label == "" then
                label = ("Criterion %d"):format(index)
            end

            lines[#lines + 1] = {
                text = "• " .. label,
                r = criterionColor.r or 0.8,
                g = criterionColor.g or 0.82,
                b = criterionColor.b or 0.88,
                wrap = true,
            }
        end
    end

    return criterionCount > 0 and lines or {}
end

local function getRewardAmountText(amount)
    local numeric = tonumber(amount)
    if numeric and numeric == numeric and numeric ~= math.huge and numeric ~= -math.huge then
        return tostring(math.max(0, math.floor(numeric)))
    end

    local configured = trimText(amount)
    return configured ~= "" and configured or "unknown"
end

local function resolveItemReward(itemRef)
    local normalizedRef = trimText(itemRef)
    if normalizedRef == "" then
        return "Unknown item", nil
    end

    if type(Registry.ResolveItemReference) == "function" then
        local callOk, _, item = pcall(Registry.ResolveItemReference, Registry, normalizedRef)
        if callOk and type(item) == "table" then
            local name = trimText(item.name)
            if name ~= "" then
                return name, trimText(item.icon)
            end
        end
    end

    return normalizedRef .. " (unavailable)", nil
end

local function resolveCurrencyReward(currencyRef)
    local normalizedRef = trimText(currencyRef)
    if normalizedRef == "" then
        return "Unknown currency", nil
    end

    local currencyKey = normalizedRef
    if type(Profile.NormalizeCurrencyKey) == "function" then
        local callOk, normalized = pcall(Profile.NormalizeCurrencyKey, normalizedRef)
        if callOk and trimText(normalized) ~= "" then
            currencyKey = trimText(normalized)
        end
    end

    if type(Profile.ResolveCurrencyDefinition) == "function" then
        local callOk, definition = pcall(Profile.ResolveCurrencyDefinition, currencyKey)
        if callOk and type(definition) == "table" then
            local name = trimText(definition.name)
            if name ~= "" then
                return name, trimText(definition.icon)
            end
        end
    end

    return currencyKey .. " (unavailable)", nil
end

local function getRewardDisplayName(reward)
    local rewardType = type(reward) == "table" and string.lower(trimText(reward.type)) or ""
    local rewardRef = type(reward) == "table" and trimText(reward.ref) or ""
    if rewardType == "item" then
        return resolveItemReward(rewardRef)
    elseif rewardType == "currency" then
        return resolveCurrencyReward(rewardRef)
    end

    local fallback = rewardType ~= "" and ("Unsupported reward: " .. rewardType) or "Unsupported reward data"
    if rewardRef ~= "" then
        fallback = fallback .. " (" .. rewardRef .. ")"
    end
    return fallback, nil
end

local function buildRewardSummary(rewards)
    local summary = {}
    for index = 1, #rewards do
        local reward = rewards[index]
        local name = getRewardDisplayName(reward)
        local amount = getRewardAmountText(type(reward) == "table" and reward.amount or nil)
        summary[#summary + 1] = ("%s x%s"):format(name, amount)
    end

    return table.concat(summary, ", ")
end

function AchievementTooltip:GetRewardSummary(detail)
    local _, _, _, _, rewards = getContext(detail)
    local summary = buildRewardSummary(rewards)
    return summary ~= "" and ("Rewards: " .. summary) or ""
end

function AchievementTooltip:Build(detail, owner)
    local context, achievement, achievementRef, state = getContext(detail)
    local name = getAchievementName(context, achievement, achievementRef)
    local completedAt = state and state.completedAt or nil
    local completionTimestamp = isFiniteTimestamp(completedAt)
    local completionDate = formatDate(completionTimestamp)
    local isComplete = completionTimestamp ~= nil
    local titleColor = isComplete
        and resolveColor("warning", { r = 0.95, g = 0.9, b = 0.7, a = 1 })
        or resolveColor("text.primary", { r = 0.92, g = 0.94, b = 0.98, a = 1 })
    local secondary = resolveColor("text.secondary", { r = 0.8, g = 0.82, b = 0.88, a = 1 })
    local lines = {}
    local description = trimText(achievement.description)
    if description == "" then
        description = trimText(context.description)
    end
    if description ~= "" then
        lines[#lines + 1] = {
            text = description,
            r = secondary.r or 0.8,
            g = secondary.g or 0.82,
            b = secondary.b or 0.88,
            wrap = true,
        }
    end

    local criterionLines = buildCriterionLines(achievement)
    for index = 1, #criterionLines do
        lines[#lines + 1] = criterionLines[index]
    end

    if isComplete then
        lines[#lines + 1] = {
            text = completionDate and ("Completed: " .. completionDate) or "Completed",
            r = titleColor.r or 0.95,
            g = titleColor.g or 0.9,
            b = titleColor.b or 0.7,
            wrap = false,
        }
    else
        lines[#lines + 1] = {
            text = "In progress",
            r = secondary.r or 0.8,
            g = secondary.g or 0.82,
            b = secondary.b or 0.88,
            wrap = false,
        }
    end

    return {
        type = "game",
        title = name,
        titleColor = titleColor,
        lines = lines,
    }
end

return AchievementTooltip
