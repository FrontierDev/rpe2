local _, Addon = ...

Addon.Internal = Addon.Internal or {}
Addon.Internal.Profile = Addon.Internal.Profile or {}

local Profile = Addon.Internal.Profile
local Registry = Addon.Internal.Registry or {}

local OldGetGuildBucket = Profile.GetGuildBucket
local OldGetGuildRequisitionUsage = Profile.GetGuildRequisitionUsage
local OldGetDailyRewardTransaction = Profile.GetDailyRewardTransaction

local function trim(value)
    return tostring(value or ""):match("^%s*(.-)%s*$") or ""
end

local function parseReference(reference)
    local datasetId, entryId = trim(reference):match("^([^:]+):(.+)$")
    datasetId, entryId = trim(datasetId), trim(entryId)
    if datasetId == "" or entryId == "" then
        return nil, nil
    end
    return datasetId, entryId
end

local function roleIdOf(role)
    return trim(type(role) == "table" and role.id or nil)
end

local function resolveGuildSetting(reference)
    if type(Registry.ResolveGuildSettingReference) ~= "function" then
        return nil, nil
    end
    local ok, dataset, setting = pcall(Registry.ResolveGuildSettingReference, Registry, reference)
    if not ok or type(dataset) ~= "table" or type(setting) ~= "table" then
        return nil, nil
    end
    return dataset, setting
end

local function resolveLegacyRoleTarget(legacyRef)
    legacyRef = trim(legacyRef)
    if legacyRef == "" then
        return nil, nil
    end

    -- Legacy rank-shaped GuildSettings that still resolve are only safe to
    -- convert when they normalize to exactly one Role.
    local resolvedDataset, resolvedSetting = resolveGuildSetting(legacyRef)
    if resolvedSetting then
        local roles = type(resolvedSetting.roles) == "table" and resolvedSetting.roles or {}
        if #roles ~= 1 then
            return nil, nil
        end
        local roleId = roleIdOf(roles[1])
        return roleId ~= "" and legacyRef or nil, roleId ~= "" and roleId or nil
    end

    -- Consolidated legacy rank refs no longer resolve as roots. #264 keeps the
    -- old setting id as the generated Role id, so an exact same-dataset Role-id
    -- match is a safe migration only when it identifies one GuildSetting.
    local datasetId, legacySettingId = parseReference(legacyRef)
    if not datasetId or type(Registry.GetActivatedDatasets) ~= "function" then
        return nil, nil
    end

    local matches = {}
    local datasets = Registry:GetActivatedDatasets() or {}
    for datasetIndex = 1, #datasets do
        local dataset = datasets[datasetIndex]
        if trim(dataset and dataset.id) == datasetId then
            for settingIndex = 1, #(dataset.guildSettings or {}) do
                local setting = dataset.guildSettings[settingIndex]
                local settingId = trim(setting and setting.id)
                if settingId ~= "" then
                    for roleIndex = 1, #(setting.roles or {}) do
                        if roleIdOf(setting.roles[roleIndex]) == legacySettingId then
                            matches[#matches + 1] = {
                                settingRef = datasetId .. ":" .. settingId,
                                roleId = legacySettingId,
                            }
                        end
                    end
                end
            end
            break
        end
    end

    if #matches == 1 then
        return matches[1].settingRef, matches[1].roleId
    end
    return nil, nil
end

local function persistBucket(guildKey, bucket)
    local state = type(Profile.GetGuildState) == "function" and Profile.GetGuildState() or nil
    if type(state) ~= "table" then
        return false
    end
    state.byGuild = type(state.byGuild) == "table" and state.byGuild or {}
    state.byGuild[guildKey] = bucket
    return type(Profile.SetGuildState) == "function" and type(Profile.SetGuildState(state)) == "table" or false
end

local function migrateLegacyAssignment(guildKey, bucket)
    if type(bucket) ~= "table" then
        return false
    end
    local legacyRef = trim(bucket.assignedRankRef)
    if legacyRef == "" then
        return false
    end

    local settingRef, roleId = resolveLegacyRoleTarget(legacyRef)
    if not settingRef or not roleId or type(Profile.MakeGuildRoleKey) ~= "function" then
        return false
    end

    local roleKey = Profile.MakeGuildRoleKey(settingRef, roleId)
    if not roleKey then
        return false
    end

    bucket.roles = type(bucket.roles) == "table" and bucket.roles or {}
    if type(bucket.roles[roleKey]) ~= "table" then
        bucket.roles[roleKey] = {
            guildSettingRef = settingRef,
            roleId = roleId,
            assignedAt = bucket.assignedRankAt,
            assignedBy = bucket.assignedRankBy,
        }
    end
    bucket.assignedRankRef = nil
    bucket.assignedRankAt = nil
    bucket.assignedRankBy = nil
    return true
