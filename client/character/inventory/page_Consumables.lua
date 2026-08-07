local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Client.UI = Addon.Client.UI or {}
Addon.Client.UI.Inventory = Addon.Client.UI.Inventory or {}

local InventoryUI = Addon.Client.UI.Inventory

local ConsumablesPage = InventoryUI.ConsumablesPage or (
    InventoryUI.CreateInventoryGridPage and InventoryUI.CreateInventoryGridPage({
        categoryKey = "consumable",
        pageLabel = "consumables",
        frameName = "RPEInventoryConsumablesPage",
        toolbarPanelName = "RPEInventoryConsumablesToolbarPanel",
        searchLabelName = "RPEInventoryConsumablesSearchLabel",
        searchInputName = "RPEInventoryConsumablesSearchInput",
        searchButtonName = "RPEInventoryConsumablesSearchButton",
        clearButtonName = "RPEInventoryConsumablesSearchClearButton",
        filterDropdownName = "RPEInventoryConsumablesFilterDropdown",
        gridPanelName = "RPEInventoryConsumablesGridPanel",
        emptyTextName = "RPEInventoryConsumablesEmptyText",
        contextMenuName = "RPEInventoryConsumablesContextMenu",
        slotNamePrefix = "RPEInventoryConsumablesSlot",
        showEmptyOverlay = false,
    })
)

InventoryUI.ConsumablesPage = ConsumablesPage

return ConsumablesPage
