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
