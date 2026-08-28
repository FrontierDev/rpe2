local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Client.UI = Addon.Client.UI or {}
Addon.Client.UI.Tooltips = Addon.Client.UI.Tooltips or {}

local UI = Addon.UI or {}
local Tooltips = Addon.Client.UI.Tooltips
local Profile = Addon.Internal and Addon.Internal.Profile or {}
local Registry = Addon.Internal and Addon.Internal.Registry or {}
local AchievementClass = Addon.Internal
    and Addon.Internal.Database
    and Addon.Internal.Database.Classes
    and Addon.Internal.Database.Classes.Achievement

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

local function normalizeProgress(value)
    local numeric = tonumber(value)
    if not numeric or numeric ~= numeric or numeric == math.huge or numeric == -math.huge then
        return 0
    end

    return math.max(0, math.floor(numeric))
end

local function normalizeGoal(value)
    local numeric = tonumber(value)
    if not numeric or numeric ~= numeric or numeric == math.huge or numeric == -math.huge then
        return 1
    end

    return math.max(1, math.floor(numeric))
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

local function formatTimestamp(value)
    local timestamp = isFiniteTimestamp(value)
    if not timestamp then
        return nil
    end

    if type(date) == "function" then
        return date("%Y-%m-%d %H:%M:%S", timestamp)
    end

    return tostring(math.floor(timestamp))
end

local function getContext(detail)
    local context = type(detail) == "table" and detail or {}
    local achievement = context.achievement or context.achievementDefinition
    local dataset = context.dataset
    local achievementRef = trimText(context.achievementRef)

    if type(achievement) ~= "table" and achievementRef ~= "" and type(Registry.ResolveAchievementReference) == "function" then
        local callOk, resolvedDataset, resolvedAchievement = pcall(
            Registry.ResolveAchievementReference,
            Registry,
            achievementRef
        )
        if callOk then
            dataset = resolvedDataset or dataset
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

    local criterionState = context.criterionState or context.criteriaState
    if type(criterionState) ~= "table" and state then
        criterionState = state.criteria
    end
    if type(criterionState) ~= "table" then
        criterionState = {}
    end

    local rewards = context.rewardDefinitions or context.rewards or achievement.rewards
    if type(rewards) ~= "table" then
        rewards = {}
    end

    local rewardState = context.rewardState or context.rewardsState
    if type(rewardState) ~= "table" and state then
        rewardState = state.rewardState
    end
    if type(rewardState) ~= "table" then
        rewardState = nil
    end

    return context, achievement, dataset, achievementRef, state, criterionState, rewards, rewardState
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

local function humanizeToken(value)
    local text = trimText(value):gsub("[-_]+", " ")
    if text == "" then
        return ""
    end

    return text:gsub("(%w)([%w']*)", function(first, rest)
        return string.upper(first) .. string.lower(rest)
    end)
end

local function getCategoryText(context, achievement)
    local category = trimText(context.category)
    if category == "" then
        category = trimText(achievement.category)
    end
    local categoryLabel = trimText(context.categoryLabel)
    local definitions = {}
    if type(AchievementClass) == "table" and type(AchievementClass.GetCategoryDefinitions) == "function" then
        local definitionsOk, resolvedDefinitions = pcall(AchievementClass.GetCategoryDefinitions)
        if definitionsOk then
            definitions = resolvedDefinitions
        end
    end
    if type(definitions) ~= "table" then
        definitions = {}
    end

    if categoryLabel == "" then
        for index = 1, #definitions do
            local definition = definitions[index]
            if type(definition) == "table" and string.lower(trimText(definition.key)) == string.lower(category) then
                categoryLabel = trimText(definition.label)
                break
            end
        end
    end

    if categoryLabel == "" then
        categoryLabel = humanizeToken(category)
    end
    if categoryLabel == "" then
        categoryLabel = "General"
    end

    local subcategory = trimText(context.subcategory)
    if subcategory == "" then
        subcategory = trimText(achievement.subcategory)
    end

    if subcategory ~= "" then
        return categoryLabel .. " — " .. subcategory
    end

    return categoryLabel
end

local function getCriterionCurrent(criterionState, criterionId, goal)
    local value = criterionState[criterionId]
    if value == true then
        return goal
    end

    return math.min(goal, normalizeProgress(value))
end

