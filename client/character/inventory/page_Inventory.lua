local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Client.UI = Addon.Client.UI or {}
Addon.Client.UI.Inventory = Addon.Client.UI.Inventory or {}

local InventoryUI = Addon.Client.UI.Inventory
local Inventory = Addon.Client.Inventory or {}
local ItemUse = Addon.Client.ItemUse or {}
local Database = Addon.Internal and Addon.Internal.Database or {}
local Profile = Addon.Internal and Addon.Internal.Profile or {}
local Equipment = Profile.Equipment or {}
local Runtime = Addon.Internal and Addon.Internal.Runtime or {}
local UI = Addon.UI or {}
local TooltipBuilders = Addon.Client.UI and Addon.Client.UI.Tooltips or {}

local function startTiming(label, thresholdMs, context)
    local timings = Addon.Debug and Addon.Debug.Timings or nil
    if timings and type(timings.Start) == "function" then
        if type(timings.IsEnabled) == "function" and not timings:IsEnabled() then
            return nil
        end
        return timings:Start(label, {
            thresholdMs = thresholdMs,
            context = context,
        })
    end
    return nil
end

local function stopTiming(timer, cardinality)
    if not timer then
        return
    end

    local timings = Addon.Debug and Addon.Debug.Timings or nil
    if timings and type(timings.Stop) == "function" then
        timings:Stop(timer, { cardinality = cardinality })
    end
end

local InventoryGridPage = {}
InventoryGridPage.__index = InventoryGridPage

local GRID_COLUMNS = 8
local GRID_ROWS = 6
local SLOT_SIZE = 28
local SLOT_SPACING = 4
local GRID_PADDING = 4
local SEARCH_ROW_HEIGHT = 18
local FILTER_ROW_HEIGHT = 18
local TOOLBAR_ROW_SPACING = 4
local TOOLBAR_HEIGHT = SEARCH_ROW_HEIGHT + FILTER_ROW_HEIGHT + TOOLBAR_ROW_SPACING
local TOOLBAR_TO_GRID_SPACING = 4
local SEARCH_LABEL_WIDTH = 38
local SEARCH_BUTTON_WIDTH = 40
local SEARCH_LABEL_TO_INPUT_SPACING = 4
local SEARCH_CLEAR_BUTTON_WIDTH = 32
local SEARCH_BUTTON_TO_CLEAR_SPACING = 4
local SEARCH_INPUT_TO_BUTTON_SPACING = 4
local TOTAL_SLOTS = GRID_COLUMNS * GRID_ROWS
local DEFAULT_ICON = "Interface\\Icons\\INV_Misc_QuestionMark"
local CURRENCY_PANEL_COLLAPSED_HEIGHT = 22
local CURRENCY_PANEL_EXPANDED_HEIGHT = 108
local GRID_TO_CURRENCY_PANEL_SPACING = 4
local GRID_WIDTH = (GRID_PADDING * 2) + (GRID_COLUMNS * SLOT_SIZE) + ((GRID_COLUMNS - 1) * SLOT_SPACING)
local GRID_HEIGHT = (GRID_PADDING * 2) + (GRID_ROWS * SLOT_SIZE) + ((GRID_ROWS - 1) * SLOT_SPACING)

local QUALITY_LABELS = {
    poor = "Poor",
    common = "Common",
    uncommon = "Uncommon",
    rare = "Rare",
    epic = "Epic",
    legendary = "Legendary",
}

local ITEM_TYPE_LABELS = {
    weapon = "Weapon",
    armor = "Armor",
    tool = "Tool",
    consumable = "Consumable",
    material = "Material",
    modification = "Modification",
    none = "Item",
}

local function ensureSelectionBuckets()
    return {
        state = {},
        dataset = {},
        quality = {},
        itemType = {},
        tag = {},
    }
end

local function trimString(value)
    return tostring(value or ""):gsub("^%s+", ""):gsub("%s+$", "")
end

local function normalizeSearchToken(value)
    return string.lower(trimString(value))
end

local function getRuntimeRevision(domain)
    if type(Runtime) == "table" and type(Runtime.GetRevision) == "function" then
        return math.max(0, math.floor(tonumber(Runtime:GetRevision(domain)) or 0))
    end

    return 0
end

local function getConfigurationRevision()
    return math.max(0, math.floor(tonumber(Addon.Internal and Addon.Internal.ConfigurationRevision) or 0))
end

