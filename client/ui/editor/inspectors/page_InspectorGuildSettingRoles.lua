local _, Addon = ...

Addon.Client = Addon.Client or {}
Addon.Client.UI = Addon.Client.UI or {}
Addon.Client.UI.Editor = Addon.Client.UI.Editor or {}

local DataEditor = Addon.Client.UI.Editor
local UI = Addon.UI or {}
local InspectorShared = DataEditor.ItemInspectorShared

local INSPECTOR_SIDE_PADDING = InspectorShared.INSPECTOR_SIDE_PADDING
local CONTROL_HEIGHT = InspectorShared.CONTROL_HEIGHT
local FIELD_WIDTH = InspectorShared.FIELD_WIDTH
local PAGE_SCROLLBAR_WIDTH = 12
local PAGE_SCROLLBAR_GAP = 4
local PAGE_SCROLLBAR_RIGHT_INSET = 4
local PAGE_SCROLL_STEP = 24
local DEFAULT_ICON = "Interface\\Icons\\INV_Misc_QuestionMark"

local PAGE_DEFINITIONS = {
    { key = "general", label = "General" },
    { key = "roles", label = "Roles" },
    { key = "shopCategories", label = "Shop Categories" },
    { key = "requisitions", label = "Requisitions" },
    { key = "dailyRewards", label = "Daily Rewards" },
}

local OldBuildRequisitionsPage = DataEditor.BuildGuildSettingInspectorRequisitionsPage
local OldBuildDailyRewardsPage = DataEditor.BuildGuildSettingInspectorDailyRewardsPage
local OldRefreshRequisitionsPage = DataEditor.RefreshGuildSettingRequisitionsPage
local OldRefreshDailyRewardsPage = DataEditor.RefreshGuildSettingDailyRewardsPage

local function trim(value)
    return tostring(value or ""):match("^%s*(.-)%s*$") or ""
end

local function createLabel(parent, name, text, width)
    return InspectorShared.buildLabel(parent, name, text, width)
end

local function setTextElementEnabled(element, enabled)
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

local function setDropdownEnabled(dropdown, enabled)
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

local function setElementGroupVisible(group, visible)
    if not group then
        return
    end
    local frame = group.GetFrame and group:GetFrame() or nil
    local targetHeight = visible and group._visibleHeight or 0
    if group.SetHeight then
        group:SetHeight(targetHeight or 0)
    elseif group.options then
        group.options.height = targetHeight or 0
    end
    if frame then
        if frame.SetHeight then
            frame:SetHeight(targetHeight or 0)
        end
        if visible then
            frame:Show()
        else
            frame:Hide()
        end
    end
end

local function createFieldGroup(parentLayout, name, labelText, height)
    return InspectorShared.createEquipmentFieldGroup(parentLayout, name, labelText, height)
end

local function setRowSelection(row, selected)
    if not row or not row.entryBackground or not row.entryBackground.SetColorTexture then
        return
    end
    local token = selected and "list.rowHover" or "list.rowBackground"
    local color = UI.ResolveColor(nil, token)
    row.entryBackground:SetColorTexture(color.r or 0.08, color.g or 0.09, color.b or 0.11, color.a or 0.85)
end

local function createCheckbox(parent, name, text, onValueChanged)
    local checkbox = UI.Checkbox:New({
        name = name,
        width = FIELD_WIDTH,
        height = 18,
        text = text,
        checked = false,
        border = false,
        fontFile = (UI.Constants and UI.Constants.FontFiles and UI.Constants.FontFiles.Default) or "Fonts\\FRIZQT__.TTF",
        fontSize = (UI.Constants and UI.Constants.FontSizes and UI.Constants.FontSizes.Checkbox) or 8,
        labelColor = UI.ResolveColor(nil, "text.primary"),
        onValueChanged = onValueChanged,
    })
    checkbox:SetParent(parent)
    checkbox:Create()
    return checkbox
end

local function normalizeInteger(value, fallback, minimum)
    local numeric = tonumber(value)
    if not numeric or numeric ~= numeric or numeric == math.huge or numeric == -math.huge then
        numeric = fallback
    end
    numeric = math.floor(tonumber(numeric) or 0)
    if minimum ~= nil then
        numeric = math.max(minimum, numeric)
    end
    return numeric
end

local function normalizeCharacterLimit(value)
    local numeric = tonumber(value)
    if not numeric or numeric ~= numeric or numeric == math.huge or numeric == -math.huge then
        return 1
    end
    if numeric == 0 then
        return 0
    end
    return math.max(1, math.floor(numeric))
end

local function buildUniqueStableId(entries, ignoredIndex, requestedId, prefix)
    local baseId = trim(requestedId)
    if baseId == "" then
        baseId = ("%s_1"):format(prefix)
    end
    local used = {}
    for index = 1, #(entries or {}) do
        if index ~= ignoredIndex then
            local id = trim(entries[index] and entries[index].id)
            if id ~= "" then
                used[id] = true
            end
        end
    end
    local candidate = baseId
    local suffix = 2
    while used[candidate] do
        candidate = ("%s_%d"):format(baseId, suffix)
        suffix = suffix + 1
    end
    return candidate
end

local function createPageScrollShell(page, rootName)
    local shell = {}
    local refreshing = false
    local root

    local function handleMouseWheel(_, delta)
        if not shell.scrollBar then
            return
        end
        local _, maxValue = shell.scrollBar:GetMinMaxValues()
        local current = shell.scrollBar:GetValue() or 0
        shell.scrollBar:SetValue(math.max(0, math.min(maxValue or 0, current - ((delta or 0) * PAGE_SCROLL_STEP))))
    end

    shell.scrollFrame = CreateFrame("ScrollFrame", rootName .. "ScrollFrame", page)
    shell.scrollFrame:SetPoint("TOPLEFT", page, "TOPLEFT", 0, 0)
    shell.scrollFrame:SetPoint("BOTTOMRIGHT", page, "BOTTOMRIGHT", -(PAGE_SCROLLBAR_WIDTH + PAGE_SCROLLBAR_GAP + PAGE_SCROLLBAR_RIGHT_INSET), 0)
    shell.scrollFrame:EnableMouseWheel(true)
    if shell.scrollFrame.SetClipsChildren then
        shell.scrollFrame:SetClipsChildren(true)
    end

    shell.scrollBar = CreateFrame("Slider", rootName .. "ScrollBar", page)
    shell.scrollBar:SetPoint("TOPRIGHT", page, "TOPRIGHT", -PAGE_SCROLLBAR_RIGHT_INSET, -2)
    shell.scrollBar:SetPoint("BOTTOMRIGHT", page, "BOTTOMRIGHT", -PAGE_SCROLLBAR_RIGHT_INSET, 2)
    shell.scrollBar:SetOrientation("VERTICAL")
    shell.scrollBar:SetMinMaxValues(0, 0)
    shell.scrollBar:SetValueStep(PAGE_SCROLL_STEP)
    if shell.scrollBar.SetObeyStepOnDrag then
        shell.scrollBar:SetObeyStepOnDrag(true)
    end
    shell.scrollBar:SetWidth(PAGE_SCROLLBAR_WIDTH)
    shell.scrollBar:Hide()

    local track = shell.scrollBar:CreateTexture(nil, "BACKGROUND")
    track:SetAllPoints(shell.scrollBar)
    local trackColor = UI.ResolveColor(nil, "scrollbar.track")
    track:SetColorTexture(trackColor.r or 0.08, trackColor.g or 0.09, trackColor.b or 0.11, trackColor.a or 0.95)
    shell.scrollBar:SetThumbTexture("Interface\\Buttons\\WHITE8x8")
    local thumb = shell.scrollBar.GetThumbTexture and shell.scrollBar:GetThumbTexture() or nil
    if thumb and thumb.SetVertexColor then
        local thumbColor = UI.ResolveColor(nil, "scrollbar.thumb")
        thumb:SetVertexColor(thumbColor.r or 0.42, thumbColor.g or 0.46, thumbColor.b or 0.52, thumbColor.a or 1)
    end

    local function refreshBounds()
        if not root or not root.GetFrame then
            return
        end
        local rootFrame = root:GetFrame()
        local contentHeight = rootFrame and rootFrame.GetHeight and rootFrame:GetHeight() or 0
        local viewportHeight = shell.scrollFrame:GetHeight() or 0
        local maxScroll = math.max(0, math.ceil(contentHeight - viewportHeight))
        shell.scrollBar:SetMinMaxValues(0, maxScroll)
        if shell.scrollBar.SetShown then
            shell.scrollBar:SetShown(maxScroll > 0)
        elseif maxScroll > 0 then
            shell.scrollBar:Show()
        else
            shell.scrollBar:Hide()
        end
        if shell.scrollBar.EnableMouse then
            shell.scrollBar:EnableMouse(maxScroll > 0)
        end
        local current = shell.scrollBar:GetValue() or 0
        if current > maxScroll then
            shell.scrollBar:SetValue(maxScroll)
        else
            shell.scrollFrame:SetVerticalScroll(math.max(0, math.min(current, maxScroll)))
        end
    end

    local function refreshLayout()
        if refreshing or not root or not root.GetFrame then
            return
        end
        refreshing = true
        root:GetFrame():SetWidth(math.max(1, shell.scrollFrame:GetWidth() or FIELD_WIDTH))
        if root.RefreshLayout then
            root:RefreshLayout()
        end
        refreshing = false
        refreshBounds()
    end

    root = UI.CreateLayout(UI.VerticalLayoutGroup, shell.scrollFrame, rootName, {
        spacing = 6,
        fitChildrenWidth = true,
        fitChildrenHeight = false,
        autoSize = true,
    })
    root:GetFrame():SetPoint("TOPLEFT", shell.scrollFrame, "TOPLEFT", 0, 0)
    root:GetFrame():SetPoint("TOPRIGHT", shell.scrollFrame, "TOPRIGHT", 0, 0)
    shell.root = root
    page._guildSettingPageScrollShell = shell
    shell.scrollFrame:SetScrollChild(root:GetFrame())
    shell.scrollBar:SetScript("OnValueChanged", function(_, value)
        shell.scrollFrame:SetVerticalScroll(value or 0)
    end)
    shell.scrollFrame:SetScript("OnMouseWheel", handleMouseWheel)
    shell.scrollFrame:SetScript("OnSizeChanged", refreshLayout)
    if root:GetFrame().HookScript then
        root:GetFrame():HookScript("OnSizeChanged", refreshBounds)
    end
    if page.HookScript then
        page:HookScript("OnShow", refreshLayout)
        page:HookScript("OnMouseWheel", handleMouseWheel)
    end
    shell.refreshLayout = refreshLayout
    shell.refreshScrollBounds = refreshBounds
    return root
