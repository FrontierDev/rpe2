local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Client.UI = Addon.Client.UI or {}
Addon.Client.UI.Editor = Addon.Client.UI.Editor or {}

local DataEditor = Addon.Client.UI.Editor
local UI = Addon.UI or {}

function DataEditor:BuildRecipePage(page)
    if self.RecipePageRoot then
        return self.RecipePageRoot
    end

    self.RecipePageRoot = UI.CreateLayout(UI.VerticalLayoutGroup, page, "RPEDataEditorRecipePageRoot", {
        spacing = 4,
        fitChildrenWidth = true,
        fitChildrenHeight = true,
    })
    UI.Utils.AnchorFill(self.RecipePageRoot, page, 0, 0, 0, 0)

    local listPanel = UI.CreatePanel(self.RecipePageRoot:GetFrame(), "RPEDataEditorRecipeListPanel", {
        width = 150,
        expandHeight = true,
        weight = 1,
        contentInset = 2,
        showBorder = false,
    })
    self.RecipePageRoot:AddChild(listPanel)

    self.RecipePageScroll = UI.ScrollLayout:New({
        name = "RPEDataEditorRecipeScroll",
        width = 146,
        height = 304,
        visibleRows = 12,
        autoFitRows = true,
        rowHeight = 16,
        rowSpacing = 0,
        border = false,
        rowElementClass = UI.ScrollListEntry,
        categoryWidth = 132,
        statusWidth = 0,
        categoryInsetLeft = 4,
        statusInsetRight = 4,
    })
    self.RecipePageScroll:SetParent(listPanel:GetContentFrame())
    self.RecipePageScroll:SetRowRenderer(function(row, recipe, itemIndex)
        if row.SetCategory then
            row:SetCategory(self:GetEntryDisplayName("recipes", recipe))
        end
        if row.SetTestName then
            row:SetTestName("")
        end
        if row.SetStatus then
            row:SetStatus("")
        end
        if row.SetDetail then
            row:SetDetail(recipe and recipe.description or "")
        end

        local frame = row.GetFrame and row:GetFrame() or nil
        if frame then
            frame:EnableMouse(true)
            frame:SetScript("OnMouseUp", function(_, button)
                if button == "LeftButton" then
                    self:SetSelectedDatasetEntryIndex("recipes", itemIndex)
                end
            end)

            local selectedEntry = self.SelectedEntryIndices and self.SelectedEntryIndices.recipes or nil
            local isSelected = tonumber(selectedEntry) == tonumber(itemIndex)
            if row.entryBackground and row.entryBackground.SetColorTexture then
                local token = isSelected and "list.rowHover" or "list.rowBackground"
                local color = UI.ResolveColor(nil, token)
                row.entryBackground:SetColorTexture(color.r or 0.08, color.g or 0.09, color.b or 0.11, color.a or 0.85)
            end
        end
    end)
    self.RecipePageScroll:Create()
    UI.Utils.AnchorFill(self.RecipePageScroll, listPanel:GetContentFrame(), 0, 0, 0, 0)

    self.RecipePageEmptyText = UI.CreateText(listPanel:GetContentFrame(), "RPEDataEditorRecipeEmptyText", "", {
        fontFile = (UI.Constants and UI.Constants.FontFiles and UI.Constants.FontFiles.Default) or "Fonts\\FRIZQT__.TTF",
        fontSize = (UI.Constants and UI.Constants.FontSizes and UI.Constants.FontSizes.Body) or 8,
        textColor = UI.ResolveColor(nil, "text.secondary"),
        width = 122,
        height = 40,
        justifyH = "CENTER",
        wordWrap = true,
    })
    self.RecipePageEmptyText:GetFrame():SetPoint("CENTER", listPanel:GetContentFrame(), "CENTER", 0, 0)

    self.RecipePageToolbar, self.RecipePageButtons = self:BuildDataPageToolbar(self.RecipePageRoot:GetFrame(), "RPEDataEditorRecipePageToolbar", "recipes")
    self.RecipePageRoot:AddChild(self.RecipePageToolbar)

    self:RefreshRecipeDataPage()
    return self.RecipePageRoot
end

function DataEditor:RefreshRecipeDataPage()
    if not self.RecipePageRoot then
        return
    end

    local dataset = self:GetSelectedDataset()
    local recipes = dataset and dataset.recipes or {}

    self:RefreshDataPageToolbar(self.RecipePageButtons)

    if self.RecipePageScroll and self.RecipePageScroll.SetItems then
        self.RecipePageScroll:SetItems(recipes)
    end

    if self.RecipePageEmptyText and self.RecipePageEmptyText.SetText then
        if not dataset then
            self.RecipePageEmptyText:SetText("Create or select a dataset to view recipes.")
        elseif #recipes == 0 then
            self.RecipePageEmptyText:SetText("This dataset has no recipes yet.")
        else
            self.RecipePageEmptyText:SetText("")
        end
    end
end
