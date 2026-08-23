local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Client.UI = Addon.Client.UI or {}
Addon.Client.UI.Profile = Addon.Client.UI.Profile or {}

local ProfileUI = Addon.Client.UI.Profile
local UI = Addon.UI or {}
local Profile = Addon.Internal and Addon.Internal.Profile or {}
local Registry = Addon.Internal and Addon.Internal.Registry or {}
local Database = Addon.Internal and Addon.Internal.Database or {}
local Client = Addon.Client or {}
local Tooltips = Addon.Client.UI and Addon.Client.UI.Tooltips or {}
local SpellbookEntry = UI.SpellbookEntry

local SpellbookPage = ProfileUI.SpellbookPage or {}
ProfileUI.SpellbookPage = SpellbookPage

local DATASET_PANEL_WIDTH = 168
local SPELLBOOK_COLUMNS = 3
local SPELLBOOK_ROWS = 7
local SPELLBOOK_ENTRY_HEIGHT = 34
local SPELLBOOK_COLUMN_SPACING = 18
local SPELLBOOK_ROW_SPACING = 8
local SPELLBOOK_CONTENT_PADDING = 12
local GRID_PADDING = 8
local SPELLBOOK_TOP_OFFSET = 10
local SPELLBOOK_NAV_HEIGHT = 24
local SPELLBOOK_ENTRIES_PER_PAGE = SPELLBOOK_COLUMNS * SPELLBOOK_ROWS
local DEFAULT_ICON = "Interface\\Icons\\INV_Misc_QuestionMark"

local function getConfigurationRevision()
    return math.max(0, math.floor(tonumber(Addon.Internal and Addon.Internal.ConfigurationRevision) or 0))
end

local function trimString(value)
    local text = tostring(value or "")
    text = text:gsub("^%s+", ""):gsub("%s+$", "")
    return text
end

local function normalizeSpellbookCategory(value)
    local category = trimString(value)
    if category == "" then
        return nil
    end

    return category
end

local function getSpellDescriptionBuilder()
    local spellcasting = Addon.Client and Addon.Client.Spellcasting or nil
    local descriptionBuilder = spellcasting and spellcasting.DescriptionBuilder or nil
    if type(descriptionBuilder) == "table" and type(descriptionBuilder.PrewarmTooltipData) == "function" then
        return descriptionBuilder
    end

    return nil
end

