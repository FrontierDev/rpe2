local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Client.UI = Addon.Client.UI or {}
Addon.Client.UI.Editor = Addon.Client.UI.Editor or {}

local DataEditor = Addon.Client.UI.Editor
local UI = Addon.UI or {}

function DataEditor:BuildMountInspectorPage(parent)
    if self.MountInspectorPage then
        self:RefreshMountInspectorPage()
        return self.MountInspectorPage
    end

    self.MountInspectorPage = CreateFrame("Frame", "RPEDataEditorMountInspectorPage", parent)

    self.MountInspectorSelectorBar = UI.CreateLayout(UI.HorizontalLayoutGroup, self.MountInspectorPage, "RPEDataEditorMountInspectorSelectorBar", {
        spacing = 4,
        fitChildrenWidth = true,
        fitChildrenHeight = false,
        height = 20,
    })
    self.MountInspectorSelectorBar:GetFrame():SetPoint("TOPLEFT", self.MountInspectorPage, "TOPLEFT", 0, 0)
    self.MountInspectorSelectorBar:GetFrame():SetPoint("TOPRIGHT", self.MountInspectorPage, "TOPRIGHT", 0, 0)

    self.MountInspectorPreviousButton = UI.CreateButton(self.MountInspectorSelectorBar:GetFrame(), "RPEDataEditorMountInspectorPreviousButton", "Prev", 40, function()
        self:SetMountInspectorTab((self:GetMountInspectorPageDefinitions()[(self.ActiveMountInspectorPageIndex or 1) - 1] or {}).key or "general")
    end, {
        height = 20,
        fontSize = 7,
    })
    self.MountInspectorSelectorBar:AddChild(self.MountInspectorPreviousButton)

    self.MountInspectorPageDropdown = UI.CreateDropdown(self.MountInspectorSelectorBar:GetFrame(), "RPEDataEditorMountInspectorPageDropdown", {
        width = 118,
        height = 18,
        expandWidth = true,
        weight = 1,
        items = self:BuildMountInspectorPageSelectorItems(),
        onValueChanged = function(value)
            if self._refreshingMountInspectorPageSelector then
                return
            end

            self:SetMountInspectorTab(value)
        end,
    })
    self.MountInspectorSelectorBar:AddChild(self.MountInspectorPageDropdown)

    self.MountInspectorNextButton = UI.CreateButton(self.MountInspectorSelectorBar:GetFrame(), "RPEDataEditorMountInspectorNextButton", "Next", 40, function()
        self:SetMountInspectorTab((self:GetMountInspectorPageDefinitions()[(self.ActiveMountInspectorPageIndex or 1) + 1] or {}).key or "stats")
    end, {
        height = 20,
        fontSize = 7,
    })
    self.MountInspectorSelectorBar:AddChild(self.MountInspectorNextButton)

    local function createPage(name)
        local page = CreateFrame("Frame", name, self.MountInspectorPage)
        page:SetPoint("TOPLEFT", self.MountInspectorPage, "TOPLEFT", self.MountInspectorSidePadding, -24)
        page:SetPoint("TOPRIGHT", self.MountInspectorPage, "TOPRIGHT", -self.MountInspectorSidePadding, -24)
        page:SetPoint("BOTTOMLEFT", self.MountInspectorPage, "BOTTOMLEFT", self.MountInspectorSidePadding, 24)
        page:SetPoint("BOTTOMRIGHT", self.MountInspectorPage, "BOTTOMRIGHT", -self.MountInspectorSidePadding, 24)
        return page
    end

    self.MountInspectorGeneralPage = createPage("RPEDataEditorMountInspectorGeneralPage")
    self:BuildMountInspectorGeneralPage(self.MountInspectorGeneralPage)

    self.MountInspectorSpellsPage = createPage("RPEDataEditorMountInspectorSpellsPage")
    self:BuildMountInspectorSpellsPage(self.MountInspectorSpellsPage)

    self.MountInspectorStatsPage = createPage("RPEDataEditorMountInspectorStatsPage")
    self:BuildMountInspectorStatsPage(self.MountInspectorStatsPage)

    self.MountInspectorEmptyText = UI.CreateText(self.MountInspectorPage, "RPEDataEditorMountInspectorEmptyText", "", {
        fontFile = (UI.Constants and UI.Constants.FontFiles and UI.Constants.FontFiles.Default) or "Fonts\\FRIZQT__.TTF",
        fontSize = (UI.Constants and UI.Constants.FontSizes and UI.Constants.FontSizes.Body) or 8,
        textColor = UI.ResolveColor(nil, "text.secondary"),
        width = self.MountInspectorFieldWidth,
        height = 20,
        justifyH = "LEFT",
    })
    self.MountInspectorEmptyText:GetFrame():SetPoint("BOTTOMLEFT", self.MountInspectorPage, "BOTTOMLEFT", 0, 0)

    self.ActiveMountInspectorPageIndex = self.ActiveMountInspectorPageIndex or self:GetMountInspectorPageIndexByKey(self.ActiveMountInspectorTabKey or "general")
    self:SetMountInspectorTab("general")
    self:RefreshMountInspectorPage()
    return self.MountInspectorPage
end

function DataEditor:RefreshMountInspectorPage()
    local _, mount = self:GetSelectedMountAndDataset()
    local hasMount = mount ~= nil

    self._refreshingMountInspector = true

    if self.MountInspectorNameInput then
        self.MountInspectorNameInput:SetText(mount and (mount.name or "") or "")
        self:SetMountInspectorTextElementEnabled(self.MountInspectorNameInput, hasMount)
    end
    if self.MountInspectorIdText then
        self.MountInspectorIdText:SetText(("ID: %s"):format(mount and mount.id ~= nil and tostring(mount.id) or "-"))
    end
    if self.MountInspectorIconInput then
        self.MountInspectorIconInput:SetText(mount and (mount.icon or "") or "")
        self:SetMountInspectorTextElementEnabled(self.MountInspectorIconInput, hasMount)
    end
    if self.MountInspectorDescriptionInput then
        self.MountInspectorDescriptionInput:SetText(mount and (mount.description or "") or "")
        self:SetMountInspectorTextElementEnabled(self.MountInspectorDescriptionInput, hasMount)
    end
    if self.MountInspectorPendingSpellDropdown then
        self.MountInspectorPendingSpellDropdown:SetItems(self:BuildMountInspectorReferencesAcrossDatasets("spells"))
        self:SetMountInspectorDropdownEnabled(self.MountInspectorPendingSpellDropdown, hasMount)
    end
    if self.MountInspectorAddSpellButton then
        self.MountInspectorAddSpellButton:SetEnabled(hasMount)
    end
    if self.MountInspectorPendingStatDropdown then
        self.MountInspectorPendingStatDropdown:SetItems(self:BuildMountInspectorReferencesAcrossDatasets("stats"))
        self:SetMountInspectorDropdownEnabled(self.MountInspectorPendingStatDropdown, hasMount)
    end
    if self.MountInspectorPendingStatValueInput then
        self:SetMountInspectorTextElementEnabled(self.MountInspectorPendingStatValueInput, hasMount)
    end
    if self.MountInspectorAddStatButton then
        self.MountInspectorAddStatButton:SetEnabled(hasMount)
    end

    self:RefreshMountInspectorSpellsTable()
    self:RefreshMountInspectorStatsTable()

    if self.MountInspectorEmptyText then
        self.MountInspectorEmptyText:SetText(hasMount and "Adjust the selected mount definition here." or "Select a mount to inspect it.")
    end

    self._refreshingMountInspector = false
    self:RefreshMountInspectorPageSelector()
end
