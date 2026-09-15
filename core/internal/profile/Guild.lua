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

local function normalizeReference(value)
    local reference = tostring(value or "")
    reference = reference:gsub("^%s+", ""):gsub("%s+$", "")
    return reference
end

local function normalizeRoleId(value)
    return normalizeReference(value)
end

local function normalizeRequisitionId(value)
    return normalizeReference(value)
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
        appendUniqueGuildRealm(realms, identity and identity.legacyRealmName)
        appendUniqueGuildRealm(realms, identity and identity.localRealmName)
    end

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

function Profile.MakeGuildRoleKey(guildSettingRef, roleId)
    local normalizedSettingRef = normalizeReference(guildSettingRef)
    local normalizedRoleId = normalizeRoleId(roleId)
    if normalizedSettingRef == "" or normalizedRoleId == "" then
        return nil
    end

    return normalizedSettingRef .. "#" .. normalizedRoleId
end

function Profile.ParseGuildRoleKey(roleKey)
    local normalized = normalizeReference(roleKey)
    local guildSettingRef, roleId = normalized:match("^(.+)#([^#]+)$")
    guildSettingRef = normalizeReference(guildSettingRef)
    roleId = normalizeRoleId(roleId)
    if guildSettingRef == "" or roleId == "" then
        return nil, nil
    end

    return guildSettingRef, roleId
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
    local settingRef = normalizeReference(value.settingRef or value.rankRef)
    local status = tostring(value.status or "")
    if status ~= "in-progress" and status ~= "failed" then
        status = "failed"
    end

    return {
        status = status,
        date = dateKey,
        settingRef = settingRef,
        rankRef = settingRef,
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

local function resolveLegacyRole(guildSettingRef)
    local Registry = Addon.Internal and Addon.Internal.Registry or nil
    if not Registry or type(Registry.ResolveGuildSettingReference) ~= "function" then
        return nil
    end

    local ok, _, setting = pcall(Registry.ResolveGuildSettingReference, Registry, guildSettingRef)
    if not ok or type(setting) ~= "table" then
        return nil
    end

    local roles = type(setting.roles) == "table" and setting.roles or {}
    if #roles ~= 1 then
        return nil
    end

    local roleId = normalizeRoleId(roles[1] and roles[1].id)
    if roleId == "" then
        return nil
    end

    return roleId
end

local function migrateBucketState(bucket)
    if type(bucket) ~= "table" then
        return false
    end

    local changed = false
    bucket.roles = type(bucket.roles) == "table" and bucket.roles or {}

    local legacyRankRef = normalizeReference(bucket.assignedRankRef)
    if legacyRankRef ~= "" then
        local roleId = resolveLegacyRole(legacyRankRef)
        if roleId then
            local roleKey = Profile.MakeGuildRoleKey(legacyRankRef, roleId)
            if roleKey and type(bucket.roles[roleKey]) ~= "table" then
                bucket.roles[roleKey] = {
                    guildSettingRef = legacyRankRef,
                    roleId = roleId,
                    assignedAt = bucket.assignedRankAt,
                    assignedBy = bucket.assignedRankBy,
                }
                changed = true
            end

            bucket.assignedRankRef = nil
            bucket.assignedRankAt = nil
            bucket.assignedRankBy = nil
            changed = true
        end
    end

    local legacyRewardRef = normalizeReference(bucket.dailyRewardRankRef)
    if normalizeReference(bucket.dailyRewardSettingRef) == "" and legacyRewardRef ~= "" then
        bucket.dailyRewardSettingRef = legacyRewardRef
        changed = true
    end
    if bucket.dailyRewardRankRef ~= nil then
        bucket.dailyRewardRankRef = nil
        changed = true
    end

    local transaction = bucket.dailyRewardTransaction
    if type(transaction) == "table" then
        local legacyTransactionRef = normalizeReference(transaction.rankRef)
        if normalizeReference(transaction.settingRef) == "" and legacyTransactionRef ~= "" then
            transaction.settingRef = legacyTransactionRef
            changed = true
        end
        if transaction.rankRef ~= nil then
            transaction.rankRef = nil
            changed = true
        end
    end

    return changed
end

function Profile.GetGuildBucket(guildKey)
    local normalizedGuildKey = normalizeGuildKey(guildKey)
    if normalizedGuildKey == "" then
        return nil
    end

    local state = Profile.GetGuildState()
    local byGuild = type(state) == "table" and state.byGuild or nil
    local bucket = type(byGuild) == "table" and byGuild[normalizedGuildKey] or nil
    if type(bucket) ~= "table" then
        return {}
    end

    if migrateBucketState(bucket) then
        state.byGuild[normalizedGuildKey] = bucket
        local persisted = Profile.SetGuildState(state)
        local persistedByGuild = type(persisted) == "table" and persisted.byGuild or nil
        bucket = type(persistedByGuild) == "table" and persistedByGuild[normalizedGuildKey] or bucket
    end

    return bucket
end

function Profile.GetAssignedGuildRoles(guildKey)
    local bucket = Profile.GetGuildBucket(guildKey)
    local roles = type(bucket) == "table" and bucket.roles or nil
    return type(roles) == "table" and cloneGuildValue(roles) or {}
end

function Profile.HasAssignedGuildRole(guildKey, guildSettingRef, roleId)
    local roleKey = Profile.MakeGuildRoleKey(guildSettingRef, roleId)
    if not roleKey then
        return false
    end

    local roles = Profile.GetAssignedGuildRoles(guildKey)
    return type(roles[roleKey]) == "table"
end

function Profile.AssignGuildRole(guildKey, guildSettingRef, roleId, metadata)
    local normalizedGuildKey = normalizeGuildKey(guildKey)
    local normalizedSettingRef = normalizeReference(guildSettingRef)
    local normalizedRoleId = normalizeRoleId(roleId)
    local roleKey = Profile.MakeGuildRoleKey(normalizedSettingRef, normalizedRoleId)
    if normalizedGuildKey == "" or not roleKey then
        return nil
    end

    local state = Profile.GetGuildState()
    state.byGuild = type(state.byGuild) == "table" and state.byGuild or {}
    local bucket = type(state.byGuild[normalizedGuildKey]) == "table"
        and state.byGuild[normalizedGuildKey]
        or {}
    migrateBucketState(bucket)
    bucket.roles = type(bucket.roles) == "table" and bucket.roles or {}

    local assignmentMetadata = type(metadata) == "table" and metadata or {}
    local existing = type(bucket.roles[roleKey]) == "table" and bucket.roles[roleKey] or {}
    bucket.roles[roleKey] = {
        guildSettingRef = normalizedSettingRef,
        roleId = normalizedRoleId,
        assignedAt = assignmentMetadata.assignedAt ~= nil
            and assignmentMetadata.assignedAt
            or assignmentMetadata.assignedRankAt ~= nil
            and assignmentMetadata.assignedRankAt
            or existing.assignedAt,
        assignedBy = assignmentMetadata.assignedBy ~= nil
            and assignmentMetadata.assignedBy
            or assignmentMetadata.assignedRankBy ~= nil
            and assignmentMetadata.assignedRankBy
            or existing.assignedBy,
    }

    state.byGuild[normalizedGuildKey] = bucket
    local persistedState = Profile.SetGuildState(state)
    local persistedByGuild = type(persistedState) == "table" and persistedState.byGuild or nil
    local persistedBucket = type(persistedByGuild) == "table" and persistedByGuild[normalizedGuildKey] or nil
    local persistedRoles = type(persistedBucket) == "table" and persistedBucket.roles or nil
    return type(persistedRoles) == "table" and cloneGuildValue(persistedRoles[roleKey]) or nil
end

function Profile.RemoveGuildRole(guildKey, guildSettingRef, roleId)
    local normalizedGuildKey = normalizeGuildKey(guildKey)
    local roleKey = Profile.MakeGuildRoleKey(guildSettingRef, roleId)
    if normalizedGuildKey == "" or not roleKey then
        return false
    end

    local state = Profile.GetGuildState()
    local byGuild = type(state) == "table" and state.byGuild or nil
    local bucket = type(byGuild) == "table" and byGuild[normalizedGuildKey] or nil
    if type(bucket) ~= "table" then
        return false
    end

    migrateBucketState(bucket)
    local roles = type(bucket.roles) == "table" and bucket.roles or nil
    if type(roles) ~= "table" or roles[roleKey] == nil then
        return false
    end

    roles[roleKey] = nil
    bucket.roles = roles
    local persistedState = Profile.SetGuildState(state)
    return type(persistedState) == "table"
end

function Profile.GetGuildRequisitionUsage(guildKey, guildSettingRef, requisitionId)
    local normalizedGuildKey = normalizeGuildKey(guildKey)
    local normalizedSettingRef = normalizeReference(guildSettingRef)
    local normalizedRequisitionId = normalizeRequisitionId(requisitionId)
    if normalizedGuildKey == "" or normalizedSettingRef == "" or normalizedRequisitionId == "" then
        return 0
    end

    local bucket = Profile.GetGuildBucket(normalizedGuildKey)
    local requisitions = type(bucket) == "table" and bucket.requisitions or nil
    local settingLedger = type(requisitions) == "table" and requisitions[normalizedSettingRef] or nil
    return normalizeRequisitionUsage(type(settingLedger) == "table" and settingLedger[normalizedRequisitionId] or 0)
end

function Profile.SetGuildRequisitionUsage(guildKey, guildSettingRef, requisitionId, usage)
    local normalizedGuildKey = normalizeGuildKey(guildKey)
    local normalizedSettingRef = normalizeReference(guildSettingRef)
    local normalizedRequisitionId = normalizeRequisitionId(requisitionId)
    if normalizedGuildKey == "" or normalizedSettingRef == "" or normalizedRequisitionId == "" then
        return nil
    end

    local normalizedUsage = normalizeRequisitionUsage(usage)
    local state = Profile.GetGuildState()
    state.byGuild = type(state.byGuild) == "table" and state.byGuild or {}
    local bucket = type(state.byGuild[normalizedGuildKey]) == "table"
        and state.byGuild[normalizedGuildKey]
        or {}
    bucket.requisitions = type(bucket.requisitions) == "table" and bucket.requisitions or {}
    bucket.requisitions[normalizedSettingRef] = type(bucket.requisitions[normalizedSettingRef]) == "table"
        and bucket.requisitions[normalizedSettingRef]
        or {}

    if normalizedUsage > 0 then
        bucket.requisitions[normalizedSettingRef][normalizedRequisitionId] = normalizedUsage
    else
        bucket.requisitions[normalizedSettingRef][normalizedRequisitionId] = nil
    end

    state.byGuild[normalizedGuildKey] = bucket
    local persistedState = Profile.SetGuildState(state)
    if type(persistedState) ~= "table" then
        return nil
    end

    return Profile.GetGuildRequisitionUsage(normalizedGuildKey, normalizedSettingRef, normalizedRequisitionId)
end

function Profile.IncrementGuildRequisitionUsage(guildKey, guildSettingRef, requisitionId)
    local currentUsage = Profile.GetGuildRequisitionUsage(guildKey, guildSettingRef, requisitionId)
    return Profile.SetGuildRequisitionUsage(guildKey, guildSettingRef, requisitionId, currentUsage + 1)
end

function Profile.GetDailyRewardClaim(guildKey)
    local normalizedGuildKey = normalizeGuildKey(guildKey)
    if normalizedGuildKey == "" then
        return nil, nil
    end

    local bucket = Profile.GetGuildBucket(normalizedGuildKey)
    local dateKey = normalizeDailyRewardDate(bucket and bucket.dailyRewardDate)
    local settingRef = normalizeReference(bucket and (bucket.dailyRewardSettingRef or bucket.dailyRewardRankRef))
    local claimSemantics = normalizeDailyRewardClaimSemantics(bucket and bucket.dailyRewardClaimSemantics)
    if dateKey == "" then
        return nil, settingRef ~= "" and settingRef or nil, claimSemantics
    end

    return dateKey, settingRef ~= "" and settingRef or nil, claimSemantics
end

function Profile.SetDailyRewardClaim(guildKey, dateKey, guildSettingRef, claimSemantics)
    local normalizedGuildKey = normalizeGuildKey(guildKey)
    local normalizedDateKey = normalizeDailyRewardDate(dateKey)
    local normalizedSettingRef = normalizeReference(guildSettingRef)
    if normalizedGuildKey == "" or normalizedDateKey == "" or normalizedSettingRef == "" then
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
    bucket.dailyRewardSettingRef = normalizedSettingRef
    bucket.dailyRewardRankRef = nil
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

function Profile.SetDailyRewardTransaction(guildKey, dateKey, guildSettingRef, status, reason)
    local normalizedGuildKey = normalizeGuildKey(guildKey)
    local normalizedDateKey = normalizeDailyRewardDate(dateKey)
    local normalizedSettingRef = normalizeReference(guildSettingRef)
    local normalizedStatus = tostring(status or "")
    if normalizedGuildKey == ""
        or normalizedDateKey == ""
        or normalizedSettingRef == ""
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
        settingRef = normalizedSettingRef,
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
