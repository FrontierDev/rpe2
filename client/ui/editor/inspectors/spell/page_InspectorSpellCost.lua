local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Client.UI = Addon.Client.UI or {}
Addon.Client.UI.Editor = Addon.Client.UI.Editor or {}

local DataEditor = Addon.Client.UI.Editor
local UI = Addon.UI or {}

local RESOURCE_COST_MODE_ITEMS = {
    { label = "Flat", value = "flat" },
    { label = "% Base", value = "base_percent" },
    { label = "% Max", value = "max_percent" },
}

function DataEditor:EnsureSpellInspectorResourceCostContextMenu()
    if self.SpellInspectorResourceCostContextMenu then
        return self.SpellInspectorResourceCostContextMenu
    end

    self.SpellInspectorResourceCostContextMenu = UI.ContextMenu:New({
        name = "RPEDataEditorSpellInspectorResourceCostContextMenu",
        width = 120,
        panelWidth = 120,
        visibleRows = 2,
        rowHeight = 18,
        border = false,
        onItemInvoked = function(item, menu)
            if not item or item.value ~= "remove-resource-cost" or not self.ContextMenuSpellResourceCostIndex then
                return
            end

            local removeIndex = self.ContextMenuSpellResourceCostIndex
            self:CommitSelectedSpell(function(spell)
                table.remove(spell.resourceCosts or {}, removeIndex)
            end)

            if menu and menu.HideMenus then
                menu:HideMenus()
            end
        end,
    })
    self.SpellInspectorResourceCostContextMenu:SetParent(self.SpellInspectorPage or UIParent)
    self.SpellInspectorResourceCostContextMenu:Create()
    return self.SpellInspectorResourceCostContextMenu
end

function DataEditor:ShowSpellInspectorResourceCostContextMenu(anchorFrame, rowData)
    if not rowData or not rowData.rowIndex then
        return
    end

    local menu = self:EnsureSpellInspectorResourceCostContextMenu()
    self.ContextMenuSpellResourceCostIndex = rowData.rowIndex
    menu:SetItems({
        { label = "Remove", value = "remove-resource-cost" },
    })
    menu:ShowAt(anchorFrame)
end

function DataEditor:BuildSpellInspectorResourceCostRows(spell)
    local rows = {}

    for index = 1, #(spell and spell.resourceCosts or {}) do
        local cost = spell.resourceCosts[index]
        rows[#rows + 1] = {
            rowIndex = index,
            resourceRef = cost and cost.resourceRef or "",
            resourceText = self:ResolveSpellInspectorReferenceLabel("resources", cost and cost.resourceRef or ""),
            amountModeText = tostring(cost and cost.amountMode or "flat"),
            phaseText = tostring(cost and cost.castPhase or "on_cast_end"),
            amountText = tostring(cost and cost.amount or 0),
        }
    end

    return rows
end

function DataEditor:RefreshSpellInspectorResourceCostsTable()
    local _, spell = self:GetSelectedSpellAndDataset()
    local rows = self:BuildSpellInspectorResourceCostRows(spell)
    if self.SpellInspectorResourceCostsScroll and self.SpellInspectorResourceCostsScroll.SetItems then
        self.SpellInspectorResourceCostsScroll:SetItems(rows)
    end
end

