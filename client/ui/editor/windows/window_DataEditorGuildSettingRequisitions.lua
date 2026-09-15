local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Client.UI = Addon.Client.UI or {}
Addon.Client.UI.Editor = Addon.Client.UI.Editor or {}

local DataEditor = Addon.Client.UI.Editor
local UI = Addon.UI or {}
local Registry = Addon.Internal and Addon.Internal.Registry or {}

local FILTER_ALL = "__all"
local FILTER_OTHER = "__other"
local FILTER_CATEGORY_PREFIX = "category:"

local QUALITY_COLORS = {
    poor = { r = 0.62, g = 0.62, b = 0.62, a = 1 },
    common = { r = 1.0, g = 1.0, b = 1.0, a = 1 },
    uncommon = { r = 0.12, g = 1.0, b = 0.0, a = 1 },
    rare = { r = 0.0, g = 0.44, b = 0.87, a = 1 },
    epic = { r = 0.64, g = 0.21, b = 0.93, a = 1 },
    legendary = { r = 1.0, g = 0.50, b = 0.0, a = 1 },
}

local OldBuildGuildSettingInspectorPage = DataEditor.BuildGuildSettingInspectorPage
local OldRefreshGuildSettingRequisitionsPage = DataEditor.RefreshGuildSettingRequisitionsPage
local OldApplyGuildSettingInternalIdEditorPolicy = DataEditor.ApplyGuildSettingInternalIdEditorPolicy

local function trim(value)
    return tostring(value or ""):match("^%s*(.-)%s*$") or ""
end

local function normalizeInteger(value, fallback, minimum)
    local numeric = tonumber(value)
    if not numeric or numeric ~= numeric or numeric == math.huge or numeric == -math.huge then
        numeric = fallback
    end
    numeric = math.floor(tonumber(numeric) or 0)
    if minimum ~= nil then numeric = math.max(minimum, numeric) end
    return numeric
end

local function getCategoryLabel(category)
    local name = trim(category and category.name)
    return name ~= "" and name or "Category"
end