end

local function refreshPageScroll(page)
    local shell = page and page._guildSettingPageScrollShell or nil
    if shell and shell.refreshLayout then
        shell.refreshLayout()
    end
end

local function getSelectedRole(self)
    local setting = self:GetSelectedGuildSetting()
    local roles = setting and setting.roles or {}
    local index = tonumber(self.SelectedGuildSettingRoleIndex)
    return setting, roles, index, index and roles[index] or nil
end

local function getSelectedCategory(self)
    local setting = self:GetSelectedGuildSetting()
    local categories = setting and setting.shopCategories or {}
    local index = tonumber(self.SelectedGuildSettingShopCategoryIndex)
    return setting, categories, index, index and categories[index] or nil
end

local function getSelectedRequisition(self)
    local setting = self:GetSelectedGuildSetting()
    local requisitions = setting and setting.requisitions or {}
    local index = tonumber(self.SelectedGuildSettingRequisitionIndex)
    return setting, requisitions, index, index and requisitions[index] or nil
end

local function getRoleLabel(role)
    local name = trim(role and role.name)
    return name ~= "" and name or trim(role and role.id)
end

local function getCategoryLabel(category)
    local name = trim(category and category.name)
    return name ~= "" and name or trim(category and category.id)
end

local function buildRoleDropdownItems(setting, storedRoleIds)
    local items = {}
    local seen = {}
    for index = 1, #(setting and setting.roles or {}) do
        local role = setting.roles[index]
        local roleId = trim(role and role.id)
        if roleId ~= "" and not seen[roleId] then
            seen[roleId] = true
            items[#items + 1] = {
                label = getRoleLabel(role) ~= "" and getRoleLabel(role) or roleId,
                value = roleId,
            }
        end
    end
    for index = 1, #(storedRoleIds or {}) do
        local roleId = trim(storedRoleIds[index])
        if roleId ~= "" and not seen[roleId] then
            seen[roleId] = true
            items[#items + 1] = {
                label = ("Missing Role: %s"):format(roleId),
                value = roleId,
            }
        end
    end
    return items
end