local function buildCriterionLines(achievement, criterionState)
    local criteria = achievement.criteria
    if type(criteria) ~= "table" or #criteria == 0 then
        return {}
    end

    local lines = {}
    local criterionCount = 0

    local success = resolveColor("success", { r = 0.35, g = 0.9, b = 0.45, a = 1 })
    local muted = resolveColor("text.muted", { r = 0.62, g = 0.66, b = 0.72, a = 1 })
    for index = 1, #criteria do
        local criterion = criteria[index]
        if type(criterion) == "table" then
            criterionCount = criterionCount + 1
            local criterionId = trimText(criterion.id)
            local label = trimText(criterion.description)
            if label == "" then
                label = criterionId
            end
            if label == "" then
                label = trimText(criterion.trigger)
            end
            if label == "" then
                label = ("Criterion %d"):format(index)
            end

            local goal = normalizeGoal(criterion.goal)
            local current = getCriterionCurrent(criterionState, criterionId, goal)
            local complete = current >= goal
            lines[#lines + 1] = {
                left = (complete and "[x] " or "[ ] ") .. label,
                right = ("%d / %d"):format(current, goal),
                r = complete and (success.r or 0.35) or (muted.r or 0.62),
                g = complete and (success.g or 0.9) or (muted.g or 0.66),
                b = complete and (success.b or 0.45) or (muted.b or 0.72),
                rightR = complete and (success.r or 0.35) or (muted.r or 0.62),
                rightG = complete and (success.g or 0.9) or (muted.g or 0.66),
                rightB = complete and (success.b or 0.45) or (muted.b or 0.72),
                wrap = false,
            }
        end
    end

    if criterionCount == 0 then
        return {}
    end

    table.insert(lines, 1, {
        text = "Criteria",
        r = 1,
        g = 1,
        b = 1,
        wrap = false,
    })

    return lines
end

local function getRewardEntryId(reward, index, usedIds)
    local baseId = type(reward) == "table" and trimText(reward.id) or ""
    if baseId == "" then
        baseId = ("reward_%d"):format(index)
    end

    local rewardId = baseId
    local suffix = 2
    while usedIds[rewardId] do
        rewardId = ("%s_%d"):format(baseId, suffix)
        suffix = suffix + 1
    end

    usedIds[rewardId] = true
    return rewardId
end

local function getRewardEntry(rewardState, rewardId)
    local entries = rewardState and rewardState.entries
    local entry = type(entries) == "table" and entries[rewardId] or nil
    return type(entry) == "table" and entry or nil
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

local function formatRewardEntryStatus(entry)
    local status = string.lower(trimText(entry and entry.status))
    if status == "complete" or status == "received" or status == "applied" then
        return "Received"
    elseif status == "failed" then
        return "Delivery failed"
    elseif status == "recovery-required" then
        return "Recovery required"
    elseif status == "in-progress" then
        return "Delivery in progress"
    elseif status == "pending" then
        return "Pending"
    elseif status == "unsupported" then
        return "Unsupported reward"
    end

    return ""
end

local function hasUnsupportedRewardData(rewards, rewardState)
    for index = 1, #rewards do
        local reward = rewards[index]
        local rewardType = type(reward) == "table" and string.lower(trimText(reward.type)) or ""
        if rewardType ~= "item" and rewardType ~= "currency" then
            return true
        end
    end

    if rewardState and rewardState.reason == "unsupported-reward-record" then
        return true
    end

    local entries = rewardState and rewardState.entries
    if type(entries) == "table" then
        for _, entry in pairs(entries) do
            if type(entry) == "table" and entry.status == "unsupported" then
                return true
            end
        end
    end

    return false
end

local function buildRewardStatus(rewards, state, rewardState)
    local completedAt = isFiniteTimestamp(state and state.completedAt)
    local hasRewards = #rewards > 0

    if not rewardState then
        if completedAt ~= nil and hasRewards then
            return "Rewards: Not retroactively granted (legacy completion)"
        end
        if hasUnsupportedRewardData(rewards, rewardState) and hasRewards then
            return "Rewards: Contains unsupported legacy reward data"
        end
        if hasRewards then
            return "Rewards: Pending"
        end
        return ""
    end

    local status = string.lower(trimText(rewardState.status))
    if status == "complete" then
        if hasUnsupportedRewardData(rewards, rewardState) then
            return "Rewards: Contains unsupported legacy reward data"
        end
        return "Rewards: Received"
    elseif status == "failed" then
        return "Rewards: Delivery failed"
    elseif status == "recovery-required" then
        return "Rewards: Recovery required"
    elseif status == "in-progress" then
        return "Rewards: Delivery in progress"
    elseif status == "pending" then
        return "Rewards: Pending"
    elseif status == "legacy-skipped" then
        return "Rewards: Not retroactively granted (legacy completion)"
    end

    if status ~= "" then
        return "Rewards: " .. status
    end

    return hasRewards and "Rewards: Pending" or ""
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

