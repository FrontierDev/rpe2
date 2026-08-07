local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Client.UI = Addon.Client.UI or {}
Addon.Client.UI.Editor = Addon.Client.UI.Editor or {}

local DataEditor = Addon.Client.UI.Editor
local UI = Addon.UI or {}
local Profile = Addon.Internal and Addon.Internal.Profile or {}
local ProfileWindow = Addon.Client and Addon.Client.UI and Addon.Client.UI.Profile and Addon.Client.UI.Profile.Window or {}
local Client = Addon.Client or {}

local function refreshProfileWindow()
    local window = ProfileWindow.Get and ProfileWindow:Get() or nil
    if window and window.Refresh then
        window:Refresh()
    end
end

local function getTraitStatusText(trait)
    if not trait then
        return ""
    end

    if trait.isEnvironmental == true then
        return "Env"
    end
    if trait.isClass == true then
        return "Class"
    end
    if trait.isRacial == true then
        return "Race"
    end

    return "Talent"
end

local function getTraitDetailText(trait)
    if not trait then
        return ""
    end

    local description = tostring(trait.description or "")
    if description ~= "" then
        return description
    end

    return ("%d stats, %d skills, %d auras, %d events"):format(
        #(trait.statBonuses or {}),
        #(trait.skillBonuses or {}),
        #(trait.automaticAuras or {}),
        #(trait.events or {})
    )
end

function DataEditor:BuildTraitsPage(page)
    if self.TraitsPageRoot then
        return self.TraitsPageRoot
    end

    self.TraitsPageRoot = UI.CreateLayout(UI.VerticalLayoutGroup, page, "RPEDataEditorTraitsPageRoot", {
        spacing = 4,
        fitChildrenWidth = true,
        fitChildrenHeight = true,
    })
    UI.Utils.AnchorFill(self.TraitsPageRoot, page, 0, 0, 0, 0)

    local listPanel = UI.CreatePanel(self.TraitsPageRoot:GetFrame(), "RPEDataEditorTraitsListPanel", {
        width = 150,
        expandHeight = true,
        weight = 1,
        contentInset = 2,
        showBorder = false,
    })
    self.TraitsPageRoot:AddChild(listPanel)

    self.TraitsPageScroll = UI.ScrollLayout:New({
        name = "RPEDataEditorTraitsScroll",
        width = 146,
        height = 248,
        visibleRows = 10,
        autoFitRows = true,
        rowHeight = 16,
        rowSpacing = 0,
        border = false,
        rowElementClass = UI.ScrollListEntry,
        categoryWidth = 84,
        statusWidth = 48,
        categoryInsetLeft = 4,
        statusInsetRight = 4,
    })
    self.TraitsPageScroll:SetParent(listPanel:GetContentFrame())
    self.TraitsPageScroll:SetRowRenderer(function(row, trait, itemIndex)
        if row.SetCategory then
            row:SetCategory(self:GetEntryDisplayName("traits", trait))
        end
        if row.SetTestName then
            row:SetTestName("")
        end
        if row.SetStatus then
            row:SetStatus(getTraitStatusText(trait))
        end
        if row.SetDetail then
            row:SetDetail(getTraitDetailText(trait))
        end

        local frame = row.GetFrame and row:GetFrame() or nil
        if frame then
            frame:EnableMouse(true)
            frame:SetScript("OnMouseUp", function(_, button)
                if button == "LeftButton" then
                    self:SetSelectedDatasetEntryIndex("traits", itemIndex)
                    if self.TraitsContextMenu and self.TraitsContextMenu.HideMenus then
                        self.TraitsContextMenu:HideMenus()
                    end
                elseif button == "RightButton" and trait then
                    self:SetSelectedDatasetEntryIndex("traits", itemIndex)
                    self:ShowTraitsContextMenu(frame, trait)
                end
            end)

            local selectedEntry = self.SelectedEntryIndices and self.SelectedEntryIndices.traits or nil
            local isSelected = tonumber(selectedEntry) == tonumber(itemIndex)
            if row.entryBackground and row.entryBackground.SetColorTexture then
                local token = isSelected and "list.rowHover" or "list.rowBackground"
                local color = UI.ResolveColor(nil, token)
                row.entryBackground:SetColorTexture(color.r or 0.08, color.g or 0.09, color.b or 0.11, color.a or 0.85)
            end
        end
    end)
    self.TraitsPageScroll:Create()
    UI.Utils.AnchorFill(self.TraitsPageScroll, listPanel:GetContentFrame(), 0, 0, 0, 0)

    self.TraitsPageEmptyText = UI.CreateText(listPanel:GetContentFrame(), "RPEDataEditorTraitsEmptyText", "", {
        fontFile = (UI.Constants and UI.Constants.FontFiles and UI.Constants.FontFiles.Default) or "Fonts\\FRIZQT__.TTF",
        fontSize = (UI.Constants and UI.Constants.FontSizes and UI.Constants.FontSizes.Body) or 8,
        textColor = UI.ResolveColor(nil, "text.secondary"),
        width = 122,
        height = 40,
        justifyH = "CENTER",
        wordWrap = true,
    })
    self.TraitsPageEmptyText:GetFrame():SetPoint("CENTER", listPanel:GetContentFrame(), "CENTER", 0, 0)

    self.TraitsPageToolbar, self.TraitsPageButtons = self:BuildDataPageToolbar(self.TraitsPageRoot:GetFrame(), "RPEDataEditorTraitsPageToolbar", "traits")
    self.TraitsPageRoot:AddChild(self.TraitsPageToolbar)

    self:RefreshTraitsDataPage()
    return self.TraitsPageRoot
