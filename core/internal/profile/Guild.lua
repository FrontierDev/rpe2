local _, Addon = ...

Addon.Internal = Addon.Internal or {}
Addon.Internal.Profile = Addon.Internal.Profile or {}

local Profile = Addon.Internal.Profile
local Database = Addon.Internal.Database or {}

local function normalizeGuildKey(value)
    local key = tostring(value or "")
    key = key:gsub("^%s+", ""):gsub("%s+$", "")
    return key
end

local function normalizeGuildRankRef(value)
    local reference = tostring(value or "")
    reference = reference:gsub("^%s+", ""):gsub("%s+$", "")
    return reference
end

function Profile.GetGuildState()
    if Database.GetProfileGuildState then
        return Database.GetProfileGuildState()
    end

    return { byGuild = {} }
end

function Profile.SetGuildState(state)
    if Database.SetProfileGuildState then
        return Database.SetProfileGuildState(state)
    end

    return nil
end

function Profile.GetGuildBucket(guildKey)
    local normalizedGuildKey = normalizeGuildKey(guildKey)
    if normalizedGuildKey == "" then
        return nil
    end

    local state = Profile.GetGuildState()
    local byGuild = type(state) == "table" and state.byGuild or nil
    local bucket = type(byGuild) == "table" and byGuild[normalizedGuildKey] or nil
    if type(bucket) == "table" then
        return bucket
    end

    return {}
end

function Profile.GetAssignedGuildRank(guildKey)
    local bucket = Profile.GetGuildBucket(guildKey)
    return bucket and bucket.assignedRankRef or nil
end

function Profile.SetAssignedGuildRank(guildKey, guildRankRef, metadata)
    local normalizedGuildKey = normalizeGuildKey(guildKey)
    local normalizedRankRef = normalizeGuildRankRef(guildRankRef)
    if normalizedGuildKey == "" or normalizedRankRef == "" then
        return nil
    end

    local state = Profile.GetGuildState()
    state.byGuild = type(state.byGuild) == "table" and state.byGuild or {}
    local bucket = type(state.byGuild[normalizedGuildKey]) == "table"
        and state.byGuild[normalizedGuildKey]
        or {}
    local assignmentMetadata = type(metadata) == "table" and metadata or {}

    bucket.assignedRankRef = normalizedRankRef
    bucket.assignedRankAt = assignmentMetadata.assignedRankAt
    bucket.assignedRankBy = assignmentMetadata.assignedRankBy
    state.byGuild[normalizedGuildKey] = bucket

    local persistedState = Profile.SetGuildState(state)
    local persistedByGuild = type(persistedState) == "table" and persistedState.byGuild or nil
    return type(persistedByGuild) == "table" and persistedByGuild[normalizedGuildKey] or nil
end

function Profile.ClearAssignedGuildRank(guildKey)
    local normalizedGuildKey = normalizeGuildKey(guildKey)
    if normalizedGuildKey == "" then
        return false
    end

    local state = Profile.GetGuildState()
    local byGuild = type(state) == "table" and state.byGuild or nil
    local bucket = type(byGuild) == "table" and byGuild[normalizedGuildKey] or nil
    if type(bucket) ~= "table" then
        return false
    end

    local hadAssignment = bucket.assignedRankRef ~= nil
        or bucket.assignedRankAt ~= nil
        or bucket.assignedRankBy ~= nil
    if not hadAssignment then
        return false
    end

    bucket.assignedRankRef = nil
    bucket.assignedRankAt = nil
    bucket.assignedRankBy = nil
    local persistedState = Profile.SetGuildState(state)
    return type(persistedState) == "table"
end
