local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Client.UI = Addon.Client.UI or {}
Addon.Client.UI.Editor = Addon.Client.UI.Editor or {}

local DataEditor = Addon.Client.UI.Editor
local UI = Addon.UI or {}

local function buildMountStatusText(mount)
    mount = mount or {}
    return ("%d spell%s, %d stat%s"):format(
        #(mount.spells or {}),
        #(mount.spells or {}) == 1 and "" or "s",
        #(mount.stats or {}),
        #(mount.stats or {}) == 1 and "" or "s"
    )
end

local function buildMountDetailText(mount)
    mount = mount or {}
    if tostring(mount.description or "") ~= "" then
        return tostring(mount.description)
    end

    return "No description"
end

function DataEditor:BuildMountsPage(page)
    if self.MountsPageRoot then
        return self.MountsPageRoot
    end

    self.MountsPageRoot = UI.CreateLayout(UI.VerticalLayoutGroup, page, "RPEDataEditorMountsPageRoot", {
        spacing = 4,
        fitChildrenWidth = true,
        fitChildrenHeight = true,
    })
    UI.Utils.AnchorFill(self.MountsPageRoot, page, 0, 0, 0, 0)

    local listPanel = UI.CreatePanel(self.MountsPageRoot:GetFrame(), "RPEDataEditorMountsListPanel", {
        width = 150,
        expandHeight = true,
        weight = 1,
        contentInset = 2,
        showBorder = false,
    })
    self.MountsPageRoot:AddChild(listPanel)

    self.MountsPageScroll = UI.ScrollLayout:New({
        name = "RPEDataEditorMountsScroll",
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
    self.MountsPageScroll:SetParent(listPanel:GetContentFrame())
    self.MountsPageScroll:SetRowRenderer(function(row, mount, itemIndex)
        if row.SetCategory then
            row:SetCategory(self:GetEntryDisplayName("mounts", mount))
        end
        if row.SetTestName then
            row:SetTestName("")
        end
        if row.SetStatus then
            row:SetStatus(buildMountStatusText(mount))
        end
        if row.SetDetail then
            row:SetDetail(buildMountDetailText(mount))
        end

        local frame = row.GetFrame and row:GetFrame() or nil
        if frame then
            frame:EnableMouse(true)
            frame:SetScript("OnMouseUp", function(_, button)
                if button == "LeftButton" then
                    self:SetSelectedDatasetEntryIndex("mounts", itemIndex)
                end
            end)

            local _, selectedIndex = self:GetSelectedDatasetEntry("mounts")
            local isSelected = tonumber(selectedIndex) == tonumber(itemIndex)
            if row.entryBackground and row.entryBackground.SetColorTexture then
                local token = isSelected and "list.rowHover" or "list.rowBackground"
                local color = UI.ResolveColor(nil, token)
                row.entryBackground:SetColorTexture(color.r or 0.08, color.g or 0.09, color.b or 0.11, color.a or 0.85)
            end
        end
    end)
    self.MountsPageScroll:Create()
    UI.Utils.AnchorFill(self.MountsPageScroll, listPanel:GetContentFrame(), 0, 0, 0, 0)

    self.MountsPageEmptyText = UI.CreateText(listPanel:GetContentFrame(), "RPEDataEditorMountsEmptyText", "", {
        fontFile = (UI.Constants and UI.Constants.FontFiles and UI.Constants.FontFiles.Default) or "Fonts\\FRIZQT__.TTF",
        fontSize = (UI.Constants and UI.Constants.FontSizes and UI.Constants.FontSizes.Body) or 8,
        textColor = UI.ResolveColor(nil, "text.secondary"),
        width = 122,
        height = 36,
        justifyH = "CENTER",
        wordWrap = true,
    })
    self.MountsPageEmptyText:GetFrame():SetPoint("CENTER", listPanel:GetContentFrame(), "CENTER", 0, 0)

    self.MountsPageToolbar, self.MountsPageButtons = self:BuildDataPageToolbar(self.MountsPageRoot:GetFrame(), "RPEDataEditorMountsPageToolbar", "mounts")
    self.MountsPageRoot:AddChild(self.MountsPageToolbar)

    self:RefreshMountsDataPage()
    return self.MountsPageRoot
end

function DataEditor:RefreshMountsDataPage()
    local dataset = self:GetSelectedDataset()
    local mounts = dataset and dataset.mounts or {}

    self:RefreshDataPageToolbar(self.MountsPageButtons)

    if self.MountsPageScroll and self.MountsPageScroll.SetItems then
        self.MountsPageScroll:SetItems(mounts)
    end

    if self.MountsPageEmptyText and self.MountsPageEmptyText.SetText then
        if not dataset then
            self.MountsPageEmptyText:SetText("Create or select a dataset to view mounts.")
        elseif #mounts == 0 then
            self.MountsPageEmptyText:SetText("This dataset has no mounts yet.")
        else
            self.MountsPageEmptyText:SetText("")
        end
    end
end
