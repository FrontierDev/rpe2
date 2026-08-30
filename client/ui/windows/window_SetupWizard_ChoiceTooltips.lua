local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Client.UI = Addon.Client.UI or {}

local SetupWizard = Addon.Client.UI.SetupWizard
local Database = Addon.Internal and Addon.Internal.Database or {}
local Registry = Addon.Internal and Addon.Internal.Registry or {}
local Profile = Addon.Internal and Addon.Internal.Profile or {}
local TooltipBuilders = Addon.Client and Addon.Client.UI and Addon.Client.UI.Tooltips or {}
local Timings = Addon.Debug and Addon.Debug.Timings or {}

if type(SetupWizard) ~= "table" then
    return true
end

local DEFAULT_ICON = "Interface\\Icons\\INV_Misc_QuestionMark"
local STARTING_ITEM_ROWS = 5
local SETUP_WIZARD_TIMING_THRESHOLD_MS = 16
local DEFAULT_SLOT_BORDER = { r = 0.42, g = 0.46, b = 0.52, a = 1 }
local SELECTED_SLOT_BORDER = { r = 0.64, g = 0.82, b = 0.38, a = 1 }

local function ensureString(value)
    if value == nil then
        return ""
    end

    return tostring(value)
end

local function trimString(value)
    return ensureString(value):gsub("^%s+", ""):gsub("%s+$", "")
end

local function setFrameShown(target, shown)
    local frame = target and target.GetFrame and target:GetFrame() or target
    if frame and frame.SetShown then
        frame:SetShown(shown == true)
    end
end

local function startSetupTiming(label, context)
    if type(Timings) == "table" and type(Timings.Start) == "function" then
        return Timings:Start(label, {
            context = context,
            thresholdMs = SETUP_WIZARD_TIMING_THRESHOLD_MS,
        })
    end

    return nil
end

local function stopSetupTiming(timer, cardinality)
    if timer and type(Timings) == "table" and type(Timings.Stop) == "function" then
        Timings:Stop(timer, {
            cardinality = cardinality,
        })
    end
end

local function getConfigurationRevision()
    return math.max(0, math.floor(tonumber(Addon.Internal and Addon.Internal.ConfigurationRevision) or 0))
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

if SetupWizard._identityChoiceTooltipExtensionInstalled ~= true then
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
end

local function buildStartingItemTooltipSpec(entry)
    if type(entry) ~= "table" then
        return nil
    end

    local datasetName = entry.dataset and Database.GetDatasetDisplayName and Database.GetDatasetDisplayName(entry.dataset)
        or tostring(entry.dataset and (entry.dataset.name or entry.dataset.id) or "")
    local builder = TooltipBuilders and TooltipBuilders.Item or nil
    if builder and builder.Build then
        return builder:Build(entry.item or {
            id = entry.itemId,
            name = entry.label or "Unknown Item",
        }, {
            dataset = entry.dataset,
            datasetId = entry.datasetId,
            datasetName = datasetName,
            itemId = entry.itemId,
            isActive = true,
            isMissing = false,
            soulbound = false,
            modifications = {},
        })
    end

    return {
        title = tostring(entry.item and entry.item.name or entry.label or "Unknown Item"),
        lines = {
            datasetName ~= "" and ("Dataset: " .. datasetName) or nil,
            entry.itemId and ("Item ID: " .. tostring(entry.itemId)) or nil,
        },
    }
end

local function getStartingItemGridMetrics(wizard)
    local grid = wizard and wizard.StartingItemsGrid or nil
    local panel = wizard and wizard.StartingItemsPanel or nil
    if type(grid) ~= "table" or type(panel) ~= "table" then
        return nil
    end

    local options = grid.options or {}
    local cellWidth = math.max(1, tonumber(options.cellWidth) or 40)
    local spacing = math.max(0, tonumber(options.spacingX or options.spacing) or 4)
    local contentFrame = panel.GetContentFrame and panel:GetContentFrame() or nil
    local availableWidth = contentFrame and contentFrame.GetWidth and tonumber(contentFrame:GetWidth()) or 0

    if not availableWidth or availableWidth <= 0 then
        local panelFrame = panel.GetFrame and panel:GetFrame() or nil
        local panelWidth = panelFrame and panelFrame.GetWidth and tonumber(panelFrame:GetWidth()) or 0
        local inset = math.max(0, tonumber(panel.options and panel.options.contentInset) or 0)
        availableWidth = math.max(0, (panelWidth or 0) - (2 * inset))
    end

    if availableWidth <= 0 then
        return nil
    end

    local columns = math.max(1, math.floor((availableWidth + spacing) / (cellWidth + spacing)))
    local gridWidth = (columns * cellWidth) + (math.max(0, columns - 1) * spacing)

    return {
        columns = columns,
        rows = STARTING_ITEM_ROWS,
        pageSize = columns * STARTING_ITEM_ROWS,
        gridWidth = gridWidth,
        cellWidth = cellWidth,
        spacing = spacing,
        availableWidth = availableWidth,
    }
