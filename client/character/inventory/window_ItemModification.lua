local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Client.UI = Addon.Client.UI or {}
Addon.Client.UI.Inventory = Addon.Client.UI.Inventory or {}

local Client = Addon.Client
local UI = Addon.UI or {}
local Inventory = Addon.Client.Inventory or {}
local InventoryUI = Addon.Client.UI.Inventory
local Database = Addon.Internal and Addon.Internal.Database or {}
local Profile = Addon.Internal and Addon.Internal.Profile or {}
local ModificationService = Profile and Profile.Modifications or {}
local TooltipBuilders = Addon.Client.UI and Addon.Client.UI.Tooltips or {}

local ItemModificationWindow = InventoryUI.ModificationWindow or {}
InventoryUI.ModificationWindow = ItemModificationWindow
ItemModificationWindow.__index = ItemModificationWindow

local DEFAULT_ICON = "Interface\\Icons\\INV_Misc_QuestionMark"

local WINDOW_WIDTH = 388
local WINDOW_HEIGHT = 272
local CONTENT_WIDTH = WINDOW_WIDTH - 16
local HEADER_HEIGHT = 38
local PANEL_HEIGHT = 178
local ROW_HEIGHT = 18
local ROWS_VISIBLE = 6
local LIST_HEIGHT = ROWS_VISIBLE * ROW_HEIGHT
local ACTION_BUTTON_WIDTH = 92
local ACTION_BUTTON_HEIGHT = 18

local EMPTY_TEXT = "No modifications available."

local QUALITY_COLORS = {
    poor = { r = 0.62, g = 0.62, b = 0.62, a = 1 },
    common = { r = 1.0, g = 1.0, b = 1.0, a = 1 },
    uncommon = { r = 0.12, g = 1.0, b = 0.0, a = 1 },
    rare = { r = 0.0, g = 0.44, b = 0.87, a = 1 },
    epic = { r = 0.64, g = 0.21, b = 0.93, a = 1 },
    legendary = { r = 1.0, g = 0.5, b = 0.0, a = 1 },
}

local APPLIED_NAME_COLOR = { r = 0.22, g = 0.95, b = 0.38, a = 1 }
local READY_TEXT_COLOR = { r = 0.76, g = 0.8, b = 0.88, a = 1 }
local DISABLED_TEXT_COLOR = { r = 0.42, g = 0.44, b = 0.5, a = 1 }
local SELECTED_ROW_COLOR = { r = 0.15, g = 0.25, b = 0.36, a = 0.95 }
local SELECTED_DISABLED_ROW_COLOR = { r = 0.14, g = 0.16, b = 0.2, a = 0.95 }
local DISABLED_ROW_COLOR = { r = 0.06, g = 0.07, b = 0.09, a = 0.9 }

local function ensureString(value, fallback)
    if value == nil or value == "" then
        return fallback or ""
    end

    return tostring(value)
end

local function getQualityColor(quality)
    return QUALITY_COLORS[tostring(quality or "common")] or QUALITY_COLORS.common
end

local function resolveDatasetName(dataset, datasetId)
    if Database.GetDatasetDisplayName then
        if type(dataset) == "table" then
            return Database.GetDatasetDisplayName(dataset)
        end
        if datasetId ~= nil and Database.GetDatasetByID then
            local resolved = Database.GetDatasetByID(datasetId)
            if resolved then
                return Database.GetDatasetDisplayName(resolved)
            end
        end
    end

    if type(dataset) == "table" then
        return ensureString(dataset.name, dataset.id or "Unknown Dataset")
    end

    return ensureString(datasetId, "Unknown Dataset")
end

local function getModificationKindLabel(item)
    local kind = type(ModificationService.GetModificationKind) == "function" and ModificationService.GetModificationKind(item) or "generic"
    if kind == "gem" then
        local color = type(ModificationService.GetGemColor) == "function" and ModificationService.GetGemColor(item) or "none"
        local label = ensureString(color, "none"):gsub("^%l", string.upper)
        return ("%s Gem"):format(label ~= "" and label or "Gem")
    end
    if kind == "enchant" then
        return "Enchant"
    end
    return "Generic"
