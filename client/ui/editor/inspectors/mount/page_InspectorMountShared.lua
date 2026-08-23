local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Client.UI = Addon.Client.UI or {}
Addon.Client.UI.Editor = Addon.Client.UI.Editor or {}

local DataEditor = Addon.Client.UI.Editor
local UI = Addon.UI or {}

local MountClass = Addon.Internal and Addon.Internal.Database and Addon.Internal.Database.Classes and Addon.Internal.Database.Classes.Mount or nil

DataEditor.MountInspectorSidePadding = DataEditor.MountInspectorSidePadding or 8
DataEditor.MountInspectorControlHeight = DataEditor.MountInspectorControlHeight or 20
DataEditor.MountInspectorFieldWidth = DataEditor.MountInspectorFieldWidth or 236

local MOUNT_INSPECTOR_PAGE_DEFINITIONS = {
    { key = "general", label = "General" },
    { key = "spells", label = "Spells" },
    { key = "stats", label = "Stats" },
}

local function applyTable(target, source)
    if type(target) ~= "table" or type(source) ~= "table" then
        return
    end

    for key in pairs(target) do
        if source[key] == nil then
            target[key] = nil
        end
    end

    for key, value in pairs(source) do
        target[key] = value
    end
end

function DataEditor:GetSelectedMount()
    local mount, _ = self:GetSelectedDatasetEntry("mounts")
    return mount
end

function DataEditor:GetSelectedMountAndDataset()
    return self:GetSelectedDataset(), self:GetSelectedMount()
end

function DataEditor:NormalizeMountDefinition(mount)
    if MountClass and MountClass.ToTable then
        return MountClass.ToTable(MountClass:New(mount))
    end

    return mount or {}
end

function DataEditor:CommitSelectedMount(mutate)
    local dataset, mount = self:GetSelectedMountAndDataset()
    if not dataset or not mount or type(mutate) ~= "function" then
        return
    end

    local before = self:DeepCopyValue(mount)
    mutate(mount, dataset)
    applyTable(mount, self:NormalizeMountDefinition(mount))

    if self:DeepEqualValues(before, mount) then
        return
    end

    self:QueuePendingDatasetEntryChanged(dataset.id, "mounts")
end

function DataEditor:SetMountInspectorDropdownEnabled(dropdown, enabled)
    local frame = dropdown and dropdown.GetFrame and dropdown:GetFrame() or nil
    if not frame then
        return
    end

    if frame.EnableMouse then
        frame:EnableMouse(enabled == true)
    end
    if frame.SetAlpha then
        frame:SetAlpha(enabled == true and 1 or 0.5)
    end
end

function DataEditor:SetMountInspectorTextElementEnabled(element, enabled)
    if not element then
        return
    end

    if element.SetEnabled then
        element:SetEnabled(enabled == true)
    end
    if element.SetReadOnly then
        element:SetReadOnly(enabled ~= true)
    end
end

function DataEditor:BuildMountInspectorLabel(parent, name, text, width)
    return UI.CreateText(parent, name, text, {
        fontFile = (UI.Constants and UI.Constants.FontFiles and UI.Constants.FontFiles.Default) or "Fonts\\FRIZQT__.TTF",
        fontSize = (UI.Constants and UI.Constants.FontSizes and UI.Constants.FontSizes.Body) or 8,
        textColor = UI.ResolveColor(nil, "text.secondary"),
        width = width or self.MountInspectorFieldWidth,
        height = 12,
        justifyH = "LEFT",
    })
end

function DataEditor:BuildMountInspectorReferencesAcrossDatasets(collectionKey)
    return self:BuildReferenceItemsAcrossDatasets(collectionKey, {
        includeNone = true,
        noneLabel = "None",
    })
end

function DataEditor:GetMountInspectorPageDefinitions()
    return MOUNT_INSPECTOR_PAGE_DEFINITIONS
end

function DataEditor:GetMountInspectorPageIndexByKey(key)
    local pages = self:GetMountInspectorPageDefinitions()
    for index = 1, #pages do
        if pages[index].key == key then
            return index
        end
    end

    return 1
end

function DataEditor:BuildMountInspectorPageSelectorItems()
    local items = {}
    local pages = self:GetMountInspectorPageDefinitions()

    for index = 1, #pages do
        items[#items + 1] = {
            label = pages[index].label,
            value = pages[index].key,
        }
    end

    return items
end

function DataEditor:RefreshMountInspectorPageSelector()
    local pages = self:GetMountInspectorPageDefinitions()
    local pageCount = #pages
    local activeIndex = math.max(1, math.min(self.ActiveMountInspectorPageIndex or 1, pageCount))
    self.ActiveMountInspectorPageIndex = activeIndex
    self.ActiveMountInspectorTabKey = pages[activeIndex] and pages[activeIndex].key or "general"

    local activeDefinition = pages[activeIndex]
    if self.MountInspectorPageDropdown and activeDefinition then
        self._refreshingMountInspectorPageSelector = true
        self.MountInspectorPageDropdown:SetSelectedValue(activeDefinition.key, true)
        self._refreshingMountInspectorPageSelector = false
    end

    if self.MountInspectorPreviousButton and self.MountInspectorPreviousButton.SetEnabled then
        self.MountInspectorPreviousButton:SetEnabled(activeIndex > 1)
    end

    if self.MountInspectorNextButton and self.MountInspectorNextButton.SetEnabled then
        self.MountInspectorNextButton:SetEnabled(activeIndex < pageCount)
    end
end

function DataEditor:SetMountInspectorTab(tabKey)
    local pages = self:GetMountInspectorPageDefinitions()
    self.ActiveMountInspectorPageIndex = self:GetMountInspectorPageIndexByKey(tabKey or "general")
    self.ActiveMountInspectorTabKey = pages[self.ActiveMountInspectorPageIndex] and pages[self.ActiveMountInspectorPageIndex].key or "general"

    local pageFrames = {
        general = self.MountInspectorGeneralPage,
        spells = self.MountInspectorSpellsPage,
        stats = self.MountInspectorStatsPage,
    }

    for key, page in pairs(pageFrames) do
        if page then
            if key == self.ActiveMountInspectorTabKey then
                page:Show()
            else
                page:Hide()
            end
        end
    end

    self:RefreshMountInspectorPageSelector()
end
