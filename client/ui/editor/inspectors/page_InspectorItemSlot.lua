local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Client.UI = Addon.Client.UI or {}
Addon.Client.UI.Editor = Addon.Client.UI.Editor or {}

local DataEditor = Addon.Client.UI.Editor
local UI = Addon.UI or {}
local Client = Addon.Client or {}
local INSPECTOR_SIDE_PADDING = 8
local CONTROL_HEIGHT = 20
local PANEL_SIDE_ITEMS = {
    { label = "Left", value = "left" },
    { label = "Right", value = "right" },
    { label = "Bottom", value = "bottom" },
}
local SLOT_TYPE_ITEMS = {
    { label = "Character", value = "character" },
    { label = "Mount", value = "mount" },
    { label = "Pet", value = "pet" },
}

local function commitSelectedItemSlot(self, mutate)
    local itemSlot = self:GetSelectedItemSlot()
    local dataset = self:GetSelectedDataset()
    if not dataset or not itemSlot or type(mutate) ~= "function" then
        return
    end

    local before = self:DeepCopyValue(itemSlot)
    mutate(itemSlot, dataset)
    if self:DeepEqualValues(before, itemSlot) then
        return
    end
    self:QueuePendingDatasetEntryChanged(dataset.id, "itemSlots")
end

function DataEditor:BuildItemSlotInspectorPage(parent)
    if self.ItemSlotInspectorPage then
        return self.ItemSlotInspectorPage
    end

    self.ItemSlotInspectorPage = CreateFrame("Frame", "RPEDataEditorItemSlotInspectorPage", parent)

    local root = UI.CreateLayout(UI.VerticalLayoutGroup, self.ItemSlotInspectorPage, "RPEDataEditorItemSlotInspectorLayout", {
        spacing = 6,
        fitChildrenWidth = true,
        fitChildrenHeight = false,
    })
    UI.Utils.AnchorFill(root, self.ItemSlotInspectorPage, INSPECTOR_SIDE_PADDING, 0, INSPECTOR_SIDE_PADDING, 0)

    root:AddChild(UI.CreateText(root:GetFrame(), "RPEDataEditorItemSlotInspectorNameLabel", "Name", {
        width = 236, height = 12, justifyH = "LEFT", textColor = UI.ResolveColor(nil, "text.secondary"),
    }))
    self.ItemSlotInspectorNameInput = UI.CreateTextInput(root:GetFrame(), "RPEDataEditorItemSlotInspectorNameInput", {
        width = 236, height = CONTROL_HEIGHT, text = "", borderColor = UI.ResolveColor(nil, "panel.border"),
    })
    self.ItemSlotInspectorNameInput:SetScript("OnEnterPressed", function()
        commitSelectedItemSlot(self, function(itemSlot) itemSlot.name = self.ItemSlotInspectorNameInput:GetText() end)
    end)
    self.ItemSlotInspectorNameInput:SetScript("OnEditFocusLost", function()
        commitSelectedItemSlot(self, function(itemSlot) itemSlot.name = self.ItemSlotInspectorNameInput:GetText() end)
    end)
    root:AddChild(self.ItemSlotInspectorNameInput)

    self.ItemSlotInspectorIdText = UI.CreateText(root:GetFrame(), "RPEDataEditorItemSlotInspectorIdText", "ID: -", {
        width = 236, height = 12, justifyH = "LEFT", textColor = UI.ResolveColor(nil, "text.secondary"),
    })
    root:AddChild(self.ItemSlotInspectorIdText)

    root:AddChild(UI.CreateText(root:GetFrame(), "RPEDataEditorItemSlotInspectorIconLabel", "Icon", {
        width = 236, height = 12, justifyH = "LEFT", textColor = UI.ResolveColor(nil, "text.secondary"),
    }))
    self.ItemSlotInspectorIconField = UI.EditorIconField:New({
        name = "RPEDataEditorItemSlotInspectorIconField", width = 236, height = CONTROL_HEIGHT, buttonText = "Select Icon", labelText = "-", iconTexture = "Interface\\Icons\\INV_Misc_QuestionMark", border = false,
    })
    self.ItemSlotInspectorIconField:SetParent(root:GetFrame())
    self.ItemSlotInspectorIconField:Create()
    local iconButton = self.ItemSlotInspectorIconField:GetButton()
    if iconButton and iconButton.SetScript then
        iconButton:SetScript("OnClick", function()
            local itemSlot = self:GetSelectedItemSlot()
            if not itemSlot or not Client.OpenIconFinder then
                return
            end
            Client:OpenIconFinder(function(_, filePath)
                commitSelectedItemSlot(self, function(selectedItemSlot)
                    selectedItemSlot.icon = filePath or ""
                end)
            end, { filter = itemSlot.icon or "" })
        end)
    end
    root:AddChild(self.ItemSlotInspectorIconField)

    root:AddChild(UI.CreateText(root:GetFrame(), "RPEDataEditorItemSlotInspectorPanelSideLabel", "Equipment Panel Side", {
        width = 236, height = 12, justifyH = "LEFT", textColor = UI.ResolveColor(nil, "text.secondary"),
    }))
    self.ItemSlotInspectorPanelSideDropdown = UI.CreateDropdown(root:GetFrame(), "RPEDataEditorItemSlotInspectorPanelSideDropdown", {
        width = 236,
        height = CONTROL_HEIGHT - 2,
        items = PANEL_SIDE_ITEMS,
        onValueChanged = function(value)
            commitSelectedItemSlot(self, function(itemSlot)
                itemSlot.panelSide = value
            end)
        end,
    })
    root:AddChild(self.ItemSlotInspectorPanelSideDropdown)

    root:AddChild(UI.CreateText(root:GetFrame(), "RPEDataEditorItemSlotInspectorSlotTypeLabel", "Slot Owner", {
        width = 236, height = 12, justifyH = "LEFT", textColor = UI.ResolveColor(nil, "text.secondary"),
    }))
    self.ItemSlotInspectorSlotTypeDropdown = UI.CreateDropdown(root:GetFrame(), "RPEDataEditorItemSlotInspectorSlotTypeDropdown", {
        width = 236,
        height = CONTROL_HEIGHT - 2,
        items = SLOT_TYPE_ITEMS,
        onValueChanged = function(value)
            commitSelectedItemSlot(self, function(itemSlot)
                itemSlot.slotType = value
            end)
        end,
    })
    root:AddChild(self.ItemSlotInspectorSlotTypeDropdown)

    root:AddChild(UI.CreateText(root:GetFrame(), "RPEDataEditorItemSlotInspectorPriorityLabel", "Equipment Priority", {
        width = 236, height = 12, justifyH = "LEFT", textColor = UI.ResolveColor(nil, "text.secondary"),
    }))
    self.ItemSlotInspectorPriorityInput = UI.CreateTextInput(root:GetFrame(), "RPEDataEditorItemSlotInspectorPriorityInput", {
        width = 236, height = CONTROL_HEIGHT, text = "0", borderColor = UI.ResolveColor(nil, "panel.border"),
    })
    self.ItemSlotInspectorPriorityInput:SetScript("OnEnterPressed", function()
        commitSelectedItemSlot(self, function(itemSlot)
            itemSlot.priority = tonumber(self.ItemSlotInspectorPriorityInput:GetText()) or 0
        end)
    end)
    self.ItemSlotInspectorPriorityInput:SetScript("OnEditFocusLost", function()
        commitSelectedItemSlot(self, function(itemSlot)
            itemSlot.priority = tonumber(self.ItemSlotInspectorPriorityInput:GetText()) or 0
        end)
    end)
    root:AddChild(self.ItemSlotInspectorPriorityInput)

    self.ItemSlotInspectorIconInput = {
        SetText = function(_, value)
            local iconPath = value ~= nil and tostring(value) or ""
            self.ItemSlotInspectorIconField:SetIcon(iconPath ~= "" and iconPath or "Interface\\Icons\\INV_Misc_QuestionMark")
            self.ItemSlotInspectorIconField:SetLabelText(iconPath ~= "" and iconPath or "-")
        end,
        SetEnabled = function(_, enabled) self.ItemSlotInspectorIconField:SetEnabled(enabled) end,
        SetReadOnly = function(_, readOnly) self.ItemSlotInspectorIconField:SetEnabled(readOnly ~= true) end,
    }

    self.ItemSlotInspectorEmptyText = UI.CreateText(root:GetFrame(), "RPEDataEditorItemSlotInspectorEmptyText", "", {
        width = 236, height = 20, justifyH = "LEFT", textColor = UI.ResolveColor(nil, "text.secondary"),
    })
    root:AddChild(self.ItemSlotInspectorEmptyText)

    self:RefreshItemSlotInspectorPage()
    return self.ItemSlotInspectorPage