end

function DataEditor:EnsureTraitsContextMenu()
    if self.TraitsContextMenu then
        return self.TraitsContextMenu
    end

    self.TraitsContextMenu = UI.ContextMenu:New({
        name = "RPEDataEditorTraitsContextMenu",
        width = 160,
        panelWidth = 160,
        visibleRows = 2,
        rowHeight = 18,
        border = false,
        onItemInvoked = function(item, menu)
            local action = item and item.value or nil
            local datasetId = self.ContextMenuTraitDatasetId
            local traitId = self.ContextMenuTraitId
            if action == "add-to-traits" and datasetId and traitId and Profile.AddKnownTrait then
                local added = Profile.AddKnownTrait(("%s:%s"):format(tostring(datasetId), tostring(traitId)))
                if added then
                    refreshProfileWindow()
                end
            end

            if menu and menu.HideMenus then
                menu:HideMenus()
            end
        end,
    })
    self.TraitsContextMenu:SetParent(self.Window and self.Window:GetFrame() or UIParent)
    self.TraitsContextMenu:Create()
    return self.TraitsContextMenu
end

function DataEditor:ShowTraitsContextMenu(anchorFrame, trait)
    local dataset = self:GetSelectedDataset()
    if not anchorFrame or not trait or not dataset or not dataset.id or not trait.id then
        return
    end

    local items = {}
    local category = trait.isClass == true and "class" or (trait.isRacial == true and "race" or tostring(trait.category or "") ~= "" and tostring(trait.category or "") or "General")
    local canAddToProfile = trait.isEnvironmental ~= true
        and trait.isClass ~= true
        and trait.isRacial ~= true
        and (type(Client.IsTraitCategoryAllowed) ~= "function" or Client:IsTraitCategoryAllowed(category))
    if canAddToProfile then
        items[#items + 1] = {
            label = "Add To Traits",
            value = "add-to-traits",
        }
    end
    if #items == 0 then
        return
    end

    local menu = self:EnsureTraitsContextMenu()
    self.ContextMenuTraitDatasetId = dataset.id
    self.ContextMenuTraitId = trait.id
    menu:SetItems(items)
    menu:ShowAt(anchorFrame)
end

function DataEditor:RefreshTraitsDataPage()
    local dataset = self:GetSelectedDataset()
    local traits = dataset and dataset.traits or {}

    self:RefreshDataPageToolbar(self.TraitsPageButtons)

    if self.TraitsPageScroll and self.TraitsPageScroll.SetItems then
        self.TraitsPageScroll:SetItems(traits)
    end

    if self.TraitsPageEmptyText and self.TraitsPageEmptyText.SetText then
        if not dataset then
            self.TraitsPageEmptyText:SetText("Create or select a dataset to view traits.")
        elseif #traits == 0 then
            self.TraitsPageEmptyText:SetText("This dataset has no traits yet.")
        else
            self.TraitsPageEmptyText:SetText("")
        end
    end
end
