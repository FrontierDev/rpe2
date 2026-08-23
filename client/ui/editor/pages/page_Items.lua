local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Client.UI = Addon.Client.UI or {}
Addon.Client.UI.Editor = Addon.Client.UI.Editor or {}

local DataEditor = Addon.Client.UI.Editor
local UI = Addon.UI or {}
local Inventory = Addon.Client and Addon.Client.Inventory or {}

local function getItemTypeLabel(itemType)
    local labels = {
        weapon = "Weapon",
        armor = "Armor",
        tool = "Tool",
        consumable = "Consumable",
        material = "Material",
        modification = "Modification",
        none = "Item",
    }

    return labels[tostring(itemType or "none")] or "Item"
end

local function getQualityLabel(quality)
    local labels = {
        poor = "Poor",
        common = "Common",
        uncommon = "Uncommon",
        rare = "Rare",
        epic = "Epic",
        legendary = "Legendary",
    }

    return labels[tostring(quality or "common")] or "Common"
end

local function matchesItemDropdownFilter(item, filterValue)
    filterValue = tostring(filterValue or "all")
    if filterValue == "all" then
        return true
    end

    if filterValue == "weapon" or filterValue == "armor" or filterValue == "tool" or filterValue == "consumable" or filterValue == "material" or filterValue == "modification" then
        return tostring(item and item.itemType or "none") == filterValue
    end

    if filterValue == "poor" or filterValue == "common" or filterValue == "uncommon" or filterValue == "rare" or filterValue == "epic" or filterValue == "legendary" then
        return tostring(item and item.quality or "common") == filterValue
    end

    return true
end

function DataEditor:BuildItemsPage(page)
    if self.ItemsPageRoot then
        return self.ItemsPageRoot
    end

    self.ItemsPageRoot = UI.CreateLayout(UI.VerticalLayoutGroup, page, "RPEDataEditorItemsPageRoot", {
        spacing = 4,
        fitChildrenWidth = true,
        fitChildrenHeight = true,
    })
    UI.Utils.AnchorFill(self.ItemsPageRoot, page, 0, 0, 0, 0)

    self.ItemsPageFilterBar, self.ItemsPageFilterInput, self.ItemsPageFilterDropdown, self.ItemsPageFilterClearButton = self:BuildDataPageFilterBar(
        self.ItemsPageRoot:GetFrame(),
        "RPEDataEditorItemsPageFilterBar",
        "items",
        {
            placeholder = "Search items",
            inputWidth = 72,
            dropdownWidth = 76,
            dropdownItems = {
                { label = "All", value = "all" },
                { label = "Weapons", value = "weapon" },
                { label = "Armor", value = "armor" },
                { label = "Tools", value = "tool" },
                { label = "Consumables", value = "consumable" },
                { label = "Materials", value = "material" },
                { label = "Mods", value = "modification" },
                { label = "Poor", value = "poor" },
                { label = "Common", value = "common" },
                { label = "Uncommon", value = "uncommon" },
                { label = "Rare", value = "rare" },
                { label = "Epic", value = "epic" },
                { label = "Legendary", value = "legendary" },
            },
        }
    )
    self.ItemsPageRoot:AddChild(self.ItemsPageFilterBar)

    local listPanel = UI.CreatePanel(self.ItemsPageRoot:GetFrame(), "RPEDataEditorItemsListPanel", {
        width = 150,
        expandHeight = true,
        weight = 1,
        contentInset = 2,
        showBorder = false,
    })
    self.ItemsPageRoot:AddChild(listPanel)

    self.ItemsPageScroll = UI.ScrollLayout:New({
        name = "RPEDataEditorItemsScroll",
        width = 146,
        height = 248,
        visibleRows = 10,
        autoFitRows = true,
        rowHeight = 16,
        rowSpacing = 0,
        border = false,
        rowElementClass = UI.ScrollListEntry,
        categoryWidth = 90,
        statusWidth = 42,
        categoryInsetLeft = 4,
        statusInsetRight = 4,
    })
    self.ItemsPageScroll:SetParent(listPanel:GetContentFrame())
    self.ItemsPageScroll:SetRowRenderer(function(row, rowData)
        local item = rowData and rowData.entry or nil
        local itemIndex = rowData and rowData.entryIndex or nil
        if row.SetCategory then
            row:SetCategory(self:GetEntryDisplayName("items", item))
        end
        if row.SetTestName then
            row:SetTestName("")
        end
        if row.SetStatus then
            row:SetStatus(("%s %s"):format(getQualityLabel(item and item.quality), getItemTypeLabel(item and item.itemType)))
        end
        if row.SetDetail then
            row:SetDetail(item and item.description or "")
        end

        local frame = row.GetFrame and row:GetFrame() or nil
        if frame then
            frame:EnableMouse(true)
            frame:SetScript("OnMouseUp", function(_, button)
                if button == "LeftButton" then
                    self:SetSelectedDatasetEntryIndex("items", itemIndex)
                    if self.ItemsContextMenu and self.ItemsContextMenu.HideMenus then
                        self.ItemsContextMenu:HideMenus()
                    end
                elseif button == "RightButton" and item then
                    self:SetSelectedDatasetEntryIndex("items", itemIndex)
                    self:ShowItemsContextMenu(frame, item)
                end
            end)

            local selectedEntry = self.SelectedEntryIndices and self.SelectedEntryIndices.items or nil
            local isSelected = tonumber(selectedEntry) == tonumber(itemIndex)
            if row.entryBackground and row.entryBackground.SetColorTexture then
                local token = isSelected and "list.rowHover" or "list.rowBackground"
                local color = UI.ResolveColor(nil, token)
                row.entryBackground:SetColorTexture(color.r or 0.08, color.g or 0.09, color.b or 0.11, color.a or 0.85)
            end
        end
    end)
    self.ItemsPageScroll:Create()
    UI.Utils.AnchorFill(self.ItemsPageScroll, listPanel:GetContentFrame(), 0, 0, 0, 0)

    self.ItemsPageEmptyText = UI.CreateText(listPanel:GetContentFrame(), "RPEDataEditorItemsEmptyText", "", {
        fontFile = (UI.Constants and UI.Constants.FontFiles and UI.Constants.FontFiles.Default) or "Fonts\\FRIZQT__.TTF",
        fontSize = (UI.Constants and UI.Constants.FontSizes and UI.Constants.FontSizes.Body) or 8,
        textColor = UI.ResolveColor(nil, "text.secondary"),
        width = 122,
        height = 36,
        justifyH = "CENTER",
        wordWrap = true,
    })
    self.ItemsPageEmptyText:GetFrame():SetPoint("CENTER", listPanel:GetContentFrame(), "CENTER", 0, 0)

    self.ItemsPageToolbar, self.ItemsPageButtons = self:BuildDataPageToolbar(self.ItemsPageRoot:GetFrame(), "RPEDataEditorItemsPageToolbar", "items")
    self.ItemsPageRoot:AddChild(self.ItemsPageToolbar)

    self:RefreshItemsDataPage()
    return self.ItemsPageRoot
