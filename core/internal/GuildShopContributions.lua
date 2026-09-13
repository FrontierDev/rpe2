local _, Addon = ...

Addon.Internal = Addon.Internal or {}
Addon.Client = Addon.Client or {}

local Database = Addon.Internal.Database or {}
local Registry = Addon.Internal and Addon.Internal.Registry or {}
local Dependecies = Database.Dependecies or {}
local Guild = Addon.Client.Guild or {}
local Classes = Database.Classes or {}
local GuildSetting = Classes.GuildSetting

local CONTRIBUTION_GUILD_SENTINEL = "__RPE_SHOP_CONTRIBUTION__"
local RUNTIME_REQUISITION_PREFIX = "@shop-contribution:"

local function trim(value)
    return tostring(value or ""):match("^%s*(.-)%s*$") or ""
end

local function deepCopy(value)
    if type(value) ~= "table" then return value end
    local copy = {}
    for key, nested in pairs(value) do copy[deepCopy(key)] = deepCopy(nested) end
    return copy
end

local function normalizeCharacterLimit(value)
    local numeric = tonumber(value)
    if not numeric or numeric ~= numeric or numeric == math.huge or numeric == -math.huge then return 1 end
    if numeric == 0 then return 0 end
    return math.max(1, math.floor(numeric))
end

local function isContribution(setting)
    return type(setting) == "table" and trim(setting.targetGuildSettingRef) ~= ""
end

local function normalizeContributionRequisitions(setting)
    local rows = type(setting and setting.requisitions) == "table" and setting.requisitions or {}
    for index = 1, #rows do
        local requisition = rows[index]
        if type(requisition) == "table" then requisition.characterLimit = 0 end
    end
end

if GuildSetting and type(GuildSetting.Merge) == "function" and type(GuildSetting.ToTable) == "function" then
    local OriginalMerge = GuildSetting.Merge
    local OriginalToTable = GuildSetting.ToTable

    function GuildSetting:Merge(data)
        OriginalMerge(self, data)
        local targetRef = trim(type(data) == "table" and data.targetGuildSettingRef or self.targetGuildSettingRef)
        if targetRef ~= "" then
            self.targetGuildSettingRef = targetRef
            self.guildName = CONTRIBUTION_GUILD_SENTINEL
            self.general = { enableRequisitions = false, enableDailyRewards = false }
            self.roles = {}
            self.shopCategories = {}
            self.dailyRewards = {}
            normalizeContributionRequisitions(self)
        else
            self.targetGuildSettingRef = nil
        end
        return self
    end

    function GuildSetting:ToTable()
        local data = OriginalToTable(self)
        local targetRef = trim(self.targetGuildSettingRef)
        if targetRef ~= "" then
            data.targetGuildSettingRef = targetRef
            data.guildName = CONTRIBUTION_GUILD_SENTINEL
            data.general = { enableRequisitions = false, enableDailyRewards = false }
            data.roles = {}
            data.shopCategories = {}
            data.dailyRewards = {}
            for index = 1, #(data.requisitions or {}) do
                data.requisitions[index].characterLimit = 0
            end
        end
        return data
    end
end

function Guild:IsShopContributionSetting(setting)
    return isContribution(setting)
end

local function makeRuntimeRequisitionId(datasetId, contributionId, requisitionId)
    return table.concat({ RUNTIME_REQUISITION_PREFIX, trim(datasetId), ":", trim(contributionId), ":", trim(requisitionId) })
end