end

local function buildTooltip(item, options)
    local builder = TooltipBuilders and TooltipBuilders.Item or nil
    if not (builder and builder.Build and item) then
        return nil
    end

    return builder:Build(item, options or {})
end

local function buildTooltipOptions(resolved)
    if type(resolved) ~= "table" then
        return nil
    end

    return {
        dataset = resolved.dataset,
        datasetId = resolved.datasetId,
        datasetName = resolveDatasetName(resolved.dataset, resolved.datasetId),
        itemId = resolved.itemId,
        isActive = resolved.isActive,
        isMissing = resolved.isMissing,
        soulbound = resolved.soulbound == true,
        modifications = resolved.modifications,
    }
end

local function refreshRelatedWindows()
    local inventoryWindow = InventoryUI and InventoryUI.Window or nil
    if inventoryWindow and inventoryWindow.Get then
        local inventoryInstance = inventoryWindow:Get()
        if inventoryInstance and inventoryInstance.Refresh then
            inventoryInstance:Refresh()
        end
    end

    local profileWindow = Addon.Client and Addon.Client.UI and Addon.Client.UI.Profile and Addon.Client.UI.Profile.Window or nil
    if profileWindow and profileWindow.Get then
        local profileInstance = profileWindow:Get()
        if profileInstance and profileInstance.Refresh then
            profileInstance:Refresh()
        end
    end
end

local function getReasonLabel(reason)
    local labels = {
        ["apply-failed"] = "Failed",
        ["armor-weight-mismatch"] = "Armor Mismatch",
        ["enchant-limit"] = "Has Enchant",
        ["generic-key-limit"] = "Limit Reached",
        ["invalid-modification"] = "Invalid Mod",
        ["invalid-target"] = "Invalid Target",
        ["missing-gem-color"] = "No Gem Color",
        ["missing-generic-key"] = "Missing Key",
        ["missing-item"] = "Missing Item",
        ["modification-unavailable"] = "Unavailable",
        ["no-matching-socket"] = "No Socket",
        ["slot-mismatch"] = "Wrong Slot",
        ["weapon-type-mismatch"] = "Weapon Mismatch",
    }

    return labels[tostring(reason or "")] or ensureString(reason, "Unavailable")
end

local function setTextColor(textRegion, color)
    if textRegion and textRegion.SetTextColor and type(color) == "table" then
        textRegion:SetTextColor(color.r or 1, color.g or 1, color.b or 1, color.a or 1)
    end
end

local function setCellColor(row, key, color)
    local textRegion = row and row.cells and row.cells[key] and row.cells[key].text or nil
    if textRegion then
        setTextColor(textRegion, color)
    end
end

local function createInstance()
    return setmetatable({
        window = nil,
        changeListenerHandle = nil,
        targetSlotIndex = nil,
        selectedItemRef = nil,
        rows = {},
    }, ItemModificationWindow)
end

function ItemModificationWindow:Get()
    if not self._singleton then
        self._singleton = createInstance()
    end

    return self._singleton
end

function ItemModificationWindow:ResolveTarget()
    local slotIndex = tonumber(self.targetSlotIndex)
    local record = slotIndex and Inventory.GetItem and Inventory.GetItem(slotIndex) or nil
    local resolved = record and Inventory.ResolveItem and Inventory.ResolveItem(record) or nil
    local itemType = resolved and resolved.item and tostring(resolved.item.itemType or "none") or "none"
    if not resolved or resolved.isMissing == true or resolved.isActive ~= true or (itemType ~= "weapon" and itemType ~= "armor") then
        return nil
    end

    resolved.sourceIndex = slotIndex
    return resolved
end