local function buildNavigationRows(knownSpells)
    local datasets = Registry.GetActivatedDatasets and Registry:GetActivatedDatasets() or {}
    local resolvedKnownSpells = knownSpells or {}
    local spellCountsByDataset = {}
    local spellCountsByDatasetAndCategory = {}
    local rows = {}

    for index = 1, #resolvedKnownSpells do
        local row = resolvedKnownSpells[index]
        local dataset = row and row.dataset or nil
        if dataset and dataset.id then
            local datasetId = tostring(dataset.id)
            spellCountsByDataset[datasetId] = (spellCountsByDataset[datasetId] or 0) + 1

            local category = normalizeSpellbookCategory(row and row.spellbookCategory)
            if category then
                local categoryCounts = spellCountsByDatasetAndCategory[datasetId]
                if not categoryCounts then
                    categoryCounts = {}
                    spellCountsByDatasetAndCategory[datasetId] = categoryCounts
                end
                categoryCounts[category] = (categoryCounts[category] or 0) + 1
            end
        end
    end

    for index = 1, #datasets do
        local dataset = datasets[index]
        if dataset and dataset.id then
            local datasetId = tostring(dataset.id)
            local datasetDisplayName = Database.GetDatasetDisplayName and Database.GetDatasetDisplayName(dataset) or tostring(dataset.name or dataset.id)
            rows[#rows + 1] = {
                rowType = "dataset",
                dataset = dataset,
                datasetId = dataset.id,
                name = datasetDisplayName,
                displayName = datasetDisplayName,
                count = spellCountsByDataset[datasetId] or 0,
            }

            local categories = {}
            local seenCategories = {}
            local categoryCounts = spellCountsByDatasetAndCategory[datasetId] or {}
            for spellIndex = 1, #(dataset.spells or {}) do
                local spell = dataset.spells[spellIndex]
                local category = normalizeSpellbookCategory(spell and spell.spellbookCategory)
                if category and not seenCategories[category] then
                    seenCategories[category] = true
                    categories[#categories + 1] = category
                end
            end

            for category in pairs(categoryCounts) do
                if category and not seenCategories[category] then
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

local function getSpellPageCount(rows)
    local count = math.max(0, math.floor(tonumber(rows) or 0))
    if count <= 0 then
        return 0
    end

    return math.max(1, math.ceil(count / SPELLBOOK_ENTRIES_PER_PAGE))
end

local function sliceSpellPageRows(rows, pageIndex)
    local sourceRows = rows or {}
    local page = math.max(1, math.floor(tonumber(pageIndex) or 1))
    local firstIndex = ((page - 1) * SPELLBOOK_ENTRIES_PER_PAGE) + 1
    local lastIndex = math.min(#sourceRows, firstIndex + SPELLBOOK_ENTRIES_PER_PAGE - 1)
    local sliced = {}

    for index = firstIndex, lastIndex do
        sliced[#sliced + 1] = sourceRows[index]
    end

    return sliced
end

function SpellbookPage:GetKnownSpellRows()
    local revision = getConfigurationRevision()
    if tonumber(self.KnownSpellRowsRevision) == revision and type(self.KnownSpellRows) == "table" then
        return self.KnownSpellRows
    end

    self.KnownSpellRows = Profile.ListKnownSpells and Profile.ListKnownSpells({
        lightweight = true,
    }) or {}
    self.KnownSpellRowsRevision = revision
    return self.KnownSpellRows
end

function SpellbookPage:GetNavigationRows(knownSpellRows)
    local revision = getConfigurationRevision()
    if tonumber(self.NavigationRowsRevision) == revision and type(self.NavigationRowsData) == "table" then
        return self.NavigationRowsData
    end

    self.NavigationRowsData = buildNavigationRows(knownSpellRows)
    self.NavigationRowsRevision = revision
    return self.NavigationRowsData
end

function SpellbookPage:GetSelectedDatasetSpells(rows)
    local sourceRows = rows or self.KnownSpellRows or {}
    if not self.SelectedDatasetId or self.SelectedDatasetId == "" then
        return {}
    end

    local filtered = {}
    local selectedCategory = normalizeSpellbookCategory(self.SelectedSpellbookCategory)
    for index = 1, #sourceRows do
        local row = sourceRows[index]
        local dataset = row and row.dataset or nil
        if dataset and tostring(dataset.id or "") == tostring(self.SelectedDatasetId) then
            local rowCategory = normalizeSpellbookCategory(row and row.spellbookCategory)
            if not selectedCategory or rowCategory == selectedCategory then
                filtered[#filtered + 1] = row
            end
        end
    end

    return filtered
end

function SpellbookPage:EnsureDatasetSelection(rows)
    local navigationRows = rows or {}
    local datasetSelections = {}
    local firstDatasetWithSpells = nil
    local firstDatasetId = nil

    for index = 1, #navigationRows do
        local row = navigationRows[index]
        if row and row.rowType == "dataset" then
            local datasetId = tostring(row.datasetId or "")
            if datasetId ~= "" then
                if not firstDatasetId then
                    firstDatasetId = row.datasetId
                end
                datasetSelections[datasetId] = datasetSelections[datasetId] or {
                    row = row,
                    categories = {},
                }
                if not firstDatasetWithSpells and (tonumber(row.count) or 0) > 0 then
                    firstDatasetWithSpells = row.datasetId
                end
            end
        elseif row and row.rowType == "category" then
            local datasetId = tostring(row.datasetId or "")
            if datasetId ~= "" then
                datasetSelections[datasetId] = datasetSelections[datasetId] or {
                    row = nil,
                    categories = {},
                }
                datasetSelections[datasetId].categories[tostring(row.category or "")] = true
            end
        end
    end

    local selectedDatasetKey = tostring(self.SelectedDatasetId or "")
    if selectedDatasetKey == "" or not datasetSelections[selectedDatasetKey] then
        self.SelectedDatasetId = firstDatasetWithSpells or firstDatasetId
        self.SelectedSpellbookCategory = nil
        return
    end

    local selectedCategory = normalizeSpellbookCategory(self.SelectedSpellbookCategory)
    if not selectedCategory then
        self.SelectedSpellbookCategory = nil
        return
    end

    if not datasetSelections[selectedDatasetKey].categories[selectedCategory] then
        self.SelectedSpellbookCategory = nil
    end
end

function SpellbookPage:SelectNavigationItem(item)
    if type(item) ~= "table" or not item.datasetId then
        return
    end

    self.SelectedDatasetId = item.datasetId
    if item.rowType == "category" then
        self.SelectedSpellbookCategory = item.category
    else
        self.SelectedSpellbookCategory = nil
    end
    self.CurrentSpellPage = 1
end

function SpellbookPage:IsNavigationItemSelected(item)
    if type(item) ~= "table" then
        return false
    end

    if tostring(item.datasetId or "") ~= tostring(self.SelectedDatasetId or "") then
        return false
    end

    if item.rowType == "category" then
        return tostring(item.category or "") == tostring(self.SelectedSpellbookCategory or "")
    end

    return normalizeSpellbookCategory(self.SelectedSpellbookCategory) == nil
end

function SpellbookPage:GetSelectedNavigationLabel(rows)
    local navigationRows = rows or {}
    for index = 1, #navigationRows do
        local row = navigationRows[index]
        if self:IsNavigationItemSelected(row) then
            if row.rowType == "category" then
                local datasetName = row.dataset and (Database.GetDatasetDisplayName and Database.GetDatasetDisplayName(row.dataset) or tostring(row.dataset.name or row.dataset.id)) or tostring(row.datasetId or "Spellbook")
                return ("%s / %s"):format(datasetName, row.displayName or tostring(row.category or "Category"))
            end
            return row.displayName or row.name or "Spellbook"
        end
    end

    return "Spellbook"
end

function SpellbookPage:RemoveSpell(spellRef)
    if not spellRef or not Profile.RemoveKnownSpell then
        return false
    end

    local removed = Profile.RemoveKnownSpell(spellRef)
    if not removed then
        return false
    end

    if self.owner and self.owner.Refresh then
        self.owner:Refresh()
    else
        self:Refresh()
    end

    return true
end

function SpellbookPage:RefreshActionBarWidget(reason)
    if Client.BuildActionBarWidget then
        Client:BuildActionBarWidget()
    end
    if Client.ShowActionBarWidget then
        Client:ShowActionBarWidget()
    end
    if Client.RefreshActionBarWidget then
        Client:RefreshActionBarWidget(reason or "spellbook-action-bar")
    end
end

function SpellbookPage:IsMountedActionBarBindingMode()
    return false
end

function SpellbookPage:FindBoundSpellSlot(spellRef)
    if self:IsMountedActionBarBindingMode() then
        return Profile.FindMountedActionBarSlotBySpell and Profile.FindMountedActionBarSlotBySpell(spellRef) or nil
    end

    return Profile.FindActionBarSlotBySpell and Profile.FindActionBarSlotBySpell(spellRef) or nil
end

function SpellbookPage:HandleSpellLeftClick(spellRef)
    if not spellRef then
        return false
    end

    local action = nil
    if not Profile.ToggleSpellActionBarBinding then
        return false
    end
    action = Profile.ToggleSpellActionBarBinding(spellRef)
    if not action then
        return false
    end

    self:RefreshActionBarWidget("spellbook-left-click")
    self:RefreshVisibleState()
    return true
end

function SpellbookPage:EnsureSpellContextMenu()
    if self.SpellContextMenu then
        return self.SpellContextMenu
    end

    self.SpellContextMenu = UI.ContextMenu:New({
        name = "RPEProfileSpellbookSpellContextMenu",
        width = 170,
        panelWidth = 170,
        visibleRows = 8,
        rowHeight = 18,
        border = false,
        onItemInvoked = function(item, menu)
            local action = item and item.value or nil
            local spellRef = self.ContextMenuSpellRef
            if not spellRef or not action then
                return
            end

            if action == "unbind" then
                if Profile.UnbindSpellFromActionBar then
                    Profile.UnbindSpellFromActionBar(spellRef)
                end
            else
                local slotIndex = tonumber(tostring(action):match("^bind:(%d+)$"))
                if slotIndex and Profile.BindSpellToActionBarSlot then
                    Profile.BindSpellToActionBarSlot(slotIndex, spellRef)
                end
            end

            self:RefreshActionBarWidget("spellbook-context-menu")
            self:RefreshVisibleState()

            if menu and menu.HideMenus then
                menu:HideMenus()
            end
        end,
    })
    self.SpellContextMenu:SetParent(self.frame or UIParent)
    self.SpellContextMenu:Create()
    return self.SpellContextMenu
end

function SpellbookPage:ShowSpellContextMenu(anchorFrame, resolved)
    if not anchorFrame or not resolved or not resolved.spellRef then
        return
    end

    local menu = self:EnsureSpellContextMenu()
    local items = {}
    local boundSlot = self:FindBoundSpellSlot(resolved.spellRef)
    local size = Profile.GetActionBarSize and Profile.GetActionBarSize() or 5
    local labelPrefix = "Slot"

    if boundSlot then
        items[#items + 1] = {
            label = ("Unbind From %s %d"):format(labelPrefix, boundSlot),
            value = "unbind",
        }
    end

    for slotIndex = 1, size do
        items[#items + 1] = {
            label = boundSlot == slotIndex
                and ("Bound To %s %d"):format(labelPrefix, slotIndex)
                or ("Bind To %s %d"):format(labelPrefix, slotIndex),
            value = ("bind:%d"):format(slotIndex),
            enabled = boundSlot ~= slotIndex,
        }
    end

    self.ContextMenuSpellRef = resolved.spellRef
    menu:SetItems(items)
    menu:ShowAt(anchorFrame)
end

function SpellbookPage:CreateSpellEntry(index, parent)
    self.SpellEntries = self.SpellEntries or {}

    local entry = self.SpellEntries[index]
    if entry then
        return entry
    end

    entry = SpellbookEntry:New({
        name = ("RPEProfileSpellbookEntry%d"):format(index),
        width = 160,
        height = SPELLBOOK_ENTRY_HEIGHT,
        iconTexture = DEFAULT_ICON,
        border = false,
    })
    entry:SetParent(parent)
    entry:Create()

    local frame = entry:GetFrame()
    frame:HookScript("OnMouseUp", function(_, button)
        local resolved = entry.resolvedSpell
        if button == "LeftButton" and resolved and resolved.spellRef then
            self:HandleSpellLeftClick(resolved.spellRef)
        elseif button == "RightButton" and resolved and resolved.spellRef then
            self:ShowSpellContextMenu(frame, resolved)
        end
    end)

    self.SpellEntries[index] = entry
    return entry
end

function SpellbookPage:LayoutSpellEntries()
    if not self.EntryContentFrame or not self.EntryListFrame then
        return
    end

    local contentWidth = math.floor(tonumber(self.EntryContentFrame:GetWidth()) or 0)
    if contentWidth <= 0 then
        local gridContent = self.GridPanel and self.GridPanel.GetContentFrame and self.GridPanel:GetContentFrame() or nil
        contentWidth = math.floor(tonumber(gridContent and gridContent.GetWidth and gridContent:GetWidth() or 0) or 0)
    end
    if contentWidth <= 0 then
        contentWidth = 420
    end

    local availableWidth = math.max(180, contentWidth - (SPELLBOOK_CONTENT_PADDING * 2))
    local columnWidth = math.floor((availableWidth - ((SPELLBOOK_COLUMNS - 1) * SPELLBOOK_COLUMN_SPACING)) / SPELLBOOK_COLUMNS)
    local layoutWidth = (columnWidth * SPELLBOOK_COLUMNS) + ((SPELLBOOK_COLUMNS - 1) * SPELLBOOK_COLUMN_SPACING)
    local layoutHeight = (SPELLBOOK_ROWS * SPELLBOOK_ENTRY_HEIGHT) + ((SPELLBOOK_ROWS - 1) * SPELLBOOK_ROW_SPACING)

    self.EntryListFrame:ClearAllPoints()
    self.EntryListFrame:SetPoint("TOP", self.EntryContentFrame, "TOP", 0, -SPELLBOOK_TOP_OFFSET)
    self.EntryListFrame:SetSize(math.max(1, layoutWidth), math.max(1, layoutHeight))

    for index = 1, SPELLBOOK_ENTRIES_PER_PAGE do
        local entry = self.SpellEntries and self.SpellEntries[index] or nil
        local frame = entry and entry.GetFrame and entry:GetFrame() or nil
        if frame then
            entry:SetLayoutMetrics(columnWidth, SPELLBOOK_ENTRY_HEIGHT)
            frame:ClearAllPoints()
            frame:SetPoint(
                "TOPLEFT",
                self.EntryListFrame,
                "TOPLEFT",
                ((index - 1) % SPELLBOOK_COLUMNS) * (columnWidth + SPELLBOOK_COLUMN_SPACING),
                -(math.floor((index - 1) / SPELLBOOK_COLUMNS) * (SPELLBOOK_ENTRY_HEIGHT + SPELLBOOK_ROW_SPACING))
            )
        end
    end
end

function SpellbookPage:RefreshSpellPageControls(totalRows, pageCount)
    local currentPage = math.max(1, math.floor(tonumber(self.CurrentSpellPage) or 1))

    if self.SpellPageLabel and self.SpellPageLabel.SetText then
        if (tonumber(totalRows) or 0) <= 0 then
            self.SpellPageLabel:SetText("Page 0 / 0")
        else
            self.SpellPageLabel:SetText(("Page %d / %d"):format(currentPage, math.max(1, math.floor(tonumber(pageCount) or 1))))
        end
    end

    if self.SpellPagePrevButton and self.SpellPagePrevButton.SetEnabled then
        self.SpellPagePrevButton:SetEnabled((tonumber(totalRows) or 0) > 0 and currentPage > 1)
    end
    if self.SpellPageNextButton and self.SpellPageNextButton.SetEnabled then
        self.SpellPageNextButton:SetEnabled((tonumber(totalRows) or 0) > 0 and currentPage < math.max(1, math.floor(tonumber(pageCount) or 1)))
    end
end

function SpellbookPage:RefreshSpellEntries(rows)
    local selectedRows = self:GetSelectedDatasetSpells(rows)
    local totalRows = #selectedRows
    local pageCount = getSpellPageCount(totalRows)
    if pageCount <= 0 then
        self.CurrentSpellPage = 1
    else
        self.CurrentSpellPage = math.max(1, math.min(math.floor(tonumber(self.CurrentSpellPage) or 1), pageCount))
    end

    local pageRows = sliceSpellPageRows(selectedRows, self.CurrentSpellPage)
    self.VisibleSpellRows = pageRows
    self:LayoutSpellEntries()
    self:RefreshSpellPageControls(totalRows, pageCount)

    if self.EntryListFrame and self.EntryListFrame.Show and self.EntryListFrame.Hide then
        if #pageRows > 0 then
            self.EntryListFrame:Show()
        else
            self.EntryListFrame:Hide()
        end
    end

    for index = 1, SPELLBOOK_ENTRIES_PER_PAGE do
        local entry = self.SpellEntries and self.SpellEntries[index] or nil
        local resolved = pageRows[index]
        if entry then
            if resolved then
                local icon = resolved.spell and tostring(resolved.spell.icon or "") or ""
                local boundSlot = self:FindBoundSpellSlot(resolved.spellRef)
                if icon == "" then
                    icon = DEFAULT_ICON
                end

                entry:SetIcon(icon)
                entry:SetSpellName(resolved.name or "Unknown Spell")
                entry:SetEnabled(true)
                entry:SetTooltip(function(owner)
                    local currentResolved = entry.resolvedSpell
                    if not currentResolved or not Tooltips.Spell or type(Tooltips.Spell.Build) ~= "function" then
                        return nil
                    end

                    return Tooltips.Spell:Build(currentResolved, owner)
                end)
                if resolved.isMissing == true then
                    entry:SetBorderColor(0.8, 0.22, 0.22, 1)
                elseif boundSlot then
                    entry:SetBorderColor(0.94, 0.74, 0.22, 1)
                else
                    entry:SetBorderColor(0.42, 0.46, 0.52, 1)
                end
                entry.resolvedSpell = resolved
                entry:GetFrame():Show()
            else
                entry:SetIcon(DEFAULT_ICON)
                entry:SetSpellName("")
                entry:SetEnabled(false)
                entry:SetTooltip(nil)
                entry:SetBorderColor(0.24, 0.24, 0.28, 1)
                entry.resolvedSpell = nil
                entry:GetFrame():Hide()
            end
        end
    end

    self.LastGridEmptyStateText = ""
    if self.GridEmptyText and self.GridEmptyText.SetText then
        if not self.SelectedDatasetId then
            self.LastGridEmptyStateText = "Activate a dataset to browse known spells."
        elseif totalRows == 0 then
            if normalizeSpellbookCategory(self.SelectedSpellbookCategory) then
                self.LastGridEmptyStateText = "No known spells in this category."
            else
                self.LastGridEmptyStateText = "No known spells in this dataset."
            end
        end
        self.GridEmptyText:SetText(self.LastGridEmptyStateText)
    end
end

function SpellbookPage:PreviousSpellPage()
    if (tonumber(self.CurrentSpellPage) or 1) <= 1 then
        return false
    end

    self.CurrentSpellPage = math.max(1, (tonumber(self.CurrentSpellPage) or 1) - 1)
    self:RefreshSpellEntries(self.KnownSpellRows)
    return true
end

function SpellbookPage:NextSpellPage()
    local rows = self:GetSelectedDatasetSpells(self.KnownSpellRows)
    local pageCount = getSpellPageCount(#rows)
    if pageCount <= 0 or (tonumber(self.CurrentSpellPage) or 1) >= pageCount then
        return false
    end

    self.CurrentSpellPage = math.min(pageCount, (tonumber(self.CurrentSpellPage) or 1) + 1)
    self:RefreshSpellEntries(self.KnownSpellRows)
    return true
end

function SpellbookPage:RefreshVisibleState()
    if not self.frame then
        return nil
    end

    local datasetRows = self.DatasetRows or {}
    local selectedDatasetName = self:GetSelectedNavigationLabel(datasetRows)

    if self.DatasetList and self.DatasetList.RefreshRows then
        self.DatasetList:RefreshRows()
    end

    if self.GridTitle and self.GridTitle.SetText then
        self.GridTitle:SetText(selectedDatasetName)
    end

    if self.GridHintText and self.GridHintText.SetText then
        self.GridHintText:SetText("Left-click to bind/unbind. Right-click for action bar slot options.")
    end

    self:RefreshSpellEntries(self.KnownSpellRows)
    return self.frame
end

function SpellbookPage:Build(parent, owner)
    self.owner = owner
    if self.frame then
        return self.frame
    end

    self.frame = CreateFrame("Frame", "RPEProfileSpellbookPage", parent)
    self.frame:SetAllPoints(parent)
    self.SpellEntries = {}
    self.CurrentSpellPage = 1

    self.RootLayout = UI.CreateLayout(UI.HorizontalLayoutGroup, self.frame, "RPEProfileSpellbookRootLayout", {
        spacing = 8,
        fitChildrenWidth = true,
        fitChildrenHeight = true,
    })
    UI.Utils.AnchorFill(self.RootLayout, self.frame, 0, 0, 0, 0)

    self.DatasetPanel = UI.CreatePanel(self.RootLayout:GetFrame(), "RPEProfileSpellbookDatasetPanel", {
        width = DATASET_PANEL_WIDTH,
        height = 304,
        contentInset = 2,
        showBorder = false,
    })
    self.RootLayout:AddChild(self.DatasetPanel)

    self.GridPanel = UI.CreatePanel(self.RootLayout:GetFrame(), "RPEProfileSpellbookGridPanel", {
        width = 340,
        height = 304,
        expandWidth = true,
        weight = 1,
        contentInset = 0,
        showBorder = false,
    })
    self.RootLayout:AddChild(self.GridPanel)

    self.DatasetList = UI.ScrollLayout:New({
        name = "RPEProfileSpellbookDatasetList",
        width = DATASET_PANEL_WIDTH - 4,
        height = 300,
        visibleRows = 14,
        rowHeight = 18,
        rowSpacing = 0,
        border = false,
        rowElementClass = UI.ScrollListEntry,
        categoryWidth = 102,
        statusWidth = 26,
        categoryInsetLeft = 4,
        statusInsetRight = 4,
    })
    self.DatasetList:SetParent(self.DatasetPanel:GetContentFrame())
    self.DatasetList:SetRowRenderer(function(row, item)
        if row.SetCategory then
            row:SetCategory(item and item.name or "")
        end
        if row.SetTestName then
            row:SetTestName("")
        end
        if row.SetStatus then
            row:SetStatus(tostring(item and item.count or 0))
        end
        if row.SetDetail then
            row:SetDetail("")
        end

        local frame = row.GetFrame and row:GetFrame() or nil
        if frame then
            frame:EnableMouse(true)
            frame:SetScript("OnMouseUp", function(_, button)
                if button == "LeftButton" and item and item.datasetId then
                    self:SelectNavigationItem(item)
                    self:RefreshVisibleState()
                end
            end)

            local isSelected = self:IsNavigationItemSelected(item)
            if row.entryBackground and row.entryBackground.SetColorTexture then
                local token = isSelected and "list.rowHover" or "list.rowBackground"
                local color = UI.ResolveColor(nil, token)
                row.entryBackground:SetColorTexture(color.r or 0.08, color.g or 0.09, color.b or 0.11, color.a or 0.85)
            end
        end
    end)
    self.DatasetList:Create()
    UI.Utils.AnchorFill(self.DatasetList, self.DatasetPanel:GetContentFrame(), 0, 0, 0, 0)

    self.DatasetEmptyText = UI.CreateText(self.DatasetPanel:GetContentFrame(), "RPEProfileSpellbookDatasetEmptyText", "", {
        width = 140,
        height = 40,
        justifyH = "CENTER",
        wordWrap = true,
        textColor = UI.ResolveColor(nil, "text.secondary"),
    })
    self.DatasetEmptyText:GetFrame():SetPoint("CENTER", self.DatasetPanel:GetContentFrame(), "CENTER", 0, 0)

    self.GridTitle = UI.CreateText(self.GridPanel:GetContentFrame(), "RPEProfileSpellbookGridTitle", "Spellbook", {
        width = 300,
        height = 18,
        justifyH = "LEFT",
    })
    self.GridTitle:GetFrame():SetPoint("TOPLEFT", self.GridPanel:GetContentFrame(), "TOPLEFT", GRID_PADDING, -2)

    self.GridHintText = UI.CreateText(self.GridPanel:GetContentFrame(), "RPEProfileSpellbookGridHintText", "Right-click a spell to remove it from the spellbook.", {
        width = 300,
        height = 16,
        justifyH = "LEFT",
        textColor = UI.ResolveColor(nil, "text.secondary"),
    })
    self.GridHintText:GetFrame():SetPoint("TOPLEFT", self.GridTitle:GetFrame(), "BOTTOMLEFT", 0, -2)

    self.GridHost = CreateFrame("Frame", "RPEProfileSpellbookGridHost", self.GridPanel:GetContentFrame())
    self.GridHost:SetPoint("TOPLEFT", self.GridPanel:GetContentFrame(), "TOPLEFT", 0, -34)
    self.GridHost:SetPoint("BOTTOMRIGHT", self.GridPanel:GetContentFrame(), "BOTTOMRIGHT", 0, 0)

    self.EntryContentFrame = CreateFrame("Frame", "RPEProfileSpellbookEntryContent", self.GridHost)
    self.EntryContentFrame:SetPoint("TOPLEFT", self.GridHost, "TOPLEFT", 0, 0)
    self.EntryContentFrame:SetPoint("TOPRIGHT", self.GridHost, "TOPRIGHT", 0, 0)
    self.EntryContentFrame:SetPoint("BOTTOMLEFT", self.GridHost, "BOTTOMLEFT", 0, SPELLBOOK_NAV_HEIGHT)
    self.EntryContentFrame:SetPoint("BOTTOMRIGHT", self.GridHost, "BOTTOMRIGHT", 0, SPELLBOOK_NAV_HEIGHT)

    self.EntryListFrame = CreateFrame("Frame", "RPEProfileSpellbookEntryList", self.EntryContentFrame)
    self.EntryListFrame:SetPoint("TOP", self.EntryContentFrame, "TOP", 0, -SPELLBOOK_TOP_OFFSET)
    self.EntryListFrame:SetSize(1, 1)

    self.SpellPageNav = CreateFrame("Frame", "RPEProfileSpellbookPageNav", self.GridHost)
    self.SpellPageNav:SetPoint("BOTTOMLEFT", self.GridHost, "BOTTOMLEFT", GRID_PADDING, 0)
    self.SpellPageNav:SetPoint("BOTTOMRIGHT", self.GridHost, "BOTTOMRIGHT", -GRID_PADDING, 0)
    self.SpellPageNav:SetHeight(SPELLBOOK_NAV_HEIGHT)

    self.GridEmptyText = UI.CreateText(self.GridHost, "RPEProfileSpellbookGridEmptyText", "", {
        width = 180,
        height = 40,
        justifyH = "CENTER",
        wordWrap = true,
        textColor = UI.ResolveColor(nil, "text.secondary"),
    })
    self.GridEmptyText:GetFrame():SetPoint("CENTER", self.GridHost, "CENTER", 0, 0)

    self.SpellPageNextButton = UI.TextButton:New({
        name = "RPEProfileSpellbookPageNextButton",
        width = 22,
        height = 18,
        text = ">",
        fontSize = 11,
        border = false,
    })
    self.SpellPageNextButton:SetParent(self.SpellPageNav)
    self.SpellPageNextButton:Create()
    self.SpellPageNextButton:SetScript("OnClick", function()
        self:NextSpellPage()
    end)
    self.SpellPageNextButton:GetFrame():SetPoint("RIGHT", self.SpellPageNav, "RIGHT", 0, 0)

    self.SpellPagePrevButton = UI.TextButton:New({
        name = "RPEProfileSpellbookPagePrevButton",
        width = 22,
        height = 18,
        text = "<",
        fontSize = 11,
        border = false,
    })
    self.SpellPagePrevButton:SetParent(self.SpellPageNav)
    self.SpellPagePrevButton:Create()
    self.SpellPagePrevButton:SetScript("OnClick", function()
        self:PreviousSpellPage()
    end)
    self.SpellPagePrevButton:GetFrame():SetPoint("RIGHT", self.SpellPageNextButton:GetFrame(), "LEFT", -4, 0)

    self.SpellPageLabel = UI.CreateText(self.SpellPageNav, "RPEProfileSpellbookPageLabel", "Page 0 / 0", {
        width = 96,
        height = 18,
        justifyH = "RIGHT",
        textColor = UI.ResolveColor(nil, "text.secondary"),
    })
    self.SpellPageLabel:GetFrame():SetPoint("RIGHT", self.SpellPagePrevButton:GetFrame(), "LEFT", -8, 0)

    for index = 1, SPELLBOOK_ENTRIES_PER_PAGE do
        self:CreateSpellEntry(index, self.EntryListFrame)
    end

    self:Refresh()
    return self.frame
end

function SpellbookPage:Refresh()
    if not self.frame then
        return nil
    end

    local knownSpellRows = self:GetKnownSpellRows()
    local datasetRows = self:GetNavigationRows(knownSpellRows)
    self.DatasetRows = datasetRows
    self:EnsureDatasetSelection(datasetRows)

    if self.DatasetList and self.DatasetList.SetItems then
        self.DatasetList:SetItems(datasetRows)
    end

    self.LastDatasetEmptyStateText = ""
    if self.DatasetEmptyText and self.DatasetEmptyText.SetText then
        if #datasetRows == 0 then
            self.LastDatasetEmptyStateText = "No active datasets."
        end
        self.DatasetEmptyText:SetText(self.LastDatasetEmptyStateText)
    end

    return self:RefreshVisibleState()
end

return SpellbookPage
