local _, Addon = ...

Addon.Internal = Addon.Internal or {}
Addon.Internal.Profile = Addon.Internal.Profile or {}

local Profile = Addon.Internal.Profile
local Database = Addon.Internal.Database or {}
local Registry = Addon.Internal.Registry or {}
local Runtime = Addon.Internal.Runtime or {}

local OldGetGuildBucket = Profile.GetGuildBucket
local OldGetGuildRequisitionUsage = Profile.GetGuildRequisitionUsage
local OldGetDailyRewardTransaction = Profile.GetDailyRewardTransaction

local function trim(value)
    return tostring(value or ""):match("^%s*(.-)%s*$") or ""
end

local function clone(value)
    if type(value) ~= "table" then
        return value
    end

    local copy = {}
    for key, nestedValue in pairs(value) do
        copy[key] = clone(nestedValue)
    end
    return copy
end

local function equal(left, right, seen)
    if left == right then
        return true
    end
    if type(left) ~= type(right) or type(left) ~= "table" then
        return false
    end

    seen = seen or {}
    seen[left] = seen[left] or {}
    if seen[left][right] then
        return true
    end
    seen[left][right] = true

    for key, value in pairs(left) do
        if not equal(value, right[key], seen) then
            return false
        end
    end
    for key in pairs(right) do
        if left[key] == nil then
            return false
        end
    end
    return true
end

local function normalizeOptionalText(value)
    local text = trim(value)
    return text ~= "" and text or nil
end

local function normalizeTimestamp(value)
    local numeric = tonumber(value)
    if numeric == nil or numeric ~= numeric or numeric == math.huge or numeric == -math.huge or numeric < 0 then
        return nil
    end
    return math.floor(numeric)
end

local function normalizeGuildBucket(record)
    local source = type(record) == "table" and record or {}
    local normalized = clone(source)
    normalized.assignedRankRef = normalizeOptionalText(source.assignedRankRef)
    normalized.assignedRankAt = normalizeTimestamp(source.assignedRankAt)
    normalized.assignedRankBy = normalizeOptionalText(source.assignedRankBy)
    return normalized
end

local function normalizeGuildState(record)
    local source = type(record) == "table" and record or {}
    local normalized = clone(source)
    normalized.byGuild = {}
    for guildKey, bucket in pairs(type(source.byGuild) == "table" and source.byGuild or {}) do
        normalized.byGuild[guildKey] = normalizeGuildBucket(bucket)
    end
    return normalized
end

-- #271: Guild profile data is runtime character state, not authored
-- configuration. Keep the public classification accurate for diagnostics, and
-- persist through the existing runtime transaction/revision infrastructure so
-- Role/ledger/reward writes cannot enter configuration/resource synchronization.
if type(Database.ConfigurationChangeClassification) == "table" then
    Database.ConfigurationChangeClassification["profile-guild"] = "runtime/profile state"
end

if type(Database.GetOrCreateActiveProfile) == "function"
    and type(Runtime) == "table"
    and type(Runtime.RunTransaction) == "function"
    and type(Runtime.BumpRevision) == "function"
then
    function Database.SetProfileGuildState(state)
        local profile = Database.GetOrCreateActiveProfile()
        local normalized = normalizeGuildState(state)
        local current = normalizeGuildState(profile.guild)

        -- Lazy migration and repeated transaction bookkeeping may attempt to
        -- persist an already-canonical value. Do not create a runtime revision
        -- or any other invalidation when nothing actually changed.
        if equal(current, normalized) then
            profile.guild = current
            return clone(current)
        end

        return Runtime:RunTransaction("profile-guild", function()
            profile.guild = normalized
            Runtime:BumpRevision("ProfileStateRevision")
            return clone(profile.guild)
        end)
    end
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

local function migrateLegacyDailyRewardIdentity(bucket)
    if type(bucket) ~= "table" then
        return false
    end

    local changed = false
    local claimRef = trim(bucket.dailyRewardSettingRef or bucket.dailyRewardRankRef)
    if claimRef ~= "" then
        local settingRef = resolveLegacyRoleTarget(claimRef)
        if settingRef and settingRef ~= claimRef then
            bucket.dailyRewardSettingRef = settingRef
            bucket.dailyRewardRankRef = nil
            changed = true
        end
    end

    local transaction = bucket.dailyRewardTransaction
    if type(transaction) == "table" then
        local transactionRef = trim(transaction.settingRef or transaction.rankRef)
        if transactionRef ~= "" then
            local settingRef = resolveLegacyRoleTarget(transactionRef)
            if settingRef and settingRef ~= transactionRef then
                transaction.settingRef = settingRef
                transaction.rankRef = nil
                changed = true
            end
        end
    end

    return changed
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
        if normalizedGuildKey ~= "" and type(bucket) == "table" then
            local changed = migrateLegacyAssignment(normalizedGuildKey, bucket)
            if migrateLegacyDailyRewardIdentity(bucket) then
                changed = true
            end
            if changed then
                persistBucket(normalizedGuildKey, bucket)
            end
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

return Profile