function ItemModificationWindow:BuildRows(resolvedTarget)
    local rows = {}
    local grouped = {}
    local ordered = {}
    local inventoryItems = Inventory.GetItems and Inventory.GetItems() or {}
    local appliedRows = ModificationService.ListAppliedModifications and ModificationService.ListAppliedModifications(resolvedTarget.modifications) or {}

    for index = 1, #appliedRows do
        local applied = appliedRows[index]
        local itemRef = ensureString(applied and applied.itemRef)
        if itemRef ~= "" then
            local bucket = grouped[itemRef]
            if not bucket then
                bucket = {
                    itemRef = itemRef,
                    item = applied.item,
                    dataset = applied.dataset,
                    inventoryQuantity = 0,
                    appliedCount = 0,
                    modKeys = {},
                    canApply = false,
                    reason = "modification-unavailable",
                    tooltip = buildTooltip(applied.item, {
                        dataset = applied.dataset,
                        datasetId = applied.dataset and applied.dataset.id or nil,
                        datasetName = resolveDatasetName(applied.dataset, applied.dataset and applied.dataset.id or nil),
                        itemId = applied.itemId,
                        isActive = applied.item ~= nil,
                        isMissing = applied.item == nil,
                    }),
                }
                grouped[itemRef] = bucket
                ordered[#ordered + 1] = bucket
            end

            bucket.appliedCount = bucket.appliedCount + 1
            bucket.modKeys[#bucket.modKeys + 1] = applied.modKey
        end
    end

    for index = 1, #inventoryItems do
        if index ~= resolvedTarget.sourceIndex then
            local resolved = Inventory.ResolveItem and Inventory.ResolveItem(inventoryItems[index]) or nil
            local item = resolved and resolved.item or nil
            if resolved and item and resolved.isMissing ~= true and resolved.isActive == true and tostring(item.itemType or "none") == "modification" then
                local itemRef = ("%s:%s"):format(tostring(resolved.datasetId or ""), tostring(resolved.itemId or ""))
                local bucket = grouped[itemRef]
                if not bucket then
                    bucket = {
                        itemRef = itemRef,
                        item = item,
                        dataset = resolved.dataset,
                        inventoryQuantity = 0,
                        appliedCount = 0,
                        modKeys = {},
                        canApply = false,
                        reason = "modification-unavailable",
                        tooltip = buildTooltip(item, buildTooltipOptions(resolved)),
                    }
                    grouped[itemRef] = bucket
                    ordered[#ordered + 1] = bucket
                end

                if not bucket.item then
                    bucket.item = item
                end
                if not bucket.dataset then
                    bucket.dataset = resolved.dataset
                end

                bucket.inventoryQuantity = bucket.inventoryQuantity + math.max(1, math.floor(tonumber(resolved.quantity) or 1))

                local canApply, reason = false, "modification-unavailable"
                if type(ModificationService.CanApplyModificationToRecord) == "function" then
                    canApply, reason = ModificationService.CanApplyModificationToRecord(resolvedTarget.record, inventoryItems[index])
                end
                if canApply == true then
                    bucket.canApply = true
                    bucket.reason = ""
                elseif bucket.canApply ~= true then
                    bucket.reason = reason or "modification-unavailable"
                end
            end
        end
    end

    table.sort(ordered, function(left, right)
        local leftBucket = left.canApply and 0 or (left.appliedCount > 0 and left.inventoryQuantity <= 0 and 1 or 2)
        local rightBucket = right.canApply and 0 or (right.appliedCount > 0 and right.inventoryQuantity <= 0 and 1 or 2)
        if leftBucket ~= rightBucket then
            return leftBucket < rightBucket
        end

        local leftName = string.lower(ensureString(left.item and left.item.name, left.itemRef))
        local rightName = string.lower(ensureString(right.item and right.item.name, right.itemRef))
        if leftName == rightName then
            return ensureString(left.itemRef) < ensureString(right.itemRef)
        end
        return leftName < rightName
    end)

    for index = 1, #ordered do
        local entry = ordered[index]
        local isApplied = entry.appliedCount > 0
        local isDisabled = entry.inventoryQuantity > 0 and entry.canApply ~= true
        local typeText = getModificationKindLabel(entry.item)
        local usage = type(ModificationService.GetModificationUsageSummary) == "function"
            and ModificationService.GetModificationUsageSummary(resolvedTarget.record, entry.itemRef)
            or nil
        local currentOnItem = math.max(0, math.floor(tonumber(usage and usage.current) or entry.appliedCount or 0))
        local maxOnItem = math.max(0, math.floor(tonumber(usage and usage.max) or currentOnItem))

        rows[index] = {
            itemRef = entry.itemRef,
            item = entry.item,
            inventoryQuantity = entry.inventoryQuantity,
            inventoryQuantityText = tostring(entry.inventoryQuantity or 0),
            appliedCount = currentOnItem,
            appliedCountText = ("%d / %d"):format(currentOnItem, maxOnItem),
            nameText = ensureString(entry.item and entry.item.name, "Modification"),
            typeText = typeText,
            canApply = entry.canApply == true and entry.inventoryQuantity > 0,
            canRemove = entry.appliedCount > 0,
            reason = entry.reason,
            modKeys = entry.modKeys,
            tooltip = entry.tooltip,
            nameColor = isDisabled and DISABLED_TEXT_COLOR or getQualityColor(entry.item and entry.item.quality),
            typeColor = isDisabled and DISABLED_TEXT_COLOR or READY_TEXT_COLOR,
            inventoryColor = isDisabled and DISABLED_TEXT_COLOR or READY_TEXT_COLOR,
            appliedColor = isApplied and APPLIED_NAME_COLOR or READY_TEXT_COLOR,
            isDisabled = isDisabled,
        }
    end

    return rows
end

function ItemModificationWindow:RefreshHeader(resolvedTarget)
    if not resolvedTarget then
        if self.TargetSlot then
            self.TargetSlot:SetIcon(DEFAULT_ICON)
            self.TargetSlot:SetCount("")
            self.TargetSlot:SetTooltip(nil)
        end
        if self.TargetNameText and self.TargetNameText.SetText then
            self.TargetNameText:SetText("No item selected")
            setTextColor(self.TargetNameText, READY_TEXT_COLOR)
        end
        return
    end

    local tooltip = buildTooltip(resolvedTarget.item, buildTooltipOptions(resolvedTarget))
    if self.TargetSlot then
        self.TargetSlot:SetIcon(resolvedTarget.item and resolvedTarget.item.icon or DEFAULT_ICON)
        self.TargetSlot:SetCount((tonumber(resolvedTarget.quantity) or 1) > 1 and tostring(resolvedTarget.quantity) or "")
        if tooltip then
            self.TargetSlot:SetGameTooltip(tooltip)
        else
            self.TargetSlot:SetTooltip(nil)
        end
    end
    if self.TargetNameText and self.TargetNameText.SetText then
        self.TargetNameText:SetText(ensureString(resolvedTarget.item and resolvedTarget.item.name, "Unnamed Item"))
        setTextColor(self.TargetNameText, getQualityColor(resolvedTarget.item and resolvedTarget.item.quality))
    end
end

function ItemModificationWindow:RefreshSelection()
    local found = false
    for index = 1, #(self.rows or {}) do
        if self.rows[index].itemRef == self.selectedItemRef then
            found = true
            break
        end
    end
    if not found then
        self.selectedItemRef = nil
    end
end

function ItemModificationWindow:GetSelectedRow()
    for index = 1, #(self.rows or {}) do
        if self.rows[index].itemRef == self.selectedItemRef then
            return self.rows[index]
        end
    end

    return nil
end

function ItemModificationWindow:RefreshButtons()
    local selected = self:GetSelectedRow()
    if self.ApplyButton and self.ApplyButton.SetEnabled then
        self.ApplyButton:SetEnabled(selected ~= nil and selected.canApply == true)
    end
    if self.RemoveButton and self.RemoveButton.SetEnabled then
        self.RemoveButton:SetEnabled(selected ~= nil and selected.canRemove == true)
    end
end

function ItemModificationWindow:RefreshEmptyState()
    if self.EmptyText and self.EmptyText.GetFrame then
        local frame = self.EmptyText:GetFrame()
        if #self.rows == 0 then
            frame:Show()
        else
            frame:Hide()
        end
    end
end

function ItemModificationWindow:Refresh()
    if not self.window then
        return nil
    end

    local resolvedTarget = self:ResolveTarget()
    self:RefreshHeader(resolvedTarget)

    if not resolvedTarget then
        self.rows = {}
        self.selectedItemRef = nil
    else
        self.rows = self:BuildRows(resolvedTarget)
        self:RefreshSelection()
    end

    if self.ModificationTable and self.ModificationTable.SetRows then
        self.ModificationTable:SetRows(self.rows)
    end

    self:RefreshButtons()
    self:RefreshEmptyState()
    return self.window
end

function ItemModificationWindow:ApplySelectedModification()
    local selected = self:GetSelectedRow()
    if not selected or selected.canApply ~= true then
        return
    end

    local choices = Inventory.GetCompatibleModificationChoices and Inventory.GetCompatibleModificationChoices(self.targetSlotIndex) or {}
    local sourceIndex = nil
    for index = 1, #choices do
        if choices[index].itemRef == selected.itemRef then
            sourceIndex = choices[index].sourceIndex
            break
        end
    end
    if not sourceIndex then
        return
    end

    local updatedRecord, updatedSlotIndex = nil, nil
    if Inventory.ApplyModification then
        local appliedModKey = nil
        updatedRecord, appliedModKey, updatedSlotIndex = Inventory.ApplyModification(self.targetSlotIndex, sourceIndex)
    end
    if type(updatedRecord) ~= "table" then
        return
    end

    self.targetSlotIndex = updatedSlotIndex or self.targetSlotIndex
    self.selectedItemRef = selected.itemRef
    refreshRelatedWindows()
    self:Refresh()
end

function ItemModificationWindow:RemoveSelectedModification()
    local selected = self:GetSelectedRow()
    if not selected or selected.canRemove ~= true then
        return
    end

    local modKeys = selected.modKeys or {}
    local modKey = modKeys[#modKeys]
    if not modKey then
        return
    end

    local updatedRecord, updatedSlotIndex = nil, nil
    if Inventory.RemoveAppliedModification then
        local removed = nil
        updatedRecord, removed, updatedSlotIndex = Inventory.RemoveAppliedModification(self.targetSlotIndex, modKey)
    end
    if type(updatedRecord) ~= "table" then
        return
    end

    self.targetSlotIndex = updatedSlotIndex or self.targetSlotIndex
    self.selectedItemRef = selected.itemRef
    refreshRelatedWindows()
    self:Refresh()
end

function ItemModificationWindow:RenderRow(row, item, itemIndex)
    local rowData = item and item.rowData or item
    local sourceIndex = item and item.sourceIndex or itemIndex

    if row.SetColumns then
        row:SetColumns(self.ModificationTable and self.ModificationTable:GetResolvedColumns() or {})
    end
    if row.SetRowData then
        row:SetRowData(rowData, sourceIndex or 0)
    end
    if row.SetRowMouseUpHandler then
        row:SetRowMouseUpHandler(function(_, button, rowData)
            if button == "LeftButton" then
                self.selectedItemRef = rowData and rowData.itemRef or nil
                self:Refresh()
            end
        end)
    end

    local isSelected = rowData and rowData.itemRef == self.selectedItemRef
    local backgroundColor = UI.ResolveColor(nil, "list.rowBackground")
    if rowData and rowData.isDisabled then
        backgroundColor = isSelected and SELECTED_DISABLED_ROW_COLOR or DISABLED_ROW_COLOR
    elseif isSelected then
        backgroundColor = SELECTED_ROW_COLOR
    end
    if row.background and row.background.SetColorTexture then
        row.background:SetColorTexture(backgroundColor.r or 0.08, backgroundColor.g or 0.09, backgroundColor.b or 0.11, backgroundColor.a or 0.85)
    end

    setCellColor(row, "nameText", rowData and rowData.nameColor or READY_TEXT_COLOR)
    setCellColor(row, "typeText", rowData and rowData.typeColor or READY_TEXT_COLOR)
    setCellColor(row, "inventoryQuantityText", rowData and rowData.inventoryColor or READY_TEXT_COLOR)
    setCellColor(row, "appliedCountText", rowData and rowData.appliedColor or READY_TEXT_COLOR)
end

function ItemModificationWindow:BuildWindow()
    if self.window then
        if not self.changeListenerHandle and Inventory.RegisterChangeListener then
            self.changeListenerHandle = Inventory.RegisterChangeListener(function()
                self:Refresh()
            end)
        end
        return self.window
    end

    self.window = UI.Window:New({
        name = "RPEItemModificationWindow",
        width = WINDOW_WIDTH,
        height = WINDOW_HEIGHT,
        point = "TOPLEFT",
        relativeTo = UIParent,
        relativePoint = "TOPLEFT",
        x = 300,
        y = -40,
        frameStrata = "HIGH",
        frameLevel = 28,
        movable = true,
        clampedToScreen = true,
        toplevel = true,
        hidden = true,
        contentInsetLeft = 8,
        contentInsetRight = 8,
        contentInsetTop = 28,
        contentInsetBottom = 8,
    })
    self.window:SetTitle("Modify Item")
    self.window:Create()

    local content = self.window:GetContentFrame()

    self.HeaderPanel = UI.CreatePanel(content, "RPEItemModificationHeaderPanel", {
        width = CONTENT_WIDTH,
        height = HEADER_HEIGHT,
        contentInset = 6,
        showBorder = true,
    })
    self.HeaderPanel:GetFrame():SetPoint("TOPLEFT", content, "TOPLEFT", 0, 0)
    self.HeaderPanel:GetFrame():SetPoint("TOPRIGHT", content, "TOPRIGHT", 0, 0)

    self.TargetSlot = UI.ObjectSlot:New({
        name = "RPEItemModificationTargetSlot",
        width = 28,
        height = 28,
        size = 28,
        iconTexture = DEFAULT_ICON,
    })
    self.TargetSlot:SetParent(self.HeaderPanel:GetContentFrame())
    self.TargetSlot:Create()
    self.TargetSlot:GetFrame():SetPoint("LEFT", self.HeaderPanel:GetContentFrame(), "LEFT", 0, 0)

    self.TargetNameText = UI.CreateText(self.HeaderPanel:GetContentFrame(), "RPEItemModificationTargetName", "No item selected", {
        width = CONTENT_WIDTH - 52,
        height = 18,
        justifyH = "LEFT",
        textColor = UI.ResolveColor(nil, "text.primary"),
        fontSize = 11,
    })
    self.TargetNameText:GetFrame():SetPoint("LEFT", self.TargetSlot:GetFrame(), "RIGHT", 8, 0)

    self.Panel = UI.CreatePanel(content, "RPEItemModificationPanel", {
        width = CONTENT_WIDTH,
        height = PANEL_HEIGHT,
        contentInset = 6,
        showBorder = true,
    })
    self.Panel:GetFrame():SetPoint("TOPLEFT", self.HeaderPanel:GetFrame(), "BOTTOMLEFT", 0, -8)
    self.Panel:GetFrame():SetPoint("TOPRIGHT", self.HeaderPanel:GetFrame(), "BOTTOMRIGHT", 0, -8)

    self.ListPanel = UI.CreatePanel(self.Panel:GetContentFrame(), "RPEItemModificationListPanel", {
        width = CONTENT_WIDTH - 12,
        height = LIST_HEIGHT + 22,
        contentInset = 1,
        showBorder = true,
    })
    self.ListPanel:GetFrame():SetPoint("TOPLEFT", self.Panel:GetContentFrame(), "TOPLEFT", 0, 0)
    self.ListPanel:GetFrame():SetPoint("TOPRIGHT", self.Panel:GetContentFrame(), "TOPRIGHT", 0, 0)

    self.ModificationTable = UI.Table:New({
        name = "RPEItemModificationTable",
        width = CONTENT_WIDTH - 14,
        height = LIST_HEIGHT + 20,
        visibleRows = ROWS_VISIBLE,
        rowHeight = ROW_HEIGHT,
        rowSpacing = 0,
        border = false,
        showColumnHeaders = true,
        headerHeight = 20,
        columns = {
            {
                key = "nameText",
                label = "Modification",
                width = 128,
                justifyH = "LEFT",
                sortable = true,
                sortValue = function(rowData)
                    return string.lower(ensureString(rowData and rowData.nameText))
                end,
                cellTooltip = function(_, rowData)
                    return rowData and rowData.tooltip or nil
                end,
            },
            {
                key = "typeText",
                label = "Type",
                width = 52,
                justifyH = "LEFT",
                sortable = true,
                sortValue = function(rowData)
                    return string.lower(ensureString(rowData and rowData.typeText))
                end,
            },
            {
                key = "inventoryQuantityText",
                label = "Bag",
                width = 30,
                justifyH = "RIGHT",
                sortable = true,
                sortValue = function(rowData)
                    return tonumber(rowData and rowData.inventoryQuantity) or 0
                end,
            },
            {
                key = "appliedCountText",
                label = "On Item",
                width = 82,
                justifyH = "RIGHT",
                sortable = true,
                sortValue = function(rowData)
                    return tonumber(rowData and rowData.appliedCount) or 0
                end,
            },
        },
        rows = {},
    })
    self.ModificationTable:SetParent(self.ListPanel:GetContentFrame())
    self.ModificationTable:Create()
    self.ModificationTable:GetFrame():SetPoint("TOPLEFT", self.ListPanel:GetContentFrame(), "TOPLEFT", 0, 0)
    self.ModificationTable.bodyScroll:SetRowRenderer(function(row, item, itemIndex)
        self:RenderRow(row, item, itemIndex)
    end)
    self.ModificationTable:Refresh()

    self.EmptyText = UI.CreateText(self.ListPanel:GetContentFrame(), "RPEItemModificationEmpty", EMPTY_TEXT, {
        width = CONTENT_WIDTH - 24,
        height = 24,
        justifyH = "CENTER",
        justifyV = "MIDDLE",
        textColor = UI.ResolveColor(nil, "text.muted"),
        fontSize = 9,
        wordWrap = true,
    })
    self.EmptyText:GetFrame():SetPoint("CENTER", self.ListPanel:GetContentFrame(), "CENTER", 0, 0)

    self.ApplyButton = UI.CreateButton(self.Panel:GetContentFrame(), "RPEItemModificationApplyButton", "Apply", ACTION_BUTTON_WIDTH, function()
        self:ApplySelectedModification()
    end, {
        height = ACTION_BUTTON_HEIGHT,
        fontSize = 8,
    })
    self.RemoveButton = UI.CreateButton(self.Panel:GetContentFrame(), "RPEItemModificationRemoveButton", "Remove", ACTION_BUTTON_WIDTH, function()
        self:RemoveSelectedModification()
    end, {
        height = ACTION_BUTTON_HEIGHT,
        fontSize = 8,
    })
    self.RemoveButton:GetFrame():SetPoint("BOTTOMRIGHT", self.Panel:GetContentFrame(), "BOTTOMRIGHT", 0, 0)

    self.ApplyButton:GetFrame():SetPoint("RIGHT", self.RemoveButton:GetFrame(), "LEFT", -8, 0)

    if Inventory.RegisterChangeListener then
        self.changeListenerHandle = Inventory.RegisterChangeListener(function()
            self:Refresh()
        end)
    end

    return self.window
end

function ItemModificationWindow:ShowForSlot(slotIndex)
    self.targetSlotIndex = tonumber(slotIndex)
    self.selectedItemRef = nil

    local window = self:BuildWindow()
    self:Refresh()
    if window and window.Show then
        window:Show()
    end
    return window
end

function ItemModificationWindow:Hide()
    if self.window and self.window.Hide then
        self.window:Hide()
    end
    return self.window
end

function Client:BuildItemModificationWindow()
    return ItemModificationWindow:Get():BuildWindow()
end

function Client:ShowItemModificationWindow(slotIndex)
    return ItemModificationWindow:Get():ShowForSlot(slotIndex)
end

function Client:HideItemModificationWindow()
    return ItemModificationWindow:Get():Hide()
end

return ItemModificationWindow
