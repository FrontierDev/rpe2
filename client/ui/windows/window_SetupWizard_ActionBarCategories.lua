local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Client.UI = Addon.Client.UI or {}

local SetupWizard = Addon.Client.UI.SetupWizard

if type(SetupWizard) ~= "table" or SetupWizard._actionBarNonEmptyCategoriesInstalled == true then
    return true
end

local originalBuildActionBarSpellNavigationRows = SetupWizard.BuildActionBarSpellNavigationRows

local function getBucketSize(bucket)
    if type(bucket) ~= "table" then
        return 0
    end

    return #bucket
end

if type(originalBuildActionBarSpellNavigationRows) == "function" then
    function SetupWizard:BuildActionBarSpellNavigationRows(...)
        local rows = originalBuildActionBarSpellNavigationRows(self, ...) or {}
        local cache = type(self.GetActionBarSpellLightweightCache) == "function"
            and self:GetActionBarSpellLightweightCache()
            or nil
        local rowsByDataset = type(cache) == "table" and cache.rowsByDataset or {}
        local rowsByDatasetAndCategory = type(cache) == "table" and cache.rowsByDatasetAndCategory or {}
        local filtered = {}

        for index = 1, #rows do
            local row = rows[index]
            if type(row) == "table" then
                local datasetId = tostring(row.datasetId or "")
                local include = false

                if row.rowType == "category" then
                    local category = tostring(row.category or "")
                    local categoryRows = rowsByDatasetAndCategory[datasetId]
                        and rowsByDatasetAndCategory[datasetId][category]
                        or nil
                    include = datasetId ~= "" and category ~= "" and getBucketSize(categoryRows) > 0
                elseif row.rowType == "dataset" then
                    include = datasetId ~= "" and getBucketSize(rowsByDataset[datasetId]) > 0
                else
                    include = true
                end

                if include then
                    filtered[#filtered + 1] = row
                end
            end
        end

        return filtered
    end
end

SetupWizard._actionBarNonEmptyCategoriesInstalled = true
return true
