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

local function normalizeProgressionEntryId(value)
    return normalizeGuildRankRef(value)
end

local function normalizeProgressionState(value)
    local source = type(value) == "table" and value or {}
    local state = {}

    -- Preserve future progression fields while normalizing the persisted maps
    -- used by the current runtime. Definition validation belongs to Guild.lua;
    -- Profile only keeps rank-scoped state well-shaped and durable.
    for key, entry in pairs(source) do
        state[key] = entry
    end

    state.slots = {}
    if type(source.slots) == "table" then
        for slot, entryId in pairs(source.slots) do
            local numericSlot = tonumber(slot)
            local normalizedEntryId = normalizeProgressionEntryId(entryId)
            if numericSlot and numericSlot == math.floor(numericSlot)
                and numericSlot >= 1 and normalizedEntryId ~= "" then
                state.slots[numericSlot] = normalizedEntryId
            end
        end
    end

    state.unlocked = {}
    if type(source.unlocked) == "table" then
        for entryId, unlocked in pairs(source.unlocked) do
            local normalizedEntryId = normalizeProgressionEntryId(entryId)
            if normalizedEntryId ~= "" and unlocked == true then
                state.unlocked[normalizedEntryId] = true
            end
        end
    end

    state.selectedSpells = {}
    if type(source.selectedSpells) == "table" then
        for entryId, spellRef in pairs(source.selectedSpells) do
            local normalizedEntryId = normalizeProgressionEntryId(entryId)
            local normalizedSpellRef = normalizeGuildRankRef(spellRef)
            if normalizedEntryId ~= "" and normalizedSpellRef ~= "" then
                state.selectedSpells[normalizedEntryId] = normalizedSpellRef
            end
        end
    end

    return state
end

local function getGuildProgressionState(state, guildKey, guildRankRef)
    local byGuild = type(state) == "table" and state.byGuild or nil
    local bucket = type(byGuild) == "table" and byGuild[guildKey] or nil
    local progression = type(bucket) == "table" and bucket.progression or nil
    local rankState = type(progression) == "table" and progression[guildRankRef] or nil
    return normalizeProgressionState(rankState)
end

local function updateGuildProgressionState(guildKey, guildRankRef, callback)
    local normalizedGuildKey = normalizeGuildKey(guildKey)
    local normalizedRankRef = normalizeGuildRankRef(guildRankRef)
    if normalizedGuildKey == "" or normalizedRankRef == "" or type(callback) ~= "function" then
        return nil
    end

    local state = Profile.GetGuildState()
    state.byGuild = type(state.byGuild) == "table" and state.byGuild or {}
    local bucket = type(state.byGuild[normalizedGuildKey]) == "table"
        and state.byGuild[normalizedGuildKey]
        or {}
    bucket.progression = type(bucket.progression) == "table" and bucket.progression or {}
    local progressionState = normalizeProgressionState(bucket.progression[normalizedRankRef])
    local updated = callback(progressionState)
    if updated == false then
        return nil
    end

    bucket.progression[normalizedRankRef] = normalizeProgressionState(progressionState)
    state.byGuild[normalizedGuildKey] = bucket
    return Profile.SetGuildState(state)
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

function Profile.GetGuildProgression(guildKey, guildRankRef)
    local normalizedGuildKey = normalizeGuildKey(guildKey)
    local normalizedRankRef = normalizeGuildRankRef(guildRankRef)
    if normalizedGuildKey == "" or normalizedRankRef == "" then
        return nil
    end

    return getGuildProgressionState(Profile.GetGuildState(), normalizedGuildKey, normalizedRankRef)
end

function Profile.SetGuildProgression(guildKey, guildRankRef, progressionState)
    local normalizedGuildKey = normalizeGuildKey(guildKey)
    local normalizedRankRef = normalizeGuildRankRef(guildRankRef)
    if normalizedGuildKey == "" or normalizedRankRef == "" or type(progressionState) ~= "table" then
        return nil
    end

    return updateGuildProgressionState(normalizedGuildKey, normalizedRankRef, function(state)
        for key, value in pairs(normalizeProgressionState(progressionState)) do
            state[key] = value
        end
        return true
    end)
end

function Profile.SetGuildProgressionSlot(guildKey, guildRankRef, slotIndex, entryId)
    local normalizedSlot = tonumber(slotIndex)
    local normalizedEntryId = normalizeProgressionEntryId(entryId)
    if not normalizedSlot or normalizedSlot ~= math.floor(normalizedSlot)
        or normalizedSlot < 1 or normalizedEntryId == "" then
        return nil
    end

    return updateGuildProgressionState(guildKey, guildRankRef, function(state)
        state.slots[normalizedSlot] = normalizedEntryId
        return true
    end)
end

function Profile.SetGuildProgressionEntryUnlocked(guildKey, guildRankRef, entryId, unlocked)
    local normalizedEntryId = normalizeProgressionEntryId(entryId)
    if normalizedEntryId == "" then
        return nil
    end

    return updateGuildProgressionState(guildKey, guildRankRef, function(state)
        if unlocked == true then
            state.unlocked[normalizedEntryId] = true
        else
            state.unlocked[normalizedEntryId] = nil
        end
        return true
    end)
end

function Profile.SetGuildProgressionSelectedSpell(guildKey, guildRankRef, entryId, spellRef)
    local normalizedEntryId = normalizeProgressionEntryId(entryId)
    local normalizedSpellRef = normalizeGuildRankRef(spellRef)
    if normalizedEntryId == "" or normalizedSpellRef == "" then
        return nil
    end

    return updateGuildProgressionState(guildKey, guildRankRef, function(state)
        state.selectedSpells[normalizedEntryId] = normalizedSpellRef
        return true
    end)
end

function Profile.ClearGuildProgressionSelectedSpell(guildKey, guildRankRef, entryId)
    local normalizedEntryId = normalizeProgressionEntryId(entryId)
    if normalizedEntryId == "" then
        return nil
    end

    return updateGuildProgressionState(guildKey, guildRankRef, function(state)
        state.selectedSpells[normalizedEntryId] = nil
        return true
    end)
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
    if dateKey == "" then
        return nil, rankRef ~= "" and rankRef or nil
    end

    return dateKey, rankRef ~= "" and rankRef or nil
end

function Profile.SetDailyRewardClaim(guildKey, dateKey, guildRankRef)
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
    bucket.dailyRewardDate = normalizedDateKey
    bucket.dailyRewardRankRef = normalizedRankRef
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
