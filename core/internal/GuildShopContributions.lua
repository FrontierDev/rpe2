local _, Addon = ...

Addon.Internal = Addon.Internal or {}
Addon.Client = Addon.Client or {}

local Database = Addon.Internal.Database or {}
local Registry = Addon.Internal.Registry or {}
local Dependecies = Database.Dependecies or {}
local Profile = Addon.Internal.Profile or {}
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
    return type(setting) == "table" and trim(setting.shopContributionTargetRef) ~= ""
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
        local targetRef = trim(type(data) == "table" and data.shopContributionTargetRef or self.shopContributionTargetRef)
        if targetRef ~= "" then
            self.shopContributionTargetRef = targetRef
            self.guildName = CONTRIBUTION_GUILD_SENTINEL
            self.general = { enableRequisitions = false, enableDailyRewards = false }
            self.roles = {}
            self.shopCategories = {}
            self.dailyRewards = {}
            normalizeContributionRequisitions(self)
        else
            self.shopContributionTargetRef = nil
        end
        return self
    end

    function GuildSetting:ToTable()
        local data = OriginalToTable(self)
        local targetRef = trim(self.shopContributionTargetRef)
        if targetRef ~= "" then
            data.shopContributionTargetRef = targetRef
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
            if isContribution(contribution) and trim(contribution.shopContributionTargetRef) == targetRef then
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
        if trim(contributionRow.contribution.shopContributionTargetRef) ~= trim(resolution.ref) then
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
                local targetDatasetId = trim(contribution.shopContributionTargetRef):match("^([^:]+):[^:]+$")
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

Addon.Internal.GuildShopContributions = Addon.Internal.GuildShopContributions or {}
Addon.Internal.GuildShopContributions.SentinelGuildName = CONTRIBUTION_GUILD_SENTINEL
Addon.Internal.GuildShopContributions.RuntimeRequisitionPrefix = RUNTIME_REQUISITION_PREFIX
Addon.Internal.GuildShopContributions.IsContribution = isContribution

return Addon.Internal.GuildShopContributions