end

function DataEditor:RefreshItemSlotInspectorPage()
    local itemSlot = self:GetSelectedItemSlot()
    local hasItemSlot = itemSlot ~= nil

    if self.ItemSlotInspectorNameInput then
        self.ItemSlotInspectorNameInput:SetText(itemSlot and (itemSlot.name or "") or "")
        self.ItemSlotInspectorNameInput:SetEnabled(hasItemSlot)
        self.ItemSlotInspectorNameInput:SetReadOnly(not hasItemSlot)
    end
    if self.ItemSlotInspectorIdText then
        self.ItemSlotInspectorIdText:SetText(("ID: %s"):format(itemSlot and tostring(itemSlot.id or "") or "-"))
    end
    if self.ItemSlotInspectorIconInput then
        self.ItemSlotInspectorIconInput:SetText(itemSlot and (itemSlot.icon or "") or "")
        self.ItemSlotInspectorIconInput:SetEnabled(hasItemSlot)
    end
    if self.ItemSlotInspectorPanelSideDropdown then
        self.ItemSlotInspectorPanelSideDropdown:SetItems(PANEL_SIDE_ITEMS)
        self.ItemSlotInspectorPanelSideDropdown:SetSelectedValue(itemSlot and itemSlot.panelSide or "left", true)
        self.ItemSlotInspectorPanelSideDropdown:SetEnabled(hasItemSlot)
    end
    if self.ItemSlotInspectorSlotTypeDropdown then
        self.ItemSlotInspectorSlotTypeDropdown:SetItems(SLOT_TYPE_ITEMS)
        self.ItemSlotInspectorSlotTypeDropdown:SetSelectedValue(itemSlot and itemSlot.slotType or "character", true)
        self.ItemSlotInspectorSlotTypeDropdown:SetEnabled(hasItemSlot)
    end
    if self.ItemSlotInspectorPriorityInput then
        self.ItemSlotInspectorPriorityInput:SetText(tostring(itemSlot and itemSlot.priority or 0))
        self.ItemSlotInspectorPriorityInput:SetEnabled(hasItemSlot)
        self.ItemSlotInspectorPriorityInput:SetReadOnly(not hasItemSlot)
    end
    if self.ItemSlotInspectorEmptyText then
        self.ItemSlotInspectorEmptyText:SetText(hasItemSlot and "Adjust the selected item slot here." or "Select an item slot to inspect it.")
    end
end
