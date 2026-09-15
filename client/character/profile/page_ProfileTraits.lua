local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Client.UI = Addon.Client.UI or {}
Addon.Client.UI.Profile = Addon.Client.UI.Profile or {}

local ProfileUI = Addon.Client.UI.Profile
local UI = Addon.UI or {}
local Profile = Addon.Internal and Addon.Internal.Profile or {}
local Client = Addon.Client or {}
local Tooltips = Addon.Client and Addon.Client.UI and Addon.Client.UI.Tooltips or {}
local Runtime = Addon.Internal and Addon.Internal.Runtime or {}
local SpellbookEntry = UI.SpellbookEntry

local TraitsPage = ProfileUI.TraitsPage or {}
ProfileUI.TraitsPage = TraitsPage

local CATEGORY_PANEL_WIDTH = 168
local TRAITBOOK_COLUMNS = 3
local TRAITBOOK_ROWS = 7
local TRAIT_ENTRY_HEIGHT = 34
local TRAIT_COLUMN_SPACING = 18
local TRAIT_ROW_SPACING = 8
local TRAIT_CONTENT_PADDING = 12
local GRID_PADDING = 8
local TRAITBOOK_TOP_OFFSET = 10
local TRAITBOOK_NAV_HEIGHT = 24
local TRAIT_ENTRIES_PER_PAGE = TRAITBOOK_COLUMNS * TRAITBOOK_ROWS
local DEFAULT_ICON = "Interface\\Icons\\INV_Misc_QuestionMark"

local function getConfigurationRevision()
    return math.max(0, math.floor(tonumber(Addon.Internal and Addon.Internal.ConfigurationRevision) or 0))
end

local function getRuntimeRevision(domain)
    if type(Runtime) == "table" and type(Runtime.GetRevision) == "function" then
        return math.max(0, math.floor(tonumber(Runtime:GetRevision(domain)) or 0))
    end

    return 0
end

local function revisionTuplesEqual(left, right)
    if type(left) ~= "table" or type(right) ~= "table" then
        return false
    end

    for key, value in pairs(left) do
        if right[key] ~= value then
            return false
        end
    end
    for key, value in pairs(right) do
        if left[key] ~= value then
            return false
        end
    end

    return true
end

local CATEGORY_LABELS = {
    class_passives = "Class Passives",
    class_talents = "Class Talents",
    race_passives = "Race Passives",
    equipment = "Equipment Traits",
    consumable = "Consumables",
    all = "All Traits",
}