local function orderedCategories(setting)
    local categories = {}
    for index = 1, #(setting and setting.shopCategories or {}) do
        categories[#categories + 1] = setting.shopCategories[index]
    end
    table.sort(categories, function(left, right)
        local leftOrder = normalizeInteger(left and left.order, 0)
        local rightOrder = normalizeInteger(right and right.order, 0)
        if leftOrder ~= rightOrder then return leftOrder < rightOrder end
        local leftName = string.lower(getCategoryLabel(left))
        local rightName = string.lower(getCategoryLabel(right))
        if leftName ~= rightName then return leftName < rightName end
        return trim(left and left.id) < trim(right and right.id)
    end)
    return categories
end

local function categorySet(setting)
    local result = {}
    for index = 1, #(setting and setting.shopCategories or {}) do
        local id = trim(setting.shopCategories[index] and setting.shopCategories[index].id)
        if id ~= "" then result[id] = true end
    end
    return result
end

local function buildFilterItems(setting)
    local items = { { label = "All", value = FILTER_ALL } }
    for _, category in ipairs(orderedCategories(setting)) do
        local id = trim(category and category.id)
        if id ~= "" then
            items[#items + 1] = {
                label = getCategoryLabel(category),
                value = FILTER_CATEGORY_PREFIX .. id,
            }
        end
    end
    items[#items + 1] = { label = "Other", value = FILTER_OTHER }
    return items
end

local function normalizeFilter(setting, value)
    value = trim(value)
    if value == "" or value == FILTER_ALL or value == FILTER_OTHER then
        return value == FILTER_OTHER and FILTER_OTHER or FILTER_ALL
    end
    local categoryId = value:match("^" .. FILTER_CATEGORY_PREFIX .. "(.+)$")
    if categoryId and categorySet(setting)[categoryId] then return value end
    return FILTER_ALL
end

local function requisitionMatchesFilter(setting, requisition, filterValue)
    filterValue = normalizeFilter(setting, filterValue)
    if filterValue == FILTER_ALL then return true end

    local storedCategory = trim(requisition and requisition.shopCategoryId)
    if filterValue == FILTER_OTHER then
        return storedCategory == "" or categorySet(setting)[storedCategory] ~= true
    end

    local categoryId = filterValue:match("^" .. FILTER_CATEGORY_PREFIX .. "(.+)$")
    return categoryId ~= nil and storedCategory == categoryId
end

local function visibleRequisitions(setting, filterValue)
    local rows, rawIndices = {}, {}
    for rawIndex = 1, #(setting and setting.requisitions or {}) do
        local requisition = setting.requisitions[rawIndex]
        if requisitionMatchesFilter(setting, requisition, filterValue) then
            rows[#rows + 1] = requisition
            rawIndices[#rawIndices + 1] = rawIndex
        end
    end
    return rows, rawIndices
end

local function containsRawIndex(indices, rawIndex)
    if rawIndex == nil then return false end
    for index = 1, #(indices or {}) do
        if tonumber(indices[index]) == tonumber(rawIndex) then return true end
    end
    return false
end

local function resolveItem(requisition)
    local itemRef = trim(requisition and requisition.itemRef)
    if itemRef == "" then return nil, "Unassigned Item" end
    if type(Registry.ResolveItemReference) == "function" then
        local ok, _, item = pcall(Registry.ResolveItemReference, Registry, itemRef)
        if ok and type(item) == "table" then
            local name = trim(item.name)
            return item, name ~= "" and name or "Unnamed Item"
        end
    end
    return nil, "Missing Item"
end

local function qualityColor(item)
    local quality = type(item) == "table" and tostring(item.quality or "common") or ""
    if type(ITEM_QUALITY_COLORS) == "table" and ITEM_QUALITY_COLORS[quality] then
        local color = ITEM_QUALITY_COLORS[quality]
        return color.r or 1, color.g or 1, color.b or 1, color.a or 1
    end
    local color = QUALITY_COLORS[quality]
    if color then return color.r, color.g, color.b, color.a end
    local fallback = UI.ResolveColor(nil, "text.primary") or {}
    return fallback.r or 1, fallback.g or 1, fallback.b or 1, fallback.a or 1
end

local function setRowSelection(row, selected)
    if not row or not row.entryBackground or not row.entryBackground.SetColorTexture then return end
    local token = selected and "list.rowHover" or "list.rowBackground"
    local color = UI.ResolveColor(nil, token) or {}
    row.entryBackground:SetColorTexture(color.r or 0.08, color.g or 0.09, color.b or 0.11, color.a or 0.85)
end

function DataEditor:InstallGuildSettingRequisitionRowRenderer()
    local scroll = self.GuildSettingInspectorRequisitionScroll
    if not scroll then return end

    scroll:SetRowRenderer(function(row, requisition, visibleIndex)
        local item, itemName = resolveItem(requisition)
        row:SetCategory(itemName)
        row:SetTestName("")
        local quantity = normalizeInteger(requisition and requisition.quantity, 1, 1)
        local characterLimit = normalizeInteger(requisition and requisition.characterLimit, 1, 0)
        row:SetStatus(("x%d / %s"):format(quantity, characterLimit == 0 and "∞" or tostring(characterLimit)))
        row:SetDetail("")

        if row.categoryRegion and row.categoryRegion.SetTextColor then
            row.categoryRegion:SetTextColor(qualityColor(item))
        end

        local rawIndex = self.GuildSettingRequisitionVisibleRawIndices
            and self.GuildSettingRequisitionVisibleRawIndices[visibleIndex]
            or visibleIndex
        local frame = row.GetFrame and row:GetFrame() or nil
        if frame then
            frame:EnableMouse(true)
            frame:SetScript("OnMouseUp", function(_, button)
                if button == "LeftButton" then
                    self.SelectedGuildSettingRequisitionIndex = rawIndex
                    self.SelectedGuildSettingCostIndex = nil
                    self:RefreshGuildSettingRequisitionsPage()
                end
            end)
        end
        setRowSelection(row, tonumber(self.SelectedGuildSettingRequisitionIndex) == tonumber(rawIndex))
    end)
end

local function moveChildToFront(root, child)
    if not root or type(root.children) ~= "table" or not child then return end
    local found
    for index = 1, #root.children do
        if root.children[index] == child then found = index break end
    end
    if found and found > 1 then
        table.remove(root.children, found)
        table.insert(root.children, 1, child)
    end
    if root.RefreshLayout then root:RefreshLayout() end
end

function DataEditor:BuildGuildSettingRequisitionCategoryFilter()
    if self.GuildSettingRequisitionCategoryFilterRow then return end
    local page = self.GuildSettingInspectorRequisitionsPage
    local shell = page and page._guildSettingPageScrollShell or nil
    local root = shell and shell.root or nil
    if not root then return end

    local row = UI.CreateLayout(UI.HorizontalLayoutGroup, root:GetFrame(), "RPEDataEditorGuildSettingRequisitionCategoryFilterRow", {
        spacing = 4,
        height = 20,
        fitChildrenWidth = true,
        fitChildrenHeight = false,
    })
    row:AddChild(UI.CreateText(row:GetFrame(), "RPEDataEditorGuildSettingRequisitionCategoryFilterLabel", "Category", {
        width = 52,
        height = 20,
        justifyH = "LEFT",
        textColor = UI.ResolveColor(nil, "text.secondary"),
    }))
    self.GuildSettingRequisitionCategoryFilterDropdown = UI.CreateDropdown(row:GetFrame(), "RPEDataEditorGuildSettingRequisitionCategoryFilterDropdown", {
        width = 180,
        height = 20,
        expandWidth = true,
        weight = 1,
        items = { { label = "All", value = FILTER_ALL }, { label = "Other", value = FILTER_OTHER } },
        onValueChanged = function(value)
            if self._refreshingGuildSettingRequisitionCategoryFilter then return end
            self.GuildSettingRequisitionCategoryFilter = trim(value) ~= "" and value or FILTER_ALL
            self.SelectedGuildSettingCostIndex = nil
            self:RefreshGuildSettingRequisitionsPage()
        end,
    })
    row:AddChild(self.GuildSettingRequisitionCategoryFilterDropdown)
    root:AddChild(row)
    moveChildToFront(root, row)
    self.GuildSettingRequisitionCategoryFilterRow = row
end

function DataEditor:WrapGuildSettingRequisitionAddButton()
    local button = self.GuildSettingInspectorAddRequisitionButton
    if not button or button._categoryAwareAddWrapped == true then return end
    local frame = button.GetFrame and button:GetFrame() or nil
    if not frame or not frame.GetScript or not frame.SetScript then return end
    local original = frame:GetScript("OnClick")
    if type(original) ~= "function" then return end

    button._categoryAwareAddWrapped = true
    frame:SetScript("OnClick", function(...)
        local settingBefore = self:GetSelectedGuildSetting()
        local countBefore = #(settingBefore and settingBefore.requisitions or {})
        original(...)

        local setting = self:GetSelectedGuildSetting()
        local requisitions = setting and setting.requisitions or {}
        if #requisitions <= countBefore then return end

        local rawIndex = #requisitions
        local requisition = requisitions[rawIndex]
        local filterValue = normalizeFilter(setting, self.GuildSettingRequisitionCategoryFilter)
        if filterValue == FILTER_OTHER then
            requisition.shopCategoryId = ""
        else
            local categoryId = filterValue:match("^" .. FILTER_CATEGORY_PREFIX .. "(.+)$")
            if categoryId then requisition.shopCategoryId = categoryId end
        end
        self.SelectedGuildSettingRequisitionIndex = rawIndex
        self.SelectedGuildSettingCostIndex = nil
        self:RefreshGuildSettingRequisitionsPage()
    end)
end

function DataEditor:SetupGuildSettingRequisitionCategoryEditor()
    self:BuildGuildSettingRequisitionCategoryFilter()
    self:InstallGuildSettingRequisitionRowRenderer()
    self:WrapGuildSettingRequisitionAddButton()
end

if type(OldApplyGuildSettingInternalIdEditorPolicy) == "function" then
    function DataEditor:ApplyGuildSettingInternalIdEditorPolicy(...)
        local result = OldApplyGuildSettingInternalIdEditorPolicy(self, ...)
        self:SetupGuildSettingRequisitionCategoryEditor()
        return result
    end
end

if type(OldBuildGuildSettingInspectorPage) == "function" then
    function DataEditor:BuildGuildSettingInspectorPage(parent)
        local page = OldBuildGuildSettingInspectorPage(self, parent)
        self:SetupGuildSettingRequisitionCategoryEditor()
        return page
    end
end

if type(OldRefreshGuildSettingRequisitionsPage) == "function" then
    function DataEditor:RefreshGuildSettingRequisitionsPage(...)
        local setting = self:GetSelectedGuildSetting()
        local settingId = trim(setting and setting.id)
        if self._requisitionFilterSettingId ~= settingId then
            self._requisitionFilterSettingId = settingId
            self.GuildSettingRequisitionCategoryFilter = FILTER_ALL
        end

        local filterValue = normalizeFilter(setting, self.GuildSettingRequisitionCategoryFilter)
        self.GuildSettingRequisitionCategoryFilter = filterValue
        local rows, rawIndices = visibleRequisitions(setting, filterValue)
        self.GuildSettingRequisitionVisibleRawIndices = rawIndices

        if not containsRawIndex(rawIndices, self.SelectedGuildSettingRequisitionIndex) then
            self.SelectedGuildSettingRequisitionIndex = rawIndices[1]
            self.SelectedGuildSettingCostIndex = nil
        end

        local result = OldRefreshGuildSettingRequisitionsPage(self, ...)

        if self.GuildSettingRequisitionCategoryFilterDropdown then
            self._refreshingGuildSettingRequisitionCategoryFilter = true
            self.GuildSettingRequisitionCategoryFilterDropdown:SetItems(buildFilterItems(setting))
            self.GuildSettingRequisitionCategoryFilterDropdown:SetSelectedValue(filterValue, true)
            local filterFrame = self.GuildSettingRequisitionCategoryFilterDropdown.GetFrame
                and self.GuildSettingRequisitionCategoryFilterDropdown:GetFrame() or nil
            if filterFrame and filterFrame.EnableMouse then filterFrame:EnableMouse(setting ~= nil) end
            if filterFrame and filterFrame.SetAlpha then filterFrame:SetAlpha(setting and 1 or 0.5) end
            self._refreshingGuildSettingRequisitionCategoryFilter = false
        end

        if self.GuildSettingInspectorRequisitionScroll then
            self.GuildSettingInspectorRequisitionScroll:SetItems(rows)
        end
        self:InstallGuildSettingRequisitionRowRenderer()
        return result
    end
end

return DataEditor
