local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Client.UI = Addon.Client.UI or {}
Addon.Client.UI.Editor = Addon.Client.UI.Editor or {}

local DataEditor = Addon.Client.UI.Editor
local UI = Addon.UI or {}

function DataEditor:EnsurePetInspectorSpellContextMenu()
    if self.PetInspectorSpellContextMenu then
        return self.PetInspectorSpellContextMenu
    end

    self.PetInspectorSpellContextMenu = UI.ContextMenu:New({
        name = "RPEDataEditorPetInspectorSpellContextMenu",
        width = 120,
        panelWidth = 120,
        visibleRows = 1,
        rowHeight = 18,
        border = false,
        onItemInvoked = function(item, menu)
            if not item or item.value ~= "remove-spell" or not self.ContextMenuPetSpellIndex then
                return
            end

            local removeIndex = self.ContextMenuPetSpellIndex
            self:CommitSelectedPet(function(pet)
                table.remove(pet.spells or {}, removeIndex)
            end)

            if menu and menu.HideMenus then
                menu:HideMenus()
            end
        end,
    })
    self.PetInspectorSpellContextMenu:SetParent(self.PetInspectorPage or UIParent)
    self.PetInspectorSpellContextMenu:Create()
    return self.PetInspectorSpellContextMenu
end

function DataEditor:ShowPetInspectorSpellContextMenu(anchorFrame, rowData)
    if not rowData or not rowData.rowIndex then
        return
    end

    local menu = self:EnsurePetInspectorSpellContextMenu()
    self.ContextMenuPetSpellIndex = rowData.rowIndex
    menu:SetItems({
        { label = "Remove", value = "remove-spell" },
    })
    menu:ShowAt(anchorFrame)
end

function DataEditor:BuildPetInspectorSpellRows(pet)
    local rows = {}

    for index = 1, #(pet and pet.spells or {}) do
        local spellRef = pet.spells[index]
        rows[#rows + 1] = {
            rowIndex = index,
            spellText = self:ResolveUnitInspectorReferenceLabel("spells", spellRef),
        }
    end

    return rows
end

function DataEditor:RefreshPetInspectorSpellsTable()
    local _, pet = self:GetSelectedPetAndDataset()
    if self.PetInspectorSpellsScroll and self.PetInspectorSpellsScroll.SetItems then
        self.PetInspectorSpellsScroll:SetItems(self:BuildPetInspectorSpellRows(pet))
    end
end

function DataEditor:BuildPetInspectorSpellsPage(page)
    local root = UI.CreateLayout(UI.VerticalLayoutGroup, page, "RPEDataEditorPetInspectorSpellsLayout", {
        spacing = 6,
        fitChildrenWidth = true,
        fitChildrenHeight = false,
    })
    UI.Utils.AnchorFill(root, page, 0, 0, 0, 0)

    root:AddChild(self:BuildPetInspectorLabel(root:GetFrame(), "RPEDataEditorPetInspectorSpellsLabel", "Spellbook Override"))

    self.PetInspectorSpellsPanel = UI.CreatePanel(root:GetFrame(), "RPEDataEditorPetInspectorSpellsPanel", {
        width = self.PetInspectorFieldWidth,
        height = 146,
        contentInset = 1,
        showBorder = true,
    })
    root:AddChild(self.PetInspectorSpellsPanel)

    self.PetInspectorSpellsScroll = UI.ScrollLayout:New({
        name = "RPEDataEditorPetInspectorSpellsScroll",
        width = self.PetInspectorFieldWidth,
        height = 144,
        visibleRows = 8,
        rowHeight = 18,
        rowSpacing = 0,
        border = false,
        rowElementClass = UI.TableRow,
    })
    self.PetInspectorSpellsScroll:SetParent(self.PetInspectorSpellsPanel:GetContentFrame())
    self.PetInspectorSpellsScroll:SetRowRenderer(function(row, item, itemIndex)
        if row.SetColumns then
            row:SetColumns({
                { key = "spellText", width = 220, justifyH = "LEFT" },
            })
        end
        if row.SetRowData then
            row:SetRowData(item, itemIndex or 0)
        end
        if row.SetRowMouseUpHandler then
            row:SetRowMouseUpHandler(function(tableRow, button, rowData)
                if button == "RightButton" then
                    local anchor = tableRow and tableRow.GetFrame and tableRow:GetFrame() or nil
                    self:ShowPetInspectorSpellContextMenu(anchor, rowData)
                end
            end)
        end
    end)
    self.PetInspectorSpellsScroll:Create()
    UI.Utils.AnchorFill(self.PetInspectorSpellsScroll, self.PetInspectorSpellsPanel:GetContentFrame(), 0, 0, 0, 0)

    self.PetInspectorPendingSpellRow = UI.CreateLayout(UI.HorizontalLayoutGroup, root:GetFrame(), "RPEDataEditorPetInspectorPendingSpellRow", {
        width = self.PetInspectorFieldWidth,
        height = 18,
        spacing = 2,
        fitChildrenWidth = false,
        fitChildrenHeight = false,
    })
    root:AddChild(self.PetInspectorPendingSpellRow)

    self.PetInspectorPendingSpellDropdown = UI.CreateDropdown(self.PetInspectorPendingSpellRow:GetFrame(), "RPEDataEditorPetInspectorPendingSpellDropdown", {
        width = 198,
        height = 18,
        items = {
            { label = "None", value = "" },
        },
    })
    self.PetInspectorPendingSpellRow:AddChild(self.PetInspectorPendingSpellDropdown)

    self.PetInspectorAddSpellButton = UI.CreateButton(self.PetInspectorPendingSpellRow:GetFrame(), "RPEDataEditorPetInspectorAddSpellButton", "Add", 36, function()
        if self._refreshingPetInspector then
            return
        end

        local spellRef = self.PetInspectorPendingSpellDropdown and self.PetInspectorPendingSpellDropdown.GetSelectedValue and self.PetInspectorPendingSpellDropdown:GetSelectedValue() or ""
        if spellRef == "" then
            return
        end

        self:CommitSelectedPet(function(pet)
            pet.spells = pet.spells or {}
            pet.spells[#pet.spells + 1] = spellRef
        end)
    end, {
        height = 18,
        fontSize = 7,
    })
    self.PetInspectorPendingSpellRow:AddChild(self.PetInspectorAddSpellButton)

    self.PetInspectorSpellsHintText = UI.CreateText(root:GetFrame(), "RPEDataEditorPetInspectorSpellsHintText", "This override replaces the referenced unit's authored spell list when the pet is resolved for summoning/runtime use.", {
        width = self.PetInspectorFieldWidth,
        height = 24,
        justifyH = "LEFT",
        wordWrap = true,
        textColor = UI.ResolveColor(nil, "text.secondary"),
    })
    root:AddChild(self.PetInspectorSpellsHintText)
end