local function buildCategoryRows()
    local traitRows = Client.BuildProfileTraitRows and Client:BuildProfileTraitRows() or {}
    local grouped = Client.GetTraitDisplayMode and Client:GetTraitDisplayMode() ~= "flat"
    local counts = {}
    local fixedOrder = { "class_passives", "class_talents", "race_passives", "equipment", "consumable" }
    local fixedLookup = {
        class_passives = true,
        class_talents = true,
        race_passives = true,
        equipment = true,
        consumable = true,
    }

    for index = 1, #traitRows do
        local row = traitRows[index]
        local key = grouped and tostring(row and row.category or "General") or "all"
        counts[key] = (counts[key] or 0) + 1
    end

    local rows = {}
    if grouped then
        for index = 1, #fixedOrder do
            local key = fixedOrder[index]
            local count = counts[key] or 0
            if count > 0 then
                rows[#rows + 1] = {
                    key = key,
                    name = CATEGORY_LABELS[key] or key,
                    count = count,
                }
            end
        end

        local dynamicKeys = {}
        for key, count in pairs(counts) do
            if count > 0 and not fixedLookup[key] then
                dynamicKeys[#dynamicKeys + 1] = key
            end
        end
        table.sort(dynamicKeys, function(left, right)
            return string.lower(tostring(left)) < string.lower(tostring(right))
        end)
        for index = 1, #dynamicKeys do
            local key = dynamicKeys[index]
            rows[#rows + 1] = {
                key = key,
                name = CATEGORY_LABELS[key] or key,
                count = counts[key] or 0,
            }
        end
    elseif #traitRows > 0 then
        rows[1] = {
            key = "all",
            name = CATEGORY_LABELS.all,
            count = #traitRows,
        }
    end

    return rows, traitRows
end

local function countActiveRows(rows)
    local count = 0
    for index = 1, #(rows or {}) do
        if rows[index] and rows[index].isActive == true then
            count = count + 1
        end
    end

    return count
end

local function buildTraitHeaderText(selectedCategoryKey, rows)
    if tostring(selectedCategoryKey or "") == "consumable" then
        return "Toggle a consumable to preselect it during matching event phase prompts. You can still change or skip it when prompted."
    end

    local summary = Profile.GetTraitCountSummary and Profile.GetTraitCountSummary() or nil
    if not summary then
        return ("Selected: %d"):format(countActiveRows(rows))
    end

    if tostring(selectedCategoryKey or "") == "class_talents" then
        local selectedCount = math.max(0, math.floor(tonumber(summary.selectedClassTalentCount) or 0))
        local maxCount = math.max(0, math.floor(tonumber(summary.maxTalentTraits) or 0))
        if maxCount > 0 then
            return ("Selected: %d / %d"):format(selectedCount, maxCount)
        end

        return ("Selected: %d / Unlimited"):format(selectedCount)
    end

    if tostring(selectedCategoryKey or "") == "all" then
        local selectedCount = math.max(0, math.floor(tonumber(summary.manualCount) or 0))
        local maxCount = math.max(0, math.floor(tonumber(summary.maxTotalTraits) or 0))
        if maxCount > 0 then
            return ("Selected: %d / %d"):format(selectedCount, maxCount)
        end

        return ("Selected: %d"):format(selectedCount)
    end

    return ("Selected: %d"):format(countActiveRows(rows))
end

local function refreshGridHeaderLayout(self)
    if not self or not self.GridHintText or not self.GridHost then
        return
    end

    local isConsumable = tostring(self.SelectedCategoryKey or "") == "consumable"
    local hintHeight = isConsumable and 36 or 18
    local hostTopOffset = isConsumable and -54 or -36

    local hintFrame = self.GridHintText.GetFrame and self.GridHintText:GetFrame() or nil
    if hintFrame then
        hintFrame:SetHeight(hintHeight)
    end

    self.GridHost:ClearAllPoints()
    self.GridHost:SetPoint("TOPLEFT", self.GridPanel:GetContentFrame(), "TOPLEFT", 0, hostTopOffset)
    self.GridHost:SetPoint("BOTTOMRIGHT", self.GridPanel:GetContentFrame(), "BOTTOMRIGHT", 0, 0)
end

local function buildTraitTooltip(row, owner)
    if not row then
        return nil
    end

    if Tooltips.Trait and type(Tooltips.Trait.Build) == "function" then
        return Tooltips.Trait:Build(row, owner)
    end

    return nil
end

local function getTraitPageCount(rows)
    local count = math.max(0, math.floor(tonumber(rows) or 0))
    if count <= 0 then
        return 0
    end

    return math.max(1, math.ceil(count / TRAIT_ENTRIES_PER_PAGE))
end

local function sliceTraitPageRows(rows, pageIndex)
    local sourceRows = rows or {}
    local page = math.max(1, math.floor(tonumber(pageIndex) or 1))
    local firstIndex = ((page - 1) * TRAIT_ENTRIES_PER_PAGE) + 1
    local lastIndex = math.min(#sourceRows, firstIndex + TRAIT_ENTRIES_PER_PAGE - 1)
    local sliced = {}

    for index = firstIndex, lastIndex do
        sliced[#sliced + 1] = sourceRows[index]
    end

    return sliced
end

function TraitsPage:GetSelectedCategoryTraits()
    local allRows = self.AllTraitRows or {}
    if not self.SelectedCategoryKey or self.SelectedCategoryKey == "all" then
        return allRows
    end

    local filtered = {}
    for index = 1, #allRows do
        local row = allRows[index]
        if row and tostring(row.category or "") == tostring(self.SelectedCategoryKey) then
            filtered[#filtered + 1] = row
        end
    end

    return filtered
end

function TraitsPage:EnsureCategorySelection(rows)
    local categories = rows or {}
    for index = 1, #categories do
        if tostring(categories[index].key or "") == tostring(self.SelectedCategoryKey or "") then
            return
        end
    end

    self.SelectedCategoryKey = categories[1] and categories[1].key or nil
end

function TraitsPage:MarkDirty()
    self.dirty = true
    return self
end

function TraitsPage:IsVisible()
    if not self.frame or not self.frame.IsShown or not self.frame:IsShown() then
        return false
    end

    if self.owner and self.owner.IsVisible then
        return self.owner:IsVisible()
    end

    return true
end

function TraitsPage:GetRevisionTuple()
    return {
        configurationRevision = getConfigurationRevision(),
        inventoryRevision = getRuntimeRevision("InventoryRevision"),
        equipmentRevision = getRuntimeRevision("EquipmentRevision"),
        selectedCategoryKey = tostring(self.SelectedCategoryKey or ""),
        currentTraitPage = math.max(1, math.floor(tonumber(self.CurrentTraitPage) or 1)),
    }
end

function TraitsPage:RefreshIfDirty()
    if not self.frame then
        return nil, false
    end

    local revision = self:GetRevisionTuple()
    if not self.dirty and revisionTuplesEqual(self.lastRenderedRevision, revision) then
        return self.frame, false
    end

    if not self:IsVisible() then
        self:MarkDirty()
        return self.frame, false
    end

    return self:Refresh(), true
end

function TraitsPage:RefreshTraitRuntime(reason)
    local eventState = Client.GetEventState and Client:GetEventState() or nil
    if type(eventState) == "table" and eventState.active == true then
        if Client.RefreshTraitRuntimeEntries then
            Client:RefreshTraitRuntimeEntries(eventState)
        end
        if Client.RefreshTraitResolvedState then
            Client:RefreshTraitResolvedState(eventState, reason or "profile-trait-toggle")
        end
    end
end

function TraitsPage:HandleTraitLeftClick(row)
    if type(row) ~= "table"
        or row.isToggleable ~= true
        or (row.isLocked == true and row.isActive ~= true)
        or (row.isAssignmentValid == false and row.isActive ~= true)
    then
        return false
    end

    local action = nil
    if row.sourceType == "trait" and row.traitRef and Profile.ToggleTraitActivation then
        action = Profile.ToggleTraitActivation(row.traitRef)
    elseif row.sourceType == "consumable" and row.itemRef and Profile.ToggleConsumableTraitActivation then
        action = Profile.ToggleConsumableTraitActivation(row.itemRef)
    end
    if not action then
        return false
    end

    self:RefreshTraitRuntime("profile-trait-toggle")
    if self.owner and self.owner.Refresh then
        self.owner:Refresh()
    else
        self:Refresh()
    end
    return true
end

function TraitsPage:EnsureTraitContextMenu()
    if self.TraitContextMenu then
        return self.TraitContextMenu
    end

    self.TraitContextMenu = UI.ContextMenu:New({
        name = "RPEProfileTraitsContextMenu",
        width = 170,
        panelWidth = 170,
        visibleRows = 3,
        rowHeight = 18,
        border = false,
        onItemInvoked = function(item, menu)
            local action = item and item.value or nil
            local row = self.ContextMenuTraitRow
            if action == "toggle-trait" and row and row.isToggleable == true then
                self:HandleTraitLeftClick(row)
            elseif action == "remove-trait" and row and row.isRemovable == true and row.traitRef and Profile.RemoveKnownTrait then
                Profile.RemoveKnownTrait(row.traitRef)
                self:RefreshTraitRuntime("profile-trait-remove")
                if self.owner and self.owner.Refresh then
                    self.owner:Refresh()
                else
                    self:Refresh()
                end
            end

            if menu and menu.HideMenus then
                menu:HideMenus()
            end
        end,
    })
    self.TraitContextMenu:SetParent(self.frame or UIParent)
    self.TraitContextMenu:Create()
    return self.TraitContextMenu
end

function TraitsPage:ShowTraitContextMenu(anchorFrame, row)
    if not anchorFrame or not row or (row.sourceType ~= "trait" and row.sourceType ~= "consumable") then
        return
    end

    local items = {}
    if row.isToggleable == true then
        items[#items + 1] = {
            label = row.isActive == true and "Deactivate" or "Activate",
            value = "toggle-trait",
            enabled = (row.isActive == true or (row.isLocked ~= true and row.isAssignmentValid ~= false)) and row.isMissing ~= true and (
                (row.sourceType == "trait" and row.traitRef ~= nil)
                or (row.sourceType == "consumable" and row.itemRef ~= nil)
            ),
        }
    end
    if row.isRemovable == true then
        items[#items + 1] = { label = "Remove From Traits", value = "remove-trait" }
    end
    if #items == 0 then
        return
    end

    local menu = self:EnsureTraitContextMenu()
    self.ContextMenuTraitRow = row
    menu:SetItems(items)
    menu:ShowAt(anchorFrame)
end

function TraitsPage:CreateTraitEntry(index, parent)
    self.TraitEntries = self.TraitEntries or {}

    local entry = self.TraitEntries[index]
    if entry then
        return entry
    end

    entry = SpellbookEntry:New({
        name = ("RPEProfileTraitEntry%d"):format(index),
        width = 160,
        height = TRAIT_ENTRY_HEIGHT,
        iconTexture = DEFAULT_ICON,
        border = false,
    })
    entry:SetParent(parent)
    entry:Create()

    local frame = entry:GetFrame()
    frame:HookScript("OnMouseUp", function(_, button)
        local row = entry.traitRow
        if button == "LeftButton" and row then
            self:HandleTraitLeftClick(row)
        elseif button == "RightButton" and row and (row.isToggleable == true or row.isRemovable == true) then
            self:ShowTraitContextMenu(frame, row)
        end
    end)

    self.TraitEntries[index] = entry
    return entry
end

function TraitsPage:LayoutTraitEntries()
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

    local availableWidth = math.max(180, contentWidth - (TRAIT_CONTENT_PADDING * 2))
    local columnWidth = math.floor((availableWidth - ((TRAITBOOK_COLUMNS - 1) * TRAIT_COLUMN_SPACING)) / TRAITBOOK_COLUMNS)
    local layoutWidth = (columnWidth * TRAITBOOK_COLUMNS) + ((TRAITBOOK_COLUMNS - 1) * TRAIT_COLUMN_SPACING)
    local layoutHeight = (TRAITBOOK_ROWS * TRAIT_ENTRY_HEIGHT) + ((TRAITBOOK_ROWS - 1) * TRAIT_ROW_SPACING)

    self.EntryListFrame:ClearAllPoints()
    self.EntryListFrame:SetPoint("TOP", self.EntryContentFrame, "TOP", 0, -TRAITBOOK_TOP_OFFSET)
    self.EntryListFrame:SetSize(math.max(1, layoutWidth), math.max(1, layoutHeight))

    for index = 1, TRAIT_ENTRIES_PER_PAGE do
        local entry = self.TraitEntries and self.TraitEntries[index] or nil
        local frame = entry and entry.GetFrame and entry:GetFrame() or nil
        if frame then
            entry:SetLayoutMetrics(columnWidth, TRAIT_ENTRY_HEIGHT)
            frame:ClearAllPoints()
            frame:SetPoint(
                "TOPLEFT",
                self.EntryListFrame,
                "TOPLEFT",
                ((index - 1) % TRAITBOOK_COLUMNS) * (columnWidth + TRAIT_COLUMN_SPACING),
                -(math.floor((index - 1) / TRAITBOOK_COLUMNS) * (TRAIT_ENTRY_HEIGHT + TRAIT_ROW_SPACING))
            )
        end
    end
end

function TraitsPage:RefreshTraitPageControls(totalRows, pageCount)
    local currentPage = math.max(1, math.floor(tonumber(self.CurrentTraitPage) or 1))

    if self.TraitPageLabel and self.TraitPageLabel.SetText then
        if (tonumber(totalRows) or 0) <= 0 then
            self.TraitPageLabel:SetText("Page 0 / 0")
        else
            self.TraitPageLabel:SetText(("Page %d / %d"):format(currentPage, math.max(1, math.floor(tonumber(pageCount) or 1))))
        end
    end

    if self.TraitPagePrevButton and self.TraitPagePrevButton.SetEnabled then
        self.TraitPagePrevButton:SetEnabled((tonumber(totalRows) or 0) > 0 and currentPage > 1)
    end
    if self.TraitPageNextButton and self.TraitPageNextButton.SetEnabled then
        self.TraitPageNextButton:SetEnabled((tonumber(totalRows) or 0) > 0 and currentPage < math.max(1, math.floor(tonumber(pageCount) or 1)))
    end
end

function TraitsPage:RefreshTraitEntries()
    local rows = self:GetSelectedCategoryTraits()
    local pageCount = getTraitPageCount(#rows)
    if pageCount <= 0 then
        self.CurrentTraitPage = 1
    else
        self.CurrentTraitPage = math.max(1, math.min(math.floor(tonumber(self.CurrentTraitPage) or 1), pageCount))
    end

    local pageRows = sliceTraitPageRows(rows, self.CurrentTraitPage)
    self.VisibleTraitRows = pageRows
    self:LayoutTraitEntries()
    self:RefreshTraitPageControls(#rows, pageCount)

    if self.EntryListFrame and self.EntryListFrame.Show and self.EntryListFrame.Hide then
        if #pageRows > 0 then
            self.EntryListFrame:Show()
        else
            self.EntryListFrame:Hide()
        end
    end

    for index = 1, TRAIT_ENTRIES_PER_PAGE do
        local entry = self.TraitEntries and self.TraitEntries[index] or nil
        local row = pageRows[index]
        if entry then
            if row then
                local icon = tostring(row.icon or "")
                local displayName = row.name or "Unknown Trait"
                if row.sourceType == "consumable" and (tonumber(row.count) or 0) > 1 then
                    displayName = ("%s x%d"):format(displayName, tonumber(row.count) or 0)
                end
                if icon == "" then
                    icon = DEFAULT_ICON
                end

                entry:SetIcon(icon)
                entry:SetSpellName(displayName)
                entry:SetEnabled(row.isLocked ~= true or row.isActive == true)
                entry:SetTooltip(function(owner)
                    local currentRow = entry.traitRow
                    if not currentRow then
                        return nil
                    end

                    return buildTraitTooltip(currentRow, owner)
                end)
                if row.isMissing == true then
                    entry:SetBorderColor(0.8, 0.22, 0.22, 1)
                elseif row.sourceType == "consumable" and row.isActive == true then
                    entry:SetBorderColor(0.94, 0.74, 0.22, 1)
                elseif row.sourceType == "consumable" then
                    entry:SetBorderColor(0.22, 0.72, 0.62, 1)
                elseif row.sourceType == "equipment" then
                    entry:SetBorderColor(0.18, 0.9, 0.3, 1)
                elseif row.isLocked == true then
                    entry:SetBorderColor(0.38, 0.28, 0.48, 1)
                elseif row.isToggleable == true and row.isActive == true then
                    entry:SetBorderColor(0.94, 0.74, 0.22, 1)
                elseif row.isToggleable == true then
                    entry:SetBorderColor(0.42, 0.46, 0.52, 1)
                elseif row.isAutoGranted == true then
                    entry:SetBorderColor(0.26, 0.58, 0.94, 1)
                elseif row.isActive == true then
                    entry:SetBorderColor(0.94, 0.74, 0.22, 1)
                else
                    entry:SetBorderColor(0.42, 0.46, 0.52, 1)
                end
                entry.traitRow = row
                entry:GetFrame():Show()
            else
                entry:SetIcon(DEFAULT_ICON)
                entry:SetSpellName("")
                entry:SetEnabled(false)
                entry:SetTooltip(nil)
                entry:SetBorderColor(0.24, 0.24, 0.28, 1)
                entry.traitRow = nil
                entry:GetFrame():Hide()
            end
        end
    end

    self.LastGridEmptyStateText = ""
    if self.GridEmptyText and self.GridEmptyText.SetText then
        if not self.SelectedCategoryKey then
            self.LastGridEmptyStateText = "No traits available."
        elseif #rows == 0 then
            self.LastGridEmptyStateText = self.SelectedCategoryKey == "consumable"
                and "No consumable traits available."
                or "No traits in this category."
        end
        self.GridEmptyText:SetText(self.LastGridEmptyStateText)
    end

    self.lastRenderedRevision = self:GetRevisionTuple()
    self.dirty = false
end

function TraitsPage:PreviousTraitPage()
    if (tonumber(self.CurrentTraitPage) or 1) <= 1 then
        return false
    end

    self.CurrentTraitPage = math.max(1, (tonumber(self.CurrentTraitPage) or 1) - 1)
    self:RefreshTraitEntries()
    return true
end

function TraitsPage:NextTraitPage()
    local rows = self:GetSelectedCategoryTraits()
    local pageCount = getTraitPageCount(#rows)
    if pageCount <= 0 or (tonumber(self.CurrentTraitPage) or 1) >= pageCount then
        return false
    end

    self.CurrentTraitPage = math.min(pageCount, (tonumber(self.CurrentTraitPage) or 1) + 1)
    self:RefreshTraitEntries()
    return true
end

function TraitsPage:Build(parent, owner)
    self.owner = owner
    if self.frame then
        return self.frame
    end

    self.frame = CreateFrame("Frame", "RPEProfileTraitsPage", parent)
    self.frame:SetAllPoints(parent)
    self.TraitEntries = {}
    self.CurrentTraitPage = 1

    self.RootLayout = UI.CreateLayout(UI.HorizontalLayoutGroup, self.frame, "RPEProfileTraitsRootLayout", {
        spacing = 8,
        fitChildrenWidth = true,
        fitChildrenHeight = true,
    })
    UI.Utils.AnchorFill(self.RootLayout, self.frame, 0, 0, 0, 0)

    self.CategoryPanel = UI.CreatePanel(self.RootLayout:GetFrame(), "RPEProfileTraitsCategoryPanel", {
        width = CATEGORY_PANEL_WIDTH,
        height = 304,
        contentInset = 2,
        showBorder = false,
    })
    self.RootLayout:AddChild(self.CategoryPanel)

    self.GridPanel = UI.CreatePanel(self.RootLayout:GetFrame(), "RPEProfileTraitsGridPanel", {
        width = 340,
        height = 304,
        expandWidth = true,
        weight = 1,
        contentInset = 0,
        showBorder = false,
    })
    self.RootLayout:AddChild(self.GridPanel)

    self.CategoryList = UI.ScrollLayout:New({
        name = "RPEProfileTraitsCategoryList",
        width = CATEGORY_PANEL_WIDTH - 4,
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
    self.CategoryList:SetParent(self.CategoryPanel:GetContentFrame())
    self.CategoryList:SetRowRenderer(function(row, item)
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
                if button == "LeftButton" and item and item.key then
                    self.SelectedCategoryKey = item.key
                    self.CurrentTraitPage = 1
                    self:Refresh()
                end
            end)

            local isSelected = item and tostring(item.key or "") == tostring(self.SelectedCategoryKey or "")
            if row.entryBackground and row.entryBackground.SetColorTexture then
                local token = isSelected and "list.rowHover" or "list.rowBackground"
                local color = UI.ResolveColor(nil, token)
                row.entryBackground:SetColorTexture(color.r or 0.08, color.g or 0.09, color.b or 0.11, color.a or 0.85)
            end
        end
    end)
    self.CategoryList:Create()
    UI.Utils.AnchorFill(self.CategoryList, self.CategoryPanel:GetContentFrame(), 0, 0, 0, 0)

    self.CategoryEmptyText = UI.CreateText(self.CategoryPanel:GetContentFrame(), "RPEProfileTraitsCategoryEmptyText", "", {
        width = 140,
        height = 40,
        justifyH = "CENTER",
        wordWrap = true,
        textColor = UI.ResolveColor(nil, "text.secondary"),
    })
    self.CategoryEmptyText:GetFrame():SetPoint("CENTER", self.CategoryPanel:GetContentFrame(), "CENTER", 0, 0)

    self.GridTitle = UI.CreateText(self.GridPanel:GetContentFrame(), "RPEProfileTraitsGridTitle", "Traits", {
        width = 300,
        height = 18,
        justifyH = "LEFT",
    })
    self.GridTitle:GetFrame():SetPoint("TOPLEFT", self.GridPanel:GetContentFrame(), "TOPLEFT", GRID_PADDING, -2)

    self.GridHintText = UI.CreateText(self.GridPanel:GetContentFrame(), "RPEProfileTraitsGridHintText", "", {
        width = 320,
        height = 18,
        justifyH = "LEFT",
        wordWrap = true,
        textColor = UI.ResolveColor(nil, "text.secondary"),
    })
    self.GridHintText:GetFrame():SetPoint("TOPLEFT", self.GridTitle:GetFrame(), "BOTTOMLEFT", 0, -2)

    self.GridHost = CreateFrame("Frame", "RPEProfileTraitsGridHost", self.GridPanel:GetContentFrame())
    self.GridHost:SetPoint("TOPLEFT", self.GridPanel:GetContentFrame(), "TOPLEFT", 0, -36)
    self.GridHost:SetPoint("BOTTOMRIGHT", self.GridPanel:GetContentFrame(), "BOTTOMRIGHT", 0, 0)

    self.EntryContentFrame = CreateFrame("Frame", "RPEProfileTraitsEntryContent", self.GridHost)
    self.EntryContentFrame:SetPoint("TOPLEFT", self.GridHost, "TOPLEFT", 0, 0)
    self.EntryContentFrame:SetPoint("TOPRIGHT", self.GridHost, "TOPRIGHT", 0, 0)
    self.EntryContentFrame:SetPoint("BOTTOMLEFT", self.GridHost, "BOTTOMLEFT", 0, TRAITBOOK_NAV_HEIGHT)
    self.EntryContentFrame:SetPoint("BOTTOMRIGHT", self.GridHost, "BOTTOMRIGHT", 0, TRAITBOOK_NAV_HEIGHT)

    self.EntryListFrame = CreateFrame("Frame", "RPEProfileTraitsEntryList", self.EntryContentFrame)
    self.EntryListFrame:SetPoint("TOP", self.EntryContentFrame, "TOP", 0, -TRAITBOOK_TOP_OFFSET)
    self.EntryListFrame:SetSize(1, 1)

    self.TraitPageNav = CreateFrame("Frame", "RPEProfileTraitsPageNav", self.GridHost)
    self.TraitPageNav:SetPoint("BOTTOMLEFT", self.GridHost, "BOTTOMLEFT", GRID_PADDING, 0)
    self.TraitPageNav:SetPoint("BOTTOMRIGHT", self.GridHost, "BOTTOMRIGHT", -GRID_PADDING, 0)
    self.TraitPageNav:SetHeight(TRAITBOOK_NAV_HEIGHT)

    self.GridEmptyText = UI.CreateText(self.GridHost, "RPEProfileTraitsGridEmptyText", "", {
        width = 180,
        height = 40,
        justifyH = "CENTER",
        wordWrap = true,
        textColor = UI.ResolveColor(nil, "text.secondary"),
    })
    self.GridEmptyText:GetFrame():SetPoint("CENTER", self.GridHost, "CENTER", 0, 0)

    self.TraitPageNextButton = UI.TextButton:New({
        name = "RPEProfileTraitsPageNextButton",
        width = 22,
        height = 18,
        text = ">",
        fontSize = 11,
        border = false,
    })
    self.TraitPageNextButton:SetParent(self.TraitPageNav)
    self.TraitPageNextButton:Create()
    self.TraitPageNextButton:SetScript("OnClick", function()
        self:NextTraitPage()
    end)
    self.TraitPageNextButton:GetFrame():SetPoint("RIGHT", self.TraitPageNav, "RIGHT", 0, 0)

    self.TraitPagePrevButton = UI.TextButton:New({
        name = "RPEProfileTraitsPagePrevButton",
        width = 22,
        height = 18,
        text = "<",
        fontSize = 11,
        border = false,
    })
    self.TraitPagePrevButton:SetParent(self.TraitPageNav)
    self.TraitPagePrevButton:Create()
    self.TraitPagePrevButton:SetScript("OnClick", function()
        self:PreviousTraitPage()
    end)
    self.TraitPagePrevButton:GetFrame():SetPoint("RIGHT", self.TraitPageNextButton:GetFrame(), "LEFT", -4, 0)

    self.TraitPageLabel = UI.CreateText(self.TraitPageNav, "RPEProfileTraitsPageLabel", "Page 0 / 0", {
        width = 96,
        height = 18,
        justifyH = "RIGHT",
        textColor = UI.ResolveColor(nil, "text.secondary"),
    })
    self.TraitPageLabel:GetFrame():SetPoint("RIGHT", self.TraitPagePrevButton:GetFrame(), "LEFT", -8, 0)

    for index = 1, TRAIT_ENTRIES_PER_PAGE do
        self:CreateTraitEntry(index, self.EntryListFrame)
    end

    return self.frame
end

function TraitsPage:Refresh()
    if not self.frame then
        return nil
    end

    if not self:IsVisible() then
        self:MarkDirty()
        return self.frame
    end

    if self.refreshInProgress then
        return self.frame
    end

    self.refreshInProgress = true

    local categoryRows, traitRows = buildCategoryRows()
    self.CategoryRows = categoryRows
    self.AllTraitRows = traitRows
    self:EnsureCategorySelection(categoryRows)

    if self.CategoryList and self.CategoryList.SetItems then
        self.CategoryList:SetItems(categoryRows)
    end

    if self.CategoryEmptyText and self.CategoryEmptyText.SetText then
        self.CategoryEmptyText:SetText(#categoryRows == 0 and "No traits available." or "")
    end

    local title = "Traits"
    for index = 1, #categoryRows do
        local row = categoryRows[index]
        if tostring(row.key or "") == tostring(self.SelectedCategoryKey or "") then
            title = row.name or title
            break
        end
    end

    if self.GridTitle and self.GridTitle.SetText then
        self.GridTitle:SetText(title)
    end

    refreshGridHeaderLayout(self)
    if self.GridHintText and self.GridHintText.SetText then
        self.GridHintText:SetText(buildTraitHeaderText(self.SelectedCategoryKey, self:GetSelectedCategoryTraits()))
    end

    self:RefreshTraitEntries()
    self.lastRenderedRevision = self:GetRevisionTuple()
    self.dirty = false
    self.refreshInProgress = false
    return self.frame
end

return TraitsPage
