local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Client.UI = Addon.Client.UI or {}
Addon.Client.UI.Editor = Addon.Client.UI.Editor or {}

local DataEditor = Addon.Client.UI.Editor
local UI = Addon.UI or {}

local function buildPetStatusText(editor, pet)
    pet = pet or {}
    local unitLabel = editor.ResolveUnitInspectorReferenceLabel and editor:ResolveUnitInspectorReferenceLabel("units", pet.unitRef) or "No Unit"
    return ("%s, %d spell%s, %d slot%s"):format(
        tostring(unitLabel or "No Unit"),
        #(pet.spells or {}),
        #(pet.spells or {}) == 1 and "" or "s",
        #(pet.equipmentSlotRefs or {}),
        #(pet.equipmentSlotRefs or {}) == 1 and "" or "s"
    )
end

local function buildPetDetailText(editor, pet)
    pet = pet or {}
    local unitLabel = editor.ResolveUnitInspectorReferenceLabel and editor:ResolveUnitInspectorReferenceLabel("units", pet.unitRef) or ""
    if tostring(unitLabel or "") ~= "" and tostring(unitLabel or "") ~= "-" then
        return ("Unit: %s"):format(unitLabel)
    end

    return "No unit selected"
end

function DataEditor:BuildPetsPage(page)
    if self.PetsPageRoot then
        return self.PetsPageRoot
    end

    self.PetsPageRoot = UI.CreateLayout(UI.VerticalLayoutGroup, page, "RPEDataEditorPetsPageRoot", {
        spacing = 4,
        fitChildrenWidth = true,
        fitChildrenHeight = true,
    })
    UI.Utils.AnchorFill(self.PetsPageRoot, page, 0, 0, 0, 0)

    local listPanel = UI.CreatePanel(self.PetsPageRoot:GetFrame(), "RPEDataEditorPetsListPanel", {
        width = 150,
        expandHeight = true,
        weight = 1,
        contentInset = 2,
        showBorder = false,
    })
    self.PetsPageRoot:AddChild(listPanel)

    self.PetsPageScroll = UI.ScrollLayout:New({
        name = "RPEDataEditorPetsScroll",
        width = 146,
        height = 248,
        visibleRows = 10,
        autoFitRows = true,
        rowHeight = 16,
        rowSpacing = 0,
        border = false,
        rowElementClass = UI.ScrollListEntry,
        categoryWidth = 82,
        statusWidth = 50,
        categoryInsetLeft = 4,
        statusInsetRight = 4,
    })
    self.PetsPageScroll:SetParent(listPanel:GetContentFrame())
    self.PetsPageScroll:SetRowRenderer(function(row, pet, itemIndex)
        if row.SetCategory then
            row:SetCategory(self:GetEntryDisplayName("pets", pet))
        end
        if row.SetTestName then
            row:SetTestName("")
        end
        if row.SetStatus then
            row:SetStatus(buildPetStatusText(self, pet))
        end
        if row.SetDetail then
            row:SetDetail(buildPetDetailText(self, pet))
        end

        local frame = row.GetFrame and row:GetFrame() or nil
        if frame then
            frame:EnableMouse(true)
            frame:SetScript("OnMouseUp", function(_, button)
                if button == "LeftButton" then
                    self:SetSelectedDatasetEntryIndex("pets", itemIndex)
                end
            end)

            local _, selectedIndex = self:GetSelectedDatasetEntry("pets")
            local isSelected = tonumber(selectedIndex) == tonumber(itemIndex)
            if row.entryBackground and row.entryBackground.SetColorTexture then
                local token = isSelected and "list.rowHover" or "list.rowBackground"
                local color = UI.ResolveColor(nil, token)
                row.entryBackground:SetColorTexture(color.r or 0.08, color.g or 0.09, color.b or 0.11, color.a or 0.85)
            end
        end
    end)
    self.PetsPageScroll:Create()
    UI.Utils.AnchorFill(self.PetsPageScroll, listPanel:GetContentFrame(), 0, 0, 0, 0)

    self.PetsPageEmptyText = UI.CreateText(listPanel:GetContentFrame(), "RPEDataEditorPetsEmptyText", "", {
        fontFile = (UI.Constants and UI.Constants.FontFiles and UI.Constants.FontFiles.Default) or "Fonts\\FRIZQT__.TTF",
        fontSize = (UI.Constants and UI.Constants.FontSizes and UI.Constants.FontSizes.Body) or 8,
        textColor = UI.ResolveColor(nil, "text.secondary"),
        width = 122,
        height = 36,
        justifyH = "CENTER",
        wordWrap = true,
    })
    self.PetsPageEmptyText:GetFrame():SetPoint("CENTER", listPanel:GetContentFrame(), "CENTER", 0, 0)

    self.PetsPageToolbar, self.PetsPageButtons = self:BuildDataPageToolbar(self.PetsPageRoot:GetFrame(), "RPEDataEditorPetsPageToolbar", "pets")
    self.PetsPageRoot:AddChild(self.PetsPageToolbar)

    self:RefreshPetsDataPage()
    return self.PetsPageRoot
end

function DataEditor:RefreshPetsDataPage()
    local dataset = self:GetSelectedDataset()
    local pets = dataset and dataset.pets or {}

    self:RefreshDataPageToolbar(self.PetsPageButtons)

    if self.PetsPageScroll and self.PetsPageScroll.SetItems then
        self.PetsPageScroll:SetItems(pets)
    end

    if self.PetsPageEmptyText and self.PetsPageEmptyText.SetText then
        if not dataset then
            self.PetsPageEmptyText:SetText("Create or select a dataset to view pets.")
        elseif #pets == 0 then
            self.PetsPageEmptyText:SetText("This dataset has no pets yet.")
        else
            self.PetsPageEmptyText:SetText("")
        end
    end
end