local function getActiveContributionRows(self)
    local setting, resolution = self:GetActiveGuildSetting()
    if type(setting) ~= "table" or type(resolution) ~= "table" or resolution.status ~= "active" then return {}, resolution end

    local targetRef = trim(resolution.ref)
    local rows = {}
    local datasets = type(Registry.GetActivatedDatasets) == "function" and Registry:GetActivatedDatasets() or {}
    for datasetIndex = 1, #datasets do
        local dataset = datasets[datasetIndex]
        local datasetId = trim(dataset and dataset.id)
        for settingIndex = 1, #(dataset and dataset.guildSettings or {}) do
            local contribution = dataset.guildSettings[settingIndex]
            if isContribution(contribution) and trim(contribution.targetGuildSettingRef) == targetRef then
                local contributionId = trim(contribution.id)
                for requisitionIndex = 1, #(contribution.requisitions or {}) do
                    local authored = contribution.requisitions[requisitionIndex]
                    if type(authored) == "table" and normalizeCharacterLimit(authored.characterLimit) == 0 then
                        local requisition = deepCopy(authored)
                        requisition.characterLimit = 0
                        requisition.id = makeRuntimeRequisitionId(datasetId, contributionId, authored.id)
                        requisition._shopContribution = {
                            datasetId = datasetId,
                            contributionId = contributionId,
                            authoredRequisitionId = trim(authored.id),
                            targetGuildSettingRef = targetRef,
                        }
                        rows[#rows + 1] = {
                            dataset = dataset,
                            datasetId = datasetId,
                            contribution = contribution,
                            contributionId = contributionId,
                            targetSetting = setting,
                            targetResolution = resolution,
                            requisition = requisition,
                            authoredRequisition = authored,
                            runtimeRequisitionId = requisition.id,
                        }
                    end
                end
            end
        end
    end
    return rows, resolution
end

function Guild:GetGuildShopContributionRows()
    return getActiveContributionRows(self)
end