end

function DataEditor:EnsureItemsContextMenu()
    if self.ItemsContextMenu then
        return self.ItemsContextMenu
    end

    self.ItemsContextMenu = UI.ContextMenu:New({
        name = "RPEDataEditorItemsContextMenu",
        width = 160,
        panelWidth = 160,
        visibleRows = 4,
        rowHeight = 18,
        border = false,
        onItemInvoked = function(item, menu)
            local action = item and item.value or nil
            local datasetId = self.ContextMenuItemDatasetId
            local itemId = self.ContextMenuItemId
            if action == "add-to-inventory" and datasetId and itemId and Inventory.AddItem then
                Inventory.AddItem({
                    dataset = datasetId,
                    id = itemId,
                    modifications = {},
                })
            end

            if menu and menu.HideMenus then
                menu:HideMenus()
            end
        end,
    })
    self.ItemsContextMenu:SetParent(self.Window and self.Window:GetFrame() or UIParent)
    self.ItemsContextMenu:Create()
    return self.ItemsContextMenu
end

function DataEditor:ShowItemsContextMenu(anchorFrame, item)
    local dataset = self:GetSelectedDataset()
    if not anchorFrame or not item or not dataset or not dataset.id or not item.id then
        return
    end

    local menu = self:EnsureItemsContextMenu()
    self.ContextMenuItemDatasetId = dataset.id
    self.ContextMenuItemId = item.id
    menu:SetItems({
        {
            label = "Add To Inventory",
            value = "add-to-inventory",
        },
    })
    menu:ShowAt(anchorFrame)
end

function DataEditor:RefreshItemsDataPage()
    local dataset = self:GetSelectedDataset()
    local items = dataset and dataset.items or {}
    local filteredItems, filterQuery = self:GetFilteredDatasetEntries("items", items)
    local dropdownFilter = self:GetCollectionDropdownFilterValue("items")
    local visibleItems = {}

    self:RefreshDataPageToolbar(self.ItemsPageButtons)

    for index = 1, #filteredItems do
        local rowData = filteredItems[index]
        if matchesItemDropdownFilter(rowData and rowData.entry, dropdownFilter) then
            visibleItems[#visibleItems + 1] = rowData
        end
    end

    if self.ItemsPageScroll and self.ItemsPageScroll.SetItems then
        self.ItemsPageScroll:SetItems(visibleItems)
    end

    if self.ItemsPageEmptyText and self.ItemsPageEmptyText.SetText then
        if not dataset then
            self.ItemsPageEmptyText:SetText("Create or select a dataset to view items.")
        elseif #items == 0 then
            self.ItemsPageEmptyText:SetText("This dataset has no items yet.")
        elseif #visibleItems == 0 and (filterQuery ~= "" or dropdownFilter ~= "all") then
            self.ItemsPageEmptyText:SetText("No items match the current filters.")
        else
            self.ItemsPageEmptyText:SetText("")
        end
    end
end
