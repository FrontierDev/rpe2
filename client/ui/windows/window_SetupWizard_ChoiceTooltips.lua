local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Client.UI = Addon.Client.UI or {}

local SetupWizard = Addon.Client.UI.SetupWizard
local Database = Addon.Internal and Addon.Internal.Database or {}
local Registry = Addon.Internal and Addon.Internal.Registry or {}

if type(SetupWizard) ~= "table" or SetupWizard._identityChoiceTooltipExtensionInstalled == true then
    return true
end

local function ensureString(value)
    if value == nil then
        return ""
    end

    return tostring(value)
end

local function trimString(value)
    return ensureString(value):gsub("^%s+", ""):gsub("%s+$", "")
end

local function getDatasetDisplayName(dataset)
    if type(Database.GetDatasetDisplayName) == "function" then
        return trimString(Database.GetDatasetDisplayName(dataset))
    end

    return trimString(dataset and (dataset.name or dataset.id))
end

local function buildChoiceMetadata(definitionKey)
    local metadata = {}
    local datasets = type(Registry.GetActivatedDatasets) == "function"
        and Registry:GetActivatedDatasets()
        or {}

    for datasetIndex = 1, #datasets do
        local dataset = datasets[datasetIndex]
        local datasetId = trimString(dataset and dataset.id)
        local entries = type(dataset) == "table" and dataset[definitionKey] or nil

        if datasetId ~= "" and type(entries) == "table" then
            local datasetName = getDatasetDisplayName(dataset)
            for entryIndex = 1, #entries do
                local entry = entries[entryIndex]
                local entryId = trimString(entry and entry.id)
                if entryId ~= "" then
                    metadata[("%s:%s"):format(datasetId, entryId)] = {
                        description = trimString(entry and entry.description),
                        datasetName = datasetName,
                    }
                end
            end
        end
    end

    return metadata
end

local function attachChoiceMetadata(items, definitionKey)
    local metadata = buildChoiceMetadata(definitionKey)

    for index = 1, #(items or {}) do
        local item = items[index]
        local itemMetadata = metadata[trimString(item and item.value)]
        if type(item) == "table" and type(itemMetadata) == "table" then
            item.description = itemMetadata.description
            item.datasetName = itemMetadata.datasetName
        end
    end

    return items
end

local originalBuildAllowedRaceItems = SetupWizard.BuildAllowedRaceItems
local originalBuildAllowedClassItems = SetupWizard.BuildAllowedClassItems
local originalRefreshChoiceGrid = SetupWizard.RefreshChoiceGrid

if type(originalBuildAllowedRaceItems) == "function" then
    function SetupWizard:BuildAllowedRaceItems(...)
        return attachChoiceMetadata(originalBuildAllowedRaceItems(self, ...), "races")
    end
end

if type(originalBuildAllowedClassItems) == "function" then
    function SetupWizard:BuildAllowedClassItems(...)
        return attachChoiceMetadata(originalBuildAllowedClassItems(self, ...), "classes")
    end
end

local function buildChoiceTooltipSpec(item)
    local title = tostring(item and (item.displayName or item.name or item.label) or "")
    local lines = {}
    local description = trimString(item and item.description)
    local datasetName = trimString(item and item.datasetName)
    local sourceLabel = trimString(item and item.label)

    if description ~= "" then
        lines[#lines + 1] = description
    end

    if datasetName ~= "" then
        lines[#lines + 1] = "Dataset: " .. datasetName
    elseif sourceLabel ~= "" then
        lines[#lines + 1] = sourceLabel
    end

    return {
        title = title,
        lines = lines,
    }
end

if type(originalRefreshChoiceGrid) == "function" then
    function SetupWizard:RefreshChoiceGrid(collectionKey, layout, items, selectedValue, setter)
        local result = originalRefreshChoiceGrid(self, collectionKey, layout, items, selectedValue, setter)

        if collectionKey ~= "raceChoices" and collectionKey ~= "classChoices" then
            return result
        end

        local collection = self[collectionKey] or {}
        for index = 1, #(items or {}) do
            local choice = collection[index]
            if choice and choice.slot and type(choice.slot.SetTooltip) == "function" then
                choice.slot:SetTooltip(buildChoiceTooltipSpec(items[index]))
            end
        end

        return result
    end
end

SetupWizard._identityChoiceTooltipExtensionInstalled = true
return true
