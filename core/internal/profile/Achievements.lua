local _, Addon = ...

Addon.Internal = Addon.Internal or {}
Addon.Internal.Profile = Addon.Internal.Profile or {}

local Profile = Addon.Internal.Profile
local Database = Addon.Internal.Database or {}

function Profile.ListAchievementStates()
    if Database.ListProfileAchievementStates then
        return Database.ListProfileAchievementStates()
    end

    return {}
end

function Profile.GetAchievementState(achievementRef)
    if Database.GetProfileAchievementState then
        return Database.GetProfileAchievementState(achievementRef)
    end

    return nil
end

function Profile.SetAchievementState(achievementRef, state)
    if Database.SetProfileAchievementState then
        return Database.SetProfileAchievementState(achievementRef, state)
    end

    return nil
end

function Profile.ClearAchievementState(achievementRef)
    if Database.ClearProfileAchievementState then
        return Database.ClearProfileAchievementState(achievementRef)
    end

    return false
end

function Profile.GetAchievementRewardState(achievementRef)
    if Database.GetProfileAchievementRewardState then
        return Database.GetProfileAchievementRewardState(achievementRef)
    end

    local state = Profile.GetAchievementState(achievementRef)
    return type(state) == "table" and state.rewardState or nil
end

function Profile.SetAchievementRewardState(achievementRef, rewardState)
    if Database.SetProfileAchievementRewardState then
        return Database.SetProfileAchievementRewardState(achievementRef, rewardState)
    end

    local state = Profile.GetAchievementState(achievementRef) or {
        criteria = {},
        completedAt = nil,
    }
    state.rewardState = rewardState
    return Profile.SetAchievementState(achievementRef, state)
end

function Profile.ClearAchievementRewardState(achievementRef)
    if Database.ClearProfileAchievementRewardState then
        return Database.ClearProfileAchievementRewardState(achievementRef)
    end

    local state = Profile.GetAchievementState(achievementRef)
    if type(state) ~= "table" or state.rewardState == nil then
        return false
    end

    state.rewardState = nil
    Profile.SetAchievementState(achievementRef, state)
    return true
end