local function buildCategoryDropdownItems(setting, storedCategoryId)
    local categories = {}
    for index = 1, #(setting and setting.shopCategories or {}) do
        categories[#categories + 1] = setting.shopCategories[index]
    end
    table.sort(categories, function(left, right)
        local leftOrder = normalizeInteger(left and left.order, 0)
        local rightOrder = normalizeInteger(right and right.order, 0)
        if leftOrder ~= rightOrder then
            return leftOrder < rightOrder
        end
        local leftName = string.lower(getCategoryLabel(left))
        local rightName = string.lower(getCategoryLabel(right))
        if leftName ~= rightName then
            return leftName < rightName
        end
        return trim(left and left.id) < trim(right and right.id)
    end)

    local items = { { label = "None / Other", value = "" } }
    local seen = { [""] = true }
    for index = 1, #categories do
        local category = categories[index]
        local categoryId = trim(category and category.id)
        if categoryId ~= "" and not seen[categoryId] then
            seen[categoryId] = true
            items[#items + 1] = { label = getCategoryLabel(category), value = categoryId }
        end
    end
    local stored = trim(storedCategoryId)
    if stored ~= "" and not seen[stored] then
        items[#items + 1] = { label = ("Missing Category: %s"):format(stored), value = stored }
    end
    return items
end

local function getGuildRankCount()
    local functions = {
        _G and _G.GuildControlGetNumRanks,
        _G and _G.GetNumGuildRanks,
        _G and _G.C_GuildInfo and _G.C_GuildInfo.GuildControlGetNumRanks,
    }
    for index = 1, #functions do
        if type(functions[index]) == "function" then
            local ok, value = pcall(functions[index])
            value = ok and tonumber(value) or nil
            if value and value >= 0 then
                return math.floor(value)
            end
        end
    end
    return 0
end

local function getGuildRankName(zeroBasedIndex)
    local rankOrder = zeroBasedIndex + 1
    local functions = {
        _G and _G.GuildControlGetRankName,
        _G and _G.C_GuildInfo and _G.C_GuildInfo.GuildControlGetRankName,
    }
    for index = 1, #functions do
        if type(functions[index]) == "function" then
            local ok, value = pcall(functions[index], rankOrder)
            if ok and trim(value) ~= "" then
                return trim(value)
            end
        end
    end
    return ""
end

local function buildWowRankItems(role)
    local items = {}
    local seen = {}
    local count = getGuildRankCount()
    for rankIndex = 0, count - 1 do
        local name = getGuildRankName(rankIndex)
        local label = name ~= "" and ("%d — %s"):format(rankIndex, name) or ("Rank %d"):format(rankIndex)
        local value = tostring(rankIndex)
        seen[value] = true
        items[#items + 1] = { label = label, value = value }
    end
    for index = 1, #(role and role.wowGuildRankIndices or {}) do
        local rankIndex = normalizeInteger(role.wowGuildRankIndices[index], -1)
        if rankIndex >= 0 then
            local value = tostring(rankIndex)
            if not seen[value] then
                seen[value] = true
                items[#items + 1] = {
                    label = ("Unavailable WoW Rank %d"):format(rankIndex),
                    value = value,
                }
            end
        end
    end
    table.sort(items, function(left, right)
        return (tonumber(left.value) or math.huge) < (tonumber(right.value) or math.huge)
    end)
    return items
end

local function roleRankSelections(role)
    local values = {}
    for index = 1, #(role and role.wowGuildRankIndices or {}) do
        local rankIndex = normalizeInteger(role.wowGuildRankIndices[index], -1)
        if rankIndex >= 0 then
            values[#values + 1] = tostring(rankIndex)
        end
    end
    return values
end

local function migrateRoleReferences(setting, oldId, newId)
    if oldId == "" or newId == "" or oldId == newId then
        return
    end
    for requisitionIndex = 1, #(setting.requisitions or {}) do
        local requisition = setting.requisitions[requisitionIndex]
        local roleIds = type(requisition.roleIds) == "table" and requisition.roleIds or {}
        for roleIndex = 1, #roleIds do
            if trim(roleIds[roleIndex]) == oldId then
                roleIds[roleIndex] = newId
            end
        end
        requisition.roleIds = roleIds
    end
end

local function migrateCategoryReferences(setting, oldId, newId)
    if oldId == "" or oldId == newId then
        return
    end
    for requisitionIndex = 1, #(setting.requisitions or {}) do
        local requisition = setting.requisitions[requisitionIndex]
        if trim(requisition and requisition.shopCategoryId) == oldId then
            requisition.shopCategoryId = newId or ""
        end
    end
end

function DataEditor:GetGuildSettingInspectorPageDefinitions()
    return PAGE_DEFINITIONS
end

function DataEditor:GetGuildSettingInspectorPageIndexByKey(key)
    for index = 1, #PAGE_DEFINITIONS do
        if PAGE_DEFINITIONS[index].key == key then
            return index
        end
    end
    return 1
end

function DataEditor:BuildGuildSettingInspectorPageSelectorItems()
    local items = {}
    for index = 1, #PAGE_DEFINITIONS do
        items[#items + 1] = { label = PAGE_DEFINITIONS[index].label, value = PAGE_DEFINITIONS[index].key }
    end
    return items
end

function DataEditor:RefreshGuildSettingInspectorPageSelector()
    local pageCount = #PAGE_DEFINITIONS
    local activeIndex = math.max(1, math.min(self.ActiveGuildSettingInspectorPageIndex or 1, pageCount))
    self.ActiveGuildSettingInspectorPageIndex = activeIndex
    self.ActiveGuildSettingInspectorTabKey = PAGE_DEFINITIONS[activeIndex].key
    if self.GuildSettingInspectorPageDropdown then
        self._refreshingGuildSettingInspectorPageSelector = true
        self.GuildSettingInspectorPageDropdown:SetSelectedValue(self.ActiveGuildSettingInspectorTabKey, true)
        self._refreshingGuildSettingInspectorPageSelector = false
    end
    if self.GuildSettingInspectorPreviousButton then
        self.GuildSettingInspectorPreviousButton:SetEnabled(activeIndex > 1)
    end
    if self.GuildSettingInspectorNextButton then
        self.GuildSettingInspectorNextButton:SetEnabled(activeIndex < pageCount)
    end
end

function DataEditor:SetGuildSettingInspectorTab(tabKey)
    local activeIndex = self:GetGuildSettingInspectorPageIndexByKey(tabKey or "general")
    self.ActiveGuildSettingInspectorPageIndex = activeIndex
    self.ActiveGuildSettingInspectorTabKey = PAGE_DEFINITIONS[activeIndex].key
    local pages = {
        general = self.GuildSettingInspectorGeneralPage,
        roles = self.GuildSettingInspectorRolesPage,
        shopCategories = self.GuildSettingInspectorShopCategoriesPage,
        requisitions = self.GuildSettingInspectorRequisitionsPage,
        dailyRewards = self.GuildSettingInspectorDailyRewardsPage,
    }
    for key, page in pairs(pages) do
        if page then
            if key == self.ActiveGuildSettingInspectorTabKey then page:Show() else page:Hide() end
        end
    end
    refreshPageScroll(pages[self.ActiveGuildSettingInspectorTabKey])
    self:RefreshGuildSettingInspectorPageSelector()
end

function DataEditor:BuildGuildSettingInspectorPage(parent)
    if self.GuildSettingInspectorPage then
        self:RefreshGuildSettingInspectorPage()
        return self.GuildSettingInspectorPage
    end

    self.GuildSettingInspectorPage = CreateFrame("Frame", "RPEDataEditorGuildSettingInspectorPage", parent)
    self.GuildSettingInspectorSelectorBar = UI.CreateLayout(UI.HorizontalLayoutGroup, self.GuildSettingInspectorPage, "RPEDataEditorGuildSettingInspectorSelectorBar", {
        spacing = 4, fitChildrenWidth = true, fitChildrenHeight = false, height = 20,
    })
    self.GuildSettingInspectorSelectorBar:GetFrame():SetPoint("TOPLEFT", self.GuildSettingInspectorPage, "TOPLEFT", 0, 0)
    self.GuildSettingInspectorSelectorBar:GetFrame():SetPoint("TOPRIGHT", self.GuildSettingInspectorPage, "TOPRIGHT", 0, 0)

    self.GuildSettingInspectorPreviousButton = UI.CreateButton(self.GuildSettingInspectorSelectorBar:GetFrame(), "RPEDataEditorGuildSettingInspectorPreviousButton", "Prev", 40, function()
        local definition = PAGE_DEFINITIONS[(self.ActiveGuildSettingInspectorPageIndex or 1) - 1]
        self:SetGuildSettingInspectorTab(definition and definition.key or "general")
    end, { height = 20, fontSize = 7 })
    self.GuildSettingInspectorSelectorBar:AddChild(self.GuildSettingInspectorPreviousButton)

    self.GuildSettingInspectorPageDropdown = UI.CreateDropdown(self.GuildSettingInspectorSelectorBar:GetFrame(), "RPEDataEditorGuildSettingInspectorPageDropdown", {
        width = 118, height = 18, expandWidth = true, weight = 1,
        items = self:BuildGuildSettingInspectorPageSelectorItems(),
        onValueChanged = function(value)
            if not self._refreshingGuildSettingInspectorPageSelector then
                self:SetGuildSettingInspectorTab(value)
            end
        end,
    })
    self.GuildSettingInspectorSelectorBar:AddChild(self.GuildSettingInspectorPageDropdown)

    self.GuildSettingInspectorNextButton = UI.CreateButton(self.GuildSettingInspectorSelectorBar:GetFrame(), "RPEDataEditorGuildSettingInspectorNextButton", "Next", 40, function()
        local definition = PAGE_DEFINITIONS[(self.ActiveGuildSettingInspectorPageIndex or 1) + 1]
        self:SetGuildSettingInspectorTab(definition and definition.key or "dailyRewards")
    end, { height = 20, fontSize = 7 })
    self.GuildSettingInspectorSelectorBar:AddChild(self.GuildSettingInspectorNextButton)

    local function createPage(name)
        local page = CreateFrame("Frame", name, self.GuildSettingInspectorPage)
        page:SetPoint("TOPLEFT", self.GuildSettingInspectorPage, "TOPLEFT", INSPECTOR_SIDE_PADDING, -24)
        page:SetPoint("TOPRIGHT", self.GuildSettingInspectorPage, "TOPRIGHT", -INSPECTOR_SIDE_PADDING, -24)
        page:SetPoint("BOTTOMLEFT", self.GuildSettingInspectorPage, "BOTTOMLEFT", INSPECTOR_SIDE_PADDING, 24)
        page:SetPoint("BOTTOMRIGHT", self.GuildSettingInspectorPage, "BOTTOMRIGHT", -INSPECTOR_SIDE_PADDING, 24)
        return page
    end

    self.GuildSettingInspectorGeneralPage = createPage("RPEDataEditorGuildSettingInspectorGeneralPage")
    self:BuildGuildSettingInspectorGeneralPage(self.GuildSettingInspectorGeneralPage)
    self.GuildSettingInspectorRolesPage = createPage("RPEDataEditorGuildSettingInspectorRolesPage")
    self:BuildGuildSettingInspectorRolesPage(self.GuildSettingInspectorRolesPage)
    self.GuildSettingInspectorShopCategoriesPage = createPage("RPEDataEditorGuildSettingInspectorShopCategoriesPage")
    self:BuildGuildSettingInspectorShopCategoriesPage(self.GuildSettingInspectorShopCategoriesPage)
    self.GuildSettingInspectorRequisitionsPage = createPage("RPEDataEditorGuildSettingInspectorRequisitionsPage")
    self:BuildGuildSettingInspectorRequisitionsPage(self.GuildSettingInspectorRequisitionsPage)
    self.GuildSettingInspectorDailyRewardsPage = createPage("RPEDataEditorGuildSettingInspectorDailyRewardsPage")
    self:BuildGuildSettingInspectorDailyRewardsPage(self.GuildSettingInspectorDailyRewardsPage)

    self.GuildSettingInspectorEmptyText = createLabel(self.GuildSettingInspectorPage, "RPEDataEditorGuildSettingInspectorEmptyText", "")
    self.GuildSettingInspectorEmptyText:GetFrame():SetPoint("BOTTOMLEFT", self.GuildSettingInspectorPage, "BOTTOMLEFT", 0, 0)
    self:SetGuildSettingInspectorTab("general")
    self:RefreshGuildSettingInspectorPage()
    return self.GuildSettingInspectorPage
end

function DataEditor:BuildGuildSettingInspectorGeneralPage(parent)
    local root = createPageScrollShell(parent, "RPEDataEditorGuildSettingInspectorGeneralLayout")
    root:AddChild(createLabel(root:GetFrame(), "RPEDataEditorGuildSettingInspectorNameLabel", "Name"))
    self.GuildSettingInspectorNameInput = UI.CreateTextInput(root:GetFrame(), "RPEDataEditorGuildSettingInspectorNameInput", {
        width = FIELD_WIDTH, height = CONTROL_HEIGHT, text = "", borderColor = UI.ResolveColor(nil, "panel.border"),
    })
    local commitName = function()
        self:CommitSelectedGuildSetting(function(setting) setting.name = self.GuildSettingInspectorNameInput:GetText() end)
    end
    self.GuildSettingInspectorNameInput:SetScript("OnEnterPressed", commitName)
    self.GuildSettingInspectorNameInput:SetScript("OnEditFocusLost", commitName)
    root:AddChild(self.GuildSettingInspectorNameInput)

    self.GuildSettingInspectorIdText = createLabel(root:GetFrame(), "RPEDataEditorGuildSettingInspectorIdText", "ID: -")
    root:AddChild(self.GuildSettingInspectorIdText)

    root:AddChild(createLabel(root:GetFrame(), "RPEDataEditorGuildSettingInspectorDescriptionLabel", "Description"))
    self.GuildSettingInspectorDescriptionInput = UI.CreateTextArea(root:GetFrame(), "RPEDataEditorGuildSettingInspectorDescriptionInput", {
        width = FIELD_WIDTH, height = 68, text = "", readOnly = false, borderColor = UI.ResolveColor(nil, "panel.border"),
    })
    self.GuildSettingInspectorDescriptionInput:SetScript("OnEditFocusLost", function()
        self:CommitSelectedGuildSetting(function(setting) setting.description = self.GuildSettingInspectorDescriptionInput:GetText() end)
    end)
    root:AddChild(self.GuildSettingInspectorDescriptionInput)

    root:AddChild(createLabel(root:GetFrame(), "RPEDataEditorGuildSettingInspectorGuildNameLabel", "Guild Name"))
    self.GuildSettingInspectorGuildNameInput = UI.CreateTextInput(root:GetFrame(), "RPEDataEditorGuildSettingInspectorGuildNameInput", {
        width = FIELD_WIDTH, height = CONTROL_HEIGHT, text = "", borderColor = UI.ResolveColor(nil, "panel.border"),
    })
    local commitGuildName = function()
        self:CommitSelectedGuildSetting(function(setting) setting.guildName = self.GuildSettingInspectorGuildNameInput:GetText() end)
    end
    self.GuildSettingInspectorGuildNameInput:SetScript("OnEnterPressed", commitGuildName)
    self.GuildSettingInspectorGuildNameInput:SetScript("OnEditFocusLost", commitGuildName)
    root:AddChild(self.GuildSettingInspectorGuildNameInput)

    self.GuildSettingInspectorEnableRequisitionsCheckbox = createCheckbox(root:GetFrame(), "RPEDataEditorGuildSettingInspectorEnableRequisitionsCheckbox", "Enable Requisitions", function(value)
        if self._refreshingGuildSettingInspector then return end
        self:CommitSelectedGuildSetting(function(setting)
            setting.general = setting.general or {}
            setting.general.enableRequisitions = value == true
        end)
    end)
    root:AddChild(self.GuildSettingInspectorEnableRequisitionsCheckbox)

    self.GuildSettingInspectorEnableDailyRewardsCheckbox = createCheckbox(root:GetFrame(), "RPEDataEditorGuildSettingInspectorEnableDailyRewardsCheckbox", "Enable Daily Rewards", function(value)
        if self._refreshingGuildSettingInspector then return end
        self:CommitSelectedGuildSetting(function(setting)
            setting.general = setting.general or {}
            setting.general.enableDailyRewards = value == true
        end)
    end)
    root:AddChild(self.GuildSettingInspectorEnableDailyRewardsCheckbox)

    root:AddChild(createLabel(root:GetFrame(), "RPEDataEditorGuildSettingInspectorTagsLabel", "Tags"))
    self.GuildSettingInspectorTagsInput = UI.CreateTextInput(root:GetFrame(), "RPEDataEditorGuildSettingInspectorTagsInput", {
        width = FIELD_WIDTH, height = CONTROL_HEIGHT, text = "", borderColor = UI.ResolveColor(nil, "panel.border"),
    })
    local commitTags = function()
        self:CommitSelectedGuildSetting(function(setting)
            setting.tags = UI.Utils.ParseCommaSeparatedList(self.GuildSettingInspectorTagsInput:GetText())
        end)
    end
    self.GuildSettingInspectorTagsInput:SetScript("OnEnterPressed", commitTags)
    self.GuildSettingInspectorTagsInput:SetScript("OnEditFocusLost", commitTags)
    root:AddChild(self.GuildSettingInspectorTagsInput)
    refreshPageScroll(parent)
end

function DataEditor:BuildGuildSettingInspectorRolesPage(parent)
    local root = createPageScrollShell(parent, "RPEDataEditorGuildSettingInspectorRolesLayout")
    local _, section = InspectorShared.createInspectorSection(root, "RPEDataEditorGuildSettingInspectorRolesPanel", "Roles", 96)
    self.GuildSettingInspectorRoleScroll = UI.ScrollLayout:New({
        name = "RPEDataEditorGuildSettingInspectorRoleScroll", width = FIELD_WIDTH - 12, height = 68,
        visibleRows = 4, autoFitRows = true, rowHeight = 18, rowSpacing = 0, border = false,
        rowElementClass = UI.ScrollListEntry, categoryWidth = 160, statusWidth = 44, categoryInsetLeft = 4, statusInsetRight = 4,
    })
    self.GuildSettingInspectorRoleScroll:SetParent(section:GetFrame())
    self.GuildSettingInspectorRoleScroll:SetRowRenderer(function(row, role, itemIndex)
        row:SetCategory(getRoleLabel(role) ~= "" and getRoleLabel(role) or "-")
        row:SetTestName("")
        row:SetStatus(("%d map"):format(#(role and role.wowGuildRankIndices or {})))
        row:SetDetail(trim(role and role.id))
        local frame = row.GetFrame and row:GetFrame() or nil
        if frame then
            frame:EnableMouse(true)
            frame:SetScript("OnMouseUp", function(_, button)
                if button == "LeftButton" then
                    self.SelectedGuildSettingRoleIndex = itemIndex
                    self:RefreshGuildSettingRolesPage()
                end
            end)
            setRowSelection(row, tonumber(self.SelectedGuildSettingRoleIndex) == tonumber(itemIndex))
        end
    end)
    self.GuildSettingInspectorRoleScroll:Create()
    section:AddChild(self.GuildSettingInspectorRoleScroll)

    local actions = UI.CreateLayout(UI.HorizontalLayoutGroup, root:GetFrame(), "RPEDataEditorGuildSettingInspectorRoleActions", {
        spacing = 2, height = 18, fitChildrenWidth = true, fitChildrenHeight = false,
    })
    self.GuildSettingInspectorAddRoleButton = UI.CreateButton(actions:GetFrame(), "RPEDataEditorGuildSettingInspectorAddRoleButton", "Add Role", 62, function()
        local setting = self:CommitSelectedGuildSetting(function(selected)
            selected.roles = selected.roles or {}
            selected.roles[#selected.roles + 1] = {
                id = buildUniqueStableId(selected.roles, nil, "", "role"),
                name = "New Role", description = "", icon = "", wowGuildRankIndices = {},
            }
        end)
        self.SelectedGuildSettingRoleIndex = setting and #(setting.roles or {}) or nil
        self:RefreshGuildSettingRolesPage()
        self:RefreshGuildSettingRequisitionsPage()
    end, { height = 18, fontSize = 7 })
    actions:AddChild(self.GuildSettingInspectorAddRoleButton)
    self.GuildSettingInspectorDeleteRoleButton = UI.CreateButton(actions:GetFrame(), "RPEDataEditorGuildSettingInspectorDeleteRoleButton", "Delete", 48, function()
        local selectedIndex = tonumber(self.SelectedGuildSettingRoleIndex)
        local setting = self:CommitSelectedGuildSetting(function(selected)
            if selectedIndex and selected.roles and selected.roles[selectedIndex] then
                -- Keep requisition.roleIds intact so deleting a Role cannot silently
                -- broaden access; the Requisition editor marks these as missing.
                table.remove(selected.roles, selectedIndex)
            end
        end)
        local roles = setting and setting.roles or {}
        self.SelectedGuildSettingRoleIndex = #roles > 0 and math.min(selectedIndex or 1, #roles) or nil
        self:RefreshGuildSettingRolesPage()
        self:RefreshGuildSettingRequisitionsPage()
    end, { height = 18, fontSize = 7 })
    actions:AddChild(self.GuildSettingInspectorDeleteRoleButton)
    root:AddChild(actions)

    root:AddChild(createLabel(root:GetFrame(), "RPEDataEditorGuildSettingInspectorRoleIdLabel", "Role ID"))
    self.GuildSettingInspectorRoleIdInput = UI.CreateTextInput(root:GetFrame(), "RPEDataEditorGuildSettingInspectorRoleIdInput", {
        width = FIELD_WIDTH, height = CONTROL_HEIGHT, text = "", borderColor = UI.ResolveColor(nil, "panel.border"),
    })
    local commitRoleId = function()
        local _, _, selectedIndex, selectedRole = getSelectedRole(self)
        local oldId = trim(selectedRole and selectedRole.id)
        self:CommitSelectedGuildSetting(function(setting)
            local role = setting.roles and setting.roles[selectedIndex]
            if role then
                local newId = buildUniqueStableId(setting.roles, selectedIndex, self.GuildSettingInspectorRoleIdInput:GetText(), "role")
                role.id = newId
                migrateRoleReferences(setting, oldId, newId)
            end
        end)
        self:RefreshGuildSettingRolesPage()
        self:RefreshGuildSettingRequisitionsPage()
    end
    self.GuildSettingInspectorRoleIdInput:SetScript("OnEnterPressed", commitRoleId)
    self.GuildSettingInspectorRoleIdInput:SetScript("OnEditFocusLost", commitRoleId)
    root:AddChild(self.GuildSettingInspectorRoleIdInput)

    root:AddChild(createLabel(root:GetFrame(), "RPEDataEditorGuildSettingInspectorRoleNameLabel", "Name"))
    self.GuildSettingInspectorRoleNameInput = UI.CreateTextInput(root:GetFrame(), "RPEDataEditorGuildSettingInspectorRoleNameInput", {
        width = FIELD_WIDTH, height = CONTROL_HEIGHT, text = "", borderColor = UI.ResolveColor(nil, "panel.border"),
    })
    local commitRoleName = function()
        local _, _, selectedIndex = getSelectedRole(self)
        self:CommitSelectedGuildSetting(function(setting)
            local role = setting.roles and setting.roles[selectedIndex]
            if role then role.name = self.GuildSettingInspectorRoleNameInput:GetText() end
        end)
        self:RefreshGuildSettingRolesPage()
        self:RefreshGuildSettingRequisitionsPage()
    end
    self.GuildSettingInspectorRoleNameInput:SetScript("OnEnterPressed", commitRoleName)
    self.GuildSettingInspectorRoleNameInput:SetScript("OnEditFocusLost", commitRoleName)
    root:AddChild(self.GuildSettingInspectorRoleNameInput)

    root:AddChild(createLabel(root:GetFrame(), "RPEDataEditorGuildSettingInspectorRoleDescriptionLabel", "Description"))
    self.GuildSettingInspectorRoleDescriptionInput = UI.CreateTextArea(root:GetFrame(), "RPEDataEditorGuildSettingInspectorRoleDescriptionInput", {
        width = FIELD_WIDTH, height = 54, text = "", readOnly = false, borderColor = UI.ResolveColor(nil, "panel.border"),
    })
    self.GuildSettingInspectorRoleDescriptionInput:SetScript("OnEditFocusLost", function()
        local _, _, selectedIndex = getSelectedRole(self)
        self:CommitSelectedGuildSetting(function(setting)
            local role = setting.roles and setting.roles[selectedIndex]
            if role then role.description = self.GuildSettingInspectorRoleDescriptionInput:GetText() end
        end)
    end)
    root:AddChild(self.GuildSettingInspectorRoleDescriptionInput)

    root:AddChild(createLabel(root:GetFrame(), "RPEDataEditorGuildSettingInspectorRoleIconLabel", "Icon"))
    self.GuildSettingInspectorRoleIconField = UI.EditorIconField:New({
        name = "RPEDataEditorGuildSettingInspectorRoleIconField", width = FIELD_WIDTH, height = CONTROL_HEIGHT,
        buttonText = "Select Icon", labelText = "-", iconTexture = DEFAULT_ICON, border = false,
    })
    self.GuildSettingInspectorRoleIconField:SetParent(root:GetFrame())
    self.GuildSettingInspectorRoleIconField:Create()
    local iconButton = self.GuildSettingInspectorRoleIconField:GetButton()
    if iconButton and iconButton.SetScript then
        iconButton:SetScript("OnClick", function()
            local _, _, selectedIndex, role = getSelectedRole(self)
            local client = Addon.Client or {}
            if not role or type(client.OpenIconFinder) ~= "function" then return end
            client:OpenIconFinder(function(_, filePath)
                self:CommitSelectedGuildSetting(function(setting)
                    local selectedRole = setting.roles and setting.roles[selectedIndex]
                    if selectedRole then selectedRole.icon = filePath or "" end
                end)
                self:RefreshGuildSettingRolesPage()
            end, { filter = type(role.icon) == "string" and role.icon or "" })
        end)
    end
    root:AddChild(self.GuildSettingInspectorRoleIconField)

    root:AddChild(createLabel(root:GetFrame(), "RPEDataEditorGuildSettingInspectorRoleWowRankLabel", "Mapped WoW Guild Ranks"))
    self.GuildSettingInspectorRoleWowRankHint = UI.CreateText(root:GetFrame(), "RPEDataEditorGuildSettingInspectorRoleWowRankHint",
        "Select any exact WoW guild rank indexes that automatically grant this Role. No selection means manual assignment only.", {
            width = FIELD_WIDTH, height = 28, justifyH = "LEFT", wordWrap = true,
            textColor = UI.ResolveColor(nil, "text.secondary"),
        })
    root:AddChild(self.GuildSettingInspectorRoleWowRankHint)
    self.GuildSettingInspectorRoleWowRankDropdown = UI.CreateDropdown(root:GetFrame(), "RPEDataEditorGuildSettingInspectorRoleWowRankDropdown", {
        width = FIELD_WIDTH, height = CONTROL_HEIGHT, multiSelect = true, showSelectionActions = true,
        items = {},
        onValueChanged = function(values)
            if self._refreshingGuildSettingInspector then return end
            local _, _, selectedIndex = getSelectedRole(self)
            local normalized = {}
            local seen = {}
            for index = 1, #(values or {}) do
                local value = normalizeInteger(values[index], -1)
                if value >= 0 and not seen[value] then
                    seen[value] = true
                    normalized[#normalized + 1] = value
                end
            end
            table.sort(normalized)
            self:CommitSelectedGuildSetting(function(setting)
                local role = setting.roles and setting.roles[selectedIndex]
                if role then role.wowGuildRankIndices = normalized end
            end)
            self:RefreshGuildSettingRolesPage()
        end,
    })
    root:AddChild(self.GuildSettingInspectorRoleWowRankDropdown)
    refreshPageScroll(parent)
end

function DataEditor:BuildGuildSettingInspectorShopCategoriesPage(parent)
    local root = createPageScrollShell(parent, "RPEDataEditorGuildSettingInspectorShopCategoriesLayout")
    local _, section = InspectorShared.createInspectorSection(root, "RPEDataEditorGuildSettingInspectorShopCategoriesPanel", "Shop Categories", 96)
    self.GuildSettingInspectorShopCategoryScroll = UI.ScrollLayout:New({
        name = "RPEDataEditorGuildSettingInspectorShopCategoryScroll", width = FIELD_WIDTH - 12, height = 68,
        visibleRows = 4, autoFitRows = true, rowHeight = 18, rowSpacing = 0, border = false,
        rowElementClass = UI.ScrollListEntry, categoryWidth = 150, statusWidth = 50, categoryInsetLeft = 4, statusInsetRight = 4,
    })
    self.GuildSettingInspectorShopCategoryScroll:SetParent(section:GetFrame())
    self.GuildSettingInspectorShopCategoryScroll:SetRowRenderer(function(row, category, itemIndex)
        row:SetCategory(getCategoryLabel(category) ~= "" and getCategoryLabel(category) or "-")
        row:SetTestName("")
        row:SetStatus(tostring(normalizeInteger(category and category.order, itemIndex * 10)))
        row:SetDetail(trim(category and category.id))
        local frame = row.GetFrame and row:GetFrame() or nil
        if frame then
            frame:EnableMouse(true)
            frame:SetScript("OnMouseUp", function(_, button)
                if button == "LeftButton" then
                    self.SelectedGuildSettingShopCategoryIndex = itemIndex
                    self:RefreshGuildSettingShopCategoriesPage()
                end
            end)
            setRowSelection(row, tonumber(self.SelectedGuildSettingShopCategoryIndex) == tonumber(itemIndex))
        end
    end)
    self.GuildSettingInspectorShopCategoryScroll:Create()
    section:AddChild(self.GuildSettingInspectorShopCategoryScroll)

    local actions = UI.CreateLayout(UI.HorizontalLayoutGroup, root:GetFrame(), "RPEDataEditorGuildSettingInspectorShopCategoryActions", {
        spacing = 2, height = 18, fitChildrenWidth = true, fitChildrenHeight = false,
    })
    self.GuildSettingInspectorAddShopCategoryButton = UI.CreateButton(actions:GetFrame(), "RPEDataEditorGuildSettingInspectorAddShopCategoryButton", "Add Category", 78, function()
        local setting = self:CommitSelectedGuildSetting(function(selected)
            selected.shopCategories = selected.shopCategories or {}
            selected.shopCategories[#selected.shopCategories + 1] = {
                id = buildUniqueStableId(selected.shopCategories, nil, "", "shop_category"),
                name = "New Category",
                order = (#selected.shopCategories + 1) * 10,
            }
        end)
        self.SelectedGuildSettingShopCategoryIndex = setting and #(setting.shopCategories or {}) or nil
        self:RefreshGuildSettingShopCategoriesPage()
        self:RefreshGuildSettingRequisitionsPage()
    end, { height = 18, fontSize = 7 })
    actions:AddChild(self.GuildSettingInspectorAddShopCategoryButton)
    self.GuildSettingInspectorDeleteShopCategoryButton = UI.CreateButton(actions:GetFrame(), "RPEDataEditorGuildSettingInspectorDeleteShopCategoryButton", "Delete", 48, function()
        local selectedIndex = tonumber(self.SelectedGuildSettingShopCategoryIndex)
        local _, _, _, category = getSelectedCategory(self)
        local oldId = trim(category and category.id)
        local setting = self:CommitSelectedGuildSetting(function(selected)
            if selectedIndex and selected.shopCategories and selected.shopCategories[selectedIndex] then
                table.remove(selected.shopCategories, selectedIndex)
                migrateCategoryReferences(selected, oldId, "")
            end
        end)
        local categories = setting and setting.shopCategories or {}
        self.SelectedGuildSettingShopCategoryIndex = #categories > 0 and math.min(selectedIndex or 1, #categories) or nil
        self:RefreshGuildSettingShopCategoriesPage()
        self:RefreshGuildSettingRequisitionsPage()
    end, { height = 18, fontSize = 7 })
    actions:AddChild(self.GuildSettingInspectorDeleteShopCategoryButton)
    root:AddChild(actions)

    root:AddChild(createLabel(root:GetFrame(), "RPEDataEditorGuildSettingInspectorShopCategoryIdLabel", "Category ID"))
    self.GuildSettingInspectorShopCategoryIdInput = UI.CreateTextInput(root:GetFrame(), "RPEDataEditorGuildSettingInspectorShopCategoryIdInput", {
        width = FIELD_WIDTH, height = CONTROL_HEIGHT, text = "", borderColor = UI.ResolveColor(nil, "panel.border"),
    })
    local commitCategoryId = function()
        local _, _, selectedIndex, category = getSelectedCategory(self)
        local oldId = trim(category and category.id)
        self:CommitSelectedGuildSetting(function(setting)
            local selectedCategory = setting.shopCategories and setting.shopCategories[selectedIndex]
            if selectedCategory then
                local newId = buildUniqueStableId(setting.shopCategories, selectedIndex, self.GuildSettingInspectorShopCategoryIdInput:GetText(), "shop_category")
                selectedCategory.id = newId
                migrateCategoryReferences(setting, oldId, newId)
            end
        end)
        self:RefreshGuildSettingShopCategoriesPage()
        self:RefreshGuildSettingRequisitionsPage()
    end
    self.GuildSettingInspectorShopCategoryIdInput:SetScript("OnEnterPressed", commitCategoryId)
    self.GuildSettingInspectorShopCategoryIdInput:SetScript("OnEditFocusLost", commitCategoryId)
    root:AddChild(self.GuildSettingInspectorShopCategoryIdInput)

    root:AddChild(createLabel(root:GetFrame(), "RPEDataEditorGuildSettingInspectorShopCategoryNameLabel", "Name"))
    self.GuildSettingInspectorShopCategoryNameInput = UI.CreateTextInput(root:GetFrame(), "RPEDataEditorGuildSettingInspectorShopCategoryNameInput", {
        width = FIELD_WIDTH, height = CONTROL_HEIGHT, text = "", borderColor = UI.ResolveColor(nil, "panel.border"),
    })
    local commitCategoryName = function()
        local _, _, selectedIndex = getSelectedCategory(self)
        self:CommitSelectedGuildSetting(function(setting)
            local category = setting.shopCategories and setting.shopCategories[selectedIndex]
            if category then category.name = self.GuildSettingInspectorShopCategoryNameInput:GetText() end
        end)
        self:RefreshGuildSettingShopCategoriesPage()
        self:RefreshGuildSettingRequisitionsPage()
    end
    self.GuildSettingInspectorShopCategoryNameInput:SetScript("OnEnterPressed", commitCategoryName)
    self.GuildSettingInspectorShopCategoryNameInput:SetScript("OnEditFocusLost", commitCategoryName)
    root:AddChild(self.GuildSettingInspectorShopCategoryNameInput)

    root:AddChild(createLabel(root:GetFrame(), "RPEDataEditorGuildSettingInspectorShopCategoryOrderLabel", "Order"))
    self.GuildSettingInspectorShopCategoryOrderInput = UI.CreateTextInput(root:GetFrame(), "RPEDataEditorGuildSettingInspectorShopCategoryOrderInput", {
        width = FIELD_WIDTH, height = CONTROL_HEIGHT, text = "0", borderColor = UI.ResolveColor(nil, "panel.border"),
    })
    local commitCategoryOrder = function()
        local _, _, selectedIndex, category = getSelectedCategory(self)
        self:CommitSelectedGuildSetting(function(setting)
            local selectedCategory = setting.shopCategories and setting.shopCategories[selectedIndex]
            if selectedCategory then
                selectedCategory.order = normalizeInteger(self.GuildSettingInspectorShopCategoryOrderInput:GetText(), category and category.order or 0)
            end
        end)
        self:RefreshGuildSettingShopCategoriesPage()
        self:RefreshGuildSettingRequisitionsPage()
    end
    self.GuildSettingInspectorShopCategoryOrderInput:SetScript("OnEnterPressed", commitCategoryOrder)
    self.GuildSettingInspectorShopCategoryOrderInput:SetScript("OnEditFocusLost", commitCategoryOrder)
    root:AddChild(self.GuildSettingInspectorShopCategoryOrderInput)
    refreshPageScroll(parent)
end

function DataEditor:BuildGuildSettingInspectorRequisitionsPage(parent)
    OldBuildRequisitionsPage(self, parent)
    local shell = parent and parent._guildSettingPageScrollShell or nil
    local root = shell and shell.root or nil
    if not root then return end

    local _, accessSection = InspectorShared.createInspectorSection(
        root,
        "RPEDataEditorGuildSettingInspectorRequisitionAccessPanel",
        "Access & Shop Placement",
        126
    )
    self.GuildSettingInspectorRequisitionAccessSection = accessSection
    root = accessSection

    root:AddChild(createLabel(root:GetFrame(), "RPEDataEditorGuildSettingInspectorAllowedRolesLabel", "Allowed Roles"))
    self.GuildSettingInspectorAllowedRolesHint = UI.CreateText(root:GetFrame(), "RPEDataEditorGuildSettingInspectorAllowedRolesHint",
        "No Roles selected = unrestricted. If one or more Roles are selected, any selected Role grants access.", {
            width = FIELD_WIDTH, height = 28, justifyH = "LEFT", wordWrap = true,
            textColor = UI.ResolveColor(nil, "text.secondary"),
        })
    root:AddChild(self.GuildSettingInspectorAllowedRolesHint)
    self.GuildSettingInspectorAllowedRolesDropdown = UI.CreateDropdown(root:GetFrame(), "RPEDataEditorGuildSettingInspectorAllowedRolesDropdown", {
        width = FIELD_WIDTH, height = CONTROL_HEIGHT, multiSelect = true, showSelectionActions = true, items = {},
        onValueChanged = function(values)
            if self._refreshingGuildSettingInspector then return end
            local _, _, selectedIndex = getSelectedRequisition(self)
            local selectedValues = {}
            for index = 1, #(values or {}) do selectedValues[#selectedValues + 1] = trim(values[index]) end
            self:CommitSelectedGuildSetting(function(setting)
                local requisition = setting.requisitions and setting.requisitions[selectedIndex]
                if requisition then requisition.roleIds = selectedValues end
            end)
            self:RefreshGuildSettingRequisitionsPage()
        end,
    })
    root:AddChild(self.GuildSettingInspectorAllowedRolesDropdown)

    local categoryGroup = createFieldGroup(root, "RPEDataEditorGuildSettingInspectorRequisitionCategoryGroup", "Shop Category")
    self.GuildSettingInspectorRequisitionCategoryDropdown = UI.CreateDropdown(categoryGroup:GetFrame(), "RPEDataEditorGuildSettingInspectorRequisitionCategoryDropdown", {
        width = FIELD_WIDTH, height = CONTROL_HEIGHT, items = { { label = "None / Other", value = "" } },
        onValueChanged = function(value)
            if self._refreshingGuildSettingInspector then return end
            local _, _, selectedIndex = getSelectedRequisition(self)
            self:CommitSelectedGuildSetting(function(setting)
                local requisition = setting.requisitions and setting.requisitions[selectedIndex]
                if requisition then requisition.shopCategoryId = trim(value) end
            end)
            self:RefreshGuildSettingRequisitionsPage()
        end,
    })
    categoryGroup:AddChild(self.GuildSettingInspectorRequisitionCategoryDropdown)
    self.GuildSettingInspectorRequisitionCategoryGroup = categoryGroup
    if accessSection.UpdateHeight then accessSection:UpdateHeight() end
    refreshPageScroll(parent)
end

function DataEditor:BuildGuildSettingInspectorDailyRewardsPage(parent)
    OldBuildDailyRewardsPage(self, parent)
    local shell = parent and parent._guildSettingPageScrollShell or nil
    local root = shell and shell.root or nil
    if not root then return end
    root:AddChild(createLabel(root:GetFrame(), "RPEDataEditorGuildSettingInspectorDailyRewardRolesLabel", "Allowed Roles"))
    self.GuildSettingInspectorDailyRewardRolesDropdown = UI.CreateDropdown(root:GetFrame(), "RPEDataEditorGuildSettingInspectorDailyRewardRolesDropdown", {
        width = FIELD_WIDTH, height = CONTROL_HEIGHT, multiSelect = true, showSelectionActions = true, items = {},
        onValueChanged = function(values)
            if self._refreshingGuildSettingInspector then return end
            local selectedIndex = tonumber(self.SelectedGuildSettingDailyRewardIndex)
            local roleIds = {}
            for index = 1, #(values or {}) do roleIds[#roleIds + 1] = trim(values[index]) end
            self:CommitSelectedGuildSetting(function(setting)
                local reward = setting.dailyRewards and setting.dailyRewards[selectedIndex]
                if reward then reward.roleIds = roleIds end
            end)
            self:RefreshGuildSettingDailyRewardsPage()
        end,
    })
    root:AddChild(self.GuildSettingInspectorDailyRewardRolesDropdown)
    refreshPageScroll(parent)
end

function DataEditor:RefreshGuildSettingInspectorGeneralPage(setting)
    local hasSetting = setting ~= nil
    local general = setting and setting.general or {}
    if self.GuildSettingInspectorNameInput then
        self.GuildSettingInspectorNameInput:SetText(setting and (setting.name or "") or "")
        setTextElementEnabled(self.GuildSettingInspectorNameInput, hasSetting)
    end
    if self.GuildSettingInspectorIdText then
        self.GuildSettingInspectorIdText:SetText(("ID: %s"):format(setting and tostring(setting.id or "") or "-"))
    end
    if self.GuildSettingInspectorDescriptionInput then
        self.GuildSettingInspectorDescriptionInput:SetText(setting and (setting.description or "") or "")
        setTextElementEnabled(self.GuildSettingInspectorDescriptionInput, hasSetting)
    end
    if self.GuildSettingInspectorGuildNameInput then
        self.GuildSettingInspectorGuildNameInput:SetText(setting and (setting.guildName or "") or "")
        setTextElementEnabled(self.GuildSettingInspectorGuildNameInput, hasSetting)
    end
    if self.GuildSettingInspectorEnableRequisitionsCheckbox then
        self.GuildSettingInspectorEnableRequisitionsCheckbox:SetChecked(general.enableRequisitions == true, true)
        self.GuildSettingInspectorEnableRequisitionsCheckbox:SetEnabled(hasSetting)
    end
    if self.GuildSettingInspectorEnableDailyRewardsCheckbox then
        self.GuildSettingInspectorEnableDailyRewardsCheckbox:SetChecked(general.enableDailyRewards == true, true)
        self.GuildSettingInspectorEnableDailyRewardsCheckbox:SetEnabled(hasSetting)
    end
    if self.GuildSettingInspectorTagsInput then
        self.GuildSettingInspectorTagsInput:SetText(setting and UI.Utils.JoinCommaSeparatedList(setting.tags or {}) or "")
        setTextElementEnabled(self.GuildSettingInspectorTagsInput, hasSetting)
    end
    refreshPageScroll(self.GuildSettingInspectorGeneralPage)
end

function DataEditor:RefreshGuildSettingRolesPage()
    local setting = self:GetSelectedGuildSetting()
    local roles = setting and setting.roles or {}
    local selectedIndex = tonumber(self.SelectedGuildSettingRoleIndex)
    if selectedIndex and not roles[selectedIndex] then
        selectedIndex = #roles > 0 and math.min(selectedIndex, #roles) or nil
        self.SelectedGuildSettingRoleIndex = selectedIndex
    end
    local role = selectedIndex and roles[selectedIndex] or nil
    if self.GuildSettingInspectorRoleScroll then self.GuildSettingInspectorRoleScroll:SetItems(roles) end
    if self.GuildSettingInspectorAddRoleButton then self.GuildSettingInspectorAddRoleButton:SetEnabled(setting ~= nil) end
    if self.GuildSettingInspectorDeleteRoleButton then self.GuildSettingInspectorDeleteRoleButton:SetEnabled(role ~= nil) end
    if self.GuildSettingInspectorRoleIdInput then
        self.GuildSettingInspectorRoleIdInput:SetText(role and (role.id or "") or "")
        setTextElementEnabled(self.GuildSettingInspectorRoleIdInput, role ~= nil)
    end
    if self.GuildSettingInspectorRoleNameInput then
        self.GuildSettingInspectorRoleNameInput:SetText(role and (role.name or "") or "")
        setTextElementEnabled(self.GuildSettingInspectorRoleNameInput, role ~= nil)
    end
    if self.GuildSettingInspectorRoleDescriptionInput then
        self.GuildSettingInspectorRoleDescriptionInput:SetText(role and (role.description or "") or "")
        setTextElementEnabled(self.GuildSettingInspectorRoleDescriptionInput, role ~= nil)
    end
    if self.GuildSettingInspectorRoleIconField then
        local icon = role and role.icon or ""
        self.GuildSettingInspectorRoleIconField:SetIcon(icon ~= "" and icon or DEFAULT_ICON)
        self.GuildSettingInspectorRoleIconField:SetLabelText(icon ~= "" and tostring(icon) or "-")
        self.GuildSettingInspectorRoleIconField:SetEnabled(role ~= nil)
    end
    if self.GuildSettingInspectorRoleWowRankDropdown then
        self.GuildSettingInspectorRoleWowRankDropdown:SetItems(buildWowRankItems(role))
        self.GuildSettingInspectorRoleWowRankDropdown:SetSelectedValues(roleRankSelections(role), true)
        setDropdownEnabled(self.GuildSettingInspectorRoleWowRankDropdown, role ~= nil)
    end
    refreshPageScroll(self.GuildSettingInspectorRolesPage)
end

function DataEditor:RefreshGuildSettingShopCategoriesPage()
    local setting = self:GetSelectedGuildSetting()
    local categories = setting and setting.shopCategories or {}
    local selectedIndex = tonumber(self.SelectedGuildSettingShopCategoryIndex)
    if selectedIndex and not categories[selectedIndex] then
        selectedIndex = #categories > 0 and math.min(selectedIndex, #categories) or nil
        self.SelectedGuildSettingShopCategoryIndex = selectedIndex
    end
    local category = selectedIndex and categories[selectedIndex] or nil
    if self.GuildSettingInspectorShopCategoryScroll then self.GuildSettingInspectorShopCategoryScroll:SetItems(categories) end
    if self.GuildSettingInspectorAddShopCategoryButton then self.GuildSettingInspectorAddShopCategoryButton:SetEnabled(setting ~= nil) end
    if self.GuildSettingInspectorDeleteShopCategoryButton then self.GuildSettingInspectorDeleteShopCategoryButton:SetEnabled(category ~= nil) end
    if self.GuildSettingInspectorShopCategoryIdInput then
        self.GuildSettingInspectorShopCategoryIdInput:SetText(category and (category.id or "") or "")
        setTextElementEnabled(self.GuildSettingInspectorShopCategoryIdInput, category ~= nil)
    end
    if self.GuildSettingInspectorShopCategoryNameInput then
        self.GuildSettingInspectorShopCategoryNameInput:SetText(category and (category.name or "") or "")
        setTextElementEnabled(self.GuildSettingInspectorShopCategoryNameInput, category ~= nil)
    end
    if self.GuildSettingInspectorShopCategoryOrderInput then
        self.GuildSettingInspectorShopCategoryOrderInput:SetText(tostring(category and normalizeInteger(category.order, 0) or 0))
        setTextElementEnabled(self.GuildSettingInspectorShopCategoryOrderInput, category ~= nil)
    end
    refreshPageScroll(self.GuildSettingInspectorShopCategoriesPage)
end

function DataEditor:RefreshGuildSettingRequisitionsPage()
    OldRefreshRequisitionsPage(self)
    local setting, _, _, requisition = getSelectedRequisition(self)
    if self.GuildSettingInspectorAllowedRolesDropdown then
        local roleIds = type(requisition and requisition.roleIds) == "table" and requisition.roleIds or {}
        self.GuildSettingInspectorAllowedRolesDropdown:SetItems(buildRoleDropdownItems(setting, roleIds))
        self.GuildSettingInspectorAllowedRolesDropdown:SetSelectedValues(roleIds, true)
        setDropdownEnabled(self.GuildSettingInspectorAllowedRolesDropdown, requisition ~= nil)
    end
    if self.GuildSettingInspectorRequisitionCategoryDropdown then
        local categoryId = trim(requisition and requisition.shopCategoryId)
        self.GuildSettingInspectorRequisitionCategoryDropdown:SetItems(buildCategoryDropdownItems(setting, categoryId))
        self.GuildSettingInspectorRequisitionCategoryDropdown:SetSelectedValue(categoryId, true)
        local unlimited = requisition ~= nil and normalizeCharacterLimit(requisition.characterLimit) == 0
        setDropdownEnabled(self.GuildSettingInspectorRequisitionCategoryDropdown, unlimited)
        setElementGroupVisible(self.GuildSettingInspectorRequisitionCategoryGroup, unlimited)
    end
    if self.GuildSettingInspectorRequisitionAccessSection and self.GuildSettingInspectorRequisitionAccessSection.UpdateHeight then
        self.GuildSettingInspectorRequisitionAccessSection:UpdateHeight()
    end
    refreshPageScroll(self.GuildSettingInspectorRequisitionsPage)
end

function DataEditor:RefreshGuildSettingDailyRewardsPage()
    OldRefreshDailyRewardsPage(self)
    local setting = self:GetSelectedGuildSetting()
    local reward = setting and setting.dailyRewards and setting.dailyRewards[tonumber(self.SelectedGuildSettingDailyRewardIndex)] or nil
    if self.GuildSettingInspectorDailyRewardRolesDropdown then
        local roleIds = type(reward and reward.roleIds) == "table" and reward.roleIds or {}
        self.GuildSettingInspectorDailyRewardRolesDropdown:SetItems(buildRoleDropdownItems(setting, roleIds))
        self.GuildSettingInspectorDailyRewardRolesDropdown:SetSelectedValues(roleIds, true)
        setDropdownEnabled(self.GuildSettingInspectorDailyRewardRolesDropdown, reward ~= nil)
    end
end

function DataEditor:RefreshGuildSettingInspectorPage()
    local setting = self:GetSelectedGuildSetting()
    local hasSetting = setting ~= nil
    self._refreshingGuildSettingInspector = true
    local selectedId = setting and setting.id or nil
    if selectedId ~= self._guildSettingInspectorSelectedId then
        self._guildSettingInspectorSelectedId = selectedId
        self.SelectedGuildSettingRoleIndex = setting and #(setting.roles or {}) > 0 and 1 or nil
        self.SelectedGuildSettingShopCategoryIndex = setting and #(setting.shopCategories or {}) > 0 and 1 or nil
        self.SelectedGuildSettingRequisitionIndex = setting and #(setting.requisitions or {}) > 0 and 1 or nil
        self.SelectedGuildSettingCostIndex = nil
        self.SelectedGuildSettingDailyRewardIndex = setting and #(setting.dailyRewards or {}) > 0 and 1 or nil
    end
    self:RefreshGuildSettingInspectorGeneralPage(setting)
    self:RefreshGuildSettingRolesPage()
    self:RefreshGuildSettingShopCategoriesPage()
    self:RefreshGuildSettingRequisitionsPage()
    OldRefreshDailyRewardsPage(self)
    if self.GuildSettingInspectorEmptyText then
        self.GuildSettingInspectorEmptyText:SetText(hasSetting and "" or "Select a Guild Setting to inspect it.")
    end
    self:RefreshGuildSettingInspectorPageSelector()
    self._refreshingGuildSettingInspector = false
end

return DataEditor