function Guild:ResolveGuildShopContributionRequisition(runtimeRequisitionId)
    local wanted = trim(runtimeRequisitionId)
    if wanted == "" or wanted:sub(1, #RUNTIME_REQUISITION_PREFIX) ~= RUNTIME_REQUISITION_PREFIX then return nil end
    local rows = getActiveContributionRows(self)
    for index = 1, #rows do
        if rows[index].runtimeRequisitionId == wanted then return rows[index] end
    end
    return nil
end

if type(Guild.GetRequisitionEligibility) == "function" then
    local OriginalGetRequisitionEligibility = Guild.GetRequisitionEligibility

    function Guild:GetRequisitionEligibility(guildSettingRef, requisitionId)
        local contributionRow = self:ResolveGuildShopContributionRequisition(requisitionId)
        if not contributionRow then
            return OriginalGetRequisitionEligibility(self, guildSettingRef, requisitionId)
        end

        local activeSetting, resolution = self:GetActiveGuildSetting()
        if type(activeSetting) ~= "table" or type(resolution) ~= "table" or resolution.status ~= "active" then
            return false, resolution and resolution.reason or "setting-unavailable", resolution
        end
        if trim(guildSettingRef) ~= "" and trim(guildSettingRef) ~= trim(resolution.ref) then
            return false, "setting-mismatch", { activeSettingRef = resolution.ref, requestedSettingRef = guildSettingRef }
        end
        if trim(contributionRow.contribution.targetGuildSettingRef) ~= trim(resolution.ref) then
            return false, "contribution-target-mismatch", { activeSettingRef = resolution.ref }
        end

        local merged = deepCopy(activeSetting)
        merged.requisitions = { deepCopy(contributionRow.requisition) }
        local originalGetActive = self.GetActiveGuildSetting
        self.GetActiveGuildSetting = function() return merged, resolution end
        local ok, eligible, reason, detail = pcall(
            OriginalGetRequisitionEligibility,
            self,
            resolution.ref,
            contributionRow.runtimeRequisitionId
        )
        self.GetActiveGuildSetting = originalGetActive

        if not ok then
            return false, "eligibility-failed", { contribution = contributionRow }
        end
        if type(detail) == "table" then
            detail.shopContribution = {
                datasetId = contributionRow.datasetId,
                contributionId = contributionRow.contributionId,
                authoredRequisitionId = trim(contributionRow.authoredRequisition and contributionRow.authoredRequisition.id),
                runtimeRequisitionId = contributionRow.runtimeRequisitionId,
                targetGuildSettingRef = resolution.ref,
            }
        end
        return eligible, reason, detail
    end
end

-- Contribution entries share GuildSetting's requisition shape, so the existing
-- dependency scanner already sees item/currency refs. Extend dependency
-- recomputation only for the target GuildSetting dataset ref.
if type(Dependecies.RecomputeDatasetDependencies) == "function" then
    local OriginalRecomputeDatasetDependencies = Dependecies.RecomputeDatasetDependencies
    function Dependecies.RecomputeDatasetDependencies(datasetId)
        local dependencies = OriginalRecomputeDatasetDependencies(datasetId)
        local dataset = type(Database.GetDatasetByID) == "function" and Database.GetDatasetByID(datasetId) or nil
        if type(dataset) ~= "table" or type(dependencies) ~= "table" then return dependencies end

        local seen = {}
        for index = 1, #dependencies do seen[tostring(dependencies[index])] = true end
        for index = 1, #(dataset.guildSettings or {}) do
            local contribution = dataset.guildSettings[index]
            if isContribution(contribution) then
                local targetDatasetId = trim(contribution.targetGuildSettingRef):match("^([^:]+):[^:]+$")
                local targetExists = targetDatasetId and type(Database.GetDatasetByID) == "function" and Database.GetDatasetByID(targetDatasetId) or nil
                if targetDatasetId and targetDatasetId ~= trim(dataset.id) and targetExists and not seen[targetDatasetId] then
                    dependencies[#dependencies + 1] = targetDatasetId
                    seen[targetDatasetId] = true
                end
            end
        end
        table.sort(dependencies, function(left, right) return tostring(left) < tostring(right) end)
        dataset.dependencies = dependencies
        return dependencies
    end
end

-- Requisitions and Daily Rewards can use a Loot Table as their reward source.
-- Preserve the source metadata that the base GuildSetting normalizer does not
-- yet know about, while leaving direct-item behaviour unchanged.
if GuildSetting
    and GuildSetting._lootTableRewardsInstalled ~= true
    and type(GuildSetting.Merge) == "function"
    and type(GuildSetting.ToTable) == "function"
then
    local LootBaseMerge = GuildSetting.Merge
    local LootBaseToTable = GuildSetting.ToTable

    local function normalizeRequisitionSourceType(requisition)
        local sourceType = string.lower(trim(requisition and requisition.sourceType))
        if sourceType == "loot" or sourceType == "table" or sourceType == "loot_table" then return "loot_table" end
        if trim(requisition and requisition.lootRef) ~= "" and trim(requisition and requisition.itemRef) == "" then return "loot_table" end
        return "item"
    end

    local function normalizeDailyRewardType(reward)
        local rewardType = string.lower(trim(reward and reward.type))
        if rewardType == "loot" or rewardType == "table" or rewardType == "loot_table" then return "loot_table" end
        if rewardType == "currency" then return "currency" end
        return "item"
    end

    local function mapRowsById(rows)
        local byId = {}
        for index = 1, #(rows or {}) do
            local row = rows[index]
            local id = trim(type(row) == "table" and row.id)
            if id ~= "" and byId[id] == nil then byId[id] = row end
        end
        return byId
    end

    local function sourceRow(rows, byId, normalizedRow, index)
        local id = trim(type(normalizedRow) == "table" and normalizedRow.id)
        if id ~= "" and byId[id] ~= nil then return byId[id] end
        return type(rows) == "table" and rows[index] or nil
    end

    function GuildSetting:Merge(data)
        local requisitionSources = type(data) == "table" and type(data.requisitions) == "table" and data.requisitions or self.requisitions
        local dailyRewardSources = type(data) == "table" and type(data.dailyRewards) == "table" and data.dailyRewards or self.dailyRewards
        local requisitionsById = mapRowsById(requisitionSources)
        local dailyRewardsById = mapRowsById(dailyRewardSources)

        LootBaseMerge(self, data)

        for index = 1, #(self.requisitions or {}) do
            local requisition = self.requisitions[index]
            local source = sourceRow(requisitionSources, requisitionsById, requisition, index) or {}
            requisition.sourceType = normalizeRequisitionSourceType(source)
            requisition.lootRef = trim(source.lootRef)
        end
        for index = 1, #(self.dailyRewards or {}) do
            local reward = self.dailyRewards[index]
            local source = sourceRow(dailyRewardSources, dailyRewardsById, reward, index) or {}
            if normalizeDailyRewardType(source) == "loot_table" then
                reward.type = "loot_table"
                reward.ref = trim(source.ref)
            end
        end
        return self
    end

    function GuildSetting:ToTable()
        local data = LootBaseToTable(self)
        for index = 1, #(data.requisitions or {}) do
            local requisition = self.requisitions and self.requisitions[index] or nil
            data.requisitions[index].sourceType = normalizeRequisitionSourceType(requisition)
            data.requisitions[index].lootRef = trim(requisition and requisition.lootRef)
        end
        for index = 1, #(data.dailyRewards or {}) do
            local reward = self.dailyRewards and self.dailyRewards[index] or nil
            if normalizeDailyRewardType(reward) == "loot_table" then
                data.dailyRewards[index].type = "loot_table"
                data.dailyRewards[index].ref = trim(reward and reward.ref)
            end
        end
        return data
    end

    GuildSetting._lootTableRewardsInstalled = true
end

-- Add active GuildSetting -> Loot Table references to dependency tracking, and
-- clear them if a referenced Loot Table/dataset is deleted.
if Dependecies._guildSettingLootDependencyIntegrationInstalled ~= true
    and type(Dependecies.RecomputeDatasetDependencies) == "function"
then
    local LootBaseRecomputeDatasetDependencies = Dependecies.RecomputeDatasetDependencies
    local LootBaseHandleDatasetDeleted = Dependecies.HandleDatasetDeleted
    local LootBaseHandleDatasetEntryDeleted = Dependecies.HandleDatasetEntryDeleted

    local function getDatasetRoot()
        return Database.Datasets or rawget(_G or {}, "RPEngineDatasetDB")
    end

    local function parseDatasetId(reference)
        local datasetId = trim(reference):match("^([^:]+):.+$")
        return datasetId and trim(datasetId) or nil
    end

    local function requisitionUsesLootTable(requisition)
        local sourceType = string.lower(trim(requisition and requisition.sourceType))
        if sourceType == "loot" or sourceType == "table" or sourceType == "loot_table" then return true end
        return trim(requisition and requisition.lootRef) ~= "" and trim(requisition and requisition.itemRef) == ""
    end

    local function dailyRewardUsesLootTable(reward)
        local rewardType = string.lower(trim(reward and reward.type))
        return rewardType == "loot" or rewardType == "table" or rewardType == "loot_table"
    end

    local function appendGuildLootDependencies(dataset, dependencies)
        if type(dataset) ~= "table" or type(dependencies) ~= "table" then return dependencies end
        local seen = {}
        for index = 1, #dependencies do
            local dependencyId = trim(dependencies[index])
            if dependencyId ~= "" then seen[dependencyId] = true end
        end
        local ownId = trim(dataset.id)
        local function append(reference)
            local dependencyId = parseDatasetId(reference)
            if dependencyId and dependencyId ~= ownId and not seen[dependencyId] then
                dependencies[#dependencies + 1] = dependencyId
                seen[dependencyId] = true
            end
        end
        for settingIndex = 1, #(dataset.guildSettings or {}) do
            local setting = dataset.guildSettings[settingIndex]
            for requisitionIndex = 1, #(setting and setting.requisitions or {}) do
                local requisition = setting.requisitions[requisitionIndex]
                if type(requisition) == "table" and requisitionUsesLootTable(requisition) then append(requisition.lootRef) end
            end
            for rewardIndex = 1, #(setting and setting.dailyRewards or {}) do
                local reward = setting.dailyRewards[rewardIndex]
                if type(reward) == "table" and dailyRewardUsesLootTable(reward) then append(reward.ref) end
            end
        end
        table.sort(dependencies, function(left, right) return tostring(left or "") < tostring(right or "") end)
        dataset.dependencies = dependencies
        return dependencies
    end

    local function pruneGuildLootReferences(dataset, deletedDatasetId, deletedRef)
        if type(dataset) ~= "table" then return false end
        local mutated = false
        local function matches(reference)
            local ref = trim(reference)
            if ref == "" then return false end
            if deletedRef and ref == deletedRef then return true end
            return deletedDatasetId ~= nil and parseDatasetId(ref) == tostring(deletedDatasetId)
        end
        for settingIndex = 1, #(dataset.guildSettings or {}) do
            local setting = dataset.guildSettings[settingIndex]
            for requisitionIndex = 1, #(setting and setting.requisitions or {}) do
                local requisition = setting.requisitions[requisitionIndex]
                if type(requisition) == "table" and requisitionUsesLootTable(requisition) and matches(requisition.lootRef) then
                    requisition.lootRef = ""
                    mutated = true
                end
            end
            for rewardIndex = 1, #(setting and setting.dailyRewards or {}) do
                local reward = setting.dailyRewards[rewardIndex]
                if type(reward) == "table" and dailyRewardUsesLootTable(reward) and matches(reward.ref) then
                    reward.ref = ""
                    mutated = true
                end
            end
        end
        return mutated
    end

    function Dependecies.RecomputeDatasetDependencies(datasetId)
        local dependencies = LootBaseRecomputeDatasetDependencies(datasetId)
        if type(dependencies) ~= "table" then return dependencies end
        local dataset = type(Database.GetDatasetByID) == "function" and Database.GetDatasetByID(datasetId) or nil
        if not dataset then
            local root = getDatasetRoot()
            dataset = type(root) == "table" and type(root.datasets) == "table" and root.datasets[tostring(datasetId or "")] or nil
        end
        if not dataset then return dependencies end
        return appendGuildLootDependencies(dataset, dependencies)
    end

    if type(LootBaseHandleDatasetDeleted) == "function" then
        function Dependecies.HandleDatasetDeleted(datasetId)
            local result = LootBaseHandleDatasetDeleted(datasetId)
            local root = getDatasetRoot()
            local changed = 0
            if type(root) == "table" and type(root.datasets) == "table" then
                for currentDatasetId, dataset in pairs(root.datasets) do
                    if tostring(currentDatasetId) ~= tostring(datasetId) and pruneGuildLootReferences(dataset, tostring(datasetId), nil) then
                        Dependecies.RecomputeDatasetDependencies(currentDatasetId)
                        changed = changed + 1
                    end
                end
            end
            return math.max(tonumber(result) or 0, changed)
        end
    end

    if type(LootBaseHandleDatasetEntryDeleted) == "function" then
        function Dependecies.HandleDatasetEntryDeleted(datasetId, collectionKey, entry)
            local result = LootBaseHandleDatasetEntryDeleted(datasetId, collectionKey, entry)
            if collectionKey ~= "loot" then return result end
            local entryId = trim(type(entry) == "table" and entry.id)
            if entryId == "" then return result end
            local deletedRef = tostring(datasetId or "") .. ":" .. entryId
            local root = getDatasetRoot()
            local changed = 0
            if type(root) == "table" and type(root.datasets) == "table" then
                for currentDatasetId, dataset in pairs(root.datasets) do
                    if pruneGuildLootReferences(dataset, nil, deletedRef) then
                        Dependecies.RecomputeDatasetDependencies(currentDatasetId)
                        changed = changed + 1
                    end
                end
            end
            return math.max(tonumber(result) or 0, changed)
        end
    end

    Dependecies._guildSettingLootDependencyIntegrationInstalled = true
end

Addon.Internal.GuildShopContributions = Addon.Internal.GuildShopContributions or {}
Addon.Internal.GuildShopContributions.SentinelGuildName = CONTRIBUTION_GUILD_SENTINEL
Addon.Internal.GuildShopContributions.RuntimeRequisitionPrefix = RUNTIME_REQUISITION_PREFIX
Addon.Internal.GuildShopContributions.IsContribution = isContribution

return Addon.Internal.GuildShopContributions
