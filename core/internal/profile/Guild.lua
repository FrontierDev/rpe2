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

local function normalizeGuildClubId(value)
    local clubId = normalizeGuildKey(value)
    if clubId == "" or clubId == "0" then
        return ""
    end

    return clubId
end

local function cloneGuildValue(value)
    if type(value) ~= "table" then
        return value
    end

    local copy = {}
    for key, nestedValue in pairs(value) do
        copy[key] = cloneGuildValue(nestedValue)
    end

    return copy
end

local function mergeMissingGuildFields(target, source)
    local changed = false

    for key, sourceValue in pairs(source) do
        local targetValue = target[key]
        if targetValue == nil then
            target[key] = cloneGuildValue(sourceValue)
            changed = true
        elseif type(targetValue) == "table" and type(sourceValue) == "table" then
            if mergeMissingGuildFields(targetValue, sourceValue) then
                changed = true
            end
        end
    end

    return changed
end

local function appendUniqueGuildKey(keys, value)
    local normalizedKey = normalizeGuildKey(value)
    if normalizedKey == "" then
        return
    end

    for index = 1, #keys do
        if keys[index] == normalizedKey then
            return
        end
    end

    keys[#keys + 1] = normalizedKey
end

local function appendUniqueGuildRealm(realms, value)
    local normalizedRealm = normalizeGuildKey(value)
    if normalizedRealm == "" then
        return
    end

    for index = 1, #realms do
        if realms[index] == normalizedRealm then
            return
        end
    end

    realms[#realms + 1] = normalizedRealm
end

local function getLegacyGuildKeys(identity)
    local keys = {}
    local guildName = normalizeGuildKey(identity and identity.guildName)
    if guildName == "" then
        return keys
    end

    local realmName = normalizeGuildKey(identity and identity.realmName)
    if realmName == "" then
        realmName = normalizeGuildKey(identity and identity.guildRealm)
    end
    if realmName == "" then
        realmName = normalizeGuildKey(identity and identity.realm)
    end

    local realms = {}
    if realmName ~= "" then
        appendUniqueGuildRealm(realms, realmName)
    else
        -- GetRealmName() is migration-only context. The pre-#35 client used
        -- it when GetGuildInfo() did not provide a same-realm guild realm, so
        -- probe that old qualified bucket without changing the current
        -- fallback key.
        appendUniqueGuildRealm(realms, identity and identity.legacyRealmName)
        appendUniqueGuildRealm(realms, identity and identity.localRealmName)
    end

    -- The realm-qualified form is newer than the original name-only form,
    -- so it wins when both legacy buckets contain conflicting fields.
    for index = 1, #realms do
        appendUniqueGuildKey(keys, guildName .. "-" .. realms[index])
    end
    appendUniqueGuildKey(keys, guildName)
    return keys
end

local function migrateLegacyGuildBucket(identity, guildKey)
    if type(identity) ~= "table" or identity.inGuild == false then
        return
    end

    local legacyKeys = getLegacyGuildKeys(identity)
    if #legacyKeys == 0 or guildKey == "" then
        return
    end

    local state = Profile.GetGuildState()
    local byGuild = type(state) == "table" and state.byGuild or nil
    if type(byGuild) ~= "table" then
        return
    end

    local targetBucket = byGuild[guildKey]
    if targetBucket ~= nil and type(targetBucket) ~= "table" then
        -- Never replace an existing non-table value while recovering legacy
        -- state. Keep the legacy bucket intact for compatibility recovery.
        return
    end

    local changed = false
    for index = 1, #legacyKeys do
        local legacyKey = legacyKeys[index]
        if legacyKey ~= guildKey then
            local sourceBucket = byGuild[legacyKey]
            if type(sourceBucket) == "table" then
                targetBucket = targetBucket or {}
                if mergeMissingGuildFields(targetBucket, sourceBucket) then
                    changed = true
                end
            end
        end
    end

    if not changed then
        return
    end

    byGuild[guildKey] = targetBucket
    Profile.SetGuildState(state)
end

-- C_Club.GetGuildClubId is the strongest stable guild identity exposed by
-- the target interface. Keep the name/realm and name-only forms as
-- deterministic compatibility fallbacks.
function Profile.GetGuildKey(identity)
    if type(identity) ~= "table" then
        return normalizeGuildKey(identity)
    end

    if identity.inGuild == false then
        return ""
    end

    local clubId = normalizeGuildClubId(identity.guildClubId)
    if clubId == "" then
        clubId = normalizeGuildClubId(identity.clubId)
    end

    if clubId ~= "" then
        local guildKey = "guild:" .. clubId
        migrateLegacyGuildBucket(identity, guildKey)
        return guildKey
    end

    local guildName = normalizeGuildKey(identity.guildName)
    if guildName == "" then
        return ""
    end

    local realmName = normalizeGuildKey(identity.realmName)
    if realmName == "" then
        realmName = normalizeGuildKey(identity.guildRealm)
    end
    if realmName == "" then
        realmName = normalizeGuildKey(identity.realm)
    end

    local guildKey = guildName
    if realmName ~= "" then
        guildKey = guildName .. "-" .. realmName
    end

    migrateLegacyGuildBucket(identity, guildKey)
    return guildKey
end

local function normalizeGuildRankRef(value)
    local reference = tostring(value or "")
    reference = reference:gsub("^%s+", ""):gsub("%s+$", "")
    return reference
end

local function normalizeRequisitionId(value)
    local requisitionId = tostring(value or "")
    requisitionId = requisitionId:gsub("^%s+", ""):gsub("%s+$", "")
    return requisitionId
end

local function normalizeRequisitionUsage(value)
    local usage = tonumber(value)
    if not usage or usage ~= usage or usage == math.huge or usage == -math.huge then
        return 0
    end

    return math.max(0, math.floor(usage))
end

local function normalizeDailyRewardDate(value)
    local dateKey = tostring(value or "")
    if dateKey:match("^%d%d%d%d%-%d%d%-%d%d$") then
        return dateKey
    end

    return ""
end

local DAILY_REWARD_CLAIM_SEMANTICS_RESET_CYCLE = "reset-cycle"
Profile.DAILY_REWARD_CLAIM_SEMANTICS_RESET_CYCLE = DAILY_REWARD_CLAIM_SEMANTICS_RESET_CYCLE

local function normalizeDailyRewardClaimSemantics(value)
    if value == DAILY_REWARD_CLAIM_SEMANTICS_RESET_CYCLE then
        return DAILY_REWARD_CLAIM_SEMANTICS_RESET_CYCLE
    end

    return nil
end

local function normalizeDailyRewardTransaction(value)
    if type(value) ~= "table" then
        return nil
    end

    local dateKey = normalizeDailyRewardDate(value.date)
    local rankRef = normalizeGuildRankRef(value.rankRef)
    local status = tostring(value.status or "")
    if status ~= "in-progress" and status ~= "failed" then
        status = "failed"
    end

    return {
        status = status,
        date = dateKey,
        rankRef = rankRef,
        reason = tostring(value.reason or ""),
    }
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

function Profile.GetGuildRequisitionUsage(guildKey, guildRankRef, requisitionId)
    local normalizedGuildKey = normalizeGuildKey(guildKey)
    local normalizedRankRef = normalizeGuildRankRef(guildRankRef)
    local normalizedRequisitionId = normalizeRequisitionId(requisitionId)
    if normalizedGuildKey == "" or normalizedRankRef == "" or normalizedRequisitionId == "" then
        return 0
    end

    local bucket = Profile.GetGuildBucket(normalizedGuildKey)
    local requisitions = type(bucket) == "table" and bucket.requisitions or nil
    local rankLedger = type(requisitions) == "table" and requisitions[normalizedRankRef] or nil
    return normalizeRequisitionUsage(type(rankLedger) == "table" and rankLedger[normalizedRequisitionId] or 0)
end

function Profile.SetGuildRequisitionUsage(guildKey, guildRankRef, requisitionId, usage)
    local normalizedGuildKey = normalizeGuildKey(guildKey)
    local normalizedRankRef = normalizeGuildRankRef(guildRankRef)
    local normalizedRequisitionId = normalizeRequisitionId(requisitionId)
    if normalizedGuildKey == "" or normalizedRankRef == "" or normalizedRequisitionId == "" then
        return nil
    end

    local normalizedUsage = normalizeRequisitionUsage(usage)
    local state = Profile.GetGuildState()
    state.byGuild = type(state.byGuild) == "table" and state.byGuild or {}
    local bucket = type(state.byGuild[normalizedGuildKey]) == "table"
        and state.byGuild[normalizedGuildKey]
        or {}
    bucket.requisitions = type(bucket.requisitions) == "table" and bucket.requisitions or {}
    bucket.requisitions[normalizedRankRef] = type(bucket.requisitions[normalizedRankRef]) == "table"
        and bucket.requisitions[normalizedRankRef]
        or {}

    if normalizedUsage > 0 then
        bucket.requisitions[normalizedRankRef][normalizedRequisitionId] = normalizedUsage
    else
        bucket.requisitions[normalizedRankRef][normalizedRequisitionId] = nil
    end

    state.byGuild[normalizedGuildKey] = bucket
    local persistedState = Profile.SetGuildState(state)
    if type(persistedState) ~= "table" then
        return nil
    end

    return Profile.GetGuildRequisitionUsage(normalizedGuildKey, normalizedRankRef, normalizedRequisitionId)
end

function Profile.IncrementGuildRequisitionUsage(guildKey, guildRankRef, requisitionId)
    local currentUsage = Profile.GetGuildRequisitionUsage(guildKey, guildRankRef, requisitionId)
    return Profile.SetGuildRequisitionUsage(guildKey, guildRankRef, requisitionId, currentUsage + 1)
end

function Profile.GetDailyRewardClaim(guildKey)
    local normalizedGuildKey = normalizeGuildKey(guildKey)
    if normalizedGuildKey == "" then
        return nil, nil
    end

    local bucket = Profile.GetGuildBucket(normalizedGuildKey)
    local dateKey = normalizeDailyRewardDate(bucket and bucket.dailyRewardDate)
    local rankRef = normalizeGuildRankRef(bucket and bucket.dailyRewardRankRef)
    local claimSemantics = normalizeDailyRewardClaimSemantics(
        bucket and bucket.dailyRewardClaimSemantics
    )
    if dateKey == "" then
        return nil, rankRef ~= "" and rankRef or nil, claimSemantics
    end

    return dateKey, rankRef ~= "" and rankRef or nil, claimSemantics
end

function Profile.SetDailyRewardClaim(guildKey, dateKey, guildRankRef, claimSemantics)
    local normalizedGuildKey = normalizeGuildKey(guildKey)
    local normalizedDateKey = normalizeDailyRewardDate(dateKey)
    local normalizedRankRef = normalizeGuildRankRef(guildRankRef)
    if normalizedGuildKey == "" or normalizedDateKey == "" or normalizedRankRef == "" then
        return nil
    end

    local state = Profile.GetGuildState()
    state.byGuild = type(state.byGuild) == "table" and state.byGuild or {}
    local bucket = type(state.byGuild[normalizedGuildKey]) == "table"
        and state.byGuild[normalizedGuildKey]
        or {}
    local normalizedClaimSemantics = claimSemantics == nil
        and normalizeDailyRewardClaimSemantics(bucket.dailyRewardClaimSemantics)
        or normalizeDailyRewardClaimSemantics(claimSemantics)
    bucket.dailyRewardDate = normalizedDateKey
    bucket.dailyRewardRankRef = normalizedRankRef
    bucket.dailyRewardClaimSemantics = normalizedClaimSemantics
    state.byGuild[normalizedGuildKey] = bucket

    local persistedState = Profile.SetGuildState(state)
    local persistedByGuild = type(persistedState) == "table" and persistedState.byGuild or nil
    return type(persistedByGuild) == "table" and persistedByGuild[normalizedGuildKey] or nil
end

function Profile.GetDailyRewardTransaction(guildKey)
    local normalizedGuildKey = normalizeGuildKey(guildKey)
    if normalizedGuildKey == "" then
        return nil
    end

    local bucket = Profile.GetGuildBucket(normalizedGuildKey)
    return normalizeDailyRewardTransaction(bucket and bucket.dailyRewardTransaction)
end

function Profile.SetDailyRewardTransaction(guildKey, dateKey, guildRankRef, status, reason)
    local normalizedGuildKey = normalizeGuildKey(guildKey)
    local normalizedDateKey = normalizeDailyRewardDate(dateKey)
    local normalizedRankRef = normalizeGuildRankRef(guildRankRef)
    local normalizedStatus = tostring(status or "")
    if normalizedGuildKey == ""
        or normalizedDateKey == ""
        or normalizedRankRef == ""
        or (normalizedStatus ~= "in-progress" and normalizedStatus ~= "failed") then
        return nil
    end

    local state = Profile.GetGuildState()
    state.byGuild = type(state.byGuild) == "table" and state.byGuild or {}
    local bucket = type(state.byGuild[normalizedGuildKey]) == "table"
        and state.byGuild[normalizedGuildKey]
        or {}
    bucket.dailyRewardTransaction = {
        status = normalizedStatus,
        date = normalizedDateKey,
        rankRef = normalizedRankRef,
        reason = tostring(reason or ""),
    }
    state.byGuild[normalizedGuildKey] = bucket

    local persistedState = Profile.SetGuildState(state)
    if type(persistedState) ~= "table" then
        return nil
    end

    return Profile.GetDailyRewardTransaction(normalizedGuildKey)
end

function Profile.ClearDailyRewardTransaction(guildKey)
    local normalizedGuildKey = normalizeGuildKey(guildKey)
    if normalizedGuildKey == "" then
        return false
    end

    local state = Profile.GetGuildState()
    local byGuild = type(state) == "table" and state.byGuild or nil
    local bucket = type(byGuild) == "table" and byGuild[normalizedGuildKey] or nil
    if type(bucket) ~= "table" or bucket.dailyRewardTransaction == nil then
        return true
    end

    bucket.dailyRewardTransaction = nil
    local persistedState = Profile.SetGuildState(state)
    return type(persistedState) == "table"
end