end

local function applyStartingItemGridGeometry(wizard)
    local metrics = getStartingItemGridMetrics(wizard)
    local grid = wizard and wizard.StartingItemsGrid or nil
    local panel = wizard and wizard.StartingItemsPanel or nil
    if not metrics or type(grid) ~= "table" or type(panel) ~= "table" then
        return nil
    end

    grid.options = grid.options or {}
    grid.options.columns = metrics.columns
    grid.options.width = metrics.gridWidth

    local gridFrame = grid.GetFrame and grid:GetFrame() or nil
    local contentFrame = panel.GetContentFrame and panel:GetContentFrame() or nil
    if gridFrame then
        if gridFrame.SetWidth then
            gridFrame:SetWidth(metrics.gridWidth)
        end
        if contentFrame and gridFrame.ClearAllPoints and gridFrame.SetPoint then
            gridFrame:ClearAllPoints()
            gridFrame:SetPoint("TOP", contentFrame, "TOP", 0, 0)
        end
    end

    return metrics
end

local function refreshStartingItemPageWindow(wizard)
    local metrics = applyStartingItemGridGeometry(wizard)
    if not metrics then
        return
    end

    local items = wizard.filteredStartingItems or {}
    local totalItems = #items
    local totalPages = math.max(1, math.ceil(totalItems / metrics.pageSize))
    wizard.startingItemPage = math.max(1, math.min(tonumber(wizard.startingItemPage) or 1, totalPages))

    local startIndex = ((wizard.startingItemPage - 1) * metrics.pageSize) + 1
    local endIndex = math.min(totalItems, startIndex + metrics.pageSize - 1)

    if wizard.StartingItemsPageLabel and wizard.StartingItemsPageLabel.SetText then
        wizard.StartingItemsPageLabel:SetText(("Page %d / %d"):format(wizard.startingItemPage, totalPages))
    end
    if wizard.StartingItemsPrevButton and wizard.StartingItemsPrevButton.SetEnabled then
        wizard.StartingItemsPrevButton:SetEnabled(wizard.startingItemPage > 1)
    end
    if wizard.StartingItemsNextButton and wizard.StartingItemsNextButton.SetEnabled then
        wizard.StartingItemsNextButton:SetEnabled(wizard.startingItemPage < totalPages)
    end

    local visibleCount = 0
    for listIndex = startIndex, endIndex do
        visibleCount = visibleCount + 1
        local entry = items[listIndex]
        local slot = wizard:EnsureStartingItemSlot(visibleCount)
        slot.setupWizardEntry = entry
        slot:SetIcon(entry and entry.icon or DEFAULT_ICON)
        slot:SetTooltip(buildStartingItemTooltipSpec(entry))
        slot:SetOverlayText("")

        if wizard.selectedStartingItemLookup[trimString(entry and entry.value)] == true then
            slot:SetBorderColor(SELECTED_SLOT_BORDER.r, SELECTED_SLOT_BORDER.g, SELECTED_SLOT_BORDER.b, SELECTED_SLOT_BORDER.a)
        else
            slot:SetBorderColor(DEFAULT_SLOT_BORDER.r, DEFAULT_SLOT_BORDER.g, DEFAULT_SLOT_BORDER.b, DEFAULT_SLOT_BORDER.a)
        end

        setFrameShown(slot, true)
    end

    local slots = wizard.startingItemSlots or {}
    local maximumSlot = math.max(metrics.pageSize, #slots)
    for slotIndex = visibleCount + 1, maximumSlot do
        local slot = slots[slotIndex]
        if not slot and slotIndex <= metrics.pageSize then
            slot = wizard:EnsureStartingItemSlot(slotIndex)
        end
        if slot then
            slot.setupWizardEntry = nil
            slot:SetTooltip(nil)
            slot:SetIcon(DEFAULT_ICON)
            slot:SetOverlayText("")
            slot:SetBorderColor(DEFAULT_SLOT_BORDER.r, DEFAULT_SLOT_BORDER.g, DEFAULT_SLOT_BORDER.b, DEFAULT_SLOT_BORDER.a)
            setFrameShown(slot, false)
        end
    end

    if wizard.StartingItemsGrid and wizard.StartingItemsGrid.RefreshLayout then
        wizard.StartingItemsGrid:RefreshLayout()
    end
end

if SetupWizard._startingItemGridWidthExtensionInstalled ~= true then
    local originalBuildStartingItemsPage = SetupWizard.BuildStartingItemsPage
    local originalRefreshStartingItemsPage = SetupWizard.RefreshStartingItemsPage

    if type(originalBuildStartingItemsPage) == "function" then
        function SetupWizard:BuildStartingItemsPage(...)
            local result = originalBuildStartingItemsPage(self, ...)
            applyStartingItemGridGeometry(self)
            return result
        end
    end

    if type(originalRefreshStartingItemsPage) == "function" then
        function SetupWizard:RefreshStartingItemsPage(...)
            local result = originalRefreshStartingItemsPage(self, ...)
            refreshStartingItemPageWindow(self)
            return result
        end
    end

    SetupWizard._startingItemGridWidthExtensionInstalled = true
end

local function appendRow(bucket, row)
    bucket[#bucket + 1] = row
end

local function isAlwaysLearnedSpellRow(row)
    return type(row) == "table"
        and type(row.spell) == "table"
        and tostring(row.spell.learnMode or "") == "always_learned"
end

local function buildActionBarNavigationRows(alwaysLearnedRows)
    local datasets = type(Registry.GetActivatedDatasets) == "function"
        and Registry:GetActivatedDatasets()
        or {}
    local spellCountsByDataset = {}
    local spellCountsByDatasetAndCategory = {}
    local rows = {}

    for index = 1, #(alwaysLearnedRows or {}) do
        local row = alwaysLearnedRows[index]
        local dataset = row and row.dataset or nil
        local datasetId = trimString(dataset and dataset.id)
        if datasetId ~= "" then
            spellCountsByDataset[datasetId] = (spellCountsByDataset[datasetId] or 0) + 1
            local category = trimString(row and row.spellbookCategory)
            if category ~= "" then
                spellCountsByDatasetAndCategory[datasetId] = spellCountsByDatasetAndCategory[datasetId] or {}
                spellCountsByDatasetAndCategory[datasetId][category] = (spellCountsByDatasetAndCategory[datasetId][category] or 0) + 1
            end
        end
    end

    for datasetIndex = 1, #datasets do
        local dataset = datasets[datasetIndex]
        local datasetId = trimString(dataset and dataset.id)
        if datasetId ~= "" then
            local datasetName = getDatasetDisplayName(dataset)
            rows[#rows + 1] = {
                rowType = "dataset",
                dataset = dataset,
                datasetId = dataset.id,
                name = datasetName,
                displayName = datasetName,
                count = spellCountsByDataset[datasetId] or 0,
            }

            local categories = {}
            local seenCategories = {}
            local categoryCounts = spellCountsByDatasetAndCategory[datasetId] or {}
            for spellIndex = 1, #(dataset.spells or {}) do
                local spell = dataset.spells[spellIndex]
                if tostring(spell and spell.learnMode or "") == "always_learned" then
                    local category = trimString(spell and spell.spellbookCategory)
                    if category ~= "" and not seenCategories[category] then
                        seenCategories[category] = true
                        categories[#categories + 1] = category
                    end
                end
            end

            for category, count in pairs(categoryCounts) do
                if category ~= "" and (tonumber(count) or 0) > 0 and not seenCategories[category] then
                    seenCategories[category] = true
                    categories[#categories + 1] = category
                end
            end

            table.sort(categories, function(left, right)
                return tostring(left) < tostring(right)
            end)

            for categoryIndex = 1, #categories do
                local category = categories[categoryIndex]
                rows[#rows + 1] = {
                    rowType = "category",
                    dataset = dataset,
                    datasetId = dataset.id,
                    category = category,
                    name = ("    %s"):format(category),
                    displayName = category,
                    count = categoryCounts[category] or 0,
                }
            end
        end
    end

    return rows
end

local function buildActionBarSpellCache(wizard)
    local revision = getConfigurationRevision()
    local cached = wizard and wizard.actionBarSpellLightweightCache or nil
    if type(cached) == "table" and tonumber(cached.revision) == revision then
        return cached
    end

    local acquireTiming = startSetupTiming("SetupWizard.ActionBar.SpellRows", "lightweight")
    local knownRows = type(Profile.ListKnownSpells) == "function"
        and Profile.ListKnownSpells({ lightweight = true })
        or {}
    stopSetupTiming(acquireTiming, {
        knownRows = #knownRows,
    })

    local indexTiming = startSetupTiming("SetupWizard.ActionBar.NavigationIndex", "configuration")
    local alwaysLearnedRows = {}
    local rowsByDataset = {}
    local rowsByDatasetAndCategory = {}

    for index = 1, #knownRows do
        local row = knownRows[index]
        if isAlwaysLearnedSpellRow(row) then
            alwaysLearnedRows[#alwaysLearnedRows + 1] = row
            local datasetId = trimString(row and row.dataset and row.dataset.id)
            if datasetId ~= "" then
                rowsByDataset[datasetId] = rowsByDataset[datasetId] or {}
                appendRow(rowsByDataset[datasetId], row)

                local category = trimString(row and row.spellbookCategory)
                if category ~= "" then
                    rowsByDatasetAndCategory[datasetId] = rowsByDatasetAndCategory[datasetId] or {}
                    rowsByDatasetAndCategory[datasetId][category] = rowsByDatasetAndCategory[datasetId][category] or {}
                    appendRow(rowsByDatasetAndCategory[datasetId][category], row)
                end
            end
        end
    end

    cached = {
        revision = revision,
        knownRows = knownRows,
        alwaysLearnedRows = alwaysLearnedRows,
        navigationRows = buildActionBarNavigationRows(alwaysLearnedRows),
        rowsByDataset = rowsByDataset,
        rowsByDatasetAndCategory = rowsByDatasetAndCategory,
    }
    wizard.actionBarSpellLightweightCache = cached
    stopSetupTiming(indexTiming, {
        alwaysLearnedRows = #alwaysLearnedRows,
        navigationRows = #cached.navigationRows,
    })
    return cached
end

if SetupWizard._actionBarSpellLightweightExtensionInstalled ~= true then
    function SetupWizard:GetActionBarSpellLightweightCache()
        return buildActionBarSpellCache(self)
    end

    function SetupWizard:BuildActionBarSpellNavigationRows()
        local cache = buildActionBarSpellCache(self)
        return cache.navigationRows
    end

    function SetupWizard:GetSelectedActionBarSpellRows()
        local timing = startSetupTiming("SetupWizard.ActionBar.SelectedFilter", "cached")
        local cache = buildActionBarSpellCache(self)
        local datasetId = trimString(self.selectedActionBarDatasetId)
        local category = trimString(self.selectedActionBarSpellbookCategory)
        local rows = {}

        if datasetId ~= "" then
            if category ~= "" then
                rows = cache.rowsByDatasetAndCategory[datasetId]
                    and cache.rowsByDatasetAndCategory[datasetId][category]
                    or {}
            else
                rows = cache.rowsByDataset[datasetId] or {}
            end
        end

        stopSetupTiming(timing, {
            selectedRows = #rows,
        })
        return rows
    end

    function SetupWizard:BuildAllowedActionBarSpellItems()
        local items = {
            { label = "None", value = "" },
        }
        local seen = {
            [""] = true,
        }
        local rows = buildActionBarSpellCache(self).alwaysLearnedRows

        for index = 1, #rows do
            local row = rows[index]
            local spellRef = trimString(row and row.spellRef)
            if spellRef ~= "" and not seen[spellRef] then
                seen[spellRef] = true
                local datasetName = getDatasetDisplayName(row and row.dataset)
                items[#items + 1] = {
                    label = ("%s%s"):format(
                        tostring(row and row.name or spellRef),
                        datasetName ~= "" and (" (" .. datasetName .. ")") or ""
                    ),
                    value = spellRef,
                }
            end
        end

        return items
    end

    local originalRefreshActionBarPage = SetupWizard.RefreshActionBarPage
    if type(originalRefreshActionBarPage) == "function" then
        function SetupWizard:RefreshActionBarPage(...)
            local timing = startSetupTiming("SetupWizard.ActionBar.Refresh", "complete")
            local result = originalRefreshActionBarPage(self, ...)
            stopSetupTiming(timing, {
                visibleEntries = #(self.actionBarSpellEntries or {}),
                configurationRevision = getConfigurationRevision(),
            })
            return result
        end
    end

    local originalLayoutActionBarSpellEntries = SetupWizard.LayoutActionBarSpellEntries
    if type(originalLayoutActionBarSpellEntries) == "function" then
        function SetupWizard:LayoutActionBarSpellEntries(...)
            local timing = startSetupTiming("SetupWizard.ActionBar.VisibleEntryRender", "page")
            local result = originalLayoutActionBarSpellEntries(self, ...)
            stopSetupTiming(timing, {
                visibleEntries = #(self.actionBarSpellEntries or {}),
            })
            return result
        end
    end

    SetupWizard._actionBarSpellLightweightExtensionInstalled = true
end

return true
