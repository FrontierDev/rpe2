local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Client.UI = Addon.Client.UI or {}
Addon.Client.UI.Inventory = Addon.Client.UI.Inventory or {}

local InventoryUI = Addon.Client.UI.Inventory

local ReagentsPage = InventoryUI.ReagentsPage or (
    InventoryUI.CreateInventoryGridPage and InventoryUI.CreateInventoryGridPage({
        categoryKey = "reagent",
        pageLabel = "reagents",
        frameName = "RPEInventoryReagentsPage",
        toolbarPanelName = "RPEInventoryReagentsToolbarPanel",
        searchLabelName = "RPEInventoryReagentsSearchLabel",
        searchInputName = "RPEInventoryReagentsSearchInput",
        searchButtonName = "RPEInventoryReagentsSearchButton",
        clearButtonName = "RPEInventoryReagentsSearchClearButton",
        filterDropdownName = "RPEInventoryReagentsFilterDropdown",
        gridPanelName = "RPEInventoryReagentsGridPanel",
        emptyTextName = "RPEInventoryReagentsEmptyText",
        contextMenuName = "RPEInventoryReagentsContextMenu",
        slotNamePrefix = "RPEInventoryReagentsSlot",
        showEmptyOverlay = false,
    })
)

InventoryUI.ReagentsPage = ReagentsPage

return ReagentsPage