local function buildRewardLines(rewards, rewardState)
    local lines = {}
    local usedIds = {}
    for index = 1, #rewards do
        local reward = rewards[index]
        local rewardId = getRewardEntryId(reward, index, usedIds)
        local entry = getRewardEntry(rewardState, rewardId)
        local name, icon = getRewardDisplayName(reward)
        local displayName = icon and icon ~= "" and ("|T%s:14:14:0:0|t %s"):format(icon, name) or name
        local line = ("Reward: %s x%s"):format(displayName, getRewardAmountText(type(reward) == "table" and reward.amount or nil))
        local entryStatus = formatRewardEntryStatus(entry)
        if entryStatus ~= "" then
            line = line .. " — " .. entryStatus
        end

        local appliedAmount = tonumber(entry and entry.appliedAmount)
        if appliedAmount and appliedAmount == appliedAmount and appliedAmount >= 0 then
            line = ("%s (applied %d)"):format(line, math.floor(appliedAmount))
        end
        local appliedAt = formatTimestamp(entry and entry.appliedAt)
        if appliedAt then
            line = line .. " on " .. appliedAt
        end

        lines[#lines + 1] = {
            text = line,
            r = 0.8,
            g = 0.82,
            b = 0.88,
            wrap = true,
        }
    end

    return lines
end

local function buildRewardTimestampLines(rewardState)
    if not rewardState then
        return {}
    end

    local lines = {}
    local startedAt = formatTimestamp(rewardState.startedAt)
    local completedAt = formatTimestamp(rewardState.completedAt)
    local failedAt = formatTimestamp(rewardState.failedAt)
    if startedAt then
        lines[#lines + 1] = "Reward started: " .. startedAt
    end
    if completedAt then
        lines[#lines + 1] = "Rewards delivered: " .. completedAt
    end
    if failedAt then
        lines[#lines + 1] = "Reward delivery failed: " .. failedAt
    end

    return lines
end

local function getStatusColor(status)
    local normalized = string.lower(trimText(status))
    if normalized:find("received", 1, true) then
        return resolveColor("success", { r = 0.35, g = 0.9, b = 0.45, a = 1 })
    elseif normalized:find("failed", 1, true) or normalized:find("unsupported", 1, true) then
        return resolveColor("danger", { r = 0.95, g = 0.35, b = 0.35, a = 1 })
    end

    return resolveColor("warning", { r = 0.95, g = 0.9, b = 0.7, a = 1 })
end

function AchievementTooltip:GetRewardStatus(detail)
    local context, achievement, _, _, state, _, rewards, rewardState = getContext(detail)
    if trimText(context.rewardStatus) ~= "" then
        return trimText(context.rewardStatus)
    end

    return buildRewardStatus(rewards, state, rewardState)
end

function AchievementTooltip:Build(detail, owner)
    local context, achievement, _, achievementRef, state, criterionState, rewards, rewardState = getContext(detail)
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

    lines[#lines + 1] = {
        text = "Category: " .. getCategoryText(context, achievement),
        r = secondary.r or 0.8,
        g = secondary.g or 0.82,
        b = secondary.b or 0.88,
        wrap = true,
    }

    local criterionLines = buildCriterionLines(achievement, criterionState)
    for index = 1, #criterionLines do
        lines[#lines + 1] = criterionLines[index]
    end
    if #criterionLines == 0 then
        lines[#lines + 1] = {
            text = "No criteria configured.",
            r = secondary.r or 0.8,
            g = secondary.g or 0.82,
            b = secondary.b or 0.88,
            wrap = true,
        }
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
            text = "Incomplete",
            r = secondary.r or 0.8,
            g = secondary.g or 0.82,
            b = secondary.b or 0.88,
            wrap = false,
        }
    end

    if #rewards > 0 then
        lines[#lines + 1] = {
            text = "Rewards",
            r = 1,
            g = 1,
            b = 1,
            wrap = false,
        }
        local rewardLines = buildRewardLines(rewards, rewardState)
        for index = 1, #rewardLines do
            lines[#lines + 1] = rewardLines[index]
        end

        local rewardStatus = self:GetRewardStatus(context)
        if rewardStatus ~= "" then
            local statusColor = getStatusColor(rewardStatus)
            lines[#lines + 1] = {
                text = rewardStatus,
                r = statusColor.r or 0.95,
                g = statusColor.g or 0.9,
                b = statusColor.b or 0.7,
                wrap = true,
            }
        end

        local rewardTimestampLines = buildRewardTimestampLines(rewardState)
        for index = 1, #rewardTimestampLines do
            lines[#lines + 1] = {
                text = rewardTimestampLines[index],
                r = secondary.r or 0.8,
                g = secondary.g or 0.82,
                b = secondary.b or 0.88,
                wrap = true,
            }
        end
    end

    return {
        type = "game",
        title = name,
        titleColor = titleColor,
        lines = lines,
    }
end

return AchievementTooltip