function DataEditor:BuildSpellInspectorCostPage(page)
    local root = UI.CreateLayout(UI.VerticalLayoutGroup, page, "RPEDataEditorSpellInspectorCostLayout", {
        spacing = 6,
        fitChildrenWidth = true,
        fitChildrenHeight = false,
    })
    UI.Utils.AnchorFill(root, page, 0, 0, 0, 0)

    root:AddChild(self:BuildSpellInspectorLabel(root:GetFrame(), "RPEDataEditorSpellInspectorResourceCostsLabel", "Resource Costs"))

    self.SpellInspectorResourceCostsPanel = UI.CreatePanel(root:GetFrame(), "RPEDataEditorSpellInspectorResourceCostsPanel", {
        width = self.SpellInspectorFieldWidth,
        height = 74,
        contentInset = 1,
        showBorder = true,
    })
    root:AddChild(self.SpellInspectorResourceCostsPanel)

    self.SpellInspectorResourceCostsScroll = UI.ScrollLayout:New({
        name = "RPEDataEditorSpellInspectorResourceCostsScroll",
        width = self.SpellInspectorFieldWidth,
        height = 72,
        visibleRows = 4,
        rowHeight = 18,
        rowSpacing = 0,
        border = false,
        rowElementClass = UI.TableRow,
    })
    self.SpellInspectorResourceCostsScroll:SetParent(self.SpellInspectorResourceCostsPanel:GetContentFrame())
    self.SpellInspectorResourceCostsScroll:SetRowRenderer(function(row, item, itemIndex)
        if row.SetColumns then
            row:SetColumns({
                { key = "resourceText", width = 94, justifyH = "LEFT" },
                { key = "amountModeText", width = 46, justifyH = "LEFT" },
                { key = "phaseText", width = 68, justifyH = "LEFT" },
                { key = "amountText", width = 42, justifyH = "RIGHT" },
            })
        end
        if row.SetRowData then
            row:SetRowData(item, itemIndex or 0)
        end
        if row.SetRowMouseUpHandler then
            row:SetRowMouseUpHandler(function(tableRow, button, rowData)
                if button == "RightButton" then
                    local anchor = tableRow and tableRow.GetFrame and tableRow:GetFrame() or nil
                    self:ShowSpellInspectorResourceCostContextMenu(anchor, rowData)
                end
            end)
        end
    end)
    self.SpellInspectorResourceCostsScroll:Create()
    UI.Utils.AnchorFill(self.SpellInspectorResourceCostsScroll, self.SpellInspectorResourceCostsPanel:GetContentFrame(), 0, 0, 0, 0)

    self.SpellInspectorPendingResourceCostRow = UI.CreateLayout(UI.HorizontalLayoutGroup, root:GetFrame(), "RPEDataEditorSpellInspectorPendingResourceCostRow", {
        width = self.SpellInspectorFieldWidth,
        height = 18,
        spacing = 2,
        fitChildrenWidth = true,
        fitChildrenHeight = false,
    })
    root:AddChild(self.SpellInspectorPendingResourceCostRow)

    self.SpellInspectorPendingResourceRefDropdown = UI.CreateDropdown(self.SpellInspectorPendingResourceCostRow:GetFrame(), "RPEDataEditorSpellInspectorPendingResourceRefDropdown", {
        width = 72,
        height = 18,
        expandWidth = true,
        weight = 1,
        items = {
            { label = "None", value = "" },
        },
    })
    self.SpellInspectorPendingResourceCostRow:AddChild(self.SpellInspectorPendingResourceRefDropdown)

    self.SpellInspectorPendingResourceCastPhaseDropdown = UI.CreateDropdown(self.SpellInspectorPendingResourceCostRow:GetFrame(), "RPEDataEditorSpellInspectorPendingResourceCastPhaseDropdown", {
        width = 56,
        height = 18,
        items = self:GetSpellInspectorCastPhaseItems(),
    })
    self.SpellInspectorPendingResourceCostRow:AddChild(self.SpellInspectorPendingResourceCastPhaseDropdown)

    self.SpellInspectorPendingResourceAmountModeDropdown = UI.CreateDropdown(self.SpellInspectorPendingResourceCostRow:GetFrame(), "RPEDataEditorSpellInspectorPendingResourceAmountModeDropdown", {
        width = 42,
        height = 18,
        items = RESOURCE_COST_MODE_ITEMS,
    })
    self.SpellInspectorPendingResourceCostRow:AddChild(self.SpellInspectorPendingResourceAmountModeDropdown)

    self.SpellInspectorPendingResourceAmountInput = UI.CreateTextInput(self.SpellInspectorPendingResourceCostRow:GetFrame(), "RPEDataEditorSpellInspectorPendingResourceAmountInput", {
        width = 28,
        height = 18,
        text = "0",
        borderColor = UI.ResolveColor(nil, "panel.border"),
    })
    self.SpellInspectorPendingResourceCostRow:AddChild(self.SpellInspectorPendingResourceAmountInput)

    self.SpellInspectorAddResourceCostButton = UI.CreateButton(self.SpellInspectorPendingResourceCostRow:GetFrame(), "RPEDataEditorSpellInspectorAddResourceCostButton", "Add", 30, function()
        if self._refreshingSpellInspector then
            return
        end

        local resourceRef = self.SpellInspectorPendingResourceRefDropdown and self.SpellInspectorPendingResourceRefDropdown.GetSelectedValue and self.SpellInspectorPendingResourceRefDropdown:GetSelectedValue() or ""
        if resourceRef == "" then
            return
        end

        local castPhase = self.SpellInspectorPendingResourceCastPhaseDropdown and self.SpellInspectorPendingResourceCastPhaseDropdown.GetSelectedValue and self.SpellInspectorPendingResourceCastPhaseDropdown:GetSelectedValue() or "on_cast_end"
        local amountMode = self.SpellInspectorPendingResourceAmountModeDropdown and self.SpellInspectorPendingResourceAmountModeDropdown.GetSelectedValue and self.SpellInspectorPendingResourceAmountModeDropdown:GetSelectedValue() or "flat"
        local amount = tonumber(self.SpellInspectorPendingResourceAmountInput and self.SpellInspectorPendingResourceAmountInput:GetText()) or 0

        self:CommitSelectedSpell(function(spell)
            spell.resourceCosts = spell.resourceCosts or {}
            spell.resourceCosts[#spell.resourceCosts + 1] = {
                resourceRef = resourceRef,
                castPhase = castPhase,
                amountMode = amountMode,
                refundOnInterrupt = 0,
                amount = amount,
            }
        end)
    end, {
        height = 18,
        fontSize = 7,
    })
    self.SpellInspectorPendingResourceCostRow:AddChild(self.SpellInspectorAddResourceCostButton)
end