local function buildFilterSignature(values)
    local normalized = {}
    for index = 1, #(values or {}) do
        normalized[#normalized + 1] = tostring(values[index] or "")
    end

    table.sort(normalized)
    return table.concat(normalized, "\31")
end

local function revisionTuplesEqual(left, right)
    if type(left) ~= "table" or type(right) ~= "table" then
        return false
    end

    return left.inventoryRevision == right.inventoryRevision
        and left.configurationRevision == right.configurationRevision
        and left.currencyRevision == right.currencyRevision
        and left.searchQuery == right.searchQuery
        and left.selectedFilters == right.selectedFilters
        and left.categoryKey == right.categoryKey
end

local function dataRevisionsEqual(left, right)
    if type(left) ~= "table" or type(right) ~= "table" then
        return false
    end

    return left.inventoryRevision == right.inventoryRevision
        and left.configurationRevision == right.configurationRevision
        and left.currencyRevision == right.currencyRevision
end

local function isCurrencyOnlyChange(previous, current)
    if type(previous) ~= "table" or type(current) ~= "table" then
        return false
    end

    return previous.inventoryRevision == current.inventoryRevision
        and previous.configurationRevision == current.configurationRevision
        and previous.searchQuery == current.searchQuery
        and previous.selectedFilters == current.selectedFilters
        and previous.categoryKey == current.categoryKey
        and previous.currencyRevision ~= current.currencyRevision
end

local function getQualityLabel(quality)
    return QUALITY_LABELS[tostring(quality or "common")] or tostring(quality or "Common")
end

local function getItemTypeLabel(itemType)
    return ITEM_TYPE_LABELS[tostring(itemType or "none")] or tostring(itemType or "Item")
end

local function appendSortedItems(itemsByValue)
    local ordered = {}
    for _, entry in pairs(itemsByValue or {}) do
        ordered[#ordered + 1] = entry
    end

    table.sort(ordered, function(left, right)
        local leftLabel = string.lower(tostring(left.label or ""))
        local rightLabel = string.lower(tostring(right.label or ""))
        if leftLabel == rightLabel then
            return tostring(left.value or "") < tostring(right.value or "")
        end

        return leftLabel < rightLabel
    end)

    return ordered
end

local function buildInventoryEquipOptions(slotKey, scope)
    local profileWindowModule = Addon.Client and Addon.Client.UI and Addon.Client.UI.Profile and Addon.Client.UI.Profile.Window or nil
    local profileWindow = profileWindowModule and profileWindowModule.Get and profileWindowModule:Get() or nil
    if not profileWindow then
        return {
            activeTabKey = "equipment",
            scope = scope or "character",
            slotKey = slotKey,
        }
    end

    local equipmentPage = profileWindow.equipmentStatsPage or nil
    local activeTabKey = profileWindow.GetActiveTabKey and profileWindow:GetActiveTabKey() or "equipment"
    local activeScope = equipmentPage and equipmentPage.GetActiveEquipmentScope and equipmentPage:GetActiveEquipmentScope() or "character"

    return {
        activeTabKey = activeTabKey,
        scope = scope or activeScope,
        slotKey = slotKey or profileWindow.SelectedSlotKey,
    }
end

local function buildEquipSlotActions(resolved)
    local item = resolved and resolved.item or nil
    if type(item) ~= "table" or type(Profile.GetEquipmentLayoutByScope) ~= "function" then
        return {}
    end

    if type(Equipment.CanEquipItemInScope) == "function" and not Equipment.CanEquipItemInScope("character", item) then
        return {}
    end

    local actions = {}
    local layout = Profile.GetEquipmentLayoutByScope("character") or {}
    for index = 1, #(layout.entries or {}) do
        local entry = layout.entries[index]
        local fits = Equipment.DoesItemFitLayoutEntry and Equipment.DoesItemFitLayoutEntry(item, entry) or false
        if fits and entry and entry.slotKey then
            local slotLabel = Equipment.PrettySlotLabel and Equipment.PrettySlotLabel(entry.slotKey) or tostring(entry.name or entry.slotKey)
            actions[#actions + 1] = {
                label = "Equip: " .. slotLabel,
                value = {
                    action = "equip",
                    scope = "character",
                    slotKey = entry.slotKey,
                },
            }
        end
    end

    return actions
end

local function selectionCount(selectionSet)
    local count = 0
    for _ in pairs(selectionSet or {}) do
        count = count + 1
    end

    return count
end

local function buildTooltipText(resolved)
    local datasetName = resolved.dataset and Database.GetDatasetDisplayName and Database.GetDatasetDisplayName(resolved.dataset) or "Unknown Dataset"
    local builder = TooltipBuilders and TooltipBuilders.Item

    if builder and builder.Build then
        return builder:Build(resolved.item or {
            id = resolved.itemId,
            name = "Unknown Item",
        }, {
            dataset = resolved.dataset,
            datasetId = resolved.datasetId,
            datasetName = datasetName,
            itemId = resolved.itemId,
            isActive = resolved.isActive,
            isMissing = resolved.isMissing,
            soulbound = resolved.soulbound == true,
            modifications = resolved.modifications,
            quantity = resolved.quantity,
            stackIdentity = resolved.stackIdentity,
        })
    end

    return {
        title = resolved.item and tostring(resolved.item.name or "Unknown Item") or "Unknown Item",
        lines = {
            ("Dataset: %s"):format(datasetName),
            ("Item ID: %s"):format(tostring(resolved.itemId or "")),
        },
    }
end

local function createInventoryGridPage(config)
    local frameName = tostring(config and config.frameName or "RPEInventoryPage")
    local pageLabel = trimString(config and config.pageLabel or "items")
    local slotNamePrefix = tostring(config and config.slotNamePrefix or (frameName .. "Slot"))

    return setmetatable({
        categoryKey = tostring(config and config.categoryKey or "general"),
        pageLabel = pageLabel ~= "" and pageLabel or "items",
        frameName = frameName,
        toolbarPanelName = tostring(config and config.toolbarPanelName or (frameName .. "ToolbarPanel")),
        searchLabelName = tostring(config and config.searchLabelName or (frameName .. "SearchLabel")),
        searchInputName = tostring(config and config.searchInputName or (frameName .. "SearchInput")),
        searchButtonName = tostring(config and config.searchButtonName or (frameName .. "SearchButton")),
        clearButtonName = tostring(config and config.clearButtonName or (frameName .. "ClearButton")),
        filterDropdownName = tostring(config and config.filterDropdownName or (frameName .. "FilterDropdown")),
        gridPanelName = tostring(config and config.gridPanelName or (frameName .. "GridPanel")),
        emptyTextName = tostring(config and config.emptyTextName or (frameName .. "EmptyText")),
        contextMenuName = tostring(config and config.contextMenuName or (frameName .. "ContextMenu")),
        slotNamePrefix = slotNamePrefix,
        showEmptyOverlay = config == nil or config.showEmptyOverlay ~= false,
        showCurrencyPanel = config == nil or config.showCurrencyPanel ~= false,
        draftSearchQuery = "",
        appliedSearchQuery = "",
        frame = nil,
        panel = nil,
        ToolbarPanel = nil,
        SearchLabel = nil,
        SearchInput = nil,
        SearchButton = nil,
        SearchClearButton = nil,
        FilterDropdown = nil,
        EmptyText = nil,
        slots = {},
        ItemContextMenu = nil,
        ContextMenuResolvedItem = nil,
        CurrencyPanel = nil,
        windowController = nil,
        dirty = true,
        lastRenderedRevision = nil,
        refreshInProgress = false,
    }, InventoryGridPage)
end

InventoryUI.CreateInventoryGridPage = createInventoryGridPage

function InventoryGridPage:SetWindowController(windowController)
    self.windowController = windowController
end

function InventoryGridPage:IsVisible()
    if not self.frame or not self.frame.IsShown or not self.frame:IsShown() then
        return false
    end

    if self.windowController and self.windowController.IsVisible then
        return self.windowController:IsVisible()
    end

    return true
end

function InventoryGridPage:MarkDirty()
    self.dirty = true
    return self
end

function InventoryGridPage:GetCurrencyPanelHeight()
    if self.CurrencyPanel and self.CurrencyPanel.GetCurrentHeight then
        return self.CurrencyPanel:GetCurrentHeight()
    end

    if self.showCurrencyPanel == false then
        return 0
    end

    return CURRENCY_PANEL_COLLAPSED_HEIGHT
end

function InventoryGridPage:GetSelectedFilterValues()
    if self.FilterDropdown and self.FilterDropdown.GetSelectedValues then
        return self.FilterDropdown:GetSelectedValues()
    end

    return {}
end

function InventoryGridPage:GetSearchQuery()
    return normalizeSearchToken(self.appliedSearchQuery)
end

function InventoryGridPage:GetRevisionTuple()
    return {
        inventoryRevision = getRuntimeRevision("InventoryRevision"),
        configurationRevision = getConfigurationRevision(),
        currencyRevision = self.CurrencyPanel and getRuntimeRevision("CurrencyRevision") or 0,
        searchQuery = self:GetSearchQuery(),
        selectedFilters = buildFilterSignature(self:GetSelectedFilterValues()),
        categoryKey = self.categoryKey,
    }
end

function InventoryGridPage:GetDraftSearchQuery()
    if self.SearchInput and self.SearchInput.GetText then
        self.draftSearchQuery = self.SearchInput:GetText()
    end

    return normalizeSearchToken(self.draftSearchQuery)
end

function InventoryGridPage:ApplySearchQuery(query)
    self.appliedSearchQuery = tostring(query or self.draftSearchQuery or "")
    return self.appliedSearchQuery
end

function InventoryGridPage:RefreshSearchButtons()
    local hasDraftQuery = self:GetDraftSearchQuery() ~= ""
    local hasAppliedQuery = self:GetSearchQuery() ~= ""
    local searchChanged = normalizeSearchToken(self.draftSearchQuery) ~= normalizeSearchToken(self.appliedSearchQuery)

    if self.SearchButton and self.SearchButton.SetEnabled then
        self.SearchButton:SetEnabled(hasDraftQuery or searchChanged or hasAppliedQuery)
    end
    if self.SearchClearButton and self.SearchClearButton.SetEnabled then
        self.SearchClearButton:SetEnabled(hasDraftQuery or hasAppliedQuery)
    end
end

function InventoryGridPage:MatchesCategory(resolved)
    local itemType = resolved and tostring(resolved.itemType or "none") or ""

    if self.categoryKey == "consumable" then
        return itemType == "consumable"
    end

    if self.categoryKey == "reagent" then
        return itemType == "material"
    end

    return itemType ~= "consumable" and itemType ~= "material"
end

function InventoryGridPage:GetCategoryDisplayItems(snapshot)
    local resolvedItems = snapshot or {}
    local filtered = {}

    for index = 1, #resolvedItems do
        local resolved = resolvedItems[index]
        if resolved and self:MatchesCategory(resolved) then
            filtered[#filtered + 1] = resolved
        end
    end

    return filtered
end

function InventoryGridPage:BuildFilterItems(categoryItems)
    local resolvedItems = categoryItems or {}
    local datasetItems = {}
    local qualityItems = {}
    local itemTypeItems = {}
    local tagItems = {}

    for index = 1, #resolvedItems do
        local resolved = resolvedItems[index]
        local dataset = resolved and resolved.dataset or nil

        if dataset and dataset.id then
            datasetItems[dataset.id] = {
                label = Database.GetDatasetDisplayName and Database.GetDatasetDisplayName(dataset) or tostring(dataset.name or dataset.id),
                value = "dataset:" .. tostring(dataset.id),
            }
        elseif resolved and resolved.datasetId then
            datasetItems.__missing__ = {
                label = "Missing Sources",
                value = "dataset:__missing__",
            }
        end

        if resolved and resolved.item then
            qualityItems[tostring(resolved.quality or "common")] = {
                label = getQualityLabel(resolved.quality),
                value = "quality:" .. tostring(resolved.quality or "common"),
            }
            itemTypeItems[tostring(resolved.itemType or "none")] = {
                label = getItemTypeLabel(resolved.itemType),
                value = "itemType:" .. tostring(resolved.itemType or "none"),
            }

            local tags = type(resolved.tags) == "table" and resolved.tags or {}
            for tagIndex = 1, #tags do
                local tag = tostring(tags[tagIndex] or "")
                if tag ~= "" then
                    tagItems[tag] = {
                        label = tag,
                        value = "tag:" .. tag,
                    }
                end
            end
        end
    end

    local items = {
        {
            label = "State",
            value = "root:state",
            children = {
                { label = "Active Sources", value = "state:active" },
                { label = "Inactive Sources", value = "state:inactive" },
                { label = "Missing Sources", value = "state:missing" },
            },
        },
    }

    local datasets = appendSortedItems(datasetItems)
    if #datasets > 0 then
        items[#items + 1] = {
            label = "Dataset",
            value = "root:dataset",
            children = datasets,
        }
    end

    local qualities = appendSortedItems(qualityItems)
    if #qualities > 0 then
        items[#items + 1] = {
            label = "Quality",
            value = "root:quality",
            children = qualities,
        }
    end

    local itemTypes = appendSortedItems(itemTypeItems)
    if #itemTypes > 0 then
        items[#items + 1] = {
            label = "Type",
            value = "root:itemType",
            children = itemTypes,
        }
    end

    local tags = appendSortedItems(tagItems)
    if #tags > 0 then
        items[#items + 1] = {
            label = "Tags",
            value = "root:tag",
            children = tags,
        }
    end

    return items
end

function InventoryGridPage:BuildFilterSelection()
    local selectedValues = self:GetSelectedFilterValues()
    local selection = ensureSelectionBuckets()

    for index = 1, #selectedValues do
        local token = tostring(selectedValues[index] or "")
        local category, value = token:match("^([^:]+)%:(.+)$")
        if category and value and selection[category] then
            selection[category][value] = true
        end
    end

    return selection
end

function InventoryGridPage:PassesFilters(resolved, selection)
    selection = selection or ensureSelectionBuckets()

    if selectionCount(selection.state) > 0 then
        local matchesState = false
        if selection.state.active and resolved.isActive and not resolved.isMissing then
            matchesState = true
        end
        if selection.state.inactive and not resolved.isActive then
            matchesState = true
        end
        if selection.state.missing and resolved.isMissing then
            matchesState = true
        end
        if not matchesState then
            return false
        end
    end

    if selectionCount(selection.dataset) > 0 then
        local datasetId = resolved.dataset and tostring(resolved.dataset.id or "") or "__missing__"
        if not selection.dataset[datasetId] then
            return false
        end
    end

    if selectionCount(selection.quality) > 0 then
        local quality = resolved.item and tostring(resolved.quality or "common") or ""
        if not selection.quality[quality] then
            return false
        end
    end

    if selectionCount(selection.itemType) > 0 then
        local itemType = resolved.item and tostring(resolved.itemType or "none") or ""
        if not selection.itemType[itemType] then
            return false
        end
    end

    if selectionCount(selection.tag) > 0 then
        local tags = type(resolved.tags) == "table" and resolved.tags or {}
        local matchesTag = false
        for index = 1, #tags do
            if selection.tag[tostring(tags[index] or "")] then
                matchesTag = true
                break
            end
        end

        if not matchesTag then
            return false
        end
    end

    return true
end

function InventoryGridPage:BuildSearchIndex(resolved)
    return resolved and resolved.normalizedSearchText or ""
end

function InventoryGridPage:PassesSearch(resolved, searchQuery)
    if searchQuery == "" then
        return true
    end

    return string.find(self:BuildSearchIndex(resolved), searchQuery, 1, true) ~= nil
end

function InventoryGridPage:GetFilteredDisplayItems(categoryItems)
    local resolvedItems = categoryItems or {}
    local selection = self:BuildFilterSelection()
    local searchQuery = self:GetSearchQuery()
    local filtered = {}
    local matches = {}
    local others = {}
    local searchMatches = {}

    for index = 1, #resolvedItems do
        local resolved = resolvedItems[index]
        if resolved and self:PassesFilters(resolved, selection) then
            local searchMatched = self:PassesSearch(resolved, searchQuery)
            searchMatches[resolved] = searchMatched
            if searchQuery == "" or searchMatched then
                matches[#matches + 1] = resolved
            else
                others[#others + 1] = resolved
            end
        end
    end

    for index = 1, #matches do
        filtered[#filtered + 1] = matches[index]
    end
    for index = 1, #others do
        filtered[#filtered + 1] = others[index]
    end

    return filtered, searchMatches
end

function InventoryGridPage:CreateSlot(index, parent)
    local slot = UI.ObjectSlot:New({
        name = ("%s%d"):format(self.slotNamePrefix, index),
        width = SLOT_SIZE,
        height = SLOT_SIZE,
        size = SLOT_SIZE,
        iconTexture = DEFAULT_ICON,
        border = false,
    })
    slot:SetParent(parent)
    slot:Create()

    local frame = slot:GetFrame()
    local row = math.floor((index - 1) / GRID_COLUMNS)
    local column = (index - 1) % GRID_COLUMNS
    frame:SetPoint(
        "TOPLEFT",
        parent,
        "TOPLEFT",
        GRID_PADDING + (column * (SLOT_SIZE + SLOT_SPACING)),
        -(GRID_PADDING + (row * (SLOT_SIZE + SLOT_SPACING)))
    )

    frame:HookScript("OnMouseUp", function(_, button)
        local resolved = slot.resolvedItem
        if button == "RightButton" and resolved then
            self:ShowItemContextMenu(frame, resolved)
        elseif self.ItemContextMenu and self.ItemContextMenu.HideMenus then
            self.ItemContextMenu:HideMenus()
        end
    end)

    self.slots[index] = slot
    return slot
end

function InventoryGridPage:EnsureItemContextMenu()
    if self.ItemContextMenu then
        return self.ItemContextMenu
    end

    self.ItemContextMenu = UI.ContextMenu:New({
        name = self.contextMenuName,
        width = 160,
        panelWidth = 160,
        visibleRows = 6,
        rowHeight = 18,
        border = false,
        onItemInvoked = function(item, menu)
            local actionValue = item and item.value or nil
            local action = type(actionValue) == "table" and actionValue.action or actionValue
            local resolved = self.ContextMenuResolvedItem
            if not resolved then
                return
            end

            if action == "use" and resolved.sourceIndex and resolved.stackIdentity and ItemUse.UseInventoryItem then
                ItemUse:UseInventoryItem(resolved.sourceIndex, resolved.stackIdentity)
            elseif action == "equip" and resolved.sourceIndex and Inventory.EquipItem then
                Inventory.EquipItem(resolved.sourceIndex, buildInventoryEquipOptions(
                    type(actionValue) == "table" and actionValue.slotKey or nil,
                    type(actionValue) == "table" and actionValue.scope or nil
                ))
            elseif action == "modify" and resolved.sourceIndex then
                local modificationWindow = InventoryUI and InventoryUI.ModificationWindow or nil
                if modificationWindow and modificationWindow.Get then
                    local instance = modificationWindow:Get()
                    if instance and instance.ShowForSlot then
                        instance:ShowForSlot(resolved.sourceIndex)
                    end
                end
            elseif action == "delete" and resolved.sourceIndex and Inventory.DeleteItem then
                Inventory.DeleteItem(resolved.sourceIndex)
            end

            if menu and menu.HideMenus then
                menu:HideMenus()
            end
        end,
    })
    self.ItemContextMenu:SetParent(self.frame or UIParent)
    self.ItemContextMenu:Create()
    return self.ItemContextMenu
end

function InventoryGridPage:ShowItemContextMenu(anchorFrame, resolved)
    if not anchorFrame or not resolved then
        return
    end

    local menu = self:EnsureItemContextMenu()
    self.ContextMenuResolvedItem = resolved
    local itemType = resolved and tostring(resolved.itemType or "none") or "none"
    local isEquipmentItem = itemType == "weapon" or itemType == "armor"
    local canUse = resolved.isMissing ~= true
        and resolved.isActive == true
        and itemType == "consumable"
        and resolved.item ~= nil
        and trimString(resolved.item.useSpellRef) ~= ""
        and resolved.sourceIndex ~= nil
        and trimString(resolved.stackIdentity) ~= ""
        and ItemUse.UseInventoryItem ~= nil
    local canEquip = resolved.isMissing ~= true
        and resolved.isActive == true
        and isEquipmentItem
        and resolved.sourceIndex ~= nil
        and Profile
        and Profile.EquipInventoryItem ~= nil
    local canModify = resolved.isMissing ~= true
        and resolved.isActive == true
        and isEquipmentItem
        and resolved.sourceIndex ~= nil

    local items = {}
    if canUse then
        items[#items + 1] = {
            label = "Use",
            value = "use",
        }
    end
    if canEquip then
        local equipActions = buildEquipSlotActions(resolved)
        for index = 1, #equipActions do
            items[#items + 1] = equipActions[index]
        end
    end
    if canModify then
        items[#items + 1] = {
            label = "Modify",
            value = "modify",
        }
    end
    items[#items + 1] = {
        label = "Delete",
        value = "delete",
    }

    menu:SetItems(items)
    menu:ShowAt(anchorFrame)
end

function InventoryGridPage:Build(parent)
    if self.frame then
        return self.frame
    end

    self.frame = CreateFrame("Frame", self.frameName, parent)
    self.frame:SetAllPoints(parent)
    self.slots = {}

    self.ToolbarPanel = UI.CreatePanel(self.frame, self.toolbarPanelName, {
        width = GRID_WIDTH,
        height = TOOLBAR_HEIGHT,
        contentInset = 0,
        showBorder = false,
    })

    if self.showCurrencyPanel ~= false and UI.CurrencyPanel and UI.CurrencyPanel.New then
        self.CurrencyPanel = UI.CurrencyPanel:New({
            name = self.frameName .. "CurrencyPanel",
            width = GRID_WIDTH,
            height = CURRENCY_PANEL_EXPANDED_HEIGHT,
            collapsedHeight = CURRENCY_PANEL_COLLAPSED_HEIGHT,
            visibleRows = 6,
            rowHeight = 16,
            onHeightChanged = function()
                if self.windowController and self.windowController.RefreshWindowLayout then
                    self.windowController:RefreshWindowLayout()
                end
            end,
        })
        self.CurrencyPanel:SetParent(self.frame)
        self.CurrencyPanel:Create()
        self.ToolbarPanel:GetFrame():SetPoint("TOP", self.frame, "TOP", 0, 0)
    else
        self.ToolbarPanel:GetFrame():SetPoint("TOP", self.frame, "TOP", 0, 0)
    end

    local toolbarContent = self.ToolbarPanel:GetContentFrame()

    self.SearchLabel = UI.CreateText(toolbarContent, self.searchLabelName, "Search:", {
        width = SEARCH_LABEL_WIDTH,
        height = SEARCH_ROW_HEIGHT,
        justifyH = "LEFT",
        textColor = UI.ResolveColor(nil, "text.secondary"),
    })
    self.SearchLabel:GetFrame():SetPoint("TOPLEFT", toolbarContent, "TOPLEFT", 0, 0)

    self.SearchClearButton = UI.CreateButton(toolbarContent, self.clearButtonName, "Clear", SEARCH_CLEAR_BUTTON_WIDTH, function()
        self.draftSearchQuery = ""
        self.appliedSearchQuery = ""
        if self.SearchInput and self.SearchInput.SetText then
            self.SearchInput:SetText("")
        end
        self:RefreshIfDirty()
    end, {
        height = SEARCH_ROW_HEIGHT,
        fontSize = 8,
    })
    self.SearchClearButton:GetFrame():SetPoint("TOPRIGHT", toolbarContent, "TOPRIGHT", 0, 0)

    self.SearchButton = UI.CreateButton(toolbarContent, self.searchButtonName, "Search", SEARCH_BUTTON_WIDTH, function()
        self:ApplySearchQuery(self.SearchInput and self.SearchInput.GetText and self.SearchInput:GetText() or self.draftSearchQuery)
        self:RefreshIfDirty()
    end, {
        height = SEARCH_ROW_HEIGHT,
        fontSize = 8,
    })
    self.SearchButton:GetFrame():SetPoint("TOPRIGHT", self.SearchClearButton:GetFrame(), "TOPLEFT", -SEARCH_BUTTON_TO_CLEAR_SPACING, 0)

    self.SearchInput = UI.CreateTextInput(toolbarContent, self.searchInputName, {
        width = GRID_WIDTH - SEARCH_LABEL_WIDTH - SEARCH_BUTTON_WIDTH - SEARCH_CLEAR_BUTTON_WIDTH - SEARCH_LABEL_TO_INPUT_SPACING - SEARCH_INPUT_TO_BUTTON_SPACING - SEARCH_BUTTON_TO_CLEAR_SPACING,
        height = SEARCH_ROW_HEIGHT,
        text = self.draftSearchQuery,
    })
    self.SearchInput:GetFrame():SetPoint("TOPLEFT", self.SearchLabel:GetFrame(), "TOPRIGHT", SEARCH_LABEL_TO_INPUT_SPACING, 0)
    self.SearchInput:GetFrame():SetPoint("TOPRIGHT", self.SearchButton:GetFrame(), "TOPLEFT", -SEARCH_INPUT_TO_BUTTON_SPACING, 0)
    self.SearchInput:SetScript("OnTextChanged", function(_, text)
        self.draftSearchQuery = tostring(text or "")
        self:RefreshSearchButtons()
    end)
    self.SearchInput:SetScript("OnEnterPressed", function(_, text)
        self:ApplySearchQuery(text)
        self:RefreshIfDirty()
    end)

    self.FilterDropdown = UI.CreateDropdown(toolbarContent, self.filterDropdownName, {
        width = GRID_WIDTH,
        height = FILTER_ROW_HEIGHT,
        multiSelect = true,
        showSelectionActions = true,
        popupWidth = 118,
        visibleRows = 10,
        placeholder = "Filter items...",
        items = {},
        onValueChanged = function()
            self:RefreshIfDirty()
        end,
    })
    self.FilterDropdown:GetFrame():SetPoint("TOPLEFT", toolbarContent, "TOPLEFT", 0, -(SEARCH_ROW_HEIGHT + TOOLBAR_ROW_SPACING))
    self.FilterDropdown:GetFrame():SetPoint("TOPRIGHT", toolbarContent, "TOPRIGHT", 0, -(SEARCH_ROW_HEIGHT + TOOLBAR_ROW_SPACING))

    self.panel = UI.CreatePanel(self.frame, self.gridPanelName, {
        width = GRID_WIDTH,
        height = GRID_HEIGHT,
        contentInset = 0,
        showBorder = false,
    })
    self.panel:GetFrame():SetPoint("TOP", self.ToolbarPanel:GetFrame(), "BOTTOM", 0, -TOOLBAR_TO_GRID_SPACING)

    if self.CurrencyPanel and self.CurrencyPanel.SetPoint then
        self.CurrencyPanel:SetPoint("TOP", self.panel:GetFrame(), "BOTTOM", 0, -GRID_TO_CURRENCY_PANEL_SPACING)
    end

    local content = self.panel:GetContentFrame()
    for index = 1, TOTAL_SLOTS do
        self:CreateSlot(index, content)
    end

    self.EmptyText = UI.CreateText(content, self.emptyTextName, "", {
        width = GRID_WIDTH - (GRID_PADDING * 2),
        height = 18,
        justifyH = "CENTER",
        textColor = UI.ResolveColor(nil, "text.secondary"),
    })
    self.EmptyText:GetFrame():SetPoint("CENTER", content, "CENTER", 0, 0)
    self.EmptyText:GetFrame():Hide()

    self:RefreshSearchButtons()

    return self.frame
end

function InventoryGridPage:RefreshIfDirty()
    if not self.frame then
        return nil, false
    end

    local revision = self:GetRevisionTuple()
    if not self.dirty and revisionTuplesEqual(self.lastRenderedRevision, revision) then
        return self.frame, false
    end

    if not self:IsVisible() then
        self.dirty = true
        return self.frame, false
    end

    if isCurrencyOnlyChange(self.lastRenderedRevision, revision) then
        if self.CurrencyPanel and self.CurrencyPanel.RefreshIfDirty then
            self.CurrencyPanel:RefreshIfDirty()
        end
        self.lastRenderedRevision = revision
        self.dirty = false
        return self.frame, true
    end

    return self:Refresh(), true
end

function InventoryGridPage:Refresh()
    if not self.frame then
        return nil
    end

    if not self:IsVisible() then
        self.dirty = true
        return self.frame
    end

    if self.refreshInProgress then
        return self.frame
    end

    self.refreshInProgress = true
    local timer = startTiming("InventoryGridPage:Refresh", 8, self.categoryKey or self.pageLabel or "inventory")
    local revision = self:GetRevisionTuple()
    local getDisplayItems = Inventory.GetDisplayItems
    local snapshot = type(getDisplayItems) == "function" and getDisplayItems() or {}
    local snapshotRevision = self:GetRevisionTuple()

    if not dataRevisionsEqual(revision, snapshotRevision) then
        self.refreshInProgress = false
        self.dirty = true
        if timer then
            stopTiming(timer, {
                aborted = true,
                reason = "revision-changed-before-filtering",
            })
        end
        if self.windowController and self.windowController.QueueRefresh then
            self.windowController:QueueRefresh("inventory-revision-changed-during-refresh")
        end
        return self.frame
    end

    local categoryItems = self:GetCategoryDisplayItems(snapshot)
    local filterItems = self:BuildFilterItems(categoryItems)

    if self.FilterDropdown and self.FilterDropdown.SetItems then
        local selectedValues = self:GetSelectedFilterValues()
        self.FilterDropdown:SetItems(filterItems)
        self.FilterDropdown:SetSelectedValues(selectedValues, true)
    end

    local renderRevision = self:GetRevisionTuple()
    local displayItems, searchMatches = self:GetFilteredDisplayItems(categoryItems)

    if self.CurrencyPanel and self.CurrencyPanel.RefreshIfDirty then
        self.CurrencyPanel:RefreshIfDirty()
    end

    self:RefreshSearchButtons()

    local preRenderRevision = self:GetRevisionTuple()
    if not revisionTuplesEqual(renderRevision, preRenderRevision) then
        self.refreshInProgress = false
        self.dirty = true
        if timer then
            stopTiming(timer, {
                aborted = true,
                reason = "revision-changed-before-render",
                categoryItems = #categoryItems,
                filteredItems = #displayItems,
            })
        end
        if self.windowController and self.windowController.QueueRefresh then
            self.windowController:QueueRefresh("inventory-revision-changed-before-render")
        end
        return self.frame
    end

    if self.EmptyText and self.EmptyText.SetText and self.EmptyText.GetFrame then
        if self.showEmptyOverlay and #displayItems == 0 then
            local emptyText = #categoryItems == 0
                and ("No %s available."):format(self.pageLabel)
                or "No items match the current filters."
            self.EmptyText:SetText(emptyText)
            self.EmptyText:GetFrame():Show()
        else
            self.EmptyText:SetText("")
            self.EmptyText:GetFrame():Hide()
        end
    end

    local searchQuery = renderRevision.searchQuery
    for index = 1, TOTAL_SLOTS do
        local slot = self.slots[index]
        local resolved = displayItems[index]
        if slot then
            if resolved then
                local icon = resolved.item and tostring(resolved.item.icon or "") or ""
                if icon == "" then
                    icon = DEFAULT_ICON
                end

                slot:SetIcon(icon)
                slot:SetCount((tonumber(resolved.quantity) or 1) > 1 and tostring(math.floor(tonumber(resolved.quantity) or 1)) or "")
                slot:SetEnabled((resolved.isActive and not resolved.isMissing) and (searchQuery == "" or searchMatches[resolved] == true))
                slot.resolvedItem = resolved
                slot:SetTooltip(function()
                    local currentResolvedItem = slot.resolvedItem
                    return currentResolvedItem and buildTooltipText(currentResolvedItem) or nil
                end)
            else
                slot:SetIcon(DEFAULT_ICON)
                slot:SetCount("")
                slot:SetEnabled(false)
                slot:SetTooltip(nil)
                slot.resolvedItem = nil
            end
        end
    end

    local finalRevision = self:GetRevisionTuple()
    if not revisionTuplesEqual(renderRevision, finalRevision) then
        self.refreshInProgress = false
        self.dirty = true
        if timer then
            stopTiming(timer, {
                aborted = true,
                reason = "revision-changed-during-render",
                categoryItems = #categoryItems,
                filteredItems = #displayItems,
            })
        end
        if self.windowController and self.windowController.QueueRefresh then
            self.windowController:QueueRefresh("inventory-revision-changed-during-render")
        end
        return self.frame
    end

    self.lastRenderedRevision = finalRevision
    self.dirty = false
    self.refreshInProgress = false

    if timer then
        stopTiming(timer, {
            categoryItems = #categoryItems,
            filteredItems = #displayItems,
            resolvedItems = #snapshot,
            visibleSlots = TOTAL_SLOTS,
            snapshotFetches = 1,
        })
    end
    return self.frame
end

function InventoryGridPage:GetSlotCount()
    return #(self.slots or {})
end

local InventoryPage = InventoryUI.InventoryPage or createInventoryGridPage({
    categoryKey = "general",
    pageLabel = "items",
    frameName = "RPEInventoryPage",
    toolbarPanelName = "RPEInventoryToolbarPanel",
    searchLabelName = "RPEInventorySearchLabel",
    searchInputName = "RPEInventorySearchInput",
    searchButtonName = "RPEInventorySearchButton",
    clearButtonName = "RPEInventorySearchClearButton",
    filterDropdownName = "RPEInventoryFilterDropdown",
    gridPanelName = "RPEInventoryGridPanel",
    emptyTextName = "RPEInventoryEmptyText",
    contextMenuName = "RPEInventoryItemContextMenu",
    slotNamePrefix = "RPEInventorySlot",
    showEmptyOverlay = false,
})

InventoryUI.InventoryPage = InventoryPage

return InventoryPage