end

local function currentSettingShape(settingRef)
    local dataset, setting = resolveGuildSetting(settingRef)
    if not setting then
        return nil
    end

    local datasetId = trim(dataset and dataset.id)
    local roleIds = {}
    for index = 1, #(setting.roles or {}) do
        local roleId = roleIdOf(setting.roles[index])
        if roleId ~= "" then
            roleIds[roleId] = true
        end
    end

    local requisitionIds = {}
    for index = 1, #(setting.requisitions or {}) do
        local requisitionId = trim(setting.requisitions[index] and setting.requisitions[index].id)
        if requisitionId ~= "" then
            requisitionIds[requisitionId] = true
        end
    end

    return {
        datasetId = datasetId,
        setting = setting,
        roleIds = roleIds,
        requisitionIds = requisitionIds,
    }
end

local function migrateLegacyUsage(guildKey, settingRef, bucket)
    if type(bucket) ~= "table" or type(bucket.requisitions) ~= "table" then
        return false
    end
    local shape = currentSettingShape(settingRef)
    if not shape or shape.datasetId == "" then
        return false
    end

    local targetLedger = type(bucket.requisitions[settingRef]) == "table" and bucket.requisitions[settingRef] or {}
    local changed = false

    for legacyRef, legacyLedger in pairs(bucket.requisitions) do
        if legacyRef ~= settingRef and type(legacyLedger) == "table" then
            local legacyDatasetId, legacySettingId = parseReference(legacyRef)
            local resolvedTargetRef, resolvedRoleId = resolveLegacyRoleTarget(legacyRef)
            if legacyDatasetId == shape.datasetId
                and legacySettingId
                and shape.roleIds[legacySettingId]
                and resolvedTargetRef == settingRef
                and resolvedRoleId == legacySettingId then
                for requisitionId, rawUsage in pairs(legacyLedger) do
                    local normalizedId = trim(requisitionId)
                    local usage = tonumber(rawUsage)
                    if shape.requisitionIds[normalizedId] and usage and usage == usage and usage ~= math.huge and usage ~= -math.huge then
                        usage = math.max(0, math.floor(usage))
                        local current = tonumber(targetLedger[normalizedId]) or 0
                        current = math.max(0, math.floor(current))
                        if usage > current then
                            targetLedger[normalizedId] = usage
                            changed = true
                        end
                    end
                end
            end
        end
    end

    if changed then
        bucket.requisitions[settingRef] = targetLedger
    end
    return changed
end

if type(OldGetGuildBucket) == "function" then
    function Profile.GetGuildBucket(guildKey)
        local normalizedGuildKey = trim(guildKey)
        local bucket = OldGetGuildBucket(guildKey)
        if normalizedGuildKey ~= "" and type(bucket) == "table" and migrateLegacyAssignment(normalizedGuildKey, bucket) then
            persistBucket(normalizedGuildKey, bucket)
        end
        return bucket
    end
end

if type(OldGetGuildRequisitionUsage) == "function" then
    function Profile.GetGuildRequisitionUsage(guildKey, guildSettingRef, requisitionId)
        local normalizedGuildKey = trim(guildKey)
        local normalizedSettingRef = trim(guildSettingRef)
        if normalizedGuildKey ~= "" and normalizedSettingRef ~= "" and type(Profile.GetGuildBucket) == "function" then
            local bucket = Profile.GetGuildBucket(normalizedGuildKey)
            if migrateLegacyUsage(normalizedGuildKey, normalizedSettingRef, bucket) then
                persistBucket(normalizedGuildKey, bucket)
            end
        end
        return OldGetGuildRequisitionUsage(guildKey, guildSettingRef, requisitionId)
    end
end

if type(OldGetDailyRewardTransaction) == "function" then
    function Profile.GetDailyRewardTransaction(guildKey)
        local transaction = OldGetDailyRewardTransaction(guildKey)
        if type(transaction) == "table" then
            transaction.rankRef = nil
        end
        return transaction
    end
end

-- #268 final cleanup: these singular-rank APIs were transitional facades for
-- pre-Role callers. Legacy SavedVariables are still consumed by the migration
-- paths above/original Guild.lua, but new runtime code cannot assign one RPE rank.
Profile.GetAssignedGuildRank = nil
Profile.SetAssignedGuildRank = nil
Profile.ClearAssignedGuildRank = nil

return Profile
